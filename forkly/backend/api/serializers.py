from rest_framework import serializers
from django.contrib.auth.models import User
from .models import Profile, Restaurant, Review, List, ListItem, Referral, RewardLedger

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

class ReferralSerializer(serializers.ModelSerializer):
    class Meta: 
        model=Referral; 
        fields="__all__"

class RewardLedgerSerializer(serializers.ModelSerializer):
    class Meta: 
        model=RewardLedger; 
        fields="__all__"
