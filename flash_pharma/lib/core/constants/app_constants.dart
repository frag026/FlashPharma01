class AppConstants {
  AppConstants._();

  // Supabase
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  // Google Sign-In — web client ID from Google Cloud Console
  static const String googleWebClientId = 'YOUR_GOOGLE_WEB_CLIENT_ID';
  // iOS client ID (leave empty if not targeting iOS)
  static const String googleIosClientId = '';

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
