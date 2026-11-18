import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/auth_service.dart';
import 'events/event_list_screen.dart';
import 'business/business_list_screen.dart';
import 'qr/qr_scanner_screen.dart';
import 'subscriptions/pricing_screen.dart';
import 'auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const EventListScreen(),
    const BusinessListScreen(),
    const PricingScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.qr_code_scanner, color: AppConstants.accentColor),
            SizedBox(width: 8),
            Text('QRouteX', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              String? logoutWarning;
              try {
                await AuthService.logout();
              } catch (error) {
                logoutWarning = error.toString();
              }
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
                if (logoutWarning != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(logoutWarning)));
                }
              }
            },
          ),
        ],
      ),
      body: _pages[_currentIndex],
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppConstants.primaryColor,
        tooltip: 'Scan QR Code',
        child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerScreen()));
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppConstants.primaryColor,
        unselectedItemColor: AppConstants.textMuted,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.celebration_outlined),
            activeIcon: Icon(Icons.celebration),
            label: 'My Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business_center_outlined),
            activeIcon: Icon(Icons.business_center),
            label: 'Businesses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star_outline),
            activeIcon: Icon(Icons.star),
            label: 'Plans',
          ),
        ],
      ),
    );
  }
}
