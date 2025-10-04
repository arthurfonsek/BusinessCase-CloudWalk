from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import *

router=DefaultRouter()
router.register(r"restaurants", RestaurantViewSet, basename="restaurants")
router.register(r"lists", ListViewSet, basename="lists")
router.register(r"list-items", ListItemViewSet, basename="listitems")

urlpatterns = [
  # Rotas específicas PRIMEIRO (antes do router)
  path("nearby/", nearby),
  path("search/", search),
  path("reviews/", create_review),
  path("referrals/track/", track_referral),
  
  # Rotas de Autenticação
  path("auth/login/", login_view),
  path("auth/register/", register_view),
  path("auth/logout/", logout_view),
  path("auth/profile/", profile_view),
  path("auth/profile/update/", update_profile_view),
  path("auth/change-password/", change_password_view),
  path("auth/password-reset/", password_reset_view),
  path("auth/password-reset-confirm/", password_reset_confirm_view),
  
  # Rotas de Amigos
  path("friends/", friends_list_view),
  path("friends/referred/", referred_friends_view),
  path("friends/add/", add_friend_view),
  path("friends/<int:friend_id>/", remove_friend_view),
  path("users/search/", search_users_view),
  
  # Rotas de Listas (específicas)
  path("lists/create/", create_list_view),
  path("lists/my/", my_lists_view),
  path("lists/friends/", friends_lists_view),
  path("restaurants/network-recommendations/", network_recommendations_view),
  path("restaurants/popular/", popular_restaurants_view),
  
  # Router por último (para evitar conflitos)
  path("", include(router.urls)),
]
