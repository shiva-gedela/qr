import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../services/auth_service.dart';
import '../home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'demo@qroutex.com');
  final _passwordController = TextEditingController(text: 'Demo@1234Password');
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final result = await AuthService.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    setState(() => _isLoading = false);

    if (result.success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.orange),
              SizedBox(width: 8),
              Text('Connection Notice'),
            ],
          ),
          content: Text(result.errorMessage ?? 'Invalid email or password.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showServerSettingsDialog();
              },
              child: const Text('Change Server URL'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _enterDemoMode();
              },
              child: const Text('Use Offline Mode'),
            ),
          ],
        ),
      );
    }
  }

  void _enterDemoMode() async {
    await AuthService.setOfflineDemo(true);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  void _showServerSettingsDialog() {
    final serverController = TextEditingController(text: AppConstants.baseUrl);
    bool testing = false;
    String? statusMessage;
    bool? isSuccess;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.dns, color: AppConstants.primaryColor),
                SizedBox(width: 8),
                Text('Server Settings', style: TextStyle(fontSize: 18)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set the backend URL your mobile phone connects to (e.g. Render cloud or Wi-Fi IP):',
                  style: TextStyle(fontSize: 13, color: AppConstants.textMuted),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: serverController,
                  decoration: const InputDecoration(
                    labelText: 'Backend Base URL',
                    hintText: 'https://your-app.onrender.com',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    ActionChip(
                      label: const Text('Render (Cloud)', style: TextStyle(fontSize: 11)),
                      onPressed: () => setDialogState(() => serverController.text = 'https://qr-backend.onrender.com'),
                    ),
                    ActionChip(
                      label: const Text('Wi-Fi PC (10.22.84.118)', style: TextStyle(fontSize: 11)),
                      onPressed: () => setDialogState(() => serverController.text = 'http://10.22.84.118:8000'),
                    ),
                    ActionChip(
                      label: const Text('Emulator (10.0.2.2)', style: TextStyle(fontSize: 11)),
                      onPressed: () => setDialogState(() => serverController.text = 'http://10.22.84.118:8000'),
                    ),
                  ],
                ),
                if (statusMessage != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        isSuccess == true ? Icons.check_circle : Icons.error,
                        color: isSuccess == true ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          statusMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSuccess == true ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: testing
                    ? null
                    : () async {
                        setDialogState(() {
                          testing = true;
                          statusMessage = 'Pinging server...';
                        });
                        final ok = await AuthService.testConnection(serverController.text);
                        setDialogState(() {
                          testing = false;
                          isSuccess = ok;
                          statusMessage = ok
                              ? 'Server reachable!'
                              : 'Cannot reach server. Verify IP / port / Wi-Fi.';
                        });
                      },
                child: testing
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Test Connection'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await AppConstants.setBaseUrl(serverController.text);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Server URL updated to: ${AppConstants.baseUrl}')),
                  );
                },
                child: const Text('Save URL'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppConstants.textDark),
            tooltip: 'Server Settings',
            onPressed: _showServerSettingsDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    size: 72,
                    color: AppConstants.primaryColor,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'QRouteX',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: AppConstants.textDark,
                    ),
                  ),
                  const Text(
                    'Smart Event QR Codes • GPS Navigation • Moments',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppConstants.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 28),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (v) => v!.isEmpty ? 'Enter email' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (v) => v!.isEmpty ? 'Enter password' : null,
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    onPressed: _enterDemoMode,
                    icon: const Icon(Icons.play_circle_outline, color: AppConstants.accentColor),
                    label: const Text('Explore in Offline Demo Mode', style: TextStyle(color: AppConstants.textDark)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? ", style: TextStyle(color: AppConstants.textMuted)),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          );
                        },
                        child: const Text(
                          'Register',
                          style: TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
