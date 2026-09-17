import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../providers/booking_provider.dart';

@visibleForTesting
bool isExpectedPaymentReturn(Uri candidate, Uri expected) {
  return candidate.scheme == expected.scheme &&
      candidate.host == expected.host &&
      candidate.port == expected.port &&
      candidate.path == expected.path;
}

class PaymentScreen extends StatefulWidget {
  final String bookingId;

  const PaymentScreen({super.key, required this.bookingId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  String? _paymentUrl;
  String? _errorMessage;
  bool _externalPaymentOpened = false;
  bool _isCheckingPaymentStatus = false;
  bool _useWebView = false;
  Timer? _pollTimer;
  WebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadBookingAndCreatePayment();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _externalPaymentOpened) {
      _checkPaymentStatus();
    }
  }

  void _startPollingTimer() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_isCheckingPaymentStatus) return;
      final provider = context.read<BookingProvider>();
      final booking = await provider.fetchBookingById(widget.bookingId);
      if (!mounted) return;
      if (booking?.status == 'Paid') {
        timer.cancel();
        Navigator.pop(context, 'Paid');
      } else if (booking?.status == 'Failed' ||
          booking?.status == 'Cancelled' ||
          booking?.status == 'Expired') {
        timer.cancel();
        Navigator.pop(context, booking!.status);
      }
    });
  }

  Future<void> _loadBookingAndCreatePayment() async {
    final provider = context.read<BookingProvider>();
    final booking = await provider.fetchBookingById(widget.bookingId);
    if (!mounted) return;
    if (booking == null) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            provider.errorMessage ?? 'Không tìm thấy thông tin đơn đặt vé.';
      });
      return;
    }

    final url = await provider.createPaymentUrl(booking.id);
    if (!mounted) return;
    if (url == null) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            provider.errorMessage ?? 'Không thể tạo liên kết thanh toán.';
      });
      return;
    }

    setState(() {
      _paymentUrl = url;
      _isLoading = false;
    });

    // Mở trang thanh toán bằng Chrome Custom Tabs / trình duyệt ngoài (ổn định, không crash emulator)
    await _openPaymentPage();
    _startPollingTimer();
  }

  Future<void> _openPaymentPage() async {
    final url = _paymentUrl;
    if (url == null) return;
    try {
      final uri = Uri.parse(url);
      bool opened = false;
      try {
        opened = await launchUrl(
          uri,
          mode: LaunchMode.inAppBrowserView,
        );
      } catch (_) {
        opened = false;
      }
      if (!opened) {
        opened = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }
      _externalPaymentOpened = true;
      _startPollingTimer();
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở trình duyệt thanh toán.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở trình duyệt thanh toán.')),
      );
    }
  }

  void _initWebViewController(String url) {
    setState(() {
      _useWebView = true;
      _errorMessage = null;
    });
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            final uri = Uri.parse(request.url);
            if (_isReturnUrl(uri)) {
              _handleReturnUrl(uri);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (String url) {
            final uri = Uri.parse(url);
            if (_isReturnUrl(uri)) {
              _handleReturnUrl(uri);
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (error.isForMainFrame ?? true) {
              setState(() {
                _errorMessage =
                    'Không thể tải trang thanh toán qua WebView: ${error.description}\n(Mã lỗi: ${error.errorCode})\n\nMột số máy ảo Android cũ có thể chưa hỗ trợ WebView renderer. Bạn có thể mở trực tiếp bằng trình duyệt ngoài.';
                _useWebView = false;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(url));

    setState(() {
      _webViewController = controller;
    });
  }

  bool _isReturnUrl(Uri uri) {
    if (uri.scheme == 'moviebooking' && uri.host == 'payment-result') {
      return true;
    }
    if (uri.path.endsWith('/payment-result') || uri.path == '/payment-result') {
      return true;
    }
    if (uri.path.endsWith('/vnpay-return') || uri.path == '/vnpay-return') {
      return true;
    }
    return false;
  }

  Future<void> _handleReturnUrl(Uri uri) async {
    _pollTimer?.cancel();
    final provider = context.read<BookingProvider>();

    if (uri.queryParameters.isNotEmpty) {
      await provider.handlePaymentReturn(uri.queryParameters);
    }

    final vnpResponseCode = uri.queryParameters['vnp_ResponseCode'];
    if (vnpResponseCode != null && vnpResponseCode != '00') {
      await provider.fetchBookingById(widget.bookingId);
      if (mounted) {
        Navigator.pop(context, 'Failed');
      }
      return;
    }

    final status = await provider.pollPaymentStatus(widget.bookingId);
    if (mounted) {
      Navigator.pop(context, status);
    }
  }

  Future<void> _checkPaymentStatus() async {
    if (_isCheckingPaymentStatus) return;
    setState(() => _isCheckingPaymentStatus = true);

    final provider = context.read<BookingProvider>();
    final status =
        await provider.pollPaymentStatus(widget.bookingId, maxAttempts: 3);

    if (!mounted) return;
    setState(() => _isCheckingPaymentStatus = false);

    if (status == 'Paid' ||
        status == 'Failed' ||
        status == 'Cancelled' ||
        status == 'Expired') {
      _pollTimer?.cancel();
      Navigator.pop(context, status);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Thanh toán vẫn đang chờ xử lý.',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _onCloseTapped() async {
    final provider = context.read<BookingProvider>();
    final booking = await provider.fetchBookingById(widget.bookingId);
    if (!mounted) return;
    if (booking?.status == 'Paid') {
      _pollTimer?.cancel();
      Navigator.pop(context, 'Paid');
      return;
    }
    _pollTimer?.cancel();
    Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) _onCloseTapped();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Thanh toán VNPAY'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _onCloseTapped,
          ),
          actions: [
            if (_paymentUrl != null)
              IconButton(
                tooltip: 'Mở bằng trình duyệt ngoài',
                onPressed: _openPaymentPage,
                icon: const Icon(Icons.open_in_browser_rounded),
              ),
          ],
        ),
        body: _errorMessage != null
            ? _buildFallback()
            : _isLoading || _paymentUrl == null
                ? const Center(child: CircularProgressIndicator())
                : _useWebView && _webViewController != null && !kIsWeb
                    ? WebViewWidget(controller: _webViewController!)
                    : _buildPaymentWaiting(),
      ),
    );
  }

  Widget _buildFallback() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: Colors.amber),
                const SizedBox(height: 16),
                Text(_errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                if (_paymentUrl != null) ...[
                  FilledButton.icon(
                    onPressed: _openPaymentPage,
                    icon: const Icon(Icons.open_in_browser_rounded),
                    label: const Text('Mở bằng trình duyệt ngoài (Chrome)'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed:
                        _isCheckingPaymentStatus ? null : _checkPaymentStatus,
                    icon: const Icon(Icons.sync_rounded),
                    label: Text(
                      _isCheckingPaymentStatus
                          ? 'Đang kiểm tra...'
                          : 'Kiểm tra trạng thái thanh toán',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentWaiting() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_user_outlined,
                      size: 64, color: Colors.greenAccent),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Cổng thanh toán bảo mật VNPAY',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Trang thanh toán đã được mở trong trình duyệt bảo mật. Vui lòng hoàn tất giao dịch trên VNPAY.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 24),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Đang tự động đồng bộ kết quả...',
                      style: TextStyle(fontSize: 13, color: Colors.white60),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _openPaymentPage,
                    icon: const Icon(Icons.open_in_browser_rounded),
                    label: const Text('Mở lại trang thanh toán'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed:
                        _isCheckingPaymentStatus ? null : _checkPaymentStatus,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(
                      _isCheckingPaymentStatus
                          ? 'Đang kiểm tra...'
                          : 'Kiểm tra trạng thái thanh toán',
                    ),
                  ),
                ),
                if (!kIsWeb) ...[
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {
                      if (_paymentUrl != null) {
                        _initWebViewController(_paymentUrl!);
                      }
                    },
                    icon: const Icon(Icons.web, size: 18),
                    label: const Text(
                      'Thử mở bằng WebView trong ứng dụng',
                      style: TextStyle(fontSize: 13, color: Colors.white54),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
