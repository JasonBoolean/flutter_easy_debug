class AppEnvironment {
  final String name;
  final String baseUrl;
  final bool isDefault;

  const AppEnvironment({
    required this.name,
    required this.baseUrl,
    this.isDefault = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AppEnvironment &&
        other.name == name &&
        other.baseUrl == baseUrl;
  }

  @override
  int get hashCode => name.hashCode ^ baseUrl.hashCode;
}
