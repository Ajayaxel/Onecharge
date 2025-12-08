import 'package:flutter/material.dart';
import 'package:onecharge/models/country.dart';
import 'package:onecharge/data/countries_data.dart';
import 'package:onecharge/utils/country_utils.dart';

class CountryPicker {
  static void show({
    required BuildContext context,
    required Function(Country) onCountrySelected,
  }) {
    final TextEditingController searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            List<Country> filteredCountries = CountriesData.allCountries;

            if (searchController.text.isNotEmpty) {
              final query = searchController.text.toLowerCase();
              filteredCountries = CountriesData.allCountries.where((country) {
                return country.name.toLowerCase().contains(query) ||
                    country.dialCode.contains(query) ||
                    country.code.toLowerCase().contains(query);
              }).toList();
            }

            return GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                height: MediaQuery.of(context).size.height * 0.8,
                child: Column(
                children: [
                  const Text(
                    'Select Country',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Search field
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search country...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) {
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.builder(
                      itemCount: filteredCountries.length,
                      itemBuilder: (context, index) {
                        final country = filteredCountries[index];
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              CountryUtils.getFlagUrl(country.code),
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
                          title: Text(country.name),
                          trailing: Text(
                            country.dialCode,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onTap: () {
                            onCountrySelected(country);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
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
}

