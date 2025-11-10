import 'package:flutter/material.dart';
import 'package:onecharge/const/onebtn.dart';
import 'package:onecharge/resources/app_resources.dart';
import 'package:onecharge/screen/login/user_info.dart';

class OtpVerification extends StatefulWidget {
  final String phoneNumber;

  const OtpVerification({super.key, required this.phoneNumber});

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
    if (value.length == 1) {
      // Move to next field
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else if (value.isEmpty && index > 0) {
      // Move to previous field on backspace
      _focusNodes[index - 1].requestFocus();
    }
  }

  String _getOtpCode() {
    return _controllers.map((controller) => controller.text).join();
  }

  void _onContinue() {
    final otp = _getOtpCode();
    if (otp.length == 6) {
      // Handle OTP verification
      // You can add your API call here
      print('OTP entered: $otp');
      
      // Navigate to UserInfo page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const UserInfo(),
        ),
      );
    }
  }

  void _onResendCode() {
    if (!_isTimerActive) {
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
      // You can add your resend OTP API call here
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
    return '${minutes}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Back button
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.black,
                    size: 24,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),

              const SizedBox(height: 40),

              // Instructional text
              Text(
                "Please enter the verification",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  color: AppColors.textColor,
                  fontWeight: FontWeight.w400,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "code sent to ${widget.phoneNumber}",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  color: AppColors.textColor,
                  fontWeight: FontWeight.w400,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 50),

              // OTP Input Fields
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    6,
                    (index) => Padding(
                      padding: EdgeInsets.only(right: index < 5 ? 12 : 0),
                      child: SizedBox(
                        width: 45,
                        height: 45,
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          textAlign: TextAlign.center,
                          textAlignVertical: TextAlignVertical.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                            height: 1.0,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            contentPadding: EdgeInsets.zero,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Colors.black,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Colors.black,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Colors.black,
                                width: 1.5,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onChanged: (value) => _onOtpChanged(index, value),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Resend code text with timer
              GestureDetector(
                onTap: _onResendCode,
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    children: [
                      const TextSpan(text: "Didn't receive the code? "),
                      TextSpan(
                        text: _isTimerActive
                            ? _formatTimer(_timerSeconds)
                            : "Resend",
                        style: TextStyle(
                          color: _isTimerActive
                              ? AppColors.textColor
                              : Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Continue button
              OneBtn(
                text: "Continue",
                onPressed: _getOtpCode().length == 6 ? _onContinue : null,
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
