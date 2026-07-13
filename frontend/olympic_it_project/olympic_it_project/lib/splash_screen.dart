import 'package:flutter/material.dart';
import 'package:olympic_it_project/core/storage_token.dart';
import 'package:olympic_it_project/screen/auth/login_screen.dart';
import 'package:olympic_it_project/screen/home/user_home_screen.dart';
import 'package:olympic_it_project/service/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    await Future.delayed(const Duration(seconds: 1));
    
    final accessToken = await StorageToken.instance.getAccessToken();
    final refreshToken = await StorageToken.instance.getRefreshToken();

    if (accessToken == null || refreshToken == null) {
      _goLogin();
      return;
    }

    try {
      await AuthService().refreshTokens();
      _goHome();
    } catch (e) {
      await StorageToken.instance.deleteAll();
      _goLogin();
    }
  }

  Future<void> _goHome() async {
  final role = await StorageToken.instance.getRole();

  if (role != null && role.toUpperCase().contains("ADMIN")) {
    await StorageToken.instance.deleteAll();
    _goLogin();
  } else {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const UserHomeScreen()),
    );
  }
}

  void _goLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
