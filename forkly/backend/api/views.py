import os, json
from dotenv import load_dotenv
from django.contrib.auth.models import User
from django.contrib.auth import login, logout
from django.db.models import F
from django.core.mail import send_mail
from django.conf import settings
from django.utils.crypto import get_random_string
from rest_framework import viewsets, permissions, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.authtoken.models import Token
from rest_framework.authtoken.views import ObtainAuthToken
from rest_framework_simplejwt.tokens import RefreshToken
from .models import Profile, Restaurant, Review, List, ListItem, Referral, RewardLedger
from .serializers import *
from .utils import gen_code, haversine

load_dotenv()
OPENAI_KEY = os.getenv("OPENAI_API_KEY")

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
                    'points': profile.points
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
        
        token = Token.objects.create(user=user)
        return Response({
            'token': token.key,
            'user': {
                'id': user.id,
                'username': user.username,
                'email': user.email,
                'profile': {
                    'referral_code': profile.referral_code,
                    'points': profile.points
                }
            }
        }, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def logout_view(request):
    try:
        request.user.auth_token.delete()
    except:
        pass
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