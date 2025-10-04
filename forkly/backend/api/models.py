from django.conf import settings
from django.db import models
from django.contrib.auth.models import User

class Profile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    referral_code = models.CharField(max_length=12, unique=True)
    points = models.IntegerField(default=0)

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