import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_notification.dart';
import '../../booking_flow/booking_flow_strings.dart';
import '../../providers/booking_provider.dart';
import '../home/home_screen.dart';
import '../payment/payment_screen.dart';

class BookingReviewScreen extends StatefulWidget {
  final String showtimeId;
  const BookingReviewScreen({super.key, required this.showtimeId});
  @override
  State<BookingReviewScreen> createState() => _BookingReviewScreenState();
}

class _BookingReviewScreenState extends State<BookingReviewScreen> {
  bool _isCheckingStatus = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<BookingProvider>();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => provider.loadReviewStage());
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _navigateToHomeWithSuccess(BookingProvider provider) {
    provider.resetFlow();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
    AppNotification.show(
      context,
      message: 'Thanh toán thành công! Đặt vé hoàn tất.',
      type: AppNotificationType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = BookingFlowStrings.of(context);
    final provider = context.watch<BookingProvider>();
    final quote = provider.currentQuote;

    if (provider.phase == BookingFlowPhase.selectingSeats &&
        ModalRoute.of(context)?.isCurrent == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    }

    if ((provider.phase == BookingFlowPhase.paymentCompleted ||
            provider.currentBooking?.status == 'Paid') &&
        ModalRoute.of(context)?.isCurrent == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _navigateToHomeWithSuccess(provider);
        }
      });
    }

    final readOnly = provider.phase == BookingFlowPhase.paymentPending;
    return PopScope(
        canPop: !readOnly,
        child: Scaffold(
            appBar: AppBar(title: Text(text.review)),
            body: ListView(padding: const EdgeInsets.all(16), children: [
              Text(provider.selectedSeats.map((seat) => seat.label).join(', '),
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...provider.selectedConcessions.entries
                  .where((entry) => entry.value > 0)
                  .map((entry) {
                final item = provider.concessions
                    .firstWhere((value) => value.id == entry.key);
                return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.name),
                    trailing: Text('x${entry.value}'));
              }),
              const SizedBox(height: 16),
              if (quote != null)
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(text.total),
                      Text('${quote.totalPrice.toStringAsFixed(0)} đ',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold))
                    ]),
              if (provider.quoteIsStale)
                Text(text.quoteUpdating,
                    style: const TextStyle(color: AppColors.textSecondary)),
              if (provider.phase == BookingFlowPhase.paymentPending) ...[
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(text.paymentPending,
                        style: const TextStyle(color: AppColors.primary))),
                OutlinedButton.icon(
                  onPressed: _isCheckingStatus
                      ? null
                      : () async {
                          if (provider.currentBooking != null) {
                            setState(() => _isCheckingStatus = true);
                            final status = await provider.pollPaymentStatus(
                                provider.currentBooking!.id,
                                maxAttempts: 5);
                            if (mounted) {
                              setState(() => _isCheckingStatus = false);
                            }
                            if ((status == 'Paid' ||
                                    provider.currentBooking?.status == 'Paid') &&
                                mounted) {
                              _navigateToHomeWithSuccess(provider);
                              return;
                            }
                            provider.returnFromPayment();
                          }
                        },
                  icon: const Icon(Icons.sync_rounded),
                  label: Text(_isCheckingStatus
                      ? 'Đang kiểm tra...'
                      : 'Kiểm tra trạng thái thanh toán'),
                ),
                const SizedBox(height: 8),
              ],
              if (provider.errorMessage != null &&
                  provider.phase != BookingFlowPhase.paymentPending)
                Text(text.error(provider.errorMessage!),
                    style: const TextStyle(color: Colors.redAccent)),
              const SizedBox(height: 20),
              SizedBox(
                  height: 52,
                  child: FilledButton(
                      onPressed: readOnly
                          ? () => _openPayment(provider)
                          : provider.canConfirmBooking
                              ? () async {
                                  final ok =
                                      await provider.createPendingBooking();
                                  if (ok && mounted) {
                                    await _openPayment(provider);
                                  }
                                }
                              : null,
                      child: Text(readOnly
                          ? text.continueLabel
                          : text.confirmBooking))),
            ])));
  }

  Future<void> _openPayment(BookingProvider provider) async {
    final booking = provider.currentBooking;
    if (booking == null) return;
    final result = await Navigator.push<dynamic>(
        context,
        MaterialPageRoute(
            builder: (_) => PaymentScreen(bookingId: booking.id)));
    final status = result == 'Paid'
        ? 'Paid'
        : await provider.pollPaymentStatus(booking.id, maxAttempts: 5);
    if ((status == 'Paid' || provider.currentBooking?.status == 'Paid') && mounted) {
      _navigateToHomeWithSuccess(provider);
      return;
    }
    provider.returnFromPayment();
  }
}
