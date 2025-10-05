"""
Security utilities and decorators for Forkly API.

Includes input validation, sanitization, and security checks.
"""

import re
import hashlib
import secrets
import logging
from functools import wraps
from django.http import JsonResponse
from django.core.exceptions import ValidationError
from django.utils.html import escape
from django.utils.safestring import mark_safe
from django.core.validators import validate_email
from django.contrib.auth.password_validation import validate_password
from django.contrib.auth.models import User
from rest_framework.response import Response
from rest_framework import status

logger = logging.getLogger('api')


def validate_input_data(data, required_fields=None, optional_fields=None):
    """
    Validate and sanitize input data.
    
    Args:
        data: Dictionary of input data
        required_fields: List of required field names
        optional_fields: List of optional field names with their types
    
    Returns:
        tuple: (is_valid, sanitized_data, errors)
    """
    errors = []
    sanitized_data = {}
    
    # Check required fields
    if required_fields:
        for field in required_fields:
            if field not in data or not data[field]:
                errors.append(f"Field '{field}' is required")
    
    # Validate and sanitize fields
    for key, value in data.items():
        if value is None:
            continue
            
        # Sanitize string inputs
        if isinstance(value, str):
            # Remove potential XSS
            sanitized_value = escape(value.strip())
            
            # Validate email fields
            if key in ['email', 'username']:
                try:
                    if key == 'email':
                        validate_email(sanitized_value)
                    elif key == 'username':
                        if not re.match(r'^[a-zA-Z0-9._-]+$', sanitized_value):
                            errors.append(f"Invalid username format: {key}")
                        if len(sanitized_value) < 3 or len(sanitized_value) > 30:
                            errors.append(f"Username must be 3-30 characters: {key}")
                except ValidationError as e:
                    errors.append(f"Invalid {key}: {str(e)}")
            
            # Validate password
            elif key == 'password':
                try:
                    validate_password(sanitized_value)
                except ValidationError as e:
                    errors.append(f"Password validation failed: {', '.join(e.messages)}")
            
            # Validate phone numbers
            elif key == 'phone':
                if not re.match(r'^\+?[\d\s\-\(\)]+$', sanitized_value):
                    errors.append(f"Invalid phone number format: {key}")
            
            # Validate referral codes
            elif key == 'referral_code':
                if not re.match(r'^[A-Z0-9]{8}$', sanitized_value):
                    errors.append(f"Invalid referral code format: {key}")
            
            sanitized_data[key] = sanitized_value
        
        # Validate numeric inputs
        elif isinstance(value, (int, float)):
            if key in ['lat', 'lng']:
                if not (-90 <= value <= 90 if key == 'lat' else -180 <= value <= 180):
                    errors.append(f"Invalid {key} coordinate: {value}")
            elif key in ['radius', 'limit', 'offset']:
                if value < 0:
                    errors.append(f"Invalid {key}: must be positive")
            sanitized_data[key] = value
        
        else:
            sanitized_data[key] = value
    
    return len(errors) == 0, sanitized_data, errors


def rate_limit_by_user(view_func):
    """
    Decorator to apply rate limiting per user.
    """
    @wraps(view_func)
    def wrapper(request, *args, **kwargs):
        if not request.user.is_authenticated:
            return view_func(request, *args, **kwargs)
        
        user_id = request.user.id
        rate_key = f"user_rate_limit:{user_id}"
        
        # Check rate limit
        from django.core.cache import cache
        current_requests = cache.get(rate_key, 0)
        
        if current_requests >= 100:  # 100 requests per hour per user
            return JsonResponse({
                'error': 'User rate limit exceeded',
                'message': 'Too many requests. Please try again later.'
            }, status=429)
        
        # Increment counter
        cache.set(rate_key, current_requests + 1, timeout=3600)
        
        return view_func(request, *args, **kwargs)
    
    return wrapper


def require_https(view_func):
    """
    Decorator to require HTTPS in production.
    """
    @wraps(view_func)
    def wrapper(request, *args, **kwargs):
        if not request.is_secure() and not request.META.get('HTTP_X_FORWARDED_PROTO') == 'https':
            if hasattr(settings, 'IS_PRODUCTION') and settings.IS_PRODUCTION:
                return JsonResponse({
                    'error': 'HTTPS required',
                    'message': 'This endpoint requires HTTPS.'
                }, status=400)
        
        return view_func(request, *args, **kwargs)
    
    return wrapper


def log_security_event(event_type, user=None, ip_address=None, details=None):
    """
    Log security-related events.
    
    Args:
        event_type: Type of security event
        user: User object (optional)
        ip_address: IP address (optional)
        details: Additional details (optional)
    """
    event_data = {
        'event_type': event_type,
        'timestamp': timezone.now().isoformat(),
        'user_id': user.id if user else None,
        'username': user.username if user else None,
        'ip_address': ip_address,
        'details': details
    }
    
    logger.warning(f"Security Event: {event_data}")


def generate_secure_token(length=32):
    """
    Generate a cryptographically secure random token.
    
    Args:
        length: Length of the token
    
    Returns:
        str: Secure random token
    """
    return secrets.token_urlsafe(length)


def hash_sensitive_data(data):
    """
    Hash sensitive data for logging purposes.
    
    Args:
        data: Sensitive data to hash
    
    Returns:
        str: Hashed data
    """
    return hashlib.sha256(data.encode()).hexdigest()[:8]


def validate_coordinates(lat, lng):
    """
    Validate latitude and longitude coordinates.
    
    Args:
        lat: Latitude
        lng: Longitude
    
    Returns:
        bool: True if valid
    """
    try:
        lat = float(lat)
        lng = float(lng)
        return -90 <= lat <= 90 and -180 <= lng <= 180
    except (ValueError, TypeError):
        return False


def sanitize_search_query(query):
    """
    Sanitize search queries to prevent injection attacks.
    
    Args:
        query: Search query string
    
    Returns:
        str: Sanitized query
    """
    if not query:
        return ""
    
    # Remove potentially dangerous characters
    sanitized = re.sub(r'[<>"\';\\]', '', query)
    
    # Limit length
    sanitized = sanitized[:100]
    
    # Remove multiple spaces
    sanitized = re.sub(r'\s+', ' ', sanitized).strip()
    
    return sanitized


def check_brute_force_attempts(identifier, max_attempts=5, lockout_duration=3600):
    """
    Check if an identifier (IP or username) is locked due to brute force attempts.
    
    Args:
        identifier: IP address or username
        max_attempts: Maximum attempts before lockout
        lockout_duration: Lockout duration in seconds
    
    Returns:
        bool: True if locked out
    """
    from django.core.cache import cache
    
    lockout_key = f"brute_force_lockout:{identifier}"
    attempts_key = f"brute_force_attempts:{identifier}"
    
    # Check if currently locked out
    if cache.get(lockout_key):
        return True
    
    # Check attempt count
    attempts = cache.get(attempts_key, 0)
    if attempts >= max_attempts:
        cache.set(lockout_key, True, timeout=lockout_duration)
        log_security_event('brute_force_lockout', details={'identifier': identifier})
        return True
    
    return False


def record_failed_attempt(identifier):
    """
    Record a failed authentication attempt.
    
    Args:
        identifier: IP address or username
    """
    from django.core.cache import cache
    
    attempts_key = f"brute_force_attempts:{identifier}"
    attempts = cache.get(attempts_key, 0) + 1
    cache.set(attempts_key, attempts, timeout=3600)  # 1 hour
    
    log_security_event('failed_attempt', details={'identifier': identifier, 'attempts': attempts})


def clear_failed_attempts(identifier):
    """
    Clear failed attempts for an identifier after successful authentication.
    
    Args:
        identifier: IP address or username
    """
    from django.core.cache import cache
    
    attempts_key = f"brute_force_attempts:{identifier}"
    lockout_key = f"brute_force_lockout:{identifier}"
    
    cache.delete(attempts_key)
    cache.delete(lockout_key)
