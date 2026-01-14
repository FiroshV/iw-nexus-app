import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'providers/auth_provider.dart';
import 'otp_verification_page.dart';
import 'widgets/common/indian_phone_input.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  
  bool _isEmailMode = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _loginController.dispose();
    super.dispose();
  }

  void _toggleLoginMode() {
    setState(() {
      _isEmailMode = !_isEmailMode;
      _loginController.clear();
    });
  }

  String? _validateLogin(String? value) {
    if (value == null || value.isEmpty) {
      return _isEmailMode ? 'Please enter your email' : 'Please enter your phone number';
    }

    if (_isEmailMode) {
      // Email validation
      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
      if (!emailRegex.hasMatch(value)) {
        return 'Please enter a valid email address';
      }
    }
    // Phone validation is handled by IndianPhoneInput widget

    return null;
  }

  String _getFormattedIdentifier() {
    if (_isEmailMode) {
      return _loginController.text;
    }
    // Format phone number with +91 prefix
    return IndianPhoneInput.formatForApi(_loginController.text);
  }


  void _sendOTP() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final authProvider = context.read<AuthProvider>();
      
      try {
        final response = await authProvider.sendOtp(
          identifier: _getFormattedIdentifier(),
          method: _isEmailMode ? 'email' : 'phone',
        );

        setState(() {
          _isLoading = false;
        });

        if (response.success && mounted) {
          // Navigate to OTP verification screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OTPVerificationPage(
                signInId: response.data?['signInId'] ?? '',
                loginMethod: _isEmailMode ? 'email' : 'phone',
                loginValue: response.data?['identifier'] ?? _getFormattedIdentifier(),
                provider: response.data?['provider'],
              ),
            ),
          );
        } else if (mounted) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.error ?? 'Failed to send OTP'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 
                         MediaQuery.of(context).padding.top - 
                         MediaQuery.of(context).padding.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo/Header
                    SvgPicture.asset(
                      'assets/logo_1.svg',
                      height: 80,
                      width: 80,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'IW Nexus',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF272579),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Login Mode Toggle
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (!_isEmailMode) _toggleLoginMode();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _isEmailMode ? const Color(0xFF272579) : Colors.transparent,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(7),
                                    bottomLeft: Radius.circular(7),
                                  ),
                                ),
                                child: Text(
                                  'Email',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _isEmailMode ? Colors.white : Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (_isEmailMode) _toggleLoginMode();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: !_isEmailMode ? const Color(0xFF272579) : Colors.transparent,
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(7),
                                    bottomRight: Radius.circular(7),
                                  ),
                                ),
                                child: Text(
                                  'Mobile',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: !_isEmailMode ? Colors.white : Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Login Input Field - conditionally show email or phone input
                    if (_isEmailMode)
                      TextFormField(
                        controller: _loginController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          hintText: '',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF272579)),
                          ),
                        ),
                        validator: _validateLogin,
                      )
                    else
                      IndianPhoneInput(
                        controller: _loginController,
                        labelText: 'Mobile Number',
                        isRequired: true,
                      ),
                    const SizedBox(height: 32),

                    // Send OTP Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _sendOTP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF272579),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Send OTP to ${_isEmailMode ? 'Email' : 'Mobile'}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                    ),
                    const SizedBox(height: 32),

                    // Footer
                    const Text(
                      'Don\'t have an account? Contact your administrator',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}