class GoogleMapsConfig {
  const GoogleMapsConfig._();

  static const String apiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyCyWXFiBQAQ6qBpb3Mq_YKta4Y_dI5c4X0',
  );
}


