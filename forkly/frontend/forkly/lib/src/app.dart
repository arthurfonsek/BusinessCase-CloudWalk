import 'package:flutter/material.dart';
import 'screens/auth_screen.dart';
import 'screens/home_map_screen.dart';
import 'screens/rewards_screen.dart';
import 'screens/register_screen.dart';
import 'screens/restaurant_detail_screen.dart';
import 'screens/my_lists_screen.dart';
import 'screens/metrics_dashboard_screen.dart';

class FoodieApp extends StatelessWidget {
  const FoodieApp({super.key});
  
  @override
  Widget build(BuildContext context){
    return MaterialApp(
      title: 'FoodieMap',
      theme: ThemeData(useMaterial3:true),
      routes: {
        "/": (_) => const HomeMapScreen(),
        "/auth": (_) => const AuthScreen(),
        "/rewards": (_) => const RewardsScreen(),
        "/register": (_) => const RegisterScreen(),
        "/my-lists": (_) => const MyListsScreen(),
        "/metrics": (_) => const MetricsDashboardScreen(),
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
