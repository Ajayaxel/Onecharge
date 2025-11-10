class CountryUtils {
  static String getFlagUrl(String countryCode) {
    return 'https://flagcdn.com/w40/${countryCode.toLowerCase()}.png';
  }
}

