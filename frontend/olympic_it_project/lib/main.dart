import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:olympic_it_project/admin/dasboard/admin_dashboard_sceen.dart';
import 'package:olympic_it_project/core/network/api_client.dart';
import 'package:olympic_it_project/core/storage/token_storage.dart';
import 'package:olympic_it_project/exam/UI/screens/essay_exam_screen.dart';
import 'package:olympic_it_project/exam/UI/screens/multiple_choice_exam_screen.dart';
import 'package:olympic_it_project/exam/UI/screens/question_loading_screen.dart';
import 'package:olympic_it_project/exam/anti_cheat/cubit/anti_cheat_cubit.dart';
import 'package:olympic_it_project/features/auth/cubit/auth_cubit.dart';
import 'package:olympic_it_project/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:olympic_it_project/features/auth/data/repositories/auth_repository.dart';
import 'package:olympic_it_project/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:olympic_it_project/features/auth/presentation/screens/login_screen.dart';
import 'package:olympic_it_project/features/auth/presentation/screens/otp_screen.dart';
import 'package:olympic_it_project/features/auth/presentation/screens/register_screen.dart';
import 'package:olympic_it_project/features/auth/presentation/screens/reset_password.dart';
import 'package:olympic_it_project/features/home/pressentation/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:olympic_it_project/features/createExam/screens/create_exam_step_1_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) =>
          AuthRepository(AuthRemoteDataSource(ApiClient()), TokenStorage()),
      child: Builder(
        builder: (context) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) => AuthCubit(context.read<AuthRepository>()),
              ),
              // AntiCheatCubit — khởi tạo ở đây để sống xuyên suốt phiên thi
              BlocProvider(create: (context) => AntiCheatCubit()),
            ],
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              //home: AuthCheckWrapper(),
              home: HomeScreen(),
            ),
          );
        },
      ),
    );
  }
}

class AuthCheckWrapper extends StatefulWidget {
  const AuthCheckWrapper({super.key});

  @override
  State<AuthCheckWrapper> createState() => _AuthCheckWrapperState();
}

class _AuthCheckWrapperState extends State<AuthCheckWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');

    if (!mounted) return;

    if (savedEmail != null && savedEmail.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
