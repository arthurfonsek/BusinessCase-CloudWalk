from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import *

router=DefaultRouter()
router.register(r"restaurants", RestaurantViewSet, basename="restaurants")
router.register(r"lists", ListViewSet, basename="lists")
router.register(r"list-items", ListItemViewSet, basename="listitems")

urlpatterns = [
  path("", include(router.urls)),
  path("nearby/", nearby),
  path("search/", search),
  path("auth/register/", register),
  path("reviews/", create_review),
  path("referrals/track/", track_referral),
]
