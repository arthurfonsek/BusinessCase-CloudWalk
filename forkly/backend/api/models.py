from django.conf import settings
from django.db import models
from django.contrib.auth.models import User

class Profile(models.Model):
    ROLE_CHOICES = [
        ('user', 'Usuário Comum'),
        ('restaurant_owner', 'Proprietário de Restaurante'),
    ]
    
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    referral_code = models.CharField(max_length=12, unique=True)
    points = models.IntegerField(default=0)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='user')

class Restaurant(models.Model):
    name = models.CharField(max_length=140)
    address = models.CharField(max_length=240, blank=True)
    lat = models.FloatField()
    lng = models.FloatField()
    categories = models.CharField(max_length=240, blank=True)  # "sandwich,fastfood"
    price_level = models.IntegerField(default=1)  # 0..4
    rating_avg = models.FloatField(default=0)
    rating_count = models.IntegerField(default=0)

class Review(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    restaurant = models.ForeignKey(Restaurant, on_delete=models.CASCADE)
    rating = models.IntegerField()
    text = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

class List(models.Model):
    owner = models.ForeignKey(User, on_delete=models.CASCADE)
    title = models.CharField(max_length=120)
    description = models.TextField(blank=True)
    is_public = models.BooleanField(default=True)
    share_code = models.CharField(max_length=16, unique=True)

class ListItem(models.Model):
    lst = models.ForeignKey(List, on_delete=models.CASCADE, related_name='items')
    restaurant = models.ForeignKey(Restaurant, on_delete=models.CASCADE)
    note = models.CharField(max_length=240, blank=True)
    position = models.IntegerField(default=0)

class Referral(models.Model):
    inviter = models.ForeignKey(User, on_delete=models.CASCADE, related_name='invites')
    invitee = models.ForeignKey(User, null=True, blank=True, on_delete=models.SET_NULL, related_name='invited_by')
    code = models.CharField(max_length=12)
    status = models.CharField(max_length=20, choices=[('clicked','clicked'),('installed','installed'),('registered','registered'),('first_review','first_review')])
    created_at = models.DateTimeField(auto_now_add=True)

class RewardLedger(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    reason = models.CharField(max_length=40)
    points = models.IntegerField()
    meta = models.JSONField(default=dict)
    created_at = models.DateTimeField(auto_now_add=True)

class Friendship(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='friends')
    friend = models.ForeignKey(User, on_delete=models.CASCADE, related_name='friend_of')
    is_referred = models.BooleanField(default=False)  # Se foi adicionado através de código de referência
    referral_code = models.CharField(max_length=12, blank=True, null=True)  # Código usado
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ['user', 'friend']

# Sistema de Gamificação
class Tier(models.Model):
    name = models.CharField(max_length=50)  # Bronze, Prata, Ouro, Diamante
    min_referrals = models.IntegerField()  # Número mínimo de referências
    color = models.CharField(max_length=7, default="#FFD700")  # Cor do tier
    icon = models.CharField(max_length=50, default="star")  # Ícone do tier
    benefits = models.JSONField(default=list)  # Lista de benefícios
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['min_referrals']

class UserTier(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='user_tier')
    tier = models.ForeignKey(Tier, on_delete=models.CASCADE)
    current_referrals = models.IntegerField(default=0)
    total_points = models.IntegerField(default=0)
    last_updated = models.DateTimeField(auto_now=True)
    
    def update_tier(self):
        """Atualiza o tier baseado no número de referências"""
        # Buscar o tier mais alto que o usuário pode alcançar baseado nas suas referências
        new_tier = Tier.objects.filter(min_referrals__lte=self.current_referrals).order_by('-min_referrals').first()
        if new_tier and new_tier != self.tier:
            self.tier = new_tier
            self.save()
            return True
        return False

class Achievement(models.Model):
    name = models.CharField(max_length=100)
    description = models.TextField()
    icon = models.CharField(max_length=50, default="emoji_events")
    points_reward = models.IntegerField(default=0)
    condition_type = models.CharField(max_length=50)  # 'referrals', 'reviews', 'points'
    condition_value = models.IntegerField()  # Valor necessário para desbloquear
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

class UserAchievement(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='achievements')
    achievement = models.ForeignKey(Achievement, on_delete=models.CASCADE)
    unlocked_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ['user', 'achievement']

class Reward(models.Model):
    name = models.CharField(max_length=100)
    description = models.TextField()
    points_cost = models.IntegerField()
    reward_type = models.CharField(max_length=50, choices=[
        ('discount', 'Desconto'),
        ('free_item', 'Item Grátis'),
        ('premium_feature', 'Recurso Premium'),
        ('badge', 'Badge'),
    ])
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

class UserReward(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='rewards')
    reward = models.ForeignKey(Reward, on_delete=models.CASCADE)
    claimed_at = models.DateTimeField(auto_now_add=True)
    is_used = models.BooleanField(default=False)
    used_at = models.DateTimeField(null=True, blank=True)

# Sistema de Chat com IA para Gamificação
class AIConversation(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='ai_conversations')
    session_id = models.CharField(max_length=100, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_active = models.BooleanField(default=True)
    
    class Meta:
        ordering = ['-created_at']

class AIMessage(models.Model):
    conversation = models.ForeignKey(AIConversation, on_delete=models.CASCADE, related_name='messages')
    role = models.CharField(max_length=20, choices=[
        ('user', 'Usuário'),
        ('assistant', 'Assistente IA'),
    ])
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    message_type = models.CharField(max_length=30, choices=[
        ('text', 'Texto'),
        ('recommendation', 'Recomendação'),
        ('achievement', 'Conquista'),
        ('tier_progress', 'Progresso de Tier'),
        ('reward_suggestion', 'Sugestão de Recompensa'),
    ], default='text')
    metadata = models.JSONField(default=dict, blank=True)
    
    class Meta:
        ordering = ['created_at']

# Sistema de Restaurantes e Reservas
class RestaurantOwner(models.Model):
    """Proprietário/Gerente do restaurante"""
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='restaurant_owner')
    restaurant = models.OneToOneField(Restaurant, on_delete=models.CASCADE, related_name='owner')
    is_verified = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"{self.user.username} - {self.restaurant.name}"

class RestaurantProfile(models.Model):
    """Perfil detalhado do restaurante"""
    restaurant = models.OneToOneField(Restaurant, on_delete=models.CASCADE, related_name='profile')
    description = models.TextField(blank=True)
    phone = models.CharField(max_length=20, blank=True)
    email = models.EmailField(blank=True)
    website = models.URLField(blank=True)
    opening_hours = models.JSONField(default=dict, blank=True)  # {"monday": {"open": "09:00", "close": "22:00"}}
    average_ticket = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)  # Ticket médio
    capacity = models.IntegerField(default=0)  # Capacidade máxima
    has_delivery = models.BooleanField(default=False)
    has_takeaway = models.BooleanField(default=True)
    has_reservations = models.BooleanField(default=True)
    payment_methods = models.JSONField(default=list, blank=True)  # ["cash", "credit", "pix"]
    special_features = models.JSONField(default=list, blank=True)  # ["wifi", "parking", "accessibility"]
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"Profile for {self.restaurant.name}"

class Reservation(models.Model):
    """Reserva de mesa no restaurante"""
    STATUS_CHOICES = [
        ('pending', 'Pendente'),
        ('confirmed', 'Confirmada'),
        ('cancelled', 'Cancelada'),
        ('completed', 'Concluída'),
        ('no_show', 'Não compareceu'),
    ]
    
    restaurant = models.ForeignKey(Restaurant, on_delete=models.CASCADE, related_name='reservations')
    customer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='reservations')
    date = models.DateField()
    time = models.TimeField()
    party_size = models.IntegerField()  # Número de pessoas
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    special_requests = models.TextField(blank=True)
    customer_phone = models.CharField(max_length=20, blank=True)
    customer_email = models.EmailField(blank=True)
    estimated_value = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)  # Valor estimado
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Reserva {self.id} - {self.restaurant.name} - {self.customer.username}"

class RestaurantAnalytics(models.Model):
    """Estatísticas e analytics do restaurante"""
    restaurant = models.OneToOneField(Restaurant, on_delete=models.CASCADE, related_name='analytics')
    total_reservations = models.IntegerField(default=0)
    total_revenue = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    average_rating = models.FloatField(default=0.0)
    total_reviews = models.IntegerField(default=0)
    times_recommended = models.IntegerField(default=0)  # Quantas vezes foi recomendado
    times_in_lists = models.IntegerField(default=0)  # Quantas vezes apareceu em listas
    last_updated = models.DateTimeField(auto_now=True)
    
    def update_stats(self):
        """Atualiza as estatísticas do restaurante"""
        # Contar reservas
        self.total_reservations = Reservation.objects.filter(
            restaurant=self.restaurant,
            status__in=['confirmed', 'completed']
        ).count()
        
        # Calcular receita total (baseado no ticket médio)
        if self.restaurant.profile.average_ticket > 0:
            self.total_revenue = self.total_reservations * self.restaurant.profile.average_ticket
        
        # Atualizar rating
        reviews = Review.objects.filter(restaurant=self.restaurant)
        if reviews.exists():
            self.total_reviews = reviews.count()
            self.average_rating = sum(review.rating for review in reviews) / self.total_reviews
        
        # Contar recomendações (vezes que apareceu em listas)
        self.times_in_lists = ListItem.objects.filter(restaurant=self.restaurant).count()
        
        # Contar vezes recomendado (simplificado - pode ser melhorado)
        self.times_recommended = self.times_in_lists
        
        self.save()
    
    def __str__(self):
        return f"Analytics for {self.restaurant.name}"