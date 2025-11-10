import 'package:flutter/material.dart';
import 'package:onecharge/const/onebtn.dart';
import 'package:onecharge/resources/app_resources.dart';
import 'package:onecharge/screen/vehicle/vehicle_selection.dart';

class UserInfo extends StatefulWidget {
  const UserInfo({super.key});

  @override
  State<UserInfo> createState() => _UserInfoState();
}

class _UserInfoState extends State<UserInfo> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _uniqueCodeController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _uniqueCodeController.dispose();
    super.dispose();
  }

  void _onContinue() {
    // Handle continue action
    final fullName = _fullNameController.text;
    final email = _emailController.text;
    final uniqueCode = _uniqueCodeController.text;

    Navigator.push(context, MaterialPageRoute(builder: (context) => VehicleSelection()));
    print('Full Name: $fullName');
    print('Email: $email');
    print('Unique Code: $uniqueCode');
    
    // You can add your API call here
  }

  bool _isFormValid() {
    return _fullNameController.text.isNotEmpty && 
           _emailController.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.black,
                  size: 24,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),

              const SizedBox(height: 40),

              // Title
              const Text(
                "Please tell us a bit more about yourself",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  color: AppColors.textColor,
                  fontWeight: FontWeight.w400,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 40),

              // Full Name Field
              TextField(
                controller: _fullNameController,
                keyboardType: TextInputType.name,
                decoration: InputDecoration(
                  hintText: "Full Name",
                  hintStyle: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade400,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 16),

              // Email Field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "Enter Email",
                  hintStyle: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade400,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 16),

              // Unique Code Field (Optional)
              TextField(
                controller: _uniqueCodeController,
                decoration: InputDecoration(
                  hintText: "Enter your unique code here (Optional)",
                  hintStyle: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade400,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),

              const Spacer(),

              // Continue button
              OneBtn(
                text: "Continue",
                onPressed: _isFormValid() ? _onContinue : null,
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

