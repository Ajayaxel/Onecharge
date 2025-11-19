import 'package:flutter/material.dart';
import 'package:onecharge/const/onebtn.dart';
import 'package:onecharge/resources/app_resources.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({
    super.key,
    this.isSuccess = true,
    this.message,
  });

  final bool isSuccess;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Icon (Checkmark for success, Error for failure)
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSuccess ? Colors.green : Colors.red,
                    width: 3,
                  ),
                ),
                child: Icon(
                  isSuccess ? Icons.check : Icons.error,
                  color: isSuccess ? Colors.green : Colors.red,
                  size: 60,
                ),
              ),
              const SizedBox(height: 24),
              // Title
              Text(
                isSuccess ? 'Successful' : 'Error',
                style: const TextStyle(
                  color: AppColors.textColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  message ??
                      (isSuccess
                          ? 'Service ticket created successfully'
                          : 'Something went wrong. Please try again.'),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(),
              // Done/Retry Button
              OneBtn(
                text: isSuccess ? 'Done' : 'Go Back',
                onPressed: () {
                  if (isSuccess) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

