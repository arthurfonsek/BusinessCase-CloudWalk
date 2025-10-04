import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:html' as html;
import 'dart:convert';
import '../models/user.dart';

// Classe simples de autenticação sem Riverpod
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: '${const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://127.0.0.1:8000')}/api/',
    headers: {
      'Content-Type': 'application/json',
    },
  ));

  User? _currentUser;
  bool _isAuthenticated = false;
  String? _token;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;

  // Inicializar autenticação ao criar o serviço
  Future<void> initialize() async {
    await _loadStoredAuth();
  }

  // Carregar autenticação salva
  Future<void> _loadStoredAuth() async {
    try {
      // Tentar carregar do localStorage (web)
      final token = html.window.localStorage['auth_token'];
      if (token != null) {
        _token = token;
        _isAuthenticated = true;
        
        // Tentar carregar dados do usuário do localStorage também
        try {
          final userDataStr = html.window.localStorage['user_data'];
          if (userDataStr != null) {
            final userData = jsonDecode(userDataStr);
            _currentUser = User(
              id: userData['id'].toString(),
              username: userData['username'],
              email: userData['email'],
              name: _buildFullName(userData['first_name'], userData['last_name']) ?? userData['username'],
              role: UserRole.user,
              createdAt: DateTime.now(),
            );
            print('Usuário carregado do localStorage: ${_currentUser?.name}');
          } else {
            // Se não tem dados do usuário, tentar carregar do backend
            try {
              final response = await _dio.get('auth/profile/', 
                options: Options(headers: {'Authorization': 'Bearer $token'})
              );
              if (response.statusCode == 200) {
                final userData = response.data;
                _currentUser = User(
                  id: userData['id'].toString(),
                  username: userData['username'],
                  email: userData['email'],
                  name: _buildFullName(userData['first_name'], userData['last_name']) ?? userData['username'],
                  role: UserRole.user,
                  createdAt: DateTime.now(),
                );
                // Salvar dados do usuário no localStorage
                html.window.localStorage['user_data'] = jsonEncode(userData);
              }
            } catch (e) {
              print('Erro ao carregar perfil: $e');
              // Se não conseguir carregar o perfil, limpar autenticação
              await logout();
            }
          }
        } catch (e) {
          print('Erro ao carregar dados do usuário: $e');
        }
      }
    } catch (e) {
      print('Erro ao carregar autenticação salva: $e');
    }
  }

  // Salvar token
  Future<void> _saveToken(String token) async {
    try {
      html.window.localStorage['auth_token'] = token;
      print('Token salvo no localStorage');
    } catch (e) {
      print('Erro ao salvar token: $e');
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      print('Token salvo no SharedPreferences');
    } catch (e) {
      print('Erro ao salvar no SharedPreferences: $e');
    }
  }

  // Login real com backend
  Future<bool> login(String username, String password) async {
    try {
      print('=== INICIANDO LOGIN ===');
      print('Usuário: $username');
      
      final response = await _dio.post('auth/login/', data: {
        'username': username,
        'password': password,
      });

      print('Status da resposta: ${response.statusCode}');
      print('Resposta completa: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        _token = data['token'];
        
        // Salvar token
        await _saveToken(_token!);
        
        final userData = data['user'];
        _currentUser = User(
          id: userData['id'].toString(),
          username: userData['username'],
          email: userData['email'],
          name: _buildFullName(userData['first_name'], userData['last_name']) ?? userData['username'],
          role: UserRole.user,
          createdAt: DateTime.now(),
        );
        
        // Salvar dados do usuário no localStorage
        try {
          html.window.localStorage['user_data'] = jsonEncode(userData);
          print('Dados do usuário salvos no localStorage');
        } catch (e) {
          print('Erro ao salvar dados do usuário: $e');
        }
        
        _isAuthenticated = true;
        
        print('=== LOGIN REALIZADO COM SUCESSO ===');
        return true;
      }
      return false;
    } catch (e) {
      print('Erro no login: $e');
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _currentUser = null;
    _isAuthenticated = false;
    _token = null;
    
    try {
      html.window.localStorage.remove('auth_token');
      html.window.localStorage.remove('user_data');
      print('Dados removidos do localStorage');
    } catch (e) {
      print('Erro ao remover dados do localStorage: $e');
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    } catch (e) {
      print('Erro ao remover token do SharedPreferences: $e');
    }
    
    print('Logout realizado');
  }

  // Verificar se está logado
  bool get isLoggedIn => _isAuthenticated && _currentUser != null;
  
  // Método auxiliar para construir o nome completo
  String? _buildFullName(String? firstName, String? lastName) {
    if (firstName == null || firstName.isEmpty) {
      return lastName?.isNotEmpty == true ? lastName : null;
    }
    if (lastName == null || lastName.isEmpty) {
      return firstName;
    }
    return '$firstName $lastName';
  }
}