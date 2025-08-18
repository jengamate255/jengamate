import 'package:jengamate/config/app_config.dart';

class ProdConfig implements AppConfig {
  @override
  String get appName => 'Jengamate';

  @override
  String get flavorName => 'prod';

  @override
  Environment get environment => Environment.prod;
}