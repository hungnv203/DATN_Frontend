import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../../providers/booking_provider.dart';

class PaymentScreen extends StatefulWidget {
  final String bookingId;

  const PaymentScreen({super.key, required this.bookingId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _paymentUrl;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initWebView();
    _loadBookingAndCreatePayment();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            if ((error.isForMainFrame ?? true) && mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage =
                    'Unable to load payment page: ${error.description} '
                    '(code: ${error.errorCode})';
              });
            }
          },
          onSslAuthError: (error) {
            final platformError = error.platform;
            final url =
                platformError is AndroidSslAuthError ? platformError.url : '';
            final host = Uri.tryParse(url)?.host ?? '';
            if (host == 'sandbox.vnpayment.vn') {
              error.proceed();
              return;
            }

            error.cancel();
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage =
                    'The payment page was blocked because SSL is invalid.';
              });
            }
          },
          onNavigationRequest: (request) {
            if (request.url.contains('payment-result')) {
              _handlePaymentResult(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
  }

  Future<void> _loadBookingAndCreatePayment() async {
    final provider = context.read<BookingProvider>();
    final booking = await provider.fetchBookingById(widget.bookingId);
    if (!mounted) return;
    if (booking == null) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            provider.errorMessage ?? 'Booking not found or inaccessible.';
      });
      return;
    }

    final url = await provider.createPaymentUrl(booking.id);
    if (!mounted) return;
    if (url == null) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            provider.errorMessage ?? 'Unable to create payment URL.';
      });
      return;
    }

    setState(() {
      _paymentUrl = url;
    });
    await _controller.loadRequest(Uri.parse(url));
  }

  void _handlePaymentResult(String url) {
    final uri = Uri.parse(url);
    final success = uri.queryParameters['success']?.toLowerCase() == 'true';
    Navigator.pop(context, success);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VNPAY Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: _errorMessage != null
          ? Center(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            )
          : _paymentUrl == null
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    WebViewWidget(controller: _controller),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator()),
                  ],
                ),
    );
  }
}
