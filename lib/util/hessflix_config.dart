class HessflixConfig {
  static HessflixConfig _instance = HessflixConfig._();
  HessflixConfig._();

  static String? get baseUrl => _instance._baseUrl;
  static set baseUrl(String? value) => _instance._baseUrl = value;
  String? _baseUrl;

  static void fromJson(Map<String, dynamic> json) => _instance = HessflixConfig._fromJson(json);

  factory HessflixConfig._fromJson(Map<String, dynamic> json) {
    final config = HessflixConfig._();
    final newUrl = json['baseUrl'] as String?;
    config._baseUrl = newUrl?.isEmpty == true ? null : newUrl;
    return config;
  }
}
