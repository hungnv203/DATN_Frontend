# Sprint Contract: Fix Payment Flow & Clean Architecture Refactor

## Source Spec
`docs/plans/payment-flow/spec.md` - Cải thiện và Khắc phục Lỗi Luồng Thanh toán VNPAY (Web & Mobile)

## Objective
Khắc phục lỗi người dùng bị kẹt ở trình duyệt thanh toán trên Mobile, đồng thời tái cấu trúc lại logic kiểm tra trạng thái thanh toán để tuân thủ tuyệt đối Clean Architecture theo quy định tại `Agent.md`.

## Included Scope
- Tái cấu trúc file `PaymentScreen.dart`: Loại bỏ logic business/polling.
- Cập nhật `BookingProvider.dart` để chứa các hàm xử lý thanh toán (thông qua UseCases).
- Tạo/Cập nhật các UseCase trong thư mục Domain (nếu cần) để xử lý logic check trạng thái và phân tích Return URL.
- Triển khai `webview_flutter` cho Mobile app để hiển thị VNPAY và bắt URL trả về bằng `NavigationDelegate`.
- Cập nhật nhánh logic cho Web (sử dụng `url_launcher` như cũ nhưng không gây crash state).

## Excluded Scope
- Không viết lại toàn bộ core của `BookingProvider`.
- Không thay đổi các UseCase/Logic không liên quan đến Payment.
- Không đụng vào CSDL hay IPN Webhook của Backend (ngoại trừ URL redirect nếu thực sự cần thiết).

## Acceptance Criteria

- [ ] **Tiêu chí 1 (Architecture):** Widget `PaymentScreen` hoàn toàn không chứa vòng lặp `for` hay hàm delay để polling API. Mọi thao tác này phải được đẩy xuống `BookingProvider` và `UseCase`.
- [ ] **Tiêu chí 2 (Mobile Flow):** Khi chạy trên Android/iOS, app phải dùng `WebViewWidget` nội bộ thay vì gọi trình duyệt ngoài (Custom Tabs).
- [ ] **Tiêu chí 3 (Auto Close):** `NavigationDelegate` của Webview phải bắt được URL chứa `payment-result`, sau đó tự động chặn request, bóc tách dữ liệu và đóng `PaymentScreen`.
- [ ] **Tiêu chí 4 (Web Fallback):** Code sử dụng `kIsWeb` để fallback sang `url_launcher` khi build trên nền tảng Web, đảm bảo không bị crash do Webview chưa tương thích.

## Verification Plan
1. Chạy thử trên máy ảo/thiết bị Android. Đặt vé -> Mở Webview -> Thực hiện thanh toán Sandbox -> Kiểm tra xem Webview có tự đóng và trả về màn hình vé không.
2. Review Code file `payment_screen.dart` để đảm bảo Widget mỏng (Thin Widget), chỉ chứa UI.
3. Review Code layer Domain và Presentation (Providers) để đảm bảo tuân thủ Dependency Rule.

## Implementation Task Breakdown

1. **Refactor Business Logic khỏi UI**
   - *Expected behavior:* Tạo các hàm xử lý tương ứng trong `BookingProvider` (ví dụ: `verifyPaymentReturnUrl`, `startPollingPaymentStatus`).
   - *Edge cases:* Người dùng thoát app đột ngột khi đang polling.
   - *Done when:* Hàm `_checkPaymentStatus` bị xóa khỏi `PaymentScreen`.

2. **Cài đặt Webview cho Mobile**
   - *Expected behavior:* Import `webview_flutter`. Trong hàm `build` của `PaymentScreen`, kiểm tra `if (kIsWeb) { ... } else { return WebViewWidget(controller: _controller); }`.
   - *Edge cases:* Webview lỗi tải trang, không có kết nối mạng.
   - *Done when:* Webview hiển thị thành công trang thanh toán VNPAY trên Mobile.

3. **Bắt sự kiện Return URL**
   - *Expected behavior:* Cấu hình `NavigationDelegate` (`onNavigationRequest`). Khi URL có scheme/host trùng với `isExpectedPaymentReturn`, gọi hàm xử lý của Provider và `Navigator.pop(context)`.
   - *Edge cases:* Người dùng bấm nút Back của hệ điều hành.
   - *Done when:* Thanh toán xong tự động quay về app mà không cần ấn nút X.

4. **Web Fallback**
   - *Expected behavior:* Giữ nguyên nút bấm "Mở trình duyệt" và `url_launcher` dành riêng cho người dùng Web.
   - *Done when:* Ứng dụng build trên Flutter Web không báo lỗi thiếu thư viện hay phương thức.

## File Guidance

### Inspect First
- `Frontend/DATN_Frontend/Agent.md` (Để hiểu rule Clean Architecture).
- `Frontend/DATN_Frontend/lib/presentation/screens/payment/payment_screen.dart`
- `Frontend/DATN_Frontend/lib/presentation/providers/booking_provider.dart`

### May Edit
- `lib/presentation/screens/payment/payment_screen.dart`
- `lib/presentation/providers/booking_provider.dart`
- `lib/domain/usecases/` (nếu cần thêm UseCase xử lý payment)

### Do Not Touch Without Approval
- Backend `PaymentsController.cs` (Trừ khi xác nhận thay đổi return URL).
- `Booking.dart` (Entities).

## Guardrails For Coding Agent
- **KHÔNG ĐƯỢC** gọi API `fetchBookingById` trực tiếp từ `PaymentScreen.dart`.
- **KHÔNG ĐƯỢC** để business logic, if/else kiểm tra trạng thái thanh toán phức tạp trong Widget.
- Đảm bảo tuân thủ tuyệt đối quy tắc import của Clean Architecture (Presentation không gọi Data Layer).

## Handoff Requirements
- Cung cấp danh sách file đã thay đổi.
- Báo cáo kết quả kiểm tra `flutter analyze` / `flutter test`.
- Ghi nhận các rủi ro (nếu có).

## Risks / Assumptions
- Giả định `webview_flutter` đã được tích hợp đúng native config trên Android (`INTERNET` permission) và iOS.
- Giả định URL trả về từ VNPAY chứa domain/path khớp với cấu hình hiện tại của backend (`payment-result`).

## Contract State
Status: Accepted
