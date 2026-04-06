import 'package:flutter/material.dart';
import '../features/home/home_page.dart';
import '../features/auth/login_page.dart';
import '../features/auth/register_page.dart';
import '../features/landing/app_landing_page.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {

      case '/':
        //return MaterialPageRoute(builder: (_) => const AppLandingPage());

      case '/home':
        //return MaterialPageRoute(builder: (_) => const HomePage());

      case '/login':
        //return MaterialPageRoute(builder: (_) => const LoginPage());

      case '/register':
        //return MaterialPageRoute(builder: (_) => const RegisterPage());

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }
}