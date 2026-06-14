import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../core/theme/app_colors.dart';
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
      context.read<BookingProvider>().fetchSeats(widget.showtime.id);
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
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.primary, width: 4),
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.elliptical(200, 40)),
                  ),
                  alignment: Alignment.center,
                  child: const Text('SCREEN', style: TextStyle(color: AppColors.textSecondary, letterSpacing: 4)),
                ),
                const SizedBox(height: 40),
                
                // Seats Grid
                Expanded(
                  child: provider.seats.isEmpty
                      ? const Center(child: Text('No seats available'))
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 8,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: provider.seats.length,
                          itemBuilder: (context, index) {
                            final seat = provider.seats[index];
                            final isSelected = provider.selectedSeats.contains(seat);
                            
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
                                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                
                // Bottom Bar
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Price', style: TextStyle(color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              Text(
                                '\$${provider.getTotalPrice(widget.showtime.basePrice).toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: provider.selectedSeats.isEmpty
                                ? null
                                : () async {
                                    final success = await provider.bookTickets(widget.showtime.id);
                                    if (success && mounted) {
                                      // Navigate to Checkout / Success
                                      final successPay = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PaymentScreen(booking: provider.currentBooking!),
                                        ),
                                      );

                                      if (successPay == true) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Booking Successful!')),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Payment Cancelled/Failed')),
                                        );
                                      }
                                      Navigator.popUntil(context, (route) => route.isFirst);
                                    } else if (!success && mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(provider.errorMessage ?? 'Failed to book tickets. Please try again.')),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              minimumSize: const Size(0, 50),
                            ),
                            child: provider.state == BookingState.loading
                                ? const SpinKitThreeBounce(color: Colors.white, size: 20)
                                : const Text('Continue'),
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
