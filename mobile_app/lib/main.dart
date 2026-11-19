import 'package:flutter/material.dart';
import 'constants.dart';
import 'services/auth_service.dart';
import 'services/theme_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConstants.initBaseUrl();
  await ThemeService.instance.init();
  final loggedIn = await AuthService.isLoggedIn();
  runApp(QRouteXApp(isLoggedIn: loggedIn));
}

class QRouteXApp extends StatelessWidget {
  final bool isLoggedIn;

  const QRouteXApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeService.instance,
      builder: (context, _) {
        final isDark = ThemeService.instance.isDarkMode;
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeService.instance.lightTheme,
          darkTheme: ThemeService.instance.darkTheme,
          home: const HomeScreen(),
        );
      },
    );
  }
}
