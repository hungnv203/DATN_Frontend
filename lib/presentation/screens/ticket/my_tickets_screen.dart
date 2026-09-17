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

class _MyTicketsScreenState extends State<MyTicketsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final provider = context.read<TicketProvider>();
        if (_tabController.index == 0) {
          provider.fetchMySuccessfulTickets();
        } else {
          provider.fetchMyTickets(onlySuccess: false);
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TicketProvider>().fetchMySuccessfulTickets();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TicketProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vé của tôi'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Vé hợp lệ'),
            Tab(text: 'Tất cả vé'),
          ],
        ),
      ),
      body: provider.state == TicketState.loading
          ? const Center(child: SpinKitFadingCircle(color: AppColors.primary))
          : provider.state == TicketState.error
              ? Center(
                  child: Text(provider.errorMessage ?? 'Không thể tải danh sách vé. Vui lòng thử lại.',
                      style: const TextStyle(color: AppColors.error)))
              : provider.tickets.isEmpty
                  ? Center(
                      child: Text(
                        _tabController.index == 0
                            ? 'Không có vé hợp lệ nào.'
                            : 'Không tìm thấy vé nào.',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        if (_tabController.index == 0) {
                          await context
                              .read<TicketProvider>()
                              .fetchMySuccessfulTickets();
                        } else {
                          await context
                              .read<TicketProvider>()
                              .fetchMyTickets(onlySuccess: false);
                        }
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.tickets.length,
                        itemBuilder: (context, index) {
                          final ticket = provider.tickets[index];
                          return _TicketCard(ticket: ticket);
                        },
                      ),
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
        ticket.movieTitle.isNotEmpty ? ticket.movieTitle : 'Phim';
    final showtime = ticket.startTime != null
        ? DateFormat('HH:mm - dd/MM/yyyy').format(ticket.startTime!)
        : 'Đang cập nhật';
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
                      label: 'Ghế: ${ticket.seatLabel}'),
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
                      'Thanh toán: ${_formatPaymentStatus(ticket.paymentStatus)}',
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

  String _formatPaymentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'Đã thanh toán';
      case 'pending':
      case 'reserved':
        return 'Chờ thanh toán';
      case 'cancelled':
        return 'Đã hủy';
      case 'expired':
        return 'Đã hết hạn';
      case 'failed':
        return 'Thất bại';
      default:
        return status;
    }
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
