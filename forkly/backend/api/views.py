import os, json
from dotenv import load_dotenv
from django.contrib.auth.models import User
from django.contrib.auth import login, logout
from django.db.models import F
from django.db import models
from django.core.mail import send_mail
from django.conf import settings
from django.utils.crypto import get_random_string
from rest_framework import viewsets, permissions, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.authtoken.models import Token
from rest_framework.authtoken.views import ObtainAuthToken
from rest_framework_simplejwt.tokens import RefreshToken
from .models import Profile, Restaurant, Review, List, ListItem, Referral, RewardLedger, Tier, UserTier, Achievement, UserAchievement, Reward, UserReward, Friendship, AIConversation, AIMessage, RestaurantOwner, RestaurantProfile, Reservation, RestaurantAnalytics
from .serializers import *
from .ai_gamification_service import AIGamificationService
from .ai_restaurant_service import AIRestaurantService
from .utils import gen_code, haversine

load_dotenv()
OPENAI_KEY = os.getenv("OPENAI_API_KEY")
FRONTEND_BASE_URL = os.getenv("FRONTEND_BASE_URL", "http://localhost:43495")

def _send_push_notification(user: User, title: str, body: str):
    """Simple pseudo-push: send email if available (stub for FCM/OneSignal)."""
    try:
        if user.email:
            send_mail(
                subject=title,
                message=body,
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[user.email],
                fail_silently=True,
            )
    except Exception:
        pass

class RestaurantViewSet(viewsets.ModelViewSet):
    queryset = Restaurant.objects.all()
    serializer_class = RestaurantSerializer
    permission_classes = [permissions.AllowAny]

@api_view(["GET"])
@permission_classes([permissions.AllowAny])
def nearby(request):
    lat=float(request.query_params.get("lat")); lng=float(request.query_params.get("lng"))
    radius=int(request.query_params.get("radius", 1500))
    q=Restaurant.objects.all()
    results=[]
    for r in q:
        d=haversine(lat,lng,r.lat,r.lng)
        if d<=radius:
            results.append((d,r))
    results.sort(key=lambda x:x[0])
    return Response([RestaurantSerializer(r).data | {"distance_m": int(d)} for d,r in results[:50]])

@api_view(["GET"])
@permission_classes([permissions.AllowAny])
def search(request):
    # optional AI: parse q into filters
    q=request.query_params.get("q","").lower()
    lat=float(request.query_params.get("lat")); lng=float(request.query_params.get("lng"))
    radius=int(request.query_params.get("radius", 1500))
    # very light NL → filters (fallback heuristics for Day 2)
    cats = []
    for k in ["sandwich","pizza","sushi","vegan","burger","coffee","ramen"]:
        if k in q: cats.append(k)
    max_price = None
    for level in [0,1,2,3,4]:
        if f"${level}" in q or f"price {level}" in q: max_price=level
    # filter by radius + contains
    pool=[]
    for r in Restaurant.objects.all():
        if haversine(lat,lng,r.lat,r.lng)<=radius and (not cats or any(c in r.categories for c in cats)):
            if max_price is None or r.price_level<=max_price:
                pool.append(r)
    # sort by distance, then rating
    pool=sorted(pool, key=lambda rr:(haversine(lat,lng,rr.lat,rr.lng), -rr.rating_avg))
    return Response(RestaurantSerializer(pool[:50], many=True).data)

@api_view(["POST"])
def create_review(request):
    ser=ReviewSerializer(data=request.data); ser.is_valid(raise_exception=True); ser.save()
    # update aggregates
    rest=Restaurant.objects.get(id=request.data["restaurant"])
    ratings=list(Review.objects.filter(restaurant=rest).values_list("rating", flat=True))
    rest.rating_count=len(ratings); rest.rating_avg=sum(ratings)/len(ratings) if ratings else 0; rest.save()
    # referral milestone
    first=Review.objects.filter(user_id=request.data["user"]).count()==1
    if first:
        ref=Referral.objects.filter(invitee_id=request.data["user"], status="registered").order_by("-created_at").first()
        if ref:
            ref.status="first_review"; ref.save()
            inviter_prof=Profile.objects.get(user_id=ref.inviter_id)
            inviter_prof.points += 100; inviter_prof.save()
            RewardLedger.objects.create(user_id=ref.inviter_id, reason="invite_first_review", points=100, meta={})
    return Response(ser.data)

@api_view(["POST"])
@permission_classes([permissions.AllowAny])
def register(request):
    # expects: username, email, password, referral_code (optional)
    data=request.data
    u=User.objects.create_user(username=data["username"], email=data.get("email",""), password=data["password"])
    prof=Profile.objects.create(user=u, referral_code=gen_code(8))
    code = data.get("referral_code")
    if code:
        inviter_prof=Profile.objects.filter(referral_code=code).first()
        if inviter_prof:
            Referral.objects.create(inviter=inviter_prof.user, invitee=u, code=code, status="registered")
            inviter_prof.points += 50; inviter_prof.save()
            RewardLedger.objects.create(user=inviter_prof.user, reason="invite_registered", points=50, meta={"invitee":u.id})
    return Response({"user_id":u.id,"referral_code":prof.referral_code})

@api_view(["POST"])
@permission_classes([permissions.AllowAny])
def track_referral(request):
    # expects: code, status (clicked/installed)
    code=request.data.get("code"); status=request.data.get("status")
    inviter_prof=Profile.objects.filter(referral_code=code).first()
    if not inviter_prof: return Response({"ok":False,"error":"invalid code"}, status=400)
    Referral.objects.create(inviter=inviter_prof.user, code=code, status=status)
    return Response({"ok":True})

class ListViewSet(viewsets.ModelViewSet):
    queryset = List.objects.all()
    serializer_class = ListSerializer
    
    def get_serializer_class(self):
        if self.action == 'create':
            return ListCreateSerializer
        return ListSerializer
    
    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)

class ListItemViewSet(viewsets.ModelViewSet):
    queryset = ListItem.objects.all()
    serializer_class = ListItemSerializer

# Views de Autenticação
@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def login_view(request):
    serializer = LoginSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.validated_data['user']
        refresh = RefreshToken.for_user(user)
        profile = Profile.objects.get(user=user)
        
        return Response({
            'token': str(refresh.access_token),
            'refresh': str(refresh),
            'user': {
                'id': user.id,
                'username': user.username,
                'email': user.email,
                'first_name': user.first_name,
                'last_name': user.last_name,
                'profile': {
                    'referral_code': profile.referral_code,
                    'points': profile.points,
                    'role': profile.role
                }
            }
        })
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def register_view(request):
    serializer = RegisterSerializer(data=request.data)
    if serializer.is_valid():
        user = User.objects.create_user(
            username=serializer.validated_data['username'],
            email=serializer.validated_data['email'],
            password=serializer.validated_data['password']
        )
        profile = Profile.objects.create(user=user, referral_code=gen_code(8))
        
        # Processar código de referência se fornecido
        referral_code = serializer.validated_data.get('referral_code')
        if referral_code:
            inviter_prof = Profile.objects.filter(referral_code=referral_code).first()
            if inviter_prof:
                Referral.objects.create(
                    inviter=inviter_prof.user, 
                    invitee=user, 
                    code=referral_code, 
                    status="registered"
                )
                inviter_prof.points += 50
                inviter_prof.save()
                RewardLedger.objects.create(
                    user=inviter_prof.user, 
                    reason="invite_registered", 
                    points=50, 
                    meta={"invitee": user.id}
                )
        
        # Gerar JWT token
        refresh = RefreshToken.for_user(user)
        return Response({
            'token': str(refresh.access_token),
            'refresh': str(refresh),
            'user': {
                'id': user.id,
                'username': user.username,
                'email': user.email,
                'profile': {
                    'referral_code': profile.referral_code,
                    'points': profile.points,
                    'role': profile.role
                }
            }
        }, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def logout_view(request):
    # Para JWT, não precisamos fazer nada especial no logout
    # O token será invalidado automaticamente quando expirar
    logout(request)
    return Response({'message': 'Logout realizado com sucesso'})

@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def profile_view(request):
    serializer = UserProfileSerializer(request.user)
    return Response(serializer.data)

@api_view(['PUT'])
@permission_classes([permissions.IsAuthenticated])
def update_profile_view(request):
    serializer = UserProfileSerializer(request.user, data=request.data, partial=True)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def change_password_view(request):
    serializer = ChangePasswordSerializer(data=request.data, context={'request': request})
    if serializer.is_valid():
        user = request.user
        user.set_password(serializer.validated_data['new_password'])
        user.save()
        return Response({'message': 'Senha alterada com sucesso'})
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def password_reset_view(request):
    serializer = PasswordResetSerializer(data=request.data)
    if serializer.is_valid():
        email = serializer.validated_data['email']
        try:
            user = User.objects.get(email=email)
            # Gerar token de reset (simplificado para demo)
            reset_token = get_random_string(32)
            # Em produção, salvar o token em uma tabela com expiração
            # Por agora, vamos apenas enviar um email simulado
            send_mail(
                'Reset de Senha - Forkly',
                f'Seu token de reset é: {reset_token}',
                settings.DEFAULT_FROM_EMAIL,
                [email],
                fail_silently=False,
            )
            return Response({'message': 'Email de reset enviado'})
        except User.DoesNotExist:
            return Response({'message': 'Email de reset enviado'})  # Não revelar se email existe
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def password_reset_confirm_view(request):
    serializer = PasswordResetConfirmSerializer(data=request.data)
    if serializer.is_valid():
        # Em produção, validar o token e sua expiração
        # Por agora, vamos apenas simular a validação
        token = serializer.validated_data['token']
        new_password = serializer.validated_data['new_password']
        
        # Simular busca do usuário pelo token (em produção seria uma tabela de tokens)
        # Por agora, vamos retornar sucesso
        return Response({'message': 'Senha redefinida com sucesso'})
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

# Views para sistema de amigos
@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def friends_list_view(request):
    """Lista todos os amigos do usuário"""
    friendships = Friendship.objects.filter(user=request.user)
    serializer = FriendshipSerializer(friendships, many=True)
    return Response(serializer.data)

@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def referred_friends_view(request):
    """Lista amigos que foram referidos pelo usuário"""
    friendships = Friendship.objects.filter(user=request.user, is_referred=True)
    serializer = FriendshipSerializer(friendships, many=True)
    return Response(serializer.data)

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def add_friend_view(request):
    """Adiciona um amigo por username"""
    serializer = AddFriendSerializer(data=request.data)
    if serializer.is_valid():
        username = serializer.validated_data['username']
        
        # Verificar se o usuário existe
        try:
            friend_user = User.objects.get(username=username)
        except User.DoesNotExist:
            return Response({'error': 'Usuário não encontrado'}, status=status.HTTP_404_NOT_FOUND)
        
        # Verificar se não é o próprio usuário
        if friend_user == request.user:
            return Response({'error': 'Você não pode adicionar a si mesmo'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Verificar se já são amigos
        if Friendship.objects.filter(user=request.user, friend=friend_user).exists():
            return Response({'error': 'Vocês já são amigos'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Criar amizade
        friendship = Friendship.objects.create(
            user=request.user,
            friend=friend_user,
            is_referred=False
        )
        
        # Criar amizade recíproca
        Friendship.objects.create(
            user=friend_user,
            friend=request.user,
            is_referred=False
        )
        
        serializer_response = FriendshipSerializer(friendship)
        return Response(serializer_response.data, status=status.HTTP_201_CREATED)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['DELETE'])
@permission_classes([permissions.IsAuthenticated])
def remove_friend_view(request, friend_id):
    """Remove um amigo"""
    try:
        friendship = Friendship.objects.get(user=request.user, friend_id=friend_id)
        # Remover amizade recíproca também
        Friendship.objects.filter(user_id=friend_id, friend=request.user).delete()
        friendship.delete()
        return Response({'message': 'Amigo removido com sucesso'})
    except Friendship.DoesNotExist:
        return Response({'error': 'Amizade não encontrada'}, status=status.HTTP_404_NOT_FOUND)

@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def search_users_view(request):
    """Busca usuários por username"""
    query = request.GET.get('q', '')
    if len(query) < 2:
        return Response({'error': 'Query deve ter pelo menos 2 caracteres'}, status=status.HTTP_400_BAD_REQUEST)
    
    users = User.objects.filter(username__icontains=query).exclude(id=request.user.id)[:10]
    serializer = UserSearchSerializer(users, many=True)
    return Response(serializer.data)

# Views para listas
@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def create_list_view(request):
    """Cria uma nova lista para o usuário"""
    serializer = ListCreateSerializer(data=request.data)
    if serializer.is_valid():
        # Gerar código de compartilhamento único
        import uuid
        share_code = str(uuid.uuid4())[:8].upper()
        
        list_obj = List.objects.create(
            owner=request.user,
            title=serializer.validated_data['title'],
            description=serializer.validated_data.get('description', ''),
            is_public=serializer.validated_data.get('is_public', True),
            share_code=share_code
        )
        
        response_serializer = ListSerializer(list_obj)
        return Response(response_serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def my_lists_view(request):
    """Lista todas as listas do usuário"""
    lists = List.objects.filter(owner=request.user).order_by('-id')
    serializer = ListSerializer(lists, many=True)
    return Response(serializer.data)

@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def friends_lists_view(request):
    """Lista todas as listas públicas dos amigos do usuário"""
    # Buscar IDs dos amigos
    friend_ids = Friendship.objects.filter(user=request.user).values_list('friend_id', flat=True)
    
    # Buscar listas públicas dos amigos
    friends_lists = List.objects.filter(
        owner_id__in=friend_ids,
        is_public=True
    ).order_by('-id')
    
    serializer = ListSerializer(friends_lists, many=True)
    return Response(serializer.data)

@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def network_recommendations_view(request):
    """Restaurantes recomendados por amigos (em alta na rede)"""
    # Buscar IDs dos amigos
    friend_ids = Friendship.objects.filter(user=request.user).values_list('friend_id', flat=True)
    
    # Buscar restaurantes que estão em listas dos amigos
    from django.db.models import Count
    recommended_restaurants = Restaurant.objects.filter(
        listitem__lst__owner_id__in=friend_ids,
        listitem__lst__is_public=True
    ).annotate(
        friend_count=Count('listitem__lst__owner', distinct=True)
    ).filter(
        friend_count__gte=2  # Pelo menos 2 amigos têm este restaurante
    ).order_by('-friend_count', '-rating_avg')[:20]
    
    serializer = RestaurantSerializer(recommended_restaurants, many=True)
    return Response(serializer.data)

@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def popular_restaurants_view(request):
    """Restaurantes populares em todo o Forkly (em várias listas)"""
    from django.db.models import Count
    popular_restaurants = Restaurant.objects.annotate(
        list_count=Count('listitem__lst', distinct=True)
    ).filter(
        list_count__gte=3  # Pelo menos 3 listas contêm este restaurante
    ).order_by('-list_count', '-rating_avg')[:20]
    
    serializer = RestaurantSerializer(popular_restaurants, many=True)
    return Response(serializer.data)

# ===== SISTEMA DE GAMIFICAÇÃO =====

@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def gamification_stats_view(request):
    """Retorna estatísticas completas de gamificação do usuário"""
    user = request.user
    
    # Obter ou criar UserTier
    user_tier, created = UserTier.objects.get_or_create(
        user=user,
        defaults={'tier': Tier.objects.filter(min_referrals=0).first()}
    )
    
    # Atualizar estatísticas
    # Contar referrals usando Friendship (sistema atual)
    referrals_count = Friendship.objects.filter(user=user, is_referred=True).count()
    user_tier.current_referrals = referrals_count
    user_tier.total_points = Profile.objects.get(user=user).points
    user_tier.save()
    
    # Atualizar tier se necessário
    tier_before = user_tier.tier
    upgraded = user_tier.update_tier()
    if upgraded and user_tier.tier != tier_before:
        _send_push_notification(
            user,
            title='Parabéns! Você subiu de tier',
            body=f"Você alcançou o tier {user_tier.tier.name}. Continue convidando amigos!",
        )
    
    # Buscar conquistas do usuário
    user_achievements = UserAchievement.objects.filter(user=user).order_by('-unlocked_at')
    
    # Buscar recompensas disponíveis
    available_rewards = Reward.objects.filter(is_active=True).order_by('points_cost')
    
    # Buscar recompensas do usuário
    user_rewards = UserReward.objects.filter(user=user).order_by('-claimed_at')
    
    # Estatísticas de referência
    referral_stats = {
        'total_referrals': referrals_count,
        'successful_referrals': Friendship.objects.filter(user=user, is_referred=True).count(),  # Todos os referrals são considerados bem-sucedidos
        'pending_referrals': 0,  # Não há referrals pendentes no sistema atual
        'total_points_earned': RewardLedger.objects.filter(user=user).aggregate(
            total=models.Sum('points')
        )['total'] or 0
    }
    
    data = {
        'user_tier': UserTierSerializer(user_tier).data,
        'achievements': UserAchievementSerializer(user_achievements, many=True).data,
        'available_rewards': RewardSerializer(available_rewards, many=True).data,
        'user_rewards': UserRewardSerializer(user_rewards, many=True).data,
        'referral_stats': referral_stats
    }
    
    return Response(data)

@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def gamification_ledger_view(request):
    """Retorna o extrato de pontos (RewardLedger) do usuário autenticado"""
    entries = RewardLedger.objects.filter(user=request.user).order_by('-created_at')
    data = RewardLedgerSerializer(entries, many=True).data
    return Response(data)

@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def notifications_feed_view(request):
    """Feed básico de notificações derivadas (últimos 30 dias)."""
    user = request.user
    from django.utils import timezone
    from datetime import timedelta
    since = timezone.now() - timedelta(days=30)

    recent_achievements = UserAchievement.objects.filter(user=user, unlocked_at__gte=since).order_by('-unlocked_at')
    achievements_payload = [
        {
            'type': 'achievement',
            'title': f"Conquista desbloqueada: {ua.achievement.name}",
            'body': ua.achievement.description,
            'created_at': ua.unlocked_at.isoformat(),
        }
        for ua in recent_achievements
    ]

    user_tier, _ = UserTier.objects.get_or_create(
        user=user, defaults={'tier': Tier.objects.filter(min_referrals=0).first()}
    )
    referrals_count = Friendship.objects.filter(user=user, is_referred=True).count()
    next_tier = Tier.objects.filter(min_referrals__gt=user_tier.tier.min_referrals).order_by('min_referrals').first() if user_tier.tier else None
    tier_payload = []
    if next_tier:
        to_next = max(0, next_tier.min_referrals - referrals_count)
        tier_payload.append({
            'type': 'tier_progress',
            'title': f"Faltam {to_next} referrals para {next_tier.name}",
            'body': 'Compartilhe seu link de convite para avançar de tier.',
            'created_at': timezone.now().isoformat(),
        })

    total_points = Profile.objects.get(user=user).points
    rewards_payload = []
    if total_points > 0:
        rewards_payload.append({
            'type': 'points',
            'title': f"Você tem {total_points} pontos",
            'body': 'Confira as recompensas disponíveis para resgatar.',
            'created_at': timezone.now().isoformat(),
        })

    return Response({'notifications': achievements_payload + tier_payload + rewards_payload})

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def claim_reward_view(request):
    """Resgata uma recompensa com pontos"""
    reward_id = request.data.get('reward_id')
    
    if not reward_id:
        return Response({'error': 'ID da recompensa é obrigatório'}, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        reward = Reward.objects.get(id=reward_id, is_active=True)
    except Reward.DoesNotExist:
        return Response({'error': 'Recompensa não encontrada'}, status=status.HTTP_404_NOT_FOUND)
    
    user_profile = Profile.objects.get(user=request.user)
    
    if user_profile.points < reward.points_cost:
        return Response({'error': 'Pontos insuficientes'}, status=status.HTTP_400_BAD_REQUEST)
    
    # Verificar se já possui esta recompensa
    if UserReward.objects.filter(user=request.user, reward=reward).exists():
        return Response({'error': 'Você já possui esta recompensa'}, status=status.HTTP_400_BAD_REQUEST)
    
    # Descontar pontos
    user_profile.points -= reward.points_cost
    user_profile.save()
    
    # Criar recompensa do usuário
    user_reward = UserReward.objects.create(user=request.user, reward=reward)
    
    # Registrar no ledger
    RewardLedger.objects.create(
        user=request.user,
        reason='reward_claimed',
        points=-reward.points_cost,
        meta={'reward_id': reward.id, 'reward_name': reward.name}
    )
    
    return Response({
        'message': 'Recompensa resgatada com sucesso!',
        'user_reward': UserRewardSerializer(user_reward).data,
        'remaining_points': user_profile.points
    })

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def use_reward_view(request):
    """Usa uma recompensa resgatada"""
    user_reward_id = request.data.get('user_reward_id')
    
    if not user_reward_id:
        return Response({'error': 'ID da recompensa do usuário é obrigatório'}, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        user_reward = UserReward.objects.get(id=user_reward_id, user=request.user)
    except UserReward.DoesNotExist:
        return Response({'error': 'Recompensa não encontrada'}, status=status.HTTP_404_NOT_FOUND)
    
    if user_reward.is_used:
        return Response({'error': 'Esta recompensa já foi utilizada'}, status=status.HTTP_400_BAD_REQUEST)
    
    # Marcar como usada
    from django.utils import timezone
    user_reward.is_used = True
    user_reward.used_at = timezone.now()
    user_reward.save()
    
    return Response({
        'message': 'Recompensa utilizada com sucesso!',
        'user_reward': UserRewardSerializer(user_reward).data
    })

@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def achievements_view(request):
    """Lista todas as conquistas disponíveis e do usuário"""
    user = request.user
    
    # Todas as conquistas
    all_achievements = Achievement.objects.filter(is_active=True).order_by('condition_value')
    
    # Conquistas do usuário
    user_achievements = UserAchievement.objects.filter(user=user).values_list('achievement_id', flat=True)
    
    # Adicionar status para cada conquista
    achievements_data = []
    for achievement in all_achievements:
        is_unlocked = achievement.id in user_achievements
        achievements_data.append({
            **AchievementSerializer(achievement).data,
            'is_unlocked': is_unlocked,
            'unlocked_at': UserAchievement.objects.filter(
                user=user, achievement=achievement
            ).first().unlocked_at if is_unlocked else None
        })
    
    return Response(achievements_data)

@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def leaderboard_view(request):
    """Ranking de usuários por pontos e referências"""
    from django.db.models import Count
    
    # Ranking por pontos
    points_ranking = User.objects.annotate(
        total_points=models.F('profile__points')
    ).order_by('-profile__points')[:20]
    
    # Ranking por referências
    referrals_ranking = User.objects.annotate(
        total_referrals=Count('invites', filter=models.Q(invites__status='registered'))
    ).order_by('-total_referrals')[:20]
    
    return Response({
        'points_ranking': [
            {
                'username': user.username,
                'points': user.profile.points,
                'tier': user.user_tier.tier.name if hasattr(user, 'user_tier') else 'Iniciante'
            }
            for user in points_ranking
        ],
        'referrals_ranking': [
            {
                'username': user.username,
                'referrals': user.total_referrals,
                'tier': user.user_tier.tier.name if hasattr(user, 'user_tier') else 'Iniciante'
            }
            for user in referrals_ranking
        ]
    })

# ===== Referral/Convite =====
@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def my_invite_link_view(request):
    """Retorna um link curto de convite com o referral_code do usuário"""
    try:
        profile = Profile.objects.get(user=request.user)
        code = profile.referral_code
        # Link curto estilo /i/<code> que front pode resolver/capturar
        short_path = f"/i/{code}"
        full_url = f"{FRONTEND_BASE_URL}{short_path}"
        return Response({'code': code, 'short_path': short_path, 'url': full_url})
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def check_achievements_view(request):
    """Verifica e desbloqueia conquistas do usuário"""
    user = request.user
    
    # Obter estatísticas do usuário
    referrals_count = Referral.objects.filter(inviter=user, status='registered').count()
    reviews_count = Review.objects.filter(user=user).count()
    total_points = Profile.objects.get(user=user).points
    
    # Verificar conquistas
    achievements_to_check = Achievement.objects.filter(is_active=True)
    new_achievements = []
    
    for achievement in achievements_to_check:
        # Verificar se já possui a conquista
        if UserAchievement.objects.filter(user=user, achievement=achievement).exists():
            continue
            
        # Verificar condições
        should_unlock = False
        if achievement.condition_type == 'referrals' and referrals_count >= achievement.condition_value:
            should_unlock = True
        elif achievement.condition_type == 'reviews' and reviews_count >= achievement.condition_value:
            should_unlock = True
        elif achievement.condition_type == 'points' and total_points >= achievement.condition_value:
            should_unlock = True
        
        if should_unlock:
            # Desbloquear conquista
            user_achievement = UserAchievement.objects.create(user=user, achievement=achievement)
            
            # Adicionar pontos da conquista
            if achievement.points_reward > 0:
                user_profile = Profile.objects.get(user=user)
                user_profile.points += achievement.points_reward
                user_profile.save()
                
                RewardLedger.objects.create(
                    user=user,
                    reason='achievement_unlocked',
                    points=achievement.points_reward,
                    meta={'achievement_id': achievement.id, 'achievement_name': achievement.name}
                )
            _send_push_notification(
                user,
                title=f"Conquista desbloqueada: {achievement.name}",
                body=f"{achievement.description} (+{achievement.points_reward} pontos)",
            )
            new_achievements.append(UserAchievementSerializer(user_achievement).data)
    
    return Response({
        'new_achievements': new_achievements,
        'message': f'{len(new_achievements)} nova(s) conquista(s) desbloqueada(s)!' if new_achievements else 'Nenhuma nova conquista desbloqueada.'
    })

# ===== SISTEMA DE CHAT COM IA =====

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def start_ai_conversation_view(request):
    """Inicia uma nova conversa com IA"""
    try:
        # Escolher serviço conforme role
        service: object
        if Profile.objects.get(user=request.user).role == 'restaurant_owner':
            service = AIRestaurantService()
        else:
            service = AIGamificationService()

        conversation = service.create_conversation(request.user)

        # Mensagem de boas-vindas específica
        welcome_prompt = (
            "Olá! Posso te ajudar com desempenho do restaurante. Pergunte por 'resumo do mês', reservas, receita e avaliação."
            if isinstance(service, AIRestaurantService) else
            "Olá! Como posso te ajudar com gamificação?"
        )
        welcome_message = service.generate_ai_response(request.user, welcome_prompt)
        service.add_message(conversation, 'assistant', welcome_message, 'text')
        
        serializer = AIConversationSerializer(conversation)
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def send_ai_message_view(request):
    """Envia mensagem para IA e recebe resposta"""
    serializer = ChatMessageSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        # Escolher serviço conforme role
        service: object
        if Profile.objects.get(user=request.user).role == 'restaurant_owner':
            service = AIRestaurantService()
        else:
            service = AIGamificationService()
        message = serializer.validated_data['message']
        conversation_id = serializer.validated_data.get('conversation_id')
        
        # Buscar ou criar conversa
        if conversation_id:
            try:
                conversation = AIConversation.objects.get(
                session_id=conversation_id, 
                user=request.user, 
                is_active=True
            )
            except AIConversation.DoesNotExist:
                return Response({'error': 'Conversa não encontrada'}, status=status.HTTP_404_NOT_FOUND)
        else:
            conversation = service.create_conversation(request.user)
        
        # Adicionar mensagem do usuário
        user_message = service.add_message(conversation, 'user', message, 'text')
        
        # Gerar resposta da IA
        ai_response = service.generate_ai_response(request.user, message)
        ai_message = service.add_message(conversation, 'assistant', ai_response, 'text')
        
        # Obter histórico da conversa
        conversation_history = service.get_conversation_history(conversation)
        
        return Response({
            'conversation_id': conversation.session_id,
            'message': AIMessageSerializer(ai_message).data,
            'conversation_history': conversation_history
        })
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_ai_conversations_view(request):
    """Lista conversas de IA do usuário"""
    try:
        conversations = AIConversation.objects.filter(
            user=request.user, 
            is_active=True
        ).order_by('-updated_at')
        
        serializer = AIConversationSerializer(conversations, many=True)
        return Response(serializer.data)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_ai_conversation_view(request, conversation_id):
    """Obtém conversa específica com histórico"""
    try:
        conversation = AIConversation.objects.get(
            session_id=conversation_id,
            user=request.user,
            is_active=True
        )
        
        serializer = AIConversationSerializer(conversation)
        return Response(serializer.data)
    except AIConversation.DoesNotExist:
        return Response({'error': 'Conversa não encontrada'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['DELETE'])
@permission_classes([permissions.IsAuthenticated])
def end_ai_conversation_view(request, conversation_id):
    """Encerra conversa com IA"""
    try:
        conversation = AIConversation.objects.get(
            session_id=conversation_id,
            user=request.user,
            is_active=True
        )
        
        conversation.is_active = False
        conversation.save()
        
        return Response({'message': 'Conversa encerrada com sucesso'})
    except AIConversation.DoesNotExist:
        return Response({'error': 'Conversa não encontrada'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_ai_recommendations_view(request):
    """Obtém recomendações personalizadas da IA"""
    try:
        # Se for proprietário de restaurante, focar em métricas do restaurante
        try:
            owner = RestaurantOwner.objects.get(user=request.user)
            restaurant = owner.restaurant
            # Garantir analytics atualizados
            restaurant.analytics.update_stats()
            from django.utils import timezone
            from datetime import timedelta
            now = timezone.now()
            month_ago = now - timedelta(days=30)
            monthly_reservations = Reservation.objects.filter(
                restaurant=restaurant,
                created_at__gte=month_ago,
                status__in=['confirmed', 'completed']
            )
            monthly_count = monthly_reservations.count()
            monthly_revenue = float(restaurant.profile.average_ticket) * monthly_count
            recent_no_shows = Reservation.objects.filter(
                restaurant=restaurant,
                created_at__gte=month_ago,
                status='no_show'
            ).count()
            recommendations = [
                {
                    'type': 'restaurant_summary',
                    'title': 'Resumo do mês',
                    'description': f'{monthly_count} reservas concluídas/confirmadas; receita estimada R$ {monthly_revenue:.2f}',
                    'priority': 'high'
                },
                {
                    'type': 'no_show_alert',
                    'title': 'No-shows no período',
                    'description': f'{recent_no_shows} no-shows nos últimos 30 dias',
                    'priority': 'medium'
                },
            ]
            return Response({
                'recommendations': recommendations,
                'context': {
                    'restaurant_id': restaurant.id,
                    'restaurant_name': restaurant.name,
                    'monthly_reservations': monthly_count,
                    'monthly_revenue': monthly_revenue,
                    'no_shows_30d': recent_no_shows,
                }
            })
        except RestaurantOwner.DoesNotExist:
            # Caso padrão: gamificação para usuários comuns
            ai_service = AIGamificationService()
            context = ai_service.get_user_gamification_context(request.user)
            
            if 'error' in context:
                return Response({'error': context['error']}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            
            recommendations = []
            if context['next_tier']:
                recommendations.append({
                    'type': 'tier_progress',
                    'title': f'Progredir para {context["next_tier"]}',
                    'description': f'Você precisa de {context["referrals_to_next"]} referrals para o próximo tier',
                    'action': 'Compartilhar código de referência',
                    'priority': 'high'
                })
            if context['total_points'] > 0:
                recommendations.append({
                    'type': 'reward_suggestion',
                    'title': 'Usar seus pontos',
                    'description': f'Você tem {context["total_points"]} pontos para gastar',
                    'action': 'Ver recompensas disponíveis',
                    'priority': 'medium'
                })
            if context['achievements_count'] < 5:
                recommendations.append({
                    'type': 'achievement',
                    'title': 'Desbloquear conquistas',
                    'description': 'Complete ações para desbloquear novas conquistas',
                    'action': 'Ver conquistas disponíveis',
                    'priority': 'low'
                })
            return Response({'recommendations': recommendations, 'context': context})
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# ===== SISTEMA DE RESTAURANTES E RESERVAS =====

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def register_restaurant_view(request):
    """Registra um novo restaurante"""
    try:
        # Verificar se o usuário já possui um restaurante
        if RestaurantOwner.objects.filter(user=request.user).exists():
            return Response({'error': 'Você já possui um restaurante registrado'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Criar restaurante
        restaurant_data = request.data.get('restaurant', {})
        restaurant = Restaurant.objects.create(
            name=restaurant_data.get('name'),
            address=restaurant_data.get('address', ''),
            lat=restaurant_data.get('lat', 0.0),
            lng=restaurant_data.get('lng', 0.0),
            categories=restaurant_data.get('categories', ''),
            price_level=restaurant_data.get('price_level', 1),
            rating_avg=0.0,
            rating_count=0
        )
        
        # Criar perfil do restaurante
        profile_data = request.data.get('profile', {})
        RestaurantProfile.objects.create(
            restaurant=restaurant,
            description=profile_data.get('description', ''),
            phone=profile_data.get('phone', ''),
            email=profile_data.get('email', ''),
            website=profile_data.get('website', ''),
            opening_hours=profile_data.get('opening_hours', {}),
            average_ticket=profile_data.get('average_ticket', 0.00),
            capacity=profile_data.get('capacity', 0),
            has_delivery=profile_data.get('has_delivery', False),
            has_takeaway=profile_data.get('has_takeaway', True),
            has_reservations=profile_data.get('has_reservations', True),
            payment_methods=profile_data.get('payment_methods', []),
            special_features=profile_data.get('special_features', [])
        )
        
        # Criar proprietário
        RestaurantOwner.objects.create(
            user=request.user,
            restaurant=restaurant,
            is_verified=False
        )
        
        # Atualizar role do usuário para restaurant_owner
        profile = Profile.objects.get(user=request.user)
        profile.role = 'restaurant_owner'
        profile.save()
        
        # Criar analytics
        RestaurantAnalytics.objects.create(restaurant=restaurant)
        
        serializer = RestaurantDetailSerializer(restaurant)
        return Response(serializer.data, status=status.HTTP_201_CREATED)
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def my_restaurant_view(request):
    """Obtém dados do restaurante do usuário"""
    try:
        restaurant_owner = RestaurantOwner.objects.get(user=request.user)
        restaurant = restaurant_owner.restaurant
        
        # Atualizar analytics
        restaurant.analytics.update_stats()
        
        serializer = RestaurantDetailSerializer(restaurant)
        return Response(serializer.data)
        
    except RestaurantOwner.DoesNotExist:
        return Response({'error': 'Restaurante não encontrado'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['PUT'])
@permission_classes([permissions.IsAuthenticated])
def update_restaurant_view(request):
    """Atualiza dados do restaurante"""
    try:
        restaurant_owner = RestaurantOwner.objects.get(user=request.user)
        restaurant = restaurant_owner.restaurant
        
        # Atualizar dados básicos do restaurante
        restaurant_data = request.data.get('restaurant', {})
        for field, value in restaurant_data.items():
            if hasattr(restaurant, field):
                setattr(restaurant, field, value)
        restaurant.save()
        
        # Atualizar perfil do restaurante
        profile_data = request.data.get('profile', {})
        if hasattr(restaurant, 'profile'):
            for field, value in profile_data.items():
                if hasattr(restaurant.profile, field):
                    setattr(restaurant.profile, field, value)
            restaurant.profile.save()
        
        serializer = RestaurantDetailSerializer(restaurant)
        return Response(serializer.data)
        
    except RestaurantOwner.DoesNotExist:
        return Response({'error': 'Restaurante não encontrado'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def restaurant_dashboard_view(request):
    """Dashboard do restaurante com estatísticas"""
    try:
        restaurant_owner = RestaurantOwner.objects.get(user=request.user)
        restaurant = restaurant_owner.restaurant
        
        # Atualizar analytics
        restaurant.analytics.update_stats()
        
        # Reservas recentes
        recent_reservations = Reservation.objects.filter(
            restaurant=restaurant
        ).order_by('-created_at')[:10]
        
        # Estatísticas mensais
        from django.utils import timezone
        from datetime import timedelta
        now = timezone.now()
        month_ago = now - timedelta(days=30)
        
        monthly_reservations = Reservation.objects.filter(
            restaurant=restaurant,
            created_at__gte=month_ago,
            status__in=['confirmed', 'completed']
        ).count()
        
        monthly_revenue = monthly_reservations * float(restaurant.profile.average_ticket)
        
        # Calcular projeção inteligente para o próximo mês
        two_months_ago = now - timedelta(days=60)
        previous_month_reservations = Reservation.objects.filter(
            restaurant=restaurant,
            created_at__gte=two_months_ago,
            created_at__lt=month_ago,
            status__in=['confirmed', 'completed']
        ).count()
        
        # Calcular tendência
        if previous_month_reservations > 0:
            growth_rate = (monthly_reservations - previous_month_reservations) / previous_month_reservations
        else:
            growth_rate = 0.0
        
        # Aplicar lift de exposição em listas
        analytics = restaurant.analytics
        times_in_lists = float(analytics.times_in_lists or 0)
        times_recommended = float(analytics.times_recommended or 0)
        k = 200.0
        raw_lift = (times_in_lists + times_recommended) / k
        lift = max(0.0, min(raw_lift, 0.3))  # Máximo 30% de lift
        
        # Projeção baseada na tendência real + lift
        trend_factor = 1.0 + (growth_rate * 0.5)  # Suavizar tendência
        lift_factor = 1.0 + lift
        projected_revenue = float(monthly_revenue) * trend_factor * lift_factor
        
        monthly_stats = {
            'reservations': monthly_reservations,
            'revenue': float(monthly_revenue),
            'period': '30 dias',
            'projection': {
                'next_month_revenue': projected_revenue,
                'growth_rate': growth_rate,
                'lift_factor': lift,
                'trend_direction': 'up' if growth_rate > 0.05 else 'down' if growth_rate < -0.05 else 'stable'
            }
        }
        
        data = {
            'restaurant': RestaurantDetailSerializer(restaurant).data,
            'analytics': RestaurantAnalyticsSerializer(restaurant.analytics).data,
            'recent_reservations': ReservationSerializer(recent_reservations, many=True).data,
            'monthly_stats': monthly_stats
        }
        
        return Response(data)
        
    except RestaurantOwner.DoesNotExist:
        return Response({'error': 'Restaurante não encontrado'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def create_reservation_view(request):
    """Cria uma nova reserva"""
    try:
        # Impedir que proprietários façam reservas (somente clientes)
        if RestaurantOwner.objects.filter(user=request.user).exists():
            return Response({'error': 'Proprietários de restaurante não podem criar reservas.'}, status=status.HTTP_403_FORBIDDEN)

        serializer = ReservationCreateSerializer(data=request.data)
        if serializer.is_valid():
            # Verificar se o restaurante aceita reservas
            restaurant = serializer.validated_data['restaurant']
            if not restaurant.profile.has_reservations:
                return Response({'error': 'Este restaurante não aceita reservas'}, status=status.HTTP_400_BAD_REQUEST)
            
            # Criar reserva
            reservation = Reservation.objects.create(
                restaurant=restaurant,
                customer=request.user,
                date=serializer.validated_data['date'],
                time=serializer.validated_data['time'],
                party_size=serializer.validated_data['party_size'],
                special_requests=serializer.validated_data.get('special_requests', ''),
                customer_phone=serializer.validated_data.get('customer_phone', ''),
                customer_email=serializer.validated_data.get('customer_email', ''),
                estimated_value=restaurant.profile.average_ticket * serializer.validated_data['party_size']
            )
            
            # Atualizar analytics do restaurante
            restaurant.analytics.update_stats()
            
            response_serializer = ReservationSerializer(reservation)
            return Response(response_serializer.data, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def my_reservations_view(request):
    """Lista reservas do usuário"""
    try:
        reservations = Reservation.objects.filter(customer=request.user).order_by('-created_at')
        serializer = ReservationSerializer(reservations, many=True)
        return Response(serializer.data)
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def restaurant_reservations_view(request):
    """Lista reservas do restaurante do usuário"""
    try:
        restaurant_owner = RestaurantOwner.objects.get(user=request.user)
        reservations = Reservation.objects.filter(
            restaurant=restaurant_owner.restaurant
        ).order_by('-created_at')
        
        serializer = ReservationSerializer(reservations, many=True)
        return Response(serializer.data)
        
    except RestaurantOwner.DoesNotExist:
        return Response({'error': 'Restaurante não encontrado'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['PUT'])
@permission_classes([permissions.IsAuthenticated])
def update_reservation_status_view(request, reservation_id):
    """Atualiza status de uma reserva (apenas proprietário do restaurante)"""
    try:
        restaurant_owner = RestaurantOwner.objects.get(user=request.user)
        
        reservation = Reservation.objects.get(
            id=reservation_id,
            restaurant=restaurant_owner.restaurant
        )
        
        new_status = request.data.get('status')
        if new_status not in ['pending', 'confirmed', 'cancelled', 'completed', 'no_show']:
            return Response({'error': 'Status inválido'}, status=status.HTTP_400_BAD_REQUEST)
        
        reservation.status = new_status
        reservation.save()
        
        # Atualizar analytics
        restaurant_owner.restaurant.analytics.update_stats()
        
        serializer = ReservationSerializer(reservation)
        return Response(serializer.data)
        
    except RestaurantOwner.DoesNotExist:
        return Response({'error': 'Restaurante não encontrado'}, status=status.HTTP_404_NOT_FOUND)
    except Reservation.DoesNotExist:
        return Response({'error': 'Reserva não encontrada'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([permissions.AllowAny])
def restaurant_detail_view(request, restaurant_id):
    """Detalhes de um restaurante específico"""
    try:
        restaurant = Restaurant.objects.get(id=restaurant_id)
        serializer = RestaurantDetailSerializer(restaurant)
        return Response(serializer.data)
        
    except Restaurant.DoesNotExist:
        return Response({'error': 'Restaurante não encontrado'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([permissions.AllowAny])
def restaurants_with_reservations_view(request):
    """Lista restaurantes que aceitam reservas"""
    try:
        restaurants = Restaurant.objects.filter(
            profile__has_reservations=True
        ).order_by('-rating_avg')
        
        serializer = RestaurantDetailSerializer(restaurants, many=True)
        return Response(serializer.data)
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)