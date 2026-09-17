import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_notification.dart';
import '../../booking_flow/booking_flow_strings.dart';
import '../../providers/booking_provider.dart';
import '../../providers/cinema_provider.dart';
import '../booking/concession_selection_screen.dart';
import '../home/home_screen.dart';

class SeatSelectionScreen extends StatefulWidget {
  final String showtimeId;
  const SeatSelectionScreen({super.key, required this.showtimeId});
  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen>
    with WidgetsBindingObserver {
  bool _allowPop = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<CinemaProvider>().fetchShowtimeById(widget.showtimeId);
      if (mounted) {
        await context.read<BookingProvider>().startFlow(widget.showtimeId);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<BookingProvider>().handleAppResumed();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _abandon() async {
    final provider = context.read<BookingProvider>();
    if (provider.commandInProgress) return;
    final text = BookingFlowStrings.of(context);
    final leave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(text.leaveTitle),
              content: Text(text.leaveBody),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(text.stay)),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(text.leave))
              ],
            ));
    if (leave != true || !mounted) return;
    var released = await provider.releaseFlow();
    while (!released && mounted) {
      if (!mounted) return;
      final action = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                content: Text(text.releaseFailed),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(text.retry)),
                  TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(text.leaveWithTtl))
                ],
              ));
      if (!mounted) return;
      if (action == true) {
        await provider.leaveWithTtl();
        if (mounted) {
          setState(() => _allowPop = true);
          Navigator.pop(context);
        }
        return;
      }
      released = await provider.releaseFlow();
    }
    if (released && mounted) {
      setState(() => _allowPop = true);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = BookingFlowStrings.of(context);
    final provider = context.watch<BookingProvider>();

    if ((provider.phase == BookingFlowPhase.paymentCompleted ||
            provider.currentBooking?.status == 'Paid') &&
        ModalRoute.of(context)?.isCurrent == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
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
      });
    }

    final rows = <String, List<dynamic>>{};
    for (final seat in provider.seats) {
      rows.putIfAbsent(seat.row, () => []).add(seat);
    }
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _abandon();
      },
      child: Scaffold(
        appBar: AppBar(
            title: Text(text.selectSeats),
            leading: IconButton(
                onPressed: _abandon, icon: const Icon(Icons.arrow_back))),
        body: provider.phase == BookingFlowPhase.initializing
            ? Center(
                child: Semantics(
                    label: text.loading,
                    child: const CircularProgressIndicator()))
            : Column(children: [
                const SizedBox(height: 16),
                Container(
                    width: 240,
                    padding: const EdgeInsets.only(top: 8),
                    decoration: const BoxDecoration(
                        border: Border(
                            top: BorderSide(
                                color: AppColors.primary, width: 4))),
                    child: Text(text.screen, textAlign: TextAlign.center)),
                if (provider.errorMessage != null)
                  Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(text.error(provider.errorMessage!),
                          style: const TextStyle(color: Colors.redAccent))),
                Expanded(
                    child: provider.seats.isEmpty
                        ? Center(child: Text(text.noSeats))
                        : SingleChildScrollView(
                            child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                    children: rows.entries.map((entry) {
                                  entry.value.sort(
                                      (a, b) => a.number.compareTo(b.number));
                                  return Row(
                                      children: entry.value.map((seat) {
                                    final selected = provider.selectedSeats
                                        .any((item) => item.id == seat.id);
                                    final stateLabel = seat.status == 'Booked'
                                        ? text.stateBooked
                                        : seat.status == 'Held' &&
                                                !seat.heldByCurrentUser
                                            ? text.stateHeld
                                            : text.stateAvailable(selected);
                                    final color = selected
                                        ? AppColors.seatSelected
                                        : seat.status == 'Available' ||
                                                seat.heldByCurrentUser
                                            ? AppColors.seatAvailable
                                            : AppColors.seatBooked;
                                    return Semantics(
                                        button: true,
                                        selected: selected,
                                        enabled: seat.status == 'Available' ||
                                            seat.heldByCurrentUser,
                                        label: text.seatSemantic(
                                            seat.label, seat.type, stateLabel),
                                        child: Padding(
                                            padding: const EdgeInsets.all(3),
                                            child: InkWell(
                                                onTap: () => provider
                                                    .toggleSeatSelection(seat),
                                                child: Container(
                                                    width: 44,
                                                    height: 44,
                                                    alignment: Alignment.center,
                                                    decoration: BoxDecoration(
                                                        color: color,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                        border: selected
                                                            ? Border.all(
                                                                color: Colors
                                                                    .white,
                                                                width: 2)
                                                            : null),
                                                    child: Stack(
                                                        alignment:
                                                            Alignment.center,
                                                        children: [
                                                          Text(seat.label,
                                                              style: const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize:
                                                                      11)),
                                                          if (seat.status ==
                                                                  'Held' &&
                                                              !seat
                                                                  .heldByCurrentUser)
                                                            const Positioned(
                                                                right: 2,
                                                                bottom: 2,
                                                                child: Icon(
                                                                    Icons.lock,
                                                                    size: 11,
                                                                    color: Colors
                                                                        .white)),
                                                          if (seat.status ==
                                                              'Booked')
                                                            const Positioned(
                                                                right: 2,
                                                                bottom: 2,
                                                                child: Icon(
                                                                    Icons
                                                                        .check_circle,
                                                                    size: 11,
                                                                    color: Colors
                                                                        .white)),
                                                        ])))));
                                  }).toList());
                                }).toList())))),
                SafeArea(
                    top: false,
                    child: Container(
                        padding: const EdgeInsets.all(16),
                        color: AppColors.surface,
                        child: Column(children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(text.selectedCount),
                                Text('${provider.selectedSeats.length}')
                              ]),
                          Align(
                              alignment: Alignment.centerLeft,
                              child: Text(text.priceAtReview,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary))),
                          Wrap(spacing: 12, children: [
                            Text(text.heldLegend),
                            Text(text.bookedLegend),
                          ]),
                          const SizedBox(height: 10),
                          if (provider.holdSession != null &&
                              provider.selectedSeats.isEmpty)
                            SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: OutlinedButton(
                                    onPressed: provider.commandInProgress
                                        ? null
                                        : provider.releaseHeldSelection,
                                    child: Text(text.releaseSeats))),
                          SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: FilledButton(
                                  onPressed: provider.selectedSeats.isEmpty ||
                                          provider.commandInProgress
                                      ? null
                                      : () async {
                                          final ok =
                                              await provider.confirmSeats();
                                          if (!context.mounted || !ok) return;
                                          await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      ConcessionSelectionScreen(
                                                          showtimeId: widget
                                                              .showtimeId)));
                                          if (context.mounted) {
                                            provider.enterSeatStage();
                                          }
                                        },
                                  child: Text(text.confirmSeats))),
                        ]))),
              ]),
      ),
    );
  }
}
