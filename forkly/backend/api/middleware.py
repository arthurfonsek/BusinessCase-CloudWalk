"""
Security middleware for Forkly API.

Includes rate limiting, request logging, and security headers.
"""

import time
import logging
from django.core.cache import cache
from django.http import JsonResponse
from django.utils.deprecation import MiddlewareMixin
from django.conf import settings
from django.utils import timezone
from django.core.exceptions import PermissionDenied
from ipware import get_client_ip

logger = logging.getLogger('api')


class RateLimitMiddleware(MiddlewareMixin):
    """
    Rate limiting middleware to prevent abuse.
    
    Implements token bucket algorithm for rate limiting.
    """
    
    def __init__(self, get_response):
        self.get_response = get_response
        self.rate_limit_enabled = getattr(settings, 'RATE_LIMIT_ENABLED', True)
        self.requests_per_minute = getattr(settings, 'RATE_LIMIT_REQUESTS_PER_MINUTE', 60)
        self.burst_size = getattr(settings, 'RATE_LIMIT_BURST_SIZE', 10)
        super().__init__(get_response)
    
    def process_request(self, request):
        if not self.rate_limit_enabled:
            return None
            
        # Skip rate limiting for admin and static files
        if request.path.startswith('/admin/') or request.path.startswith('/static/'):
            return None
            
        # Get client IP
        client_ip, _ = get_client_ip(request)
        if not client_ip:
            return None
            
        # Rate limiting key
        rate_key = f"rate_limit:{client_ip}"
        
        # Token bucket algorithm
        now = time.time()
        bucket_data = cache.get(rate_key, {'tokens': self.burst_size, 'last_update': now})
        
        # Add tokens based on time passed
        time_passed = now - bucket_data['last_update']
        tokens_to_add = time_passed * (self.requests_per_minute / 60.0)
        bucket_data['tokens'] = min(self.burst_size, bucket_data['tokens'] + tokens_to_add)
        bucket_data['last_update'] = now
        
        # Check if request is allowed
        if bucket_data['tokens'] >= 1:
            bucket_data['tokens'] -= 1
            cache.set(rate_key, bucket_data, timeout=3600)  # 1 hour
            return None
        else:
            # Rate limit exceeded
            logger.warning(f"Rate limit exceeded for IP: {client_ip}")
            return JsonResponse({
                'error': 'Rate limit exceeded',
                'message': 'Too many requests. Please try again later.',
                'retry_after': 60
            }, status=429)


class SecurityHeadersMiddleware(MiddlewareMixin):
    """
    Add security headers to all responses.
    """
    
    def process_response(self, request, response):
        # Security headers
        response['X-Content-Type-Options'] = 'nosniff'
        response['X-Frame-Options'] = 'DENY'
        response['X-XSS-Protection'] = '1; mode=block'
        response['Referrer-Policy'] = 'strict-origin-when-cross-origin'
        
        # Content Security Policy (basic)
        if not request.path.startswith('/admin/'):
            csp = (
                "default-src 'self'; "
                "script-src 'self' 'unsafe-inline' 'unsafe-eval'; "
                "style-src 'self' 'unsafe-inline'; "
                "img-src 'self' data: https:; "
                "font-src 'self' data:; "
                "connect-src 'self'; "
                "frame-ancestors 'none';"
            )
            response['Content-Security-Policy'] = csp
        
        return response


class RequestLoggingMiddleware(MiddlewareMixin):
    """
    Log all API requests for monitoring and debugging.
    """
    
    def process_request(self, request):
        # Log request details
        client_ip, _ = get_client_ip(request)
        user_agent = request.META.get('HTTP_USER_AGENT', 'Unknown')
        
        logger.info(f"Request: {request.method} {request.path} from {client_ip} - {user_agent}")
        
        # Log sensitive endpoints
        if request.path in ['/api/auth/login/', '/api/auth/register/']:
            logger.info(f"Authentication attempt from {client_ip}")
    
    def process_response(self, request, response):
        # Log response status
        if response.status_code >= 400:
            logger.warning(f"Error response: {response.status_code} for {request.path}")
        
        return response


class APIVersionMiddleware(MiddlewareMixin):
    """
    Add API version information to responses.
    """
    
    def process_response(self, request, response):
        response['X-API-Version'] = '1.0'
        response['X-Server'] = 'Forkly-API'
        return response
