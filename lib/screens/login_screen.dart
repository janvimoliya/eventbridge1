import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../admin/admin_login.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import 'home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const String routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      context.read<UserProvider>().login(user);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _biometricLogin() async {
    setState(() => _isLoading = true);
    try {
      final success = await _authService.biometricLogin();
      if (!success) {
        throw Exception('Biometric auth unavailable or failed.');
      }

      final remembered = _authService.getRememberedUser();
      if (remembered == null) {
        throw Exception('No remembered account. Sign up and login once first.');
      }

      if (!mounted) {
        return;
      }
      context.read<UserProvider>().login(remembered);
      Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _socialLogin(String provider) async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.socialLogin(provider: provider);
      if (!mounted) {
        return;
      }
      context.read<UserProvider>().login(user);
      Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
    } catch (error) {
      final normalized = error.toString().replaceFirst('Exception: ', '');
      final label = provider.toLowerCase() == 'facebook'
          ? 'Facebook'
          : 'Google';
      _showMessage('$label sign-in error: $normalized');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _socialButton({
    required String label,
    required VoidCallback onTap,
    required Color backgroundColor,
    required Color foregroundColor,
    required Widget logo,
    Color? borderColor,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _isLoading ? null : onTap,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: borderColor == null
                  ? null
                  : Border.all(color: borderColor, width: 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                SizedBox(width: 24, child: Center(child: logo)),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: foregroundColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 18),
                Center(
                  child: Container(
                    width: 82,
                    height: 82,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF448AFF), Color(0xFFFF6F61)],
                      ),
                    ),
                    child: const Text(
                      'EB',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Login',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text('Welcome back to EventBridge'),
                const SizedBox(height: 22),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    if (!regex.hasMatch(email)) {
                      return 'Enter a valid email address.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (value) {
                    if ((value ?? '').length < 6) {
                      return 'Password must be at least 6 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                CustomButton(
                  label: 'Login',
                  isLoading: _isLoading,
                  onPressed: _login,
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _biometricLogin,
                  icon: const Icon(Icons.fingerprint_rounded),
                  label: const Text('Biometric Login'),
                ),
                const SizedBox(height: 14),
                const Text('Continue with'),
                const SizedBox(height: 8),
                _socialButton(
                  label: 'Continue with Facebook',
                  onTap: () => _socialLogin('facebook'),
                  backgroundColor: const Color(0xFF1F73E8),
                  foregroundColor: Colors.white,
                  logo: const Icon(Icons.facebook_rounded, color: Colors.white),
                ),
                const SizedBox(height: 10),
                _socialButton(
                  label: 'Continue with Google',
                  onTap: () => _socialLogin('google'),
                  backgroundColor: const Color(0xFFF5F5F5),
                  foregroundColor: const Color(0xFF7A7A7A),
                  borderColor: const Color(0xFFE3E3E3),
                  logo: const Text(
                    'G',
                    style: TextStyle(
                      color: Color(0xFFDB4437),
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('New user? '),
                    TextButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pushNamed(SignupScreen.routeName),
                      child: const Text('Sign up first'),
                    ),
                  ],
                ),
                Center(
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamed(AdminLoginScreen.routeName),
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    label: const Text('Organizer Login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
