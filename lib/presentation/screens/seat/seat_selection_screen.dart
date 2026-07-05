import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/concession.dart';
import '../../../domain/entities/showtime.dart';
import '../../providers/booking_provider.dart';
import '../payment/payment_screen.dart';

class SeatSelectionScreen extends StatefulWidget {
  final Showtime showtime;

  const SeatSelectionScreen({super.key, required this.showtime});

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().fetchBookingOptions(widget.showtime.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Select Seats')),
      body: provider.state == BookingState.loading && provider.seats.isEmpty
          ? const Center(child: SpinKitFadingCircle(color: AppColors.primary))
          : Column(
              children: [
                const SizedBox(height: 20),
                // Screen curve
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  height: 40,
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.primary, width: 4),
                    ),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.elliptical(200, 40),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text('SCREEN',
                      style: TextStyle(
                          color: AppColors.textSecondary, letterSpacing: 4)),
                ),
                const SizedBox(height: 40),

                // Seats Grid
                Expanded(
                  child: provider.seats.isEmpty
                      ? const Center(child: Text('No seats available'))
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 8,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: provider.seats.length,
                          itemBuilder: (context, index) {
                            final seat = provider.seats[index];
                            final isSelected =
                                provider.selectedSeats.contains(seat);

                            Color seatColor = AppColors.seatAvailable;
                            if (!seat.isAvailable) {
                              seatColor = AppColors.seatBooked;
                            } else if (isSelected) {
                              seatColor = AppColors.seatSelected;
                            }

                            return GestureDetector(
                              onTap: () => provider.toggleSeatSelection(seat),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: seatColor,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(8),
                                    topRight: Radius.circular(8),
                                    bottomLeft: Radius.circular(4),
                                    bottomRight: Radius.circular(4),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  seat.label,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                if (provider.concessions.isNotEmpty)
                  _ConcessionSection(provider: provider),

                // Bottom Bar
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Price',
                                    style: TextStyle(
                                        color: AppColors.textSecondary)),
                                const SizedBox(height: 4),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    _formatCurrency(provider.getTotalPrice(
                                        widget.showtime.basePrice)),
                                    style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tickets ${_formatCurrency(provider.getSeatTotal(widget.showtime.basePrice))} + Combo ${_formatCurrency(provider.getConcessionTotal())}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 118,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: provider.selectedSeats.isEmpty
                                  ? null
                                  : () async {
                                      final success = await provider
                                          .bookTickets(widget.showtime.id);
                                      if (!context.mounted) return;

                                      if (success) {
                                        final booking = provider.currentBooking;
                                        if (booking == null) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Failed to create booking. Please try again.'),
                                            ),
                                          );
                                          return;
                                        }

                                        final successPay = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                PaymentScreen(booking: booking),
                                          ),
                                        );
                                        if (!context.mounted) return;

                                        if (successPay == true) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Booking Successful!')),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Payment Cancelled/Failed')),
                                          );
                                        }
                                        Navigator.popUntil(
                                            context, (route) => route.isFirst);
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(provider
                                                      .errorMessage ??
                                                  'Failed to book tickets. Please try again.')),
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                              ),
                              child: provider.state == BookingState.loading
                                  ? const SpinKitThreeBounce(
                                      color: Colors.white, size: 20)
                                  : const FittedBox(child: Text('Continue')),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _ConcessionSection extends StatelessWidget {
  const _ConcessionSection({required this.provider});

  final BookingProvider provider;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 178,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Popcorn & Drinks',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: provider.concessions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final concession = provider.concessions[index];
                return _ConcessionCard(
                  concession: concession,
                  quantity: provider.getConcessionQuantity(concession.id),
                  onAdd: () => provider.incrementConcession(concession),
                  onRemove: () => provider.decrementConcession(concession),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ConcessionCard extends StatelessWidget {
  const _ConcessionCard({
    required this.concession,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  final Concession concession;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: quantity > 0 ? AppColors.primary : AppColors.seatAvailable,
        ),
      ),
      child: Row(
        children: [
          _ConcessionImage(imageUrl: concession.imageUrl),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  concession.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  concession.description.isNotEmpty
                      ? concession.description
                      : 'Combo cinema',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  _formatCurrency(concession.price),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _QuantityButton(
                      icon: Icons.remove,
                      onPressed: quantity == 0 ? null : onRemove,
                    ),
                    SizedBox(
                      width: 34,
                      child: Text(
                        '$quantity',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _QuantityButton(icon: Icons.add, onPressed: onAdd),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConcessionImage extends StatelessWidget {
  const _ConcessionImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 64,
        height: 96,
        color: AppColors.seatAvailable,
        child: imageUrl.isEmpty
            ? const Icon(Icons.local_movies, color: AppColors.textSecondary)
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.fastfood, color: AppColors.textSecondary),
              ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton.filled(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.seatAvailable,
          foregroundColor: Colors.white,
          disabledForegroundColor: AppColors.textSecondary,
        ),
      ),
    );
  }
}

String _formatCurrency(double value) {
  return NumberFormat.currency(locale: 'vi_VN', symbol: 'VND').format(value);
}
