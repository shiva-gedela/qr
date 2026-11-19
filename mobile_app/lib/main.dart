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
          initialRoute: '/',
          routes: {
            '/': (_) => const HomeScreen(),
          },
          onGenerateRoute: (settings) {
            // Deep Link Handler for Android App Links & Universal Links
            final uri = Uri.tryParse(settings.name ?? '');
            if (uri != null && uri.pathSegments.isNotEmpty) {
              final segments = uri.pathSegments;
              if (segments.length >= 3 && segments[0] == 'events' && segments[1] == 'e') {
                return MaterialPageRoute(
                  builder: (_) => const HomeScreen(),
                  settings: settings,
                );
              } else if (segments.length >= 2 && segments[0] == 'b') {
                return MaterialPageRoute(
                  builder: (_) => const HomeScreen(),
                  settings: settings,
                );
              }
            }
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          },
        );
      },
    );
  }
}
