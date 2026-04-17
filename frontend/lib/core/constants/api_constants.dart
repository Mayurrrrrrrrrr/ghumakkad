class ApiConstants {
  // In production: https://api.ghumakkad.in/v1/
  // For local development, change this to your machine's IP (e.g., http://192.168.1.10/ghumakkad/api/v1)
  static const String baseUrl = 'https://ghumakkad.yuktaa.com/api/v1';

  // Auth
  // sendOtp removed — Firebase SDK handles SMS directly, no backend route needed
  static const String verifyOtp = '/auth/verify-otp';
  static const String logout = '/auth/logout';
  static const String updateProfile = '/auth/update-profile';
  static const String fcmToken = '/auth/fcm-token';

  // Trips
  static const String trips = '/trips';
  static const String joinTrip = '/trips/join';
  static const String inviteLink = '/invite-link';
  static const String transferOwnership = '/transfer';

  // Members
  static const String members = '/members';

  // Pins
  static const String pins = '/pins';

  // Memories
  static const String memories = '/memories';

  // Tickets & Hotels
  static const String tickets = '/tickets';
  static const String hotels = '/hotels';

  // Expenses & Hisaab
  static const String expenses = '/expenses';
  static const String hisaab = '/hisaab';
  static const String settlement = '/settle';

  // Route
  static const String route = '/route';

  // Upload
  static const String uploadImage = '/upload/image';
}
