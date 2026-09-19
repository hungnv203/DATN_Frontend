import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../booking_flow/booking_flow_strings.dart';
import '../../providers/booking_provider.dart';
import 'booking_review_screen.dart';

class ConcessionSelectionScreen extends StatefulWidget {
  final String showtimeId;
  const ConcessionSelectionScreen({super.key, required this.showtimeId});
  @override
  State<ConcessionSelectionScreen> createState() =>
      _ConcessionSelectionScreenState();
}

class _ConcessionSelectionScreenState extends State<ConcessionSelectionScreen> {
  bool _releaseInProgress = false;
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<BookingProvider>().loadConcessionStage());
  }

  String _time(Duration value) =>
      '${value.inMinutes.toString().padLeft(2, '0')}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';

  Future<void> _returnToSeatSelection() async {
    if (_releaseInProgress) return;
    setState(() => _releaseInProgress = true);
    final released =
        await context.read<BookingProvider>().releaseHeldSelection();
    if (!mounted) return;
    if (released) {
      _allowAndPop();
      return;
    }
    setState(() => _releaseInProgress = false);
    final text = BookingFlowStrings.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text.releaseFailed)),
    );
  }

  void _allowAndPop() {
    if (!mounted || _allowPop) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = BookingFlowStrings.of(context);
    final provider = context.watch<BookingProvider>();
    if (provider.phase == BookingFlowPhase.selectingSeats &&
        ModalRoute.of(context)?.isCurrent == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _allowAndPop());
    }
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _returnToSeatSelection();
      },
      child: Scaffold(
          appBar: AppBar(
              leading: IconButton(
                  onPressed: _releaseInProgress ? null : _returnToSeatSelection,
                  icon: _releaseInProgress
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.arrow_back)),
              title: Text(text.concessions)),
          body: Column(children: [
            Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: AppColors.surface,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(text.holdTime),
                      Text(_time(provider.remainingHoldTime),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary))
                    ])),
            Expanded(
                child: provider.concessions.isEmpty
                    ? Center(child: Text(text.emptyConcessions))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: provider.concessions.length,
                        itemBuilder: (context, index) {
                          final item = provider.concessions[index];
                          final count = provider.getConcessionQuantity(item.id);
                          return Card(
                              child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(children: [
                                    if (item.imageUrl.isNotEmpty)
                                      Image.network(item.imageUrl,
                                          width: 72,
                                          height: 72,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const SizedBox(
                                                  width: 72,
                                                  height: 72,
                                                  child: Icon(Icons.fastfood)))
                                    else
                                      const SizedBox(
                                          width: 72,
                                          height: 72,
                                          child: Icon(Icons.fastfood)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                          Text(item.name,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          Text(item.description),
                                          Text(
                                              '${item.price.toStringAsFixed(0)} đ')
                                        ])),
                                    IconButton(
                                        constraints: const BoxConstraints(
                                            minWidth: 44, minHeight: 44),
                                        onPressed: count == 0
                                            ? null
                                            : () => provider
                                                .decrementConcession(item),
                                        icon: const Icon(
                                            Icons.remove_circle_outline)),
                                    Text('$count'),
                                    IconButton(
                                        constraints: const BoxConstraints(
                                            minWidth: 44, minHeight: 44),
                                        onPressed: () =>
                                            provider.incrementConcession(item),
                                        icon: const Icon(
                                            Icons.add_circle_outline)),
                                  ])));
                        })),
            SafeArea(
                top: false,
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                            onPressed: provider.hasActiveHold
                                ? () async {
                                    await provider.loadReviewStage();
                                    if (context.mounted) {
                                      await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  BookingReviewScreen(
                                                      showtimeId:
                                                          widget.showtimeId)));
                                      if (provider.hasActiveHold) {
                                        provider.enterConcessionStage();
                                      }
                                    }
                                  }
                                : null,
                            child: Text(text.continueLabel)))))
          ])),
    );
  }
}
