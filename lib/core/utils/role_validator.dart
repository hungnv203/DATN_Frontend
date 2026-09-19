import 'dart:convert';

class RoleValidator {
  static const String customerRole = 'customer';
  static const String adminRole = 'admin';
  static const String staffRole = 'staff';

  /// Validates whether the given role is allowed to access the Mobile App.
  /// Backend provides 3 roles: Customer, Admin, Staff.
  /// Only Customer can log into the Mobile App. Admin and Staff are strictly rejected.
  static bool isAllowedMobileCustomerRole(String? role) {
    if (role == null) return false;
    final normalized = role.trim().toLowerCase();
    return normalized == customerRole;
  }

  /// Extracts the role string from a JWT access token if present.
  static String? extractRoleFromJwt(String? token) {
    if (token == null || token.trim().isEmpty) return null;
    try {
      final parts = token.trim().split('.');
      if (parts.length != 3) return null;

      final normalized = base64Url.normalize(parts[1]);
      final payloadString = utf8.decode(base64Url.decode(normalized));
      final payload = jsonDecode(payloadString);

      if (payload is! Map<String, dynamic>) return null;

      final roleClaim = payload['role'] ??
          payload['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'] ??
          payload['roles'];

      if (roleClaim is String) return roleClaim;
      if (roleClaim is List && roleClaim.isNotEmpty) {
        return roleClaim.first.toString();
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
