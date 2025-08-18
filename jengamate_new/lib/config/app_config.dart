enum Environment {
  dev,
  prod,
}

abstract class AppConfig {
  String get appName;
  String get flavorName;
  Environment get environment;
}