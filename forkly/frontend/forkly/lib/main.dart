import 'package:flutter/material.dart';
import 'src/app.dart';
import 'src/services/auth_service_simple.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar o AuthService
  final authService = AuthService();
  await authService.initialize();
  
  runApp(const FoodieApp());
}

