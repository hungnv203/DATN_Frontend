class ApiConstants {
  // Thay đổi '10.0.2.2' nếu dùng Android Emulator. Nếu dùng thiết bị thật, thay bằng IP LAN của máy tính (vd: 192.168.1.x)
  static const String baseUrl = 'http://192.168.0.101:5275/api/';
  // static const String baseUrl = 'https://datn-0w8z.onrender.com/api/';
  // Auth
  static const String login = 'Auth/sign-in';
  static const String register = 'Auth/sign-up';

  // Movies
  static const String movies = 'movies';

  // Cinemas & Showtimes
  static const String cinemas = 'cinemas';
  static const String showtimes = 'showtimes';

  // Bookings
  static const String bookings = 'bookings';
  static const String seats = 'seats';
  static const String tickets = 'tickets';
  static const String myTickets = 'bookings/my-tickets';
  static const String concessions = 'concessions';

  // Payments
  static const String payments = 'payments';
}
