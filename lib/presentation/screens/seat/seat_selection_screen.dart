import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_notification.dart';
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
  final TextEditingController _promotionController = TextEditingController();
  final TextEditingController _pointsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().fetchBookingOptions(widget.showtime.id);
    });
  }

  @override
  void dispose() {
    _promotionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _showBookingExtras() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Consumer<BookingProvider>(
          builder: (context, currentProvider, _) {
            return SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Popcorn, drinks & discounts',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close),
                            tooltip: 'Close',
                          ),
                        ],
                      ),
                    ),
                    if (currentProvider.concessions.isNotEmpty)
                      _ConcessionSection(
                        provider: currentProvider,
                        showtimeId: widget.showtime.id,
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                      child: _DiscountSection(
                        provider: currentProvider,
                        promotionController: _promotionController,
                        pointsController: _pointsController,
                        onApply: () => currentProvider
                            .quoteCurrentSelection(widget.showtime.id),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
                const SizedBox(height: 12),
                // Screen curve
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  height: 32,
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
                const SizedBox(height: 12),

                // Seats Grid
                Expanded(
                  child: provider.seats.isEmpty
                      ? const Center(child: Text('No seats available'))
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
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
                              onTap: () {
                                provider.toggleSeatSelection(seat);
                                provider.quoteCurrentSelection(
                                    widget.showtime.id);
                              },
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

                // Bottom Bar
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _BookingExtrasButton(
                        provider: provider,
                        onPressed: _showBookingExtras,
                      ),
                      const SizedBox(height: 10),
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
                                    _formatCurrency(provider.currentQuote
                                            ?.totalPrice ??
                                        provider.getTotalPrice(
                                            widget.showtime.basePrice)),
                                    style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _buildPriceBreakdown(provider),
                                  maxLines: 2,
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
                                          AppNotification.showError(
                                            context,
                                            'Failed to create booking. Please try again.',
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
                                          AppNotification.showSuccess(
                                            context,
                                            'Booking Successful!',
                                          );
                                        } else {
                                          AppNotification.showError(
                                            context,
                                            'Payment Cancelled/Failed',
                                          );
                                        }
                                        Navigator.popUntil(
                                            context, (route) => route.isFirst);
                                      } else {
                                        AppNotification.showError(
                                          context,
                                          provider.errorMessage ??
                                              'Failed to book tickets. Please try again.',
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

class _BookingExtrasButton extends StatelessWidget {
  const _BookingExtrasButton({
    required this.provider,
    required this.onPressed,
  });

  final BookingProvider provider;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final concessionCount = provider.selectedConcessions.values.fold<int>(
      0,
      (total, quantity) => total + quantity,
    );
    final hasDiscount = provider.promotionCode.isNotEmpty ||
        provider.usedPoints > 0;
    final details = <String>[
      if (concessionCount > 0) '$concessionCount item(s)',
      if (hasDiscount) 'Discount added',
    ];

    return Material(
      color: AppColors.seatAvailable.withOpacity(0.18),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: [
              const Icon(Icons.fastfood_outlined, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Popcorn, drinks & discounts',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      details.isEmpty
                          ? 'Optional - add later if needed'
                          : details.join(' / '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_up,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConcessionSection extends StatelessWidget {
  const _ConcessionSection({
    required this.provider,
    required this.showtimeId,
  });

  final BookingProvider provider;
  final String showtimeId;

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
                  onAdd: () {
                    provider.incrementConcession(concession);
                    provider.quoteCurrentSelection(showtimeId);
                  },
                  onRemove: () {
                    provider.decrementConcession(concession);
                    provider.quoteCurrentSelection(showtimeId);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscountSection extends StatelessWidget {
  const _DiscountSection({
    required this.provider,
    required this.promotionController,
    required this.pointsController,
    required this.onApply,
  });

  final BookingProvider provider;
  final TextEditingController promotionController;
  final TextEditingController pointsController;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final availablePoints = provider.loyaltyWallet?.points ?? 0;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: promotionController,
                onChanged: provider.updatePromotionCode,
                decoration: const InputDecoration(
                  labelText: 'Promotion code',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 122,
              child: TextField(
                controller: pointsController,
                keyboardType: TextInputType.number,
                onChanged: provider.updateUsedPoints,
                decoration: InputDecoration(
                  labelText: 'Points',
                  helperText: '$availablePoints available',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: provider.selectedSeats.isEmpty ? null : onApply,
              icon: const Icon(Icons.check),
              tooltip: 'Apply discount',
            ),
          ],
        ),
        if (provider.errorMessage != null &&
            provider.state != BookingState.loading)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              provider.errorMessage!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
      ],
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

String _buildPriceBreakdown(BookingProvider provider) {
  final quote = provider.currentQuote;
  if (quote == null) {
    return 'Tickets + Combo calculated after seat selection';
  }

  return 'Subtotal ${_formatCurrency(quote.subtotal)}'
      ' - Promo ${_formatCurrency(quote.discountAmount)}'
      ' - Points ${_formatCurrency(quote.pointDiscountAmount)}';
}
