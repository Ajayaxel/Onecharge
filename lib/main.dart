import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:onecharge/features/auth/data/repositories/auth_repository.dart';
import 'package:onecharge/features/auth/presentation/bloc/login_bloc.dart';
import 'package:onecharge/screen/login/phone_login.dart';
import 'package:onecharge/screen/onbording/splash.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final authRepository = AuthRepository();
  runApp(MyApp(authRepository: authRepository));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: authRepository,
      child: BlocProvider(
        create: (_) => LoginBloc(authRepository),
        child: MaterialApp(
          title: 'OneCharge',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            scaffoldBackgroundColor: Colors.white,
            fontFamily: 'Lufga',
          ),
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
