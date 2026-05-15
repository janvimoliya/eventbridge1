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
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _otpSent = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
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

  String _normalizePhoneNumber(String input) {
    var phone = input.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    if (phone.isEmpty) {
      return '';
    }

    if (phone.startsWith('+')) {
      return phone;
    }

    phone = phone.replaceAll(RegExp(r'\D'), '');
    if (phone.length == 10) {
      return '+91$phone';
    }

    return phone.isEmpty ? '' : '+$phone';
  }

  Future<void> _sendOtp() async {
    final phone = _normalizePhoneNumber(_phoneController.text);
    if (phone.isEmpty) {
      _showMessage('Enter a valid phone number.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.requestOtp(phoneNumber: phone);
      if (!mounted) {
        return;
      }
      setState(() {
        _otpSent = true;
        _otpController.clear();
      });
      _showMessage('OTP sent to $phone');
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      _showMessage('Enter the 6-digit OTP.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = await _authService.verifyOtp(otp: otp);
      if (!mounted) {
        return;
      }

      context.read<UserProvider>().login(user);
      Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openOtpSheet() async {
    _phoneController.clear();
    _otpController.clear();
    setState(() => _otpSent = false);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 14,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD0D2D8),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: Text(
                        'Login with OTP',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Enter your phone number to receive OTP',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        hintText: '+91XXXXXXXXXX or 10 digit number',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CustomButton(
                      label: _otpSent ? 'Resend OTP' : 'Send OTP',
                      icon: Icons.sms_outlined,
                      isLoading: _isLoading,
                      onPressed: () async {
                        await _sendOtp();
                        if (!mounted) {
                          return;
                        }
                        setSheetState(() {});
                      },
                    ),
                    if (_otpSent) ...[
                      const SizedBox(height: 14),
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: 'Enter OTP',
                          counterText: '',
                          prefixIcon: Icon(Icons.lock_clock_outlined),
                        ),
                      ),
                      const SizedBox(height: 8),
                      CustomButton(
                        label: 'Verify OTP',
                        icon: Icons.verified_user_outlined,
                        isLoading: _isLoading,
                        onPressed: _verifyOtp,
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.shield_outlined,
                          size: 16,
                          color: Color(0xFF6A6E79),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'We will never share your number',
                          style: TextStyle(color: Color(0xFF6A6E79)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'logo/EventBridge_logo.png',
                      width: 92,
                      height: 92,
                      fit: BoxFit.cover,
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
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () => setState(() {
                        _obscurePassword = !_obscurePassword;
                      }),
                    ),
                  ),
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
                const SizedBox(height: 18),
                const Divider(),
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
                const SizedBox(height: 2),
                Center(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(40),
                    onTap: _isLoading ? null : _openOtpSheet,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFF2F7FF),
                              border: Border.all(
                                color: const Color(0xFFD4E5FF),
                              ),
                            ),
                            child: const Icon(
                              Icons.phone_android_outlined,
                              color: Color(0xFF2D6BFF),
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Login with OTP',
                            style: TextStyle(
                              color: Color(0xFF2D6BFF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
