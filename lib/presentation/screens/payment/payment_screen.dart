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
  bool _isHandlingReturn = false;
  WebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadBookingAndCreatePayment();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _externalPaymentOpened) {
      _checkPaymentStatus();
    }
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

    if (kIsWeb) {
      await _openPaymentPage();
    } else {
      _initWebViewController(url);
    }
  }

  void _initWebViewController(String url) {
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
                    'Không thể tải trang thanh toán qua WebView: ${error.description}\n(Mã lỗi: ${error.errorCode})\n\nMột số máy ảo Android cũ có thể chưa hỗ trợ chứng chỉ SSL của VNPAY Sandbox. Bạn có thể mở trực tiếp bằng trình duyệt ngoài bên dưới để tiếp tục.';
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
    if (_isHandlingReturn) return;
    _isHandlingReturn = true;

    final vnpResponseCode = uri.queryParameters['vnp_ResponseCode'];
    final provider = context.read<BookingProvider>();

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

  Future<void> _openPaymentPage() async {
    final url = _paymentUrl;
    if (url == null) return;
    try {
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      _externalPaymentOpened = opened;
      if (opened || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở trình duyệt thanh toán.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở trình duyệt thanh toán.')),
      );
    }
  }

  Future<void> _checkPaymentStatus() async {
    if (_isCheckingPaymentStatus) return;
    setState(() => _isCheckingPaymentStatus = true);

    final provider = context.read<BookingProvider>();
    final status = await provider.pollPaymentStatus(widget.bookingId);

    if (!mounted) return;
    setState(() => _isCheckingPaymentStatus = false);

    if (status == 'Paid' ||
        status == 'Failed' ||
        status == 'Cancelled' ||
        status == 'Expired') {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán VNPAY'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
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
              : kIsWeb
                  ? _buildPaymentWaiting()
                  : _webViewController == null
                      ? const Center(child: CircularProgressIndicator())
                      : WebViewWidget(controller: _webViewController!),
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
                const Icon(Icons.error_outline_rounded, size: 48, color: Colors.amber),
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
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                      });
                      _initWebViewController(_paymentUrl!);
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Thử tải lại WebView'),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_user_outlined, size: 56),
              const SizedBox(height: 16),
              const Text(
                'Trang VNPAY được mở trong cửa sổ thanh toán an toàn của trình duyệt.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _openPaymentPage,
                icon: const Icon(Icons.open_in_browser_rounded),
                label: const Text('Mở lại trang thanh toán'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed:
                    _isCheckingPaymentStatus ? null : _checkPaymentStatus,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  _isCheckingPaymentStatus
                      ? 'Đang kiểm tra...'
                      : 'Kiểm tra trạng thái thanh toán',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
