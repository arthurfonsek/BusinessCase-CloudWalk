import 'package:dio/dio.dart';
import 'auth_service_simple.dart';

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
  
  Future<Map<String,dynamic>> register(String email, String password, {String? referral}) async {
    final data = {
      "username": email, // Usar email como username
      "email": email,
      "password": password,
      "password_confirm": password,
      "referral_code": referral ?? ""
    };
    final r = await _dio.post('auth/register/', data: data);
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
}
