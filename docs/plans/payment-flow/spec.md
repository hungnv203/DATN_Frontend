# Product Spec: Cải thiện và Khắc phục Lỗi Luồng Thanh toán VNPAY (Web & Mobile)

## 1. Product Overview

### Problem statement
Luồng thanh toán hiện tại sử dụng `url_launcher` gây ra các lỗi UX nghiêm trọng trên cả hai nền tảng Mobile (Android/iOS) và Web (Browser). Đặc biệt, việc đặt quá nhiều logic xử lý trạng thái thanh toán (polling) vào bên trong `PaymentScreen` (Presentation Layer) đang vi phạm nguyên tắc Clean Architecture được định nghĩa trong `Agent.md`.
- **Trên Mobile:** Trình duyệt ẩn (`inAppBrowserView`) không tự đóng sau khi VNPAY hoàn tất giao dịch. App phụ thuộc vào việc polling API ở UI (`_checkPaymentStatus`).
- **Trên Web:** Mở thanh toán trên tab mới khiến kết quả trả về tải lại một phiên bản mới của Web App làm mất state.
- **Backend:** Cần phân luồng rõ ràng Return URL cho Mobile và Web.

### Target user / audience
- **Người dùng cuối:** Có trải nghiệm thanh toán mượt mà, không bị kẹt ở màn hình trình duyệt.
- **Dev team:** Đảm bảo code tuân thủ nghiêm ngặt **Clean Architecture** (Logic nằm ở UseCase/Provider, UI chỉ làm nhiệm vụ hiển thị).

### Value proposition
Mang lại luồng thanh toán liền mạch, tự động nhận diện kết quả giao dịch và đóng màn hình thanh toán. Đồng thời tái cấu trúc lại phần code thanh toán để đảm bảo tuân thủ Clean Architecture (Tách bạch Data, Domain và Presentation).

### Constraints
- Tuân thủ **Agent.md**: Không gọi API trực tiếp từ UI, đưa Business Logic vào UseCases, giữ Providers mỏng (thin), tránh logic phức tạp trong Widgets.
- Sử dụng `webview_flutter` cho Mobile.
- Tái cấu trúc lại `PaymentScreen` và `BookingProvider`.

---

## 2. Feature List

1. **Tích hợp Webview Thanh toán Native (Mobile)**
   - *Priority:* Core
   - *Description:* Thay thế `url_launcher` bằng `webview_flutter` nhúng trực tiếp trong `PaymentScreen` (Presentation). UI chỉ bắt URL `onNavigationRequest`, các logic xác thực kết quả phải đẩy về Provider/UseCase.

2. **Cơ chế Đồng bộ Tab Thanh toán (Web)**
   - *Priority:* Core
   - *Description:* Web sử dụng `url_launcher` mở tab mới nhưng tối ưu giao tiếp tab (thông qua `SharedPreferences` hoặc polling ở background layer) để tự động cập nhật UI mà không mất state.

3. **Tái cấu trúc (Refactoring) theo Clean Architecture**
   - *Priority:* Core
   - *Description:* Di chuyển logic polling (`_checkPaymentStatus`) và xác thực URL trả về (`isExpectedPaymentReturn`) từ Widget `PaymentScreen` sang `BookingProvider` và các `UseCases` tương ứng trong Domain layer.

4. **Cập nhật Backend Return URL Router**
   - *Priority:* Core
   - *Description:* Đảm bảo Backend có cơ chế redirect về đúng scheme (cho Mobile) hoặc route (cho Web).

---

## 3. AI Integration Opportunities
- `None identified`

---

## 4. Sprint / Milestone Plan

**Milestone 1 (Refactoring & Mobile Fix)**
- Chuyển logic kiểm tra thanh toán từ `PaymentScreen` vào `BookingProvider` / `CheckPaymentStatusUseCase`.
- Tích hợp `webview_flutter` vào `PaymentScreen` thay cho browser ngoài. Bắt URL và chuyển về Provider xử lý.
- Sửa Backend redirect URL nếu cần.

**Milestone 2 (Web Fix)**
- Thiết lập trang/Route nhận kết quả cho Flutter Web.
- Đồng bộ state giữa 2 tab web.

---

## 5. Non-Functional Requirements
- **Architecture Compliance:** 100% tuân thủ Clean Code và Dependency Rule (`presentation -> domain -> data -> core`).
- **Reliability:** State cập nhật qua `ChangeNotifier` phải đồng bộ ngay khi webhook hoặc IPN kích hoạt.

---

## 6. Out Of Scope
- Tích hợp thêm các cổng thanh toán mới.
- Thay đổi cấu trúc luồng IPN backend.

---

## 7. Acceptance Criteria
- [ ] Hàm `_checkPaymentStatus` không còn nằm trong file Widget (`PaymentScreen.dart`).
- [ ] Mobile Webview tự động đóng khi thanh toán xong.
- [ ] Clean Architecture rule được đảm bảo (UI gọi Provider, Provider gọi UseCase).

---

## 8. Open Questions
- Với Web, chúng ta sẽ ưu tiên sửa backend để trả về 1 trang tĩnh tự đóng tab, hay sẽ bắt trong hệ thống route của Flutter Web? 

---

## 9. Human Approval State
Status: Draft pending review.
