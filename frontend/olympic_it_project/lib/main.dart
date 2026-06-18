import 'package:flutter/material.dart';
import 'package:olympic_it_project/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:olympic_it_project/features/auth/presentation/screens/login_screen.dart';
import 'package:olympic_it_project/features/auth/presentation/screens/otp_screen.dart';
import 'package:olympic_it_project/features/auth/presentation/screens/register_screen.dart';
import 'package:olympic_it_project/features/auth/presentation/screens/reset_password.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: LoginScreen()
    );
  }
}
