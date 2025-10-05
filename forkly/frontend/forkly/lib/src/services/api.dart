import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'auth_service_simple.dart';
import '../models/user.dart';

class Api {
  final Dio _dio = Dio(BaseOptions(baseUrl: '${const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://127.0.0.1:8000')}/api/'));
  final AuthService _authService = AuthService();
  
  // Método para verificar se está autenticado
  bool get isAuthenticated => _authService.isAuthenticated;
  
  // Método para fazer logout
  Future<void> logout() async {
    await _authService.logout();
  }
  
  Api() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Adicionar token de autenticação se disponível
        final token = _authService.token;
        if (token != null) {
          print('Token: ${token.substring(0, 20)}...');
          options.headers['Authorization'] = 'Bearer $token';
        } else {
          print('Nenhum token encontrado');
        }
        print('Fazendo requisição para: ${options.uri}');
        handler.next(options);
      },
    ));
  }
  
  Future<List<dynamic>> nearby(double lat, double lng, {int radius=1500}) async {
    final r = await _dio.get('nearby/', queryParameters: {"lat":lat,"lng":lng,"radius":radius});
    return r.data;
  }
  
  Future<List<dynamic>> search(String q, double lat, double lng, {int radius=1500}) async {
    final r = await _dio.get('search/', queryParameters: {"q":q,"lat":lat,"lng":lng,"radius":radius});
    return r.data;
  }
  
  Future<Map<String,dynamic>> register(String username, String email, String password, {String? referral}) async {
    final data = {
      "username": username, // Usar nome como username
      "email": email,
      "password": password,
      "password_confirm": password,
      "referral_code": referral ?? ""
    };
    final r = await _dio.post('auth/register/', data: data);
    
    // Salvar token no AuthService após registro bem-sucedido
    if (r.data.containsKey('token')) {
      await _authService.setToken(r.data['token']);
      
      // Salvar dados do usuário se disponíveis
      if (r.data.containsKey('user')) {
        final userData = r.data['user'];
        final user = User(
          id: userData['id'].toString(),
          username: userData['username'],
          email: userData['email'],
          name: userData['username'], // Usar username como nome por enquanto
          role: UserRole.user,
          createdAt: DateTime.now(),
        );
        _authService.setUser(user);
      }
    }
    
    return r.data;
  }

  // Métodos genéricos para requisições HTTP
  Future<Response> get(String endpoint) async {
    return await _dio.get(endpoint);
  }

  Future<Response> post(String endpoint, {dynamic data}) async {
    return await _dio.post(endpoint, data: data);
  }

  Future<Response> put(String endpoint, {dynamic data}) async {
    return await _dio.put(endpoint, data: data);
  }

  Future<Response> delete(String endpoint) async {
    return await _dio.delete(endpoint);
  }
  
  // Convites/Referral
  Future<Map<String, dynamic>> getMyInviteLink() async {
    final r = await _dio.get('invites/my-link/');
    return r.data;
  }

  Future<List<dynamic>> getNotificationsFeed() async {
    final r = await _dio.get('notifications/feed/');
    return (r.data['notifications'] as List).cast<dynamic>();
  }
  
  Future<void> track(String code, String status) async {
    await _dio.post('referrals/track/', data: {"code":code,"status":status});
  }


  Future<Map<String, dynamic>> getProfile() async {
    final r = await _dio.get('auth/profile/');
    return r.data;
  }

  // Métodos para listas
  Future<Map<String, dynamic>> createList(String title, {String? description, bool isPublic = true}) async {
    final r = await _dio.post('lists/', data: {
      "title": title,
      "description": description ?? "",
      "is_public": isPublic,
    });
    return r.data;
  }

  Future<List<dynamic>> getMyLists() async {
    final r = await _dio.get('lists/my/');
    return r.data;
  }

  Future<List<dynamic>> getFriendsLists() async {
    final r = await _dio.get('lists/friends/');
    return r.data;
  }

  // Métodos para restaurantes
  Future<List<dynamic>> getNetworkRecommendations() async {
    final r = await _dio.get('restaurants/network-recommendations/');
    return r.data;
  }

  Future<List<dynamic>> getPopularRestaurants() async {
    final r = await _dio.get('restaurants/popular/');
    return r.data;
  }

  // Métodos para amigos
  Future<List<dynamic>> getFriends() async {
    final r = await _dio.get('friends/');
    return r.data;
  }

  Future<List<dynamic>> getReferredFriends() async {
    final r = await _dio.get('friends/referred/');
    return r.data;
  }

  Future<bool> addFriend(String username) async {
    try {
      await _dio.post('friends/add/', data: {"username": username});
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeFriend(int friendId) async {
    try {
      await _dio.delete('friends/$friendId/');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> searchUsers(String query) async {
    final r = await _dio.get('users/search/', queryParameters: {"q": query});
    return r.data;
  }

  // Métodos para restaurantes e reservas
  Future<Map<String, dynamic>> registerRestaurant(Map<String, dynamic> restaurantData, Map<String, dynamic> profileData) async {
    final r = await _dio.post('restaurants/register/', data: {
      "restaurant": restaurantData,
      "profile": profileData,
    });
    return r.data;
  }

  Future<Map<String, dynamic>> getMyRestaurant() async {
    final r = await _dio.get('restaurants/my/');
    return r.data;
  }

  Future<Map<String, dynamic>> updateRestaurant(Map<String, dynamic> restaurantData, Map<String, dynamic> profileData) async {
    final r = await _dio.put('restaurants/update/', data: {
      "restaurant": restaurantData,
      "profile": profileData,
    });
    return r.data;
  }

  Future<Map<String, dynamic>> getRestaurantDashboard() async {
    final r = await _dio.get('restaurants/dashboard/');
    return r.data;
  }

  Future<Map<String, dynamic>> getRestaurantDetail(int restaurantId) async {
    final r = await _dio.get('restaurants/$restaurantId/');
    return r.data;
  }

  Future<List<dynamic>> getRestaurantsWithReservations() async {
    final r = await _dio.get('restaurants/with-reservations/');
    return r.data;
  }

  Future<Map<String, dynamic>> createReservation(
    int restaurantId,
    DateTime date,
    TimeOfDay time,
    int partySize, {
    String? phone,
    String? email,
    String? specialRequests,
  }) async {
    final r = await _dio.post('reservations/create/', data: {
      "restaurant": restaurantId,
      "date": "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
      "time": "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}",
      "party_size": partySize,
      "customer_phone": phone ?? "",
      "customer_email": email ?? "",
      "special_requests": specialRequests ?? "",
    });
    return r.data;
  }

  Future<List<dynamic>> getMyReservations() async {
    final r = await _dio.get('reservations/my/');
    return r.data;
  }

  Future<List<dynamic>> getRestaurantReservations() async {
    final r = await _dio.get('reservations/restaurant/');
    return r.data;
  }

  Future<Map<String, dynamic>> updateReservationStatus(int reservationId, String status) async {
    final r = await _dio.put('reservations/$reservationId/status/', data: {"status": status});
    return r.data;
  }
}
