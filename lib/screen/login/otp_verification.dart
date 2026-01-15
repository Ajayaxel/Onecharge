import 'package:flutter/material.dart';
import 'package:onecharge/const/onebtn.dart';
import 'package:onecharge/core/error/api_exception.dart';
import 'package:onecharge/features/auth/data/repositories/auth_repository.dart';
import 'package:onecharge/screen/login/phone_login.dart';
import 'package:onecharge/widgets/crypto_loading.dart';

class OtpVerification extends StatefulWidget {
  final String email;

  const OtpVerification({super.key, required this.email});

  @override
  State<OtpVerification> createState() => _OtpVerificationState();
}

class _OtpVerificationState extends State<OtpVerification> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _timerSeconds = 24;
  bool _isTimerActive = true;
  bool _isVerifying = false;
  bool _isResending = false;
  final _authRepository = AuthRepository();

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Auto-focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _isTimerActive) {
        setState(() {
          if (_timerSeconds > 0) {
            _timerSeconds--;
            _startTimer();
          } else {
            _isTimerActive = false;
          }
        });
      }
    });
  }

  void _onOtpChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (value.length > 1) {
        _controllers[index].text = value.substring(0, 1);
      }
      // Move to next field
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _onContinue(); // Auto-continue when last digit entered
      }
    } else if (value.isEmpty && index > 0) {
      // Move to previous field on backspace
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {}); // Rebuild for styling possibly
  }

  String _getOtpCode() {
    return _controllers.map((controller) => controller.text).join();
  }

  Future<void> _onContinue() async {
    final otp = _getOtpCode();
    if (otp.length != 6) {
      _showSnackBar('Please enter the complete 6-digit OTP code');
      return;
    }

    if (_isVerifying) return;

    setState(() {
      _isVerifying = true;
    });

    try {
      final response = await _authRepository.verifyOtp(
        email: widget.email,
        otp: otp,
      );

      if (!mounted) return;

      _showSnackBar(response.message);

      // Navigate to login screen after successful verification
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const PhoneLogin()),
        (route) => false,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      _showSnackBar(error.message);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onResendCode() async {
    if (!_isTimerActive && !_isResending) {
      setState(() {
        _isResending = true;
      });

      try {
        final response = await _authRepository.resendOtp(email: widget.email);

        if (!mounted) return;

        _showSnackBar(response.message);

        setState(() {
          _timerSeconds = 24;
          _isTimerActive = true;
          // Clear all OTP fields
          for (var controller in _controllers) {
            controller.clear();
          }
          _focusNodes[0].requestFocus();
        });
        _startTimer();
      } on ApiException catch (error) {
        if (!mounted) return;
        _showSnackBar(error.message);
      } catch (e) {
        if (!mounted) return;
        _showSnackBar('Something went wrong. Please try again.');
      } finally {
        if (mounted) {
          setState(() {
            _isResending = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String _formatTimer(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            Column(
              children: [
                // Top Section (Black background) - Fills remaining space
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: const BoxDecoration(color: Colors.black),
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: isKeyboardVisible ? 40 : 60),
                          // Logo
                          Image.asset(
                            "assets/login/logo.png",
                            height: 30,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox(height: 30),
                          ),
                          const SizedBox(height: 30),
                          const Text(
                            "Electric vehicle charging station for everyone.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom Section (White Rounded Container - Content Based)
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 32, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Verify Details",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "OTP sent to ${widget.email}",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // OTP Input Boxes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            6,
                            (index) => Expanded(
                              child: Container(
                                margin: EdgeInsets.only(
                                  right: index < 5 ? 8 : 0,
                                ),
                                height: 56,
                                child: TextField(
                                  controller: _controllers[index],
                                  focusNode: _focusNodes[index],
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  maxLength: 1,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                  decoration: InputDecoration(
                                    counterText: "",
                                    filled: true,
                                    fillColor: Colors.grey.shade100,
                                    contentPadding: EdgeInsets.zero,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Colors.black,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  onChanged: (value) =>
                                      _onOtpChanged(index, value),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Resend option
                        Center(
                          child: _isResending
                              ? const CryptoLoading(size: 20)
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Didn't receive the code? ",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _onResendCode,
                                      child: Text(
                                        _isTimerActive
                                            ? _formatTimer(_timerSeconds)
                                            : "Resend",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _isTimerActive
                                              ? Colors.black
                                              : Colors.blue,
                                          fontWeight: FontWeight.w600,
                                          decoration: _isTimerActive
                                              ? TextDecoration.none
                                              : TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 40),

                        // Continue Button
                        OneBtn(
                          text: "Continue",
                          isLoading: _isVerifying,
                          onPressed: _isVerifying ? null : _onContinue,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Back button
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
