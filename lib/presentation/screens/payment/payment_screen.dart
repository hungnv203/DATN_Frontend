import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

class _PaymentScreenState extends State<PaymentScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _paymentUrl;
  Uri? _expectedReturnUri;
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
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri != null &&
                _expectedReturnUri != null &&
                isExpectedPaymentReturn(uri, _expectedReturnUri!)) {
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
      final paymentUri = Uri.parse(url);
      _expectedReturnUri = Uri.tryParse(
        paymentUri.queryParameters['vnp_ReturnUrl'] ?? '',
      );
    });
    await _controller.loadRequest(Uri.parse(url));
  }

  Future<void> _handlePaymentResult(String url) async {
    final uri = Uri.parse(url);
    final returnedBookingId = uri.queryParameters['bookingId'];
    if (returnedBookingId != null && returnedBookingId != widget.bookingId) {
      return;
    }
    final booking = await context
        .read<BookingProvider>()
        .fetchBookingById(widget.bookingId);
    if (!mounted) return;
    Navigator.pop(context, booking?.status);
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
