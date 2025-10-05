import 'package:flutter/material.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/rewards_screen.dart';
import 'screens/register_screen.dart';
import 'screens/restaurant_detail_screen.dart';
import 'screens/my_lists_screen.dart';
import 'screens/metrics_dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/restaurant_register_screen.dart';
import 'screens/restaurant_dashboard_screen.dart';
import 'screens/reservations_screen.dart';
import 'services/auth_service_simple.dart';
import 'models/user.dart';

class FoodieApp extends StatelessWidget {
  const FoodieApp({super.key});
  
  @override
  Widget build(BuildContext context){
    return MaterialApp(
      title: 'Forkly',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFd60000),
          primary: const Color(0xFFd60000),
          secondary: const Color(0xFFd60000),
          surface: Colors.white,
          onSurface: const Color(0xFFd60000),
          onPrimary: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFd60000),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFd60000),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFd60000),
            side: const BorderSide(color: Color(0xFFd60000)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFd60000),
          foregroundColor: Colors.white,
        ),
      ),
      home: const RoleBasedHome(),
      routes: {
        "/login": (_) => const LoginScreen(),
        "/auth": (_) => const AuthScreen(),
        "/register": (_) => const RegisterScreen(),
        "/forgot-password": (_) => const ForgotPasswordScreen(),
        "/admin": (_) => const AdminScreen(),
        "/rewards": (_) => const RewardsScreen(),
        "/my-lists": (_) => const MyListsScreen(),
        "/metrics": (_) => const MetricsDashboardScreen(),
        "/friends": (_) => const FriendsScreen(),
        "/restaurant-register": (_) => const RestaurantRegisterScreen(),
        "/restaurant-dashboard": (_) => const RestaurantDashboardScreen(),
        "/reservations": (_) => const ReservationsScreen(),
        "/home": (_) => const HomeScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/restaurant-detail') {
          final restaurant = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => RestaurantDetailScreen(restaurant: restaurant),
          );
        }
        return null;
      },
    );
  }
}

class RoleBasedHome extends StatefulWidget {
  const RoleBasedHome({super.key});

  @override
  State<RoleBasedHome> createState() => _RoleBasedHomeState();
}

class _RoleBasedHomeState extends State<RoleBasedHome> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    await _authService.initialize();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_authService.isAuthenticated) {
      return const LoginScreen();
    }

    final user = _authService.currentUser;
    if (user == null) {
      return const LoginScreen();
    }

    // Redirecionar baseado no role
    if (user.role.isRestaurantOwner) {
      return const RestaurantDashboardScreen();
    } else {
      return const HomeScreen();
    }
  }
}
