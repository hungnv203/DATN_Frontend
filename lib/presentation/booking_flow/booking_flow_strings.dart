import 'package:flutter/widgets.dart';

class BookingFlowErrorKeys {
  static const paymentPending = 'payment_pending';
  static const authenticationRequired = 'authentication_required';
  static const holdExpired = 'hold_expired';
  static const seatUnavailable = 'seat_unavailable';
  static const requestFailed = 'request_failed';
}

class BookingFlowStrings {
  final bool vi;
  const BookingFlowStrings._(this.vi);

  static BookingFlowStrings of(BuildContext context) => BookingFlowStrings._(
      Localizations.localeOf(context).languageCode == 'vi');

  String get selectSeats => vi ? 'Chọn ghế' : 'Select seats';
  String get concessions => vi ? 'Bắp nước' : 'Concessions';
  String get review => vi ? 'Thông tin đặt vé' : 'Booking review';
  String get screen => vi ? 'MÀN HÌNH' : 'SCREEN';
  String get noSeats => vi ? 'Không có ghế khả dụng' : 'No seats available';
  String get confirmSeats => vi ? 'Xác nhận ghế' : 'Confirm seats';
  String get releaseSeats => vi ? 'Trả ghế đang giữ' : 'Release held seats';
  String get continueLabel => vi ? 'Tiếp tục' : 'Continue';
  String get selectedCount => vi ? 'Số ghế đã chọn' : 'Selected seats';
  String get priceAtReview =>
      vi ? 'Giá được tính ở bước xem lại' : 'Price calculated at review';
  String get holdTime => vi ? 'Thời gian giữ ghế' : 'Seat hold time';
  String get backToSeats => vi ? 'Sửa ghế' : 'Edit seats';
  String get promotion => vi ? 'Mã khuyến mãi' : 'Promotion code';
  String get points => vi ? 'Điểm sử dụng' : 'Points to use';
  String get total => vi ? 'Tổng thanh toán' : 'Total';
  String get confirmBooking => vi ? 'Xác nhận đặt vé' : 'Confirm booking';
  String get paymentPending =>
      vi ? 'Thanh toán đang chờ xử lý.' : 'Payment is pending.';
  String get leaveTitle => vi ? 'Rời luồng đặt vé?' : 'Leave booking flow?';
  String get leaveBody => vi
      ? 'Ghế đang giữ sẽ được trả lại.'
      : 'Your held seats will be released.';
  String get stay => vi ? 'Ở lại' : 'Stay';
  String get leave => vi ? 'Rời đi' : 'Leave';
  String get retry => vi ? 'Thử lại' : 'Retry';
  String get leaveWithTtl =>
      vi ? 'Rời đi và chờ hết hạn' : 'Leave and let hold expire';
  String get releaseFailed =>
      vi ? 'Không thể trả ghế lúc này.' : 'Unable to release seats.';
  String seatSemantic(String label, String type, String state) => vi
      ? 'Ghế $label, loại $type, trạng thái $state'
      : 'Seat $label, $type, $state';
  String stateAvailable(bool selected) => selected
      ? (vi ? 'đã chọn' : 'selected')
      : (vi ? 'còn trống' : 'available');
  String get stateHeld => vi ? 'đang giữ' : 'held';
  String get stateBooked => vi ? 'đã bán' : 'booked';
  String get heldLegend =>
      vi ? 'Đang giữ (biểu tượng khóa)' : 'Held (lock icon)';
  String get bookedLegend => vi ? 'Đã bán (dấu kiểm)' : 'Booked (check icon)';
  String get loading => vi ? 'Đang tải' : 'Loading';
  String get emptyConcessions =>
      vi ? 'Không có bắp nước đang bán' : 'No active concessions';
  String get quoteUpdating => vi ? 'Đang cập nhật giá…' : 'Updating price…';
  String get showtimeMissing =>
      vi ? 'Không tìm thấy suất chiếu' : 'Showtime not found';
  String get requestFailed => vi
      ? 'Không thể hoàn tất yêu cầu. Vui lòng thử lại.'
      : 'Unable to complete the request. Please try again.';
  String get authenticationRequired => vi
      ? 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.'
      : 'Your session has expired. Please sign in again.';
  String get holdExpired =>
      vi ? 'Thời gian giữ ghế đã hết.' : 'Your seat hold has expired.';
  String get seatUnavailable => vi
      ? 'Một ghế đã chọn không còn khả dụng.'
      : 'A selected seat is no longer available.';

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
