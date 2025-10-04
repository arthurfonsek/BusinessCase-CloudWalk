import 'package:dio/dio.dart';
import '../models/friend.dart';
import 'auth_service_simple.dart';

class FriendsService {
  static final FriendsService _instance = FriendsService._internal();
  factory FriendsService() => _instance;
  FriendsService._internal();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: '${const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://127.0.0.1:8000')}/api/',
    headers: {
      'Content-Type': 'application/json',
    },
  ));

  // Buscar amigos
  Future<List<Friend>> getFriends() async {
    try {
      final token = AuthService().token;
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }
      _dio.options.headers['Authorization'] = 'Bearer $token';
      final response = await _dio.get('friends/');
      print('Resposta da API de amigos: ${response.data}');
      return (response.data as List)
          .map((json) => Friend.fromJson(json))
          .toList();
    } catch (e) {
      print('Erro ao buscar amigos: $e');
      rethrow;
    }
  }

  // Buscar amigos que usaram código de referência
  Future<List<Friend>> getReferredFriends() async {
    try {
      final token = AuthService().token;
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }
      _dio.options.headers['Authorization'] = 'Bearer $token';
      final response = await _dio.get('friends/referred/');
      print('Resposta da API de amigos referidos: ${response.data}');
      return (response.data as List)
          .map((json) => Friend.fromJson(json))
          .toList();
    } catch (e) {
      print('Erro ao buscar amigos referidos: $e');
      rethrow;
    }
  }

  // Adicionar amigo por username
  Future<bool> addFriend(String username) async {
    try {
      final token = AuthService().token;
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }
      _dio.options.headers['Authorization'] = 'Bearer $token';
      await _dio.post('friends/add/', data: {'username': username});
      return true;
    } catch (e) {
      print('Erro ao adicionar amigo: $e');
      return false;
    }
  }

  // Remover amigo
  Future<bool> removeFriend(String friendId) async {
    try {
      final token = AuthService().token;
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }
      _dio.options.headers['Authorization'] = 'Bearer $token';
      await _dio.delete('friends/$friendId/');
      return true;
    } catch (e) {
      print('Erro ao remover amigo: $e');
      return false;
    }
  }

  // Buscar usuários por username
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final token = AuthService().token;
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }
      _dio.options.headers['Authorization'] = 'Bearer $token';
      final response = await _dio.get('users/search/', queryParameters: {'q': query});
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      print('Erro ao buscar usuários: $e');
      return [];
    }
  }
}
