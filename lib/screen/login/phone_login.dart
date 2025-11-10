import 'package:flutter/material.dart';
import 'package:onecharge/const/onebtn.dart';
import 'package:onecharge/resources/app_resources.dart';
import 'package:onecharge/models/country.dart';
import 'package:onecharge/data/countries_data.dart';
import 'package:onecharge/screen/login/otp_verification.dart';
import 'package:onecharge/utils/country_utils.dart';
import 'package:onecharge/widgets/country_picker.dart';

class PhoneLogin extends StatefulWidget {
  const PhoneLogin({super.key});

  @override
  State<PhoneLogin> createState() => _PhoneLoginState();
}

class _PhoneLoginState extends State<PhoneLogin> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isTermsAccepted = false;
  Country _selectedCountry = CountriesData.defaultCountry;

  void _showCountryPicker() {
    CountryPicker.show(
      context: context,
      onCountrySelected: (country) {
        setState(() {
          _selectedCountry = country;
        });
      },
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 50),

              /// Logo
              Image.asset(
                AppImages.logo,
                width: AppHeights.logoWidth,
                height: AppHeights.logoHeight,
                fit: BoxFit.cover,
              ),

              const SizedBox(height: 16),

              /// Tagline
              const Text(
                "Electric vehicle charging station for everyone.\nDiscover. Charge. Pay.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textColor,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 120),

              /// Phone Number Field
              Container(
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),

                    /// Country Flag - Tappable
                    GestureDetector(
                      onTap: _showCountryPicker,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          CountryUtils.getFlagUrl(_selectedCountry.code),
                          width: 32,
                          height: 22,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 32,
                              height: 22,
                              color: Colors.grey.shade300,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    /// Dropdown Icon - Tappable
                    GestureDetector(
                      onTap: _showCountryPicker,
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),

                    /// Country Code - Tappable
                    GestureDetector(
                      onTap: _showCountryPicker,
                      child: Text(
                        _selectedCountry.dialCode,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Mobile Number",
                          hintStyle: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),
              OneBtn(
                text: "Continue",
                onPressed: _isTermsAccepted
                    ? () {
                        final phoneNumber = _phoneController.text;
                        final fullNumber = '${_selectedCountry.dialCode} $phoneNumber';
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OtpVerification(
                              phoneNumber: fullNumber,
                            ),
                          ),
                        );
                        // You can add your API call here
                      }
                    : null,
              ),

              const SizedBox(height: 50),

              /// Divider OR
              Row(
                children: const [
                  Expanded(child: Divider(thickness: 1)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text("OR", style: TextStyle(fontSize: 14)),
                  ),
                  Expanded(child: Divider(thickness: 1)),
                ],
              ),

              const SizedBox(height: 30),

              /// Apple & Google icons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(AppLoginImages.apple, width: 50, height: 50),
                  const SizedBox(width: 60),
                  Image.asset(AppLoginImages.google, width: 50, height: 50),
                ],
              ),
              const Spacer(),

              /// Checkbox + Terms Text
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isTermsAccepted = !_isTermsAccepted;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Icon(
                        _isTermsAccepted
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        size: 20,
                        color: AppColors.textColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isTermsAccepted = !_isTermsAccepted;
                        });
                      },
                      child: Text(
                        overflow: TextOverflow.fade,
                        "By continuing, I accept the Privacy Policy and\nTerms of Service",
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
