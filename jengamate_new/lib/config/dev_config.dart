import 'package:jengamate/config/app_config.dart';

class DevConfig implements AppConfig {
  @override
  String get appName => 'Jengamate Dev';

  @override
  String get flavorName => 'dev';

  @override
  Environment get environment => Environment.dev;
}