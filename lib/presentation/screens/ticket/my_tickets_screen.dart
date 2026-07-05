import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/ticket.dart';
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
              ? Center(
                  child: Text(provider.errorMessage ?? 'Error',
                      style: const TextStyle(color: AppColors.error)))
              : provider.tickets.isEmpty
                  ? const Center(child: Text('No tickets found.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.tickets.length,
                      itemBuilder: (context, index) {
                        final ticket = provider.tickets[index];
                        return _TicketCard(ticket: ticket);
                      },
                    ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final movieTitle =
        ticket.movieTitle.isNotEmpty ? ticket.movieTitle : 'Movie';
    final showtime = ticket.startTime != null
        ? DateFormat('HH:mm - dd/MM/yyyy').format(ticket.startTime!)
        : 'Updating';
    final price = NumberFormat.currency(locale: 'vi_VN', symbol: 'VND')
        .format(ticket.price);
    final paymentColor = _statusColor(ticket.paymentStatus);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _QrCodeBox(data: ticket.qrCodeData),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movieTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  if (ticket.cinemaName.isNotEmpty ||
                      ticket.roomName.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      [ticket.cinemaName, ticket.roomName]
                          .where((value) => value.isNotEmpty)
                          .join(' - '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 10),
                  _TicketInfoRow(icon: Icons.schedule, label: showtime),
                  const SizedBox(height: 6),
                  _TicketInfoRow(
                      icon: Icons.event_seat,
                      label: 'Seat: ${ticket.seatLabel}'),
                  const SizedBox(height: 6),
                  _TicketInfoRow(icon: Icons.payments, label: price),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: paymentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: paymentColor.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      'Payment: ${ticket.paymentStatus}',
                      style: TextStyle(
                        color: paymentColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return AppColors.success;
      case 'pending':
      case 'reserved':
        return AppColors.warning;
      case 'cancelled':
      case 'expired':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }
}

class _QrCodeBox extends StatelessWidget {
  const _QrCodeBox({required this.data});

  final String data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: data.isEmpty
          ? const Icon(Icons.qr_code_2, color: AppColors.surface, size: 56)
          : QrImageView(
              data: data,
              version: QrVersions.auto,
              backgroundColor: Colors.white,
            ),
    );
  }
}

class _TicketInfoRow extends StatelessWidget {
  const _TicketInfoRow({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
