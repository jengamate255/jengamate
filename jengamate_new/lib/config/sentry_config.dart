/// Sentry configuration for JengaMate
/// 
/// To get your Sentry DSN:
/// 1. Go to https://sentry.io/
/// 2. Login to your account
/// 3. Navigate to Settings > Projects > jengamate > Client Keys (DSN)
/// 4. Copy the DSN and replace the placeholder below
class SentryConfig {
  // Sentry DSN for JengaMate project
  static const String dsn = 'https://750f14e00bd508d8106243c84195c4ff@o4509864404910080.ingest.de.sentry.io/4509864609644624';
  
  // Performance monitoring settings
  static const double tracesSampleRate = 1.0; // 100% in development, reduce in production
  static const double profilesSampleRate = 1.0; // 100% in development, reduce in production
  
  // Environment settings
  static const String environment = String.fromEnvironment('SENTRY_ENVIRONMENT', defaultValue: 'development');
  static const String release = String.fromEnvironment('SENTRY_RELEASE', defaultValue: '1.0.0');
  
  // Feature flags
  static const bool enableSentry = String.fromEnvironment('ENABLE_SENTRY', defaultValue: 'true') == 'true';
  static const bool enablePerformanceMonitoring = true;
  static const bool enableProfiling = true;
  
  // User context
  static const bool attachStackTrace = true;
  static const bool sendDefaultPii = false; // Set to false for privacy
}
