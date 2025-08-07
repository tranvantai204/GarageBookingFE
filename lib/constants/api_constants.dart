class ApiConstants {
  // Base URLs cho API (fallback servers)
  static const List<String> serverUrls = [
    'https://garagebooking.onrender.com/api', // MongoDB server (primary)
    'https://ha-phuong-mongodb-api.onrender.com/api', // MongoDB server backup
    'https://ha-phuong-app.onrender.com/api', // Old in-memory server
  ];

  // Primary server (đang hoạt động)
  static const String baseUrl = 'https://garagebooking.onrender.com/api';

  // Auth endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String refreshTokenEndpoint = '/auth/refresh';

  // Trip endpoints
  static const String tripsEndpoint = '/trips';
  static const String searchTripsEndpoint = '/trips/search';

  // Booking endpoints
  static const String bookingsEndpoint = '/bookings';
  static const String cancelBookingEndpoint = '/bookings/cancel';

  // User endpoints
  static const String usersEndpoint = '/users';
  static const String driversEndpoint = '/users/drivers';
  static const String adminsEndpoint = '/users/admins';

  // Payment endpoints
  static const String paymentEndpoint = '/payments';
  static const String paymentCallbackEndpoint = '/payments/callback';

  // QR Code endpoints
  static const String qrCodeEndpoint = '/qr';
  static const String validateQrEndpoint = '/qr/validate';

  // File upload endpoints
  static const String uploadEndpoint = '/upload';
  static const String avatarUploadEndpoint = '/upload/avatar';

  // Notification endpoints
  static const String notificationsEndpoint = '/notifications';
  static const String fcmTokenEndpoint = '/notifications/fcm-token';

  // Statistics endpoints
  static const String statsEndpoint = '/stats';
  static const String revenueStatsEndpoint = '/stats/revenue';

  // Request timeouts
  static const Duration defaultTimeout = Duration(seconds: 10);
  static const Duration uploadTimeout = Duration(seconds: 30);
  static const Duration downloadTimeout = Duration(seconds: 15);

  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static const Map<String, String> multipartHeaders = {
    'Content-Type': 'multipart/form-data',
    'Accept': 'application/json',
  };

  // Status codes
  static const int statusOk = 200;
  static const int statusCreated = 201;
  static const int statusNoContent = 204;
  static const int statusBadRequest = 400;
  static const int statusUnauthorized = 401;
  static const int statusForbidden = 403;
  static const int statusNotFound = 404;
  static const int statusInternalServerError = 500;

  // Error messages
  static const String networkErrorMessage = 'Lỗi kết nối mạng';
  static const String timeoutErrorMessage = 'Timeout: Server không phản hồi';
  static const String unauthorizedErrorMessage = 'Phiên đăng nhập đã hết hạn';
  static const String serverErrorMessage = 'Lỗi server nội bộ';
  static const String unknownErrorMessage = 'Lỗi không xác định';

  // Helper methods
  static String getFullUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  static Map<String, String> getAuthHeaders(String token) {
    return {...defaultHeaders, 'Authorization': 'Bearer $token'};
  }

  static Map<String, String> getMultipartAuthHeaders(String token) {
    return {...multipartHeaders, 'Authorization': 'Bearer $token'};
  }

  // Environment specific URLs
  static const String devBaseUrl = 'http://localhost:3000/api';
  static const String stagingBaseUrl =
      'https://ha-phuong-staging.onrender.com/api';
  static const String prodBaseUrl = 'https://ha-phuong-app.onrender.com/api';

  // Get base URL based on environment
  static String getBaseUrlForEnvironment(String environment) {
    switch (environment.toLowerCase()) {
      case 'development':
      case 'dev':
        return devBaseUrl;
      case 'staging':
      case 'stage':
        return stagingBaseUrl;
      case 'production':
      case 'prod':
      default:
        return prodBaseUrl;
    }
  }

  // API versioning
  static const String apiVersion = 'v1';
  static const String versionedBaseUrl = '$baseUrl/$apiVersion';

  // Pagination defaults
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache settings
  static const Duration cacheExpiry = Duration(minutes: 5);
  static const Duration longCacheExpiry = Duration(hours: 1);

  // Rate limiting
  static const int maxRequestsPerMinute = 60;
  static const Duration rateLimitWindow = Duration(minutes: 1);
}
