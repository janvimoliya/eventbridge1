import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  static const String routeName = '/signup';

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneLoginController = TextEditingController();
  final _otpController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _isOrganizer = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isPhoneLogin = false;
  bool _phoneOtpSent = false;

  Future<String?> _promptForOtp() async {
    final otpController = TextEditingController();
    return showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Verify phone number'),
        content: TextField(
          controller: otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            hintText: 'Enter OTP sent to your phone',
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(otpController.text),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneLoginController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signup(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        password: _passwordController.text,
        isOrganizer: _isOrganizer,
      );

      await _authService.requestOtp(phoneNumber: _phoneController.text);
      if (!mounted) {
        return;
      }

      final otp = await _promptForOtp();
      if (otp == null || otp.trim().isEmpty) {
        throw Exception(
          'Phone verification cancelled. Account was created, but OTP link was not completed.',
        );
      }

      await _authService.verifyAndLinkOtp(otp: otp);

      if (!mounted) {
        return;
      }

      await _authService.logout();
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created and phone linked. Please log in.'),
        ),
      );
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(LoginScreen.routeName, (_) => false);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
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

  Future<void> _sendPhoneLoginOtp() async {
    final phone = _phoneLoginController.text.trim();

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
      );
      return;
    }

    final normalizedPhone = _normalizePhoneNumber(phone);
    if (!RegExp(r'^\+91\d{10}$').hasMatch(normalizedPhone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone must be exactly 10 digits')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.requestOtp(phoneNumber: normalizedPhone);
      if (!mounted) return;
      setState(() {
        _phoneOtpSent = true;
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('OTP sent to $normalizedPhone')));
      _otpController.clear();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _verifyPhoneLogin() async {
    final otp = _otpController.text.trim();

    if (otp.isEmpty || otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid 6-digit OTP code')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.verifyOtp(otp: otp);
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login successful!')));

      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Toggle between signup and phone login
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: !_isPhoneLogin
                              ? Colors.blue.shade50
                              : Colors.transparent,
                          child: InkWell(
                            onTap: () => setState(() => _isPhoneLogin = false),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                'Sign Up',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: !_isPhoneLogin
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const VerticalDivider(width: 1, thickness: 1),
                      Expanded(
                        child: Material(
                          color: _isPhoneLogin
                              ? Colors.blue.shade50
                              : Colors.transparent,
                          child: InkWell(
                            onTap: () => setState(() {
                              _isPhoneLogin = true;
                              _phoneOtpSent = false;
                            }),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.phone_outlined,
                                    size: 18,
                                    color: _isPhoneLogin
                                        ? Colors.blue
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'OTP Login',
                                    style: TextStyle(
                                      fontWeight: _isPhoneLogin
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Email/Password Signup Form
              if (!_isPhoneLogin) ...[
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Account',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text('All fields are required.'),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (value) {
                          final name = value?.trim() ?? '';
                          final regex = RegExp(r'^[A-Za-z\s]+$');
                          if (name.isEmpty || !regex.hasMatch(name)) {
                            return 'Name must be alphabetic and non-empty.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
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
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Phone'),
                        validator: (value) {
                          final phone = value?.trim() ?? '';
                          final regex = RegExp(r'^\d{10}$');
                          if (!regex.hasMatch(phone)) {
                            return 'Phone must be exactly 10 numeric digits.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
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
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            }),
                          ),
                        ),
                        validator: (value) {
                          if ((value ?? '') != _passwordController.text) {
                            return 'Passwords must match.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      CheckboxListTile(
                        value: _isOrganizer,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Sign up as organizer'),
                        onChanged: (value) =>
                            setState(() => _isOrganizer = value ?? false),
                      ),
                      const SizedBox(height: 10),
                      CustomButton(
                        label: 'Create Account',
                        onPressed: _signup,
                        isLoading: _isLoading,
                      ),
                    ],
                  ),
                ),
              ]
              // Phone OTP Login Form
              else ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Login with Phone OTP',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _phoneOtpSent
                          ? 'Enter the OTP sent to your phone'
                          : 'Already have an account? Login with OTP',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 18),
                    if (!_phoneOtpSent) ...[
                      TextFormField(
                        controller: _phoneLoginController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          hintText: 'Enter 10-digit phone number',
                          prefixText: '+91 ',
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        label: 'Send OTP',
                        onPressed: _sendPhoneLoginOtp,
                        isLoading: _isLoading,
                      ),
                    ] else ...[
                      TextFormField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'OTP Code',
                          hintText: 'Enter 6-digit OTP',
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        label: 'Verify & Login',
                        onPressed: _verifyPhoneLogin,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () => setState(() {
                                  _phoneOtpSent = false;
                                  _phoneLoginController.clear();
                                  _otpController.clear();
                                }),
                          child: const Text('Change Phone Number'),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
