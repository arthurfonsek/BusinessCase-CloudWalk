from rest_framework import serializers
from django.contrib.auth.models import User
from django.contrib.auth import authenticate
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError
from .models import Profile, Restaurant, Review, List, ListItem, Referral, RewardLedger, Friendship, Tier, UserTier, Achievement, UserAchievement, Reward, UserReward, AIConversation, AIMessage, RestaurantOwner, RestaurantProfile, Reservation, RestaurantAnalytics

class UserSerializer(serializers.ModelSerializer):
    class Meta: 
        model=User; 
        fields=["id","username","email"]

class ProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    class Meta: 
        model=Profile; 
        fields=["user","referral_code","points","role"]

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

# Serializers para Sistema de Gamificação
class TierSerializer(serializers.ModelSerializer):
    class Meta:
        model = Tier
        fields = '__all__'

class UserTierSerializer(serializers.ModelSerializer):
    tier = TierSerializer(read_only=True)
    tier_name = serializers.CharField(source='tier.name', read_only=True)
    tier_color = serializers.CharField(source='tier.color', read_only=True)
    tier_icon = serializers.CharField(source='tier.icon', read_only=True)
    tier_benefits = serializers.JSONField(source='tier.benefits', read_only=True)
    
    class Meta:
        model = UserTier
        fields = ['tier', 'tier_name', 'tier_color', 'tier_icon', 'tier_benefits', 'current_referrals', 'total_points', 'last_updated']

class AchievementSerializer(serializers.ModelSerializer):
    class Meta:
        model = Achievement
        fields = '__all__'

class UserAchievementSerializer(serializers.ModelSerializer):
    achievement = AchievementSerializer(read_only=True)
    achievement_name = serializers.CharField(source='achievement.name', read_only=True)
    achievement_description = serializers.CharField(source='achievement.description', read_only=True)
    achievement_icon = serializers.CharField(source='achievement.icon', read_only=True)
    points_reward = serializers.IntegerField(source='achievement.points_reward', read_only=True)
    
    class Meta:
        model = UserAchievement
        fields = ['achievement', 'achievement_name', 'achievement_description', 'achievement_icon', 'points_reward', 'unlocked_at']

class RewardSerializer(serializers.ModelSerializer):
    class Meta:
        model = Reward
        fields = '__all__'

class UserRewardSerializer(serializers.ModelSerializer):
    reward = RewardSerializer(read_only=True)
    reward_name = serializers.CharField(source='reward.name', read_only=True)
    reward_description = serializers.CharField(source='reward.description', read_only=True)
    reward_type = serializers.CharField(source='reward.reward_type', read_only=True)
    
    class Meta:
        model = UserReward
        fields = ['id', 'reward', 'reward_name', 'reward_description', 'reward_type', 'claimed_at', 'is_used', 'used_at']

class GamificationStatsSerializer(serializers.Serializer):
    user_tier = UserTierSerializer(read_only=True)
    achievements = UserAchievementSerializer(many=True, read_only=True)
    available_rewards = RewardSerializer(many=True, read_only=True)
    user_rewards = UserRewardSerializer(many=True, read_only=True)
    referral_stats = serializers.DictField(read_only=True)

# Serializers para Sistema de Chat com IA
class AIMessageSerializer(serializers.ModelSerializer):
    class Meta:
        model = AIMessage
        fields = ['id', 'role', 'content', 'message_type', 'created_at', 'metadata']
        read_only_fields = ['id', 'created_at']

class AIConversationSerializer(serializers.ModelSerializer):
    messages = AIMessageSerializer(many=True, read_only=True)
    
    class Meta:
        model = AIConversation
        fields = ['id', 'session_id', 'created_at', 'updated_at', 'is_active', 'messages']
        read_only_fields = ['id', 'session_id', 'created_at', 'updated_at']

class ChatMessageSerializer(serializers.Serializer):
    message = serializers.CharField(max_length=1000)
    conversation_id = serializers.CharField(required=False, allow_blank=True)

class ChatResponseSerializer(serializers.Serializer):
    conversation_id = serializers.CharField()
    message = AIMessageSerializer()
    conversation_history = AIMessageSerializer(many=True)

# Serializers para Sistema de Restaurantes e Reservas
class RestaurantProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = RestaurantProfile
        fields = '__all__'

class RestaurantOwnerSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    restaurant = RestaurantSerializer(read_only=True)
    
    class Meta:
        model = RestaurantOwner
        fields = ['id', 'user', 'restaurant', 'is_verified', 'created_at']

class RestaurantDetailSerializer(serializers.ModelSerializer):
    profile = RestaurantProfileSerializer(read_only=True)
    owner = RestaurantOwnerSerializer(read_only=True)
    analytics = serializers.SerializerMethodField()
    
    class Meta:
        model = Restaurant
        fields = '__all__'
    
    def get_analytics(self, obj):
        try:
            analytics = obj.analytics
            return {
                'total_reservations': analytics.total_reservations,
                'total_revenue': float(analytics.total_revenue),
                'average_rating': analytics.average_rating,
                'total_reviews': analytics.total_reviews,
                'times_recommended': analytics.times_recommended,
                'times_in_lists': analytics.times_in_lists,
                'last_updated': analytics.last_updated
            }
        except:
            return None

class ReservationSerializer(serializers.ModelSerializer):
    restaurant_name = serializers.CharField(source='restaurant.name', read_only=True)
    customer_username = serializers.CharField(source='customer.username', read_only=True)
    
    class Meta:
        model = Reservation
        fields = '__all__'

class ReservationCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Reservation
        fields = ['restaurant', 'date', 'time', 'party_size', 'special_requests', 'customer_phone', 'customer_email']
    
    def validate_date(self, value):
        from django.utils import timezone
        if value < timezone.now().date():
            raise serializers.ValidationError('Data não pode ser no passado')
        return value

class RestaurantAnalyticsSerializer(serializers.ModelSerializer):
    class Meta:
        model = RestaurantAnalytics
        fields = '__all__'

class RestaurantDashboardSerializer(serializers.Serializer):
    restaurant = RestaurantDetailSerializer(read_only=True)
    analytics = RestaurantAnalyticsSerializer(read_only=True)
    recent_reservations = ReservationSerializer(many=True, read_only=True)
    monthly_stats = serializers.DictField(read_only=True)
