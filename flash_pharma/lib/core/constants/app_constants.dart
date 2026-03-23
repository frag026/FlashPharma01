class AppConstants {
  AppConstants._();

  // Supabase
  static const String supabaseUrl = 'https://pvcqbdkmzlztosjvtmhx.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB2Y3FiZGttemx6dG9zanZ0bWh4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMzMjY1ODUsImV4cCI6MjA4ODkwMjU4NX0.16CD46UbMOl4j7DFFYHM35DfOUpsc3YIY0wWWIniS3s';

  // API
  static const String baseUrl = 'https://api.flashpharma.com/v1';
  static const String algoliaAppId = 'YOUR_ALGOLIA_APP_ID';
  static const String algoliaApiKey = 'YOUR_ALGOLIA_API_KEY';
  static const String algoliaIndexName = 'medicines';
  static const String mapboxAccessToken = 'YOUR_MAPBOX_ACCESS_TOKEN';
  static const String razorpayKey = 'YOUR_RAZORPAY_KEY';
  static const String cloudinaryCloudName = 'YOUR_CLOUDINARY_CLOUD_NAME';
  static const String cloudinaryUploadPreset = 'flash_pharma_prescriptions';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String roleKey = 'user_role';
  static const String onboardingKey = 'onboarding_done';

  // Defaults
  static const double defaultSearchRadius = 10.0; // km
  static const int defaultPageSize = 20;
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration locationUpdateInterval = Duration(seconds: 10);

  // Order Statuses
  static const String orderPending = 'pending';
  static const String orderConfirmed = 'confirmed';
  static const String orderPreparing = 'preparing';
  static const String orderOutForDelivery = 'out_for_delivery';
  static const String orderDelivered = 'delivered';
  static const String orderCancelled = 'cancelled';

  // User Roles
  static const String rolePatient = 'patient';
  static const String rolePharmacy = 'pharmacy';
  static const String roleAdmin = 'admin';
  static const String roleDelivery = 'delivery';
}
