import 'package:movie_booking_app/presentation/screens/payment/payment_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('payment return requires exact scheme host port and path', () {
    final expected = Uri.parse('https://app.example.com/payment-result');

    expect(
      isExpectedPaymentReturn(
        Uri.parse('https://app.example.com/payment-result?bookingId=1'),
        expected,
      ),
      isTrue,
    );
    expect(
      isExpectedPaymentReturn(
        Uri.parse('https://evil.example.com/payment-result'),
        expected,
      ),
      isFalse,
    );
    expect(
      isExpectedPaymentReturn(
        Uri.parse('https://app.example.com/attacker/payment-result'),
        expected,
      ),
      isFalse,
    );
    expect(
      isExpectedPaymentReturn(
        Uri.parse('http://app.example.com/payment-result'),
        expected,
      ),
      isFalse,
    );
  });
}
