import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'services/profile_service.dart';
import 'screens/profile_screen.dart';

class OTPVerificationPage extends StatefulWidget {
  final String signInId;
  final String loginMethod;
  final String loginValue;
  final String? provider;

  const OTPVerificationPage({
    super.key,
    required this.signInId,
    required this.loginMethod,
    required this.loginValue,
    this.provider,
  });

  @override
  State<OTPVerificationPage> createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  
  bool _isLoading = false;
  bool _isResending = false;
  int _resendTimer = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _resendTimer = 30;
    });
    
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _resendTimer--;
        });
        if (_resendTimer <= 0) {
          setState(() {
            _canResend = true;
          });
          return false;
        }
        return true;
      }
      return false;
    });
  }

  void _onOTPChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else {
      // Handle backspace - move to previous field if current is empty
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  String _getOTPValue() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  bool _isOTPComplete() {
    return _getOTPValue().length == 6;
  }

  void _verifyOTP() async {
    if (!_isOTPComplete()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter complete OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = context.read<AuthProvider>();
    
    try {
      final success = await authProvider.verifyOtpAndLogin(
        signInId: widget.signInId,
        code: _getOTPValue(),
        provider: widget.provider,
      );

      setState(() {
        _isLoading = false;
      });

      if (success && mounted) {
        // Login successful - check if profile is complete
        final userData = authProvider.user;
        final isProfileComplete = ProfileService.isProfileComplete(userData);
        
        if (isProfileComplete) {
          // Profile is complete - show success message and go to dashboard
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login successful! Welcome to IW Nexus'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate back to main app (AuthWrapper will handle the authenticated state)
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          // Profile is incomplete - navigate to profile screen with popup
          Navigator.of(context).popUntil((route) => route.isFirst);
          
          // Navigate to profile screen with completion dialog flag
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ProfileScreen(showCompletionDialog: true),
            ),
          );
        }
      } else if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Invalid OTP'),
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

  void _resendOTP() async {
    if (!_canResend) return;

    setState(() {
      _isResending = true;
    });

    final authProvider = context.read<AuthProvider>();
    
    try {
      final response = await authProvider.resendOtp(
        signInId: widget.signInId,
        method: widget.loginMethod,
        provider: widget.provider,
        identifier: widget.loginValue,
      );

      setState(() {
        _isResending = false;
      });

      if (response.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP sent to your ${widget.loginMethod}'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Clear current OTP inputs
        for (var controller in _otpControllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
        
        _startResendTimer();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Failed to resend OTP'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isResending = false;
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


  String _getMaskedValue() {
    if (widget.loginMethod == 'email') {
      final parts = widget.loginValue.split('@');
      if (parts.length == 2) {
        final username = parts[0];
        final domain = parts[1];
        final maskedUsername = username.length > 2 
          ? '${username.substring(0, 2)}${'*' * (username.length - 2)}'
          : username;
        return '$maskedUsername@$domain';
      }
    } else {
      // Phone number with +91 prefix
      String phoneNumber = widget.loginValue;
      
      // Handle cases where phone number already has +91 prefix
      if (phoneNumber.startsWith('+91')) {
        if (phoneNumber.length >= 7) { // +91 + at least 4 digits
          return '+91 ${phoneNumber.substring(3, 5)}${'*' * (phoneNumber.length - 7)}${phoneNumber.substring(phoneNumber.length - 2)}';
        }
      } else {
        // Original number without prefix, add +91 and mask
        if (phoneNumber.length >= 4) {
          return '+91 ${phoneNumber.substring(0, 2)}${'*' * (phoneNumber.length - 4)}${phoneNumber.substring(phoneNumber.length - 2)}';
        }
      }
    }
    return widget.loginValue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF272579)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Verify OTP',
          style: TextStyle(
            color: Color(0xFF272579),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 
                         MediaQuery.of(context).padding.top - 
                         AppBar().preferredSize.height,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF272579).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.message,
                      size: 40,
                      color: Color(0xFF272579),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Title
                  const Text(
                    'Enter Verification Code',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF272579),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Subtitle
                  Text(
                    'We sent a 6-digit code to your ${widget.loginMethod}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Masked contact info
                  Text(
                    _getMaskedValue(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF272579),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // OTP Input Fields
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: 50,
                        height: 60,
                        child: TextFormField(
                          controller: _otpControllers[index],
                          focusNode: _focusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(1),
                          ],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF272579),
                          ),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF272579), width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          onChanged: (value) => _onOTPChanged(value, index),
                          onTap: () {
                            _otpControllers[index].selection = TextSelection.fromPosition(
                              TextPosition(offset: _otpControllers[index].text.length),
                            );
                          },
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 40),
                  
                  // Verify Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyOTP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF272579),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
                        : const Text(
                            'Verify OTP',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Resend OTP
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Didn't receive code? ",
                        style: TextStyle(color: Colors.grey),
                      ),
                      if (_canResend)
                        TextButton(
                          onPressed: _isResending ? null : _resendOTP,
                          child: _isResending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF272579)),
                                ),
                              )
                            : const Text(
                                'Resend',
                                style: TextStyle(
                                  color: Color(0xFF272579),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                        )
                      else
                        Text(
                          'Resend in ${_resendTimer}s',
                          style: const TextStyle(
                            color: Colors.grey,
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