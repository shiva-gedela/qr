import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants.dart';
import '../../services/theme_service.dart';
import '../../services/auth_service.dart';
import '../events/event_list_screen.dart';
import '../booking/my_bookings_screen.dart';
import '../business/vendor_dashboard_screen.dart';
import '../business/vendor_add_screen.dart';
import '../auth/login_screen.dart';
import 'qr_tickets_wallet_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String _userName = 'QRouteX Member';
  String _userEmail = 'member@qroutex.com';
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() async {
    final loggedIn = await AuthService.isLoggedIn();
    if (!mounted) return;
    setState(() {
      _isLoggedIn = loggedIn;
      if (loggedIn) {
        _userName = 'Verified Host';
        _userEmail = 'host@qroutex.com';
      }
    });
  }

  void _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showServerSettings() {
    final urlController = TextEditingController(text: AppConstants.baseUrl);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.dns, color: AppConstants.primaryColor),
              SizedBox(width: 8),
              Text('Server Settings', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Configure backend API host URL:', style: TextStyle(fontSize: 13, color: AppConstants.textMuted)),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Server URL'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor),
              onPressed: () async {
                await AppConstants.setBaseUrl(urlController.text.trim());
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Server updated: ${AppConstants.baseUrl}')),
                );
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showEditProfileModal() {
    final nameCtrl = TextEditingController(text: _userName);
    final emailCtrl = TextEditingController(text: _userEmail);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Edit Profile Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Display Name', prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email), border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  setState(() {
                    _userName = nameCtrl.text.trim();
                    _userEmail = emailCtrl.text.trim();
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!')));
                },
                child: const Text('Save Profile', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.instance.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? AppConstants.darkBackgroundColor : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Profile & Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppConstants.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: () => ThemeService.instance.toggleTheme(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Profile Hero Header ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppConstants.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: AppConstants.primaryColor.withOpacity(0.3), blurRadius: 14, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: AppConstants.accentColor, width: 2),
                        ),
                        child: const Icon(Icons.person, color: AppConstants.primaryColor, size: 36),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(_userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: AppConstants.accentColor, borderRadius: BorderRadius.circular(6)),
                                  child: const Text('PRO', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 9)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(_userEmail, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: _showEditProfileModal,
                              child: const Text('Edit Profile ✎', style: TextStyle(color: AppConstants.accentColor, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 28),
                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildProfileStat('My Events', '6'),
                      _buildProfileStat('QR Passes', '8'),
                      _buildProfileStat('Bookings', '2'),
                      _buildProfileStat('Moments', '4'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Core Navigation Tiles ──
            _buildSectionCard(
              title: 'Activity & Management',
              children: [
                _buildActionTile(
                  icon: Icons.celebration,
                  iconColor: AppConstants.primaryColor,
                  title: 'My Events Management',
                  subtitle: 'View upcoming, draft and past invitations',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventListScreen())),
                ),
                const Divider(height: 1),
                _buildActionTile(
                  icon: Icons.qr_code_2,
                  iconColor: const Color(0xFF06B6D4),
                  title: 'My QR Tickets & Passes Wallet',
                  subtitle: 'Digital passes ready for gate scan',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QrTicketsWalletScreen())),
                ),
                const Divider(height: 1),
                _buildActionTile(
                  icon: Icons.calendar_today,
                  iconColor: const Color(0xFF10B981),
                  title: 'My Bookings & Reservations',
                  subtitle: 'Restaurants, salons, and vendor appointments',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsScreen())),
                ),
                const Divider(height: 1),
                _buildActionTile(
                  icon: Icons.storefront,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Vendor Partner Dashboard',
                  subtitle: 'Manage client inquiries, services & catalog',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorDashboardScreen())),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── App Settings & Preferences ──
            _buildSectionCard(
              title: 'Preferences & Server',
              children: [
                ListTile(
                  leading: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: AppConstants.primaryColor),
                  title: const Text('Dark Mode Appearance', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(isDark ? 'Dark theme active' : 'Light theme active', style: const TextStyle(fontSize: 11)),
                  trailing: Switch(
                    value: isDark,
                    activeColor: AppConstants.accentColor,
                    onChanged: (val) => ThemeService.instance.setDarkMode(val),
                  ),
                ),
                const Divider(height: 1),
                _buildActionTile(
                  icon: Icons.dns,
                  iconColor: AppConstants.primaryColor,
                  title: 'Backend Server Configuration',
                  subtitle: AppConstants.baseUrl,
                  onTap: _showServerSettings,
                ),
                const Divider(height: 1),
                _buildActionTile(
                  icon: Icons.add_business,
                  iconColor: const Color(0xFF10B981),
                  title: 'Register as Event Vendor',
                  subtitle: 'List your catering, photography, decor services',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorAddScreen())),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Support & Authentication ──
            _buildSectionCard(
              title: 'Support & Legal',
              children: [
                _buildActionTile(
                  icon: Icons.help_outline,
                  iconColor: AppConstants.primaryColor,
                  title: 'Help & Support Desk',
                  subtitle: 'support@qroutex.com',
                  onTap: () => _openUrl('mailto:support@qroutex.com'),
                ),
                const Divider(height: 1),
                _buildActionTile(
                  icon: Icons.public,
                  iconColor: AppConstants.accentColor,
                  title: 'Official Website (qroutex.com)',
                  subtitle: 'Explore cloud portal and designer tools',
                  onTap: () => _openUrl('https://qroutex.com'),
                ),
                const Divider(height: 1),
                if (!_isLoggedIn)
                  _buildActionTile(
                    icon: Icons.login,
                    iconColor: AppConstants.primaryColor,
                    title: 'Sign In / Register Account',
                    subtitle: 'Sync celebrations across devices',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                    },
                  )
                else
                  _buildActionTile(
                    icon: Icons.logout,
                    iconColor: AppConstants.dangerColor,
                    title: 'Sign Out Account',
                    subtitle: 'Signed in as $_userEmail',
                    onTap: () async {
                      await AuthService.logout();
                      _checkAuth();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Successfully signed out')),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppConstants.textMuted, letterSpacing: 0.8),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppConstants.textMuted)),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: onTap,
    );
  }
}
