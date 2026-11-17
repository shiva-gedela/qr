import 'package:flutter/material.dart';
import 'constants.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConstants.initBaseUrl();
  final loggedIn = await AuthService.isLoggedIn();
  runApp(EventConnectApp(isLoggedIn: loggedIn));
}

class EventConnectApp extends StatelessWidget {
  final bool isLoggedIn;

  const EventConnectApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EventConnect QR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.primaryColor,
          primary: AppConstants.primaryColor,
          background: AppConstants.backgroundColor,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppConstants.textDark,
          elevation: 0.5,
          centerTitle: false,
        ),
      ),
      home: isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
