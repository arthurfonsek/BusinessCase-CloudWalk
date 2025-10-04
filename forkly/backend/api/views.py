import os, json
from dotenv import load_dotenv
from django.contrib.auth.models import User
from django.db.models import F
from rest_framework import viewsets, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
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

class ListItemViewSet(viewsets.ModelViewSet):
    queryset = ListItem.objects.all()
    serializer_class = ListItemSerializer