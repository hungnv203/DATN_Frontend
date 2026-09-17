import 'package:flutter/widgets.dart';

class BookingFlowErrorKeys {
  static const paymentPending = 'payment_pending';
  static const authenticationRequired = 'authentication_required';
  static const holdExpired = 'hold_expired';
  static const seatUnavailable = 'seat_unavailable';
  static const requestFailed = 'request_failed';
}

class BookingFlowStrings {
  const BookingFlowStrings._();

  static BookingFlowStrings of(BuildContext context) =>
      const BookingFlowStrings._();

  String get selectSeats => 'Chọn ghế';
  String get concessions => 'Bắp nước & Combo';
  String get review => 'Thông tin đặt vé';
  String get screen => 'MÀN HÌNH';
  String get noSeats => 'Không có ghế khả dụng';
  String get confirmSeats => 'Xác nhận ghế';
  String get releaseSeats => 'Hủy giữ ghế';
  String get continueLabel => 'Tiếp tục';
  String get selectedCount => 'Số ghế đã chọn';
  String get priceAtReview => 'Giá vé chính xác sẽ được tính ở bước xác nhận';
  String get holdTime => 'Thời gian giữ ghế';
  String get backToSeats => 'Chọn lại ghế';
  String get promotion => 'Mã khuyến mãi';
  String get points => 'Điểm tích lũy';
  String get total => 'Tổng thanh toán';
  String get confirmBooking => 'Xác nhận đặt vé';
  String get paymentPending => 'Thanh toán đang chờ xử lý...';
  String get leaveTitle => 'Rời luồng đặt vé?';
  String get leaveBody => 'Các ghế bạn đang giữ sẽ bị hủy bỏ và nhả lại cho khách hàng khác.';
  String get stay => 'Ở lại';
  String get leave => 'Rời đi';
  String get retry => 'Thử lại';
  String get leaveWithTtl => 'Rời đi (chờ hết hạn)';
  String get releaseFailed => 'Không thể hủy giữ ghế lúc này.';
  String seatSemantic(String label, String type, String state) =>
      'Ghế $label, loại $type, trạng thái $state';
  String stateAvailable(bool selected) =>
      selected ? 'đã chọn' : 'còn trống';
  String get stateHeld => 'đang giữ';
  String get stateBooked => 'đã bán';
  String get heldLegend => 'Đang giữ (biểu tượng khóa)';
  String get bookedLegend => 'Đã bán (dấu kiểm)';
  String get loading => 'Đang tải...';
  String get emptyConcessions => 'Hiện tại rạp chưa có bắp nước đang bán';
  String get quoteUpdating => 'Đang cập nhật giá...';
  String get showtimeMissing => 'Không tìm thấy thông tin suất chiếu';
  String get requestFailed =>
      'Không thể hoàn tất yêu cầu. Vui lòng thử lại.';
  String get authenticationRequired =>
      'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
  String get holdExpired =>
      'Thời gian giữ ghế đã hết hạn. Vui lòng chọn lại ghế.';
  String get seatUnavailable =>
      'Một hoặc nhiều ghế bạn chọn vừa có người khác giữ. Vui lòng chọn ghế khác.';

  String error(String key) {
    switch (key) {
      case BookingFlowErrorKeys.paymentPending:
        return paymentPending;
      case BookingFlowErrorKeys.authenticationRequired:
        return authenticationRequired;
      case BookingFlowErrorKeys.holdExpired:
        return holdExpired;
      case BookingFlowErrorKeys.seatUnavailable:
        return seatUnavailable;
      default:
        return requestFailed;
    }
  }
}
