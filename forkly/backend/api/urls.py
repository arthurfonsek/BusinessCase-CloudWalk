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
  
  # Rotas de Gamificação
  path("gamification/stats/", gamification_stats_view),
  path("gamification/ledger/", gamification_ledger_view),
  path("gamification/rewards/claim/", claim_reward_view),
  path("gamification/rewards/use/", use_reward_view),
  path("gamification/achievements/", achievements_view),
  path("gamification/achievements/check/", check_achievements_view),
  path("gamification/leaderboard/", leaderboard_view),
  path("notifications/feed/", notifications_feed_view),
  # Convites/Referral
  path("invites/my-link/", my_invite_link_view),
  
  # Rotas de Chat com IA
  path("ai/chat/start/", start_ai_conversation_view),
  path("ai/chat/send/", send_ai_message_view),
  path("ai/chat/conversations/", get_ai_conversations_view),
  path("ai/chat/conversations/<str:conversation_id>/", get_ai_conversation_view),
  path("ai/chat/conversations/<str:conversation_id>/end/", end_ai_conversation_view),
  path("ai/recommendations/", get_ai_recommendations_view),
  
  # Rotas de Restaurantes e Reservas
  path("restaurants/register/", register_restaurant_view),
  path("restaurants/my/", my_restaurant_view),
  path("restaurants/update/", update_restaurant_view),
  path("restaurants/dashboard/", restaurant_dashboard_view),
  path("restaurants/<int:restaurant_id>/", restaurant_detail_view),
  path("restaurants/with-reservations/", restaurants_with_reservations_view),
  
  # Rotas de Reservas
  path("reservations/create/", create_reservation_view),
  path("reservations/my/", my_reservations_view),
  path("reservations/restaurant/", restaurant_reservations_view),
  path("reservations/<int:reservation_id>/status/", update_reservation_status_view),
  
  # Router por último (para evitar conflitos)
  path("", include(router.urls)),
]
