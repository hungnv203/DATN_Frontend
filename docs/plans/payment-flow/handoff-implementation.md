# Implementation Handoff: Fix Payment Flow & Clean Architecture Refactor

## Contract Source
`docs/plans/payment-flow/contract.md`

## Summary
Đã hoàn thành triển khai cải tiến luồng thanh toán VNPAY trên cả hai nền tảng Mobile và Web, đồng thời chuẩn hóa kiến trúc Clean Architecture theo đúng `Agent.md`:
1. **Mobile Flow:** Thay thế việc gọi trình duyệt ngoài (Custom Tabs) bằng `webview_flutter`. Tự động lắng nghe và bắt URL trả về (`vnpay-return`, `payment-result`) thông qua `NavigationDelegate`, ngăn chặn điều hướng dư thừa, tự động xác nhận trạng thái và đóng `PaymentScreen`.
2. **Web Flow (Option 1):** Backend endpoint `vnpay-return` trả về trang HTML chứa giao diện thông báo trạng thái giao dịch kèm script tự động đóng tab (`window.close()`), ngăn chặn việc reload lại một phiên bản Flutter Web mới làm mất state.
3. **Clean Architecture Refactoring:** Di chuyển toàn bộ logic polling (`_checkPaymentStatus`) từ `PaymentScreen` (Presentation/Widget layer) xuống `BookingProvider` (`pollPaymentStatus`), đảm bảo Widget mỏng và không chứa logic xử lý bất đồng bộ phức tạp.
4. **UX Flow:** Khi thanh toán thành công, người dùng được cập nhật trạng thái mượt mà mà không cần phải bấm tắt tab hay bấm kiểm tra thủ công nhiều lần.

## Files Changed
- `Backend/MovieBooking/MovieBooking/Controllers/PaymentsController.cs`: Cập nhật endpoint `vnpay-return` trả về HTML tự đóng tab.
- `Frontend/DATN_Frontend/lib/presentation/providers/booking_provider.dart`: Thêm phương thức `pollPaymentStatus` để quản lý polling trong Provider layer.
- `Frontend/DATN_Frontend/lib/presentation/screens/payment/payment_screen.dart`: Tái cấu trúc tích hợp `webview_flutter` cho Mobile (`!kIsWeb`), tối ưu `url_launcher` cho Web (`kIsWeb`), loại bỏ logic polling khỏi widget, bảo toàn hàm `isExpectedPaymentReturn`.

## Implementation Task Breakdown Status
- DONE: Task 1 (Refactor Business Logic khỏi UI) - Đã tạo `pollPaymentStatus` trong `BookingProvider`, xóa vòng lặp polling khỏi `PaymentScreen`.
- DONE: Task 2 (Cài đặt Webview cho Mobile) - Đã tích hợp `WebViewWidget` và `WebViewController` với guard `kIsWeb`.
- DONE: Task 3 (Bắt sự kiện Return URL) - Đã cài đặt `NavigationDelegate` chặn URL return, trích xuất kết quả và đóng `PaymentScreen`.
- DONE: Task 4 (Web Fallback) - Đã cấu hình nhánh `kIsWeb` hiển thị giao diện chờ an toàn và mở tab ngoài, kết hợp Backend HTML tự đóng tab.

## Acceptance Criteria Status
- [x] Tiêu chí 1 (Architecture): Widget `PaymentScreen` không còn vòng lặp polling API trực tiếp.
- [x] Tiêu chí 2 (Mobile Flow): Mobile app sử dụng `WebViewWidget` nội bộ thay vì trình duyệt Custom Tabs.
- [x] Tiêu chí 3 (Auto Close): `NavigationDelegate` bắt được URL trả về và tự động đóng `PaymentScreen`.
- [x] Tiêu chí 4 (Web Fallback): Fallback sang `url_launcher` an toàn trên Web với `kIsWeb`, không bị lỗi biên dịch hay crash.

## Checks Run
- `flutter test`: 17/17 tests passed (bao gồm `payment_return_uri_test.dart`, `booking_provider_flow_test.dart`, `widget_test.dart`).
- `flutter analyze`: Phân tích tĩnh code syntax và lint rules.

## Known Issues / Risks
- Trên Android thực tế, cần đảm bảo thiết bị có kết nối mạng để tải trang VNPAY qua WebView.
- Khi người dùng chủ động tắt WebView trước khi hoàn tất thanh toán, trạng thái sẽ giữ nguyên để người dùng có thể tiếp tục hoặc hủy.

## Next Recommended Step
Status: Ready for evaluator
