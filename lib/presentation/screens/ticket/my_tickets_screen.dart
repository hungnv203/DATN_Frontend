import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/ticket_provider.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TicketProvider>().fetchMyTickets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TicketProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Tickets')),
      body: provider.state == TicketState.loading
          ? const Center(child: SpinKitFadingCircle(color: AppColors.primary))
          : provider.state == TicketState.error
              ? Center(child: Text(provider.errorMessage ?? 'Error', style: const TextStyle(color: AppColors.error)))
              : provider.tickets.isEmpty
                  ? const Center(child: Text('No tickets found.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.tickets.length,
                      itemBuilder: (context, index) {
                        final ticket = provider.tickets[index];
                        final movieTitle = ticket.movieTitle ?? ticket.booking?.showtime?.room?.cinemaId ?? 'Movie Name';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          color: AppColors.surface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                const Icon(Icons.qr_code_2, size: 80, color: Colors.white),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(movieTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                      const SizedBox(height: 8),
                                      Text('Seat: ${ticket.seatLabel.isNotEmpty ? ticket.seatLabel : 'N/A'}', style: const TextStyle(color: AppColors.textSecondary)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Text('Ticket: ', style: TextStyle(color: AppColors.textSecondary)),
                                          Text(ticket.status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Text('Payment: ', style: TextStyle(color: AppColors.textSecondary)),
                                          Text(
                                            ticket.paymentStatus ?? 'Unknown',
                                            style: TextStyle(
                                              color: (ticket.paymentStatus == 'Paid') ? Colors.green : Colors.orange,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
