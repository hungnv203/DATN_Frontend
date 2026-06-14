import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../domain/entities/booking.dart';

class PaymentScreen extends StatefulWidget {
  final Booking booking;

  const PaymentScreen({super.key, required this.booking});

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
    _createPaymentUrl();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
          onNavigationRequest: (NavigationRequest request) {
            // Intercept return url from VNPAY
            if (request.url.contains('payment-result')) {
              _handlePaymentResult(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
  }

  Future<void> _createPaymentUrl() async {
    try {
      final dio = Dio();
      final response = await dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.payments}/create-url',
        data: {'bookingId': widget.booking.id},
      );
      
      setState(() {
        _paymentUrl = response.data['url'];
      });

      if (_paymentUrl != null) {
        _controller.loadRequest(Uri.parse(_paymentUrl!));
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể khởi tạo thanh toán VNPAY';
      });
    }
  }

  void _handlePaymentResult(String url) {
    final uri = Uri.parse(url);
    final success = uri.queryParameters['success'] == 'true';
    
    // Đóng màn hình thanh toán và trả về kết quả
    Navigator.pop(context, success);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán VNPAY'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false), // Cancel payment
        ),
      ),
      body: _errorMessage != null
          ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
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
