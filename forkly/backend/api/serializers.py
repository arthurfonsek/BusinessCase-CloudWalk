from rest_framework import serializers
from django.contrib.auth.models import User
from django.contrib.auth import authenticate
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError
from .models import Profile, Restaurant, Review, List, ListItem, Referral, RewardLedger, Friendship

class UserSerializer(serializers.ModelSerializer):
    class Meta: 
        model=User; 
        fields=["id","username","email"]

class ProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    class Meta: 
        model=Profile; 
        fields=["user","referral_code","points"]

class RestaurantSerializer(serializers.ModelSerializer):
    class Meta: 
        model=Restaurant; 
        fields="__all__"

class ReviewSerializer(serializers.ModelSerializer):
    class Meta: 
        model=Review; 
        fields="__all__"

class ListItemSerializer(serializers.ModelSerializer):
    class Meta: 
        model=ListItem; 
        fields="__all__"

class ListSerializer(serializers.ModelSerializer):
    items = ListItemSerializer(many=True, read_only=True)
    class Meta: 
        model=List; 
        fields="__all__"

class ListCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = List
        fields = ['title', 'description', 'is_public']

class ReferralSerializer(serializers.ModelSerializer):
    class Meta: 
        model=Referral; 
        fields="__all__"

class RewardLedgerSerializer(serializers.ModelSerializer):
    class Meta: 
        model=RewardLedger; 
        fields="__all__"

# Serializers de Autenticação
class LoginSerializer(serializers.Serializer):
    username = serializers.CharField()
    password = serializers.CharField()

    def validate(self, attrs):
        username = attrs.get('username')
        password = attrs.get('password')
        
        if username and password:
            user = authenticate(username=username, password=password)
            if not user:
                raise serializers.ValidationError('Credenciais inválidas')
            if not user.is_active:
                raise serializers.ValidationError('Conta desativada')
            attrs['user'] = user
        else:
            raise serializers.ValidationError('Username e password são obrigatórios')
        
        return attrs

class RegisterSerializer(serializers.Serializer):
    username = serializers.CharField(max_length=150)
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)
    password_confirm = serializers.CharField(write_only=True)
    referral_code = serializers.CharField(required=False, allow_blank=True)

    def validate_username(self, value):
        if User.objects.filter(username=value).exists():
            raise serializers.ValidationError('Username já existe')
        return value

    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError('Email já existe')
        return value

    def validate(self, attrs):
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError('Senhas não coincidem')
        
        try:
            validate_password(attrs['password'])
        except ValidationError as e:
            raise serializers.ValidationError({'password': e.messages})
        
        return attrs

class PasswordResetSerializer(serializers.Serializer):
    email = serializers.EmailField()

class PasswordResetConfirmSerializer(serializers.Serializer):
    token = serializers.CharField()
    new_password = serializers.CharField()
    new_password_confirm = serializers.CharField()

    def validate(self, attrs):
        if attrs['new_password'] != attrs['new_password_confirm']:
            raise serializers.ValidationError('Senhas não coincidem')
        
        try:
            validate_password(attrs['new_password'])
        except ValidationError as e:
            raise serializers.ValidationError({'new_password': e.messages})
        
        return attrs

class UserProfileSerializer(serializers.ModelSerializer):
    profile = ProfileSerializer(read_only=True)
    
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 'profile']
        read_only_fields = ['id', 'username']

class ChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField()
    new_password = serializers.CharField()
    new_password_confirm = serializers.CharField()

class FriendshipSerializer(serializers.ModelSerializer):
    friend_username = serializers.CharField(source='friend.username', read_only=True)
    friend_name = serializers.CharField(source='friend.first_name', read_only=True)
    friend_email = serializers.CharField(source='friend.email', read_only=True)
    
    class Meta:
        model = Friendship
        fields = ['id', 'friend', 'friend_username', 'friend_name', 'friend_email', 'is_referred', 'referral_code', 'created_at']
        read_only_fields = ['id', 'created_at']

class AddFriendSerializer(serializers.Serializer):
    username = serializers.CharField()

class UserSearchSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name']

    def validate_old_password(self, value):
        user = self.context['request'].user
        if not user.check_password(value):
            raise serializers.ValidationError('Senha atual incorreta')
        return value

    def validate(self, attrs):
        if attrs['new_password'] != attrs['new_password_confirm']:
            raise serializers.ValidationError('Senhas não coincidem')
        
        try:
            validate_password(attrs['new_password'])
        except ValidationError as e:
            raise serializers.ValidationError({'new_password': e.messages})
        
        return attrs

class ListCreateSerializer(serializers.Serializer):
    title = serializers.CharField(max_length=120)
    description = serializers.CharField(max_length=500, required=False, allow_blank=True)
    is_public = serializers.BooleanField(default=True)
