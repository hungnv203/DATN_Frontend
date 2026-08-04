import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../booking_flow/booking_flow_strings.dart';
import '../../providers/booking_provider.dart';
import '../payment/payment_screen.dart';

class BookingReviewScreen extends StatefulWidget {
  final String showtimeId;
  const BookingReviewScreen({super.key, required this.showtimeId});
  @override
  State<BookingReviewScreen> createState() => _BookingReviewScreenState();
}

class _BookingReviewScreenState extends State<BookingReviewScreen> {
  late final TextEditingController _promotion;
  late final TextEditingController _points;
  @override
  void initState() {
    super.initState();
    final provider = context.read<BookingProvider>();
    _promotion = TextEditingController(text: provider.promotionCode);
    _points = TextEditingController(text: '${provider.usedPoints}');
    WidgetsBinding.instance
        .addPostFrameCallback((_) => provider.loadReviewStage());
  }

  @override
  void dispose() {
    _promotion.dispose();
    _points.dispose();
    super.dispose();
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
              TextField(
                  controller: _promotion,
                  readOnly: readOnly,
                  decoration: InputDecoration(labelText: text.promotion),
                  onChanged: provider.updatePromotionCode),
              const SizedBox(height: 12),
              TextField(
                  controller: _points,
                  readOnly: readOnly,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: text.points),
                  onChanged: provider.updateUsedPoints),
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
              if (provider.phase == BookingFlowPhase.paymentPending)
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(text.paymentPending,
                        style: const TextStyle(color: AppColors.primary))),
              if (provider.errorMessage != null)
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
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => PaymentScreen(bookingId: booking.id)));
    await provider.fetchBookingById(booking.id);
    provider.returnFromPayment();
  }
}
