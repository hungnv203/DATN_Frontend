import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../domain/entities/assistant_response.dart';
import '../../providers/assistant_provider.dart';
import '../cinema/cinema_selection_screen.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AssistantProvider>().checkAvailability();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? choice]) async {
    final message = choice ?? _controller.text;
    if (message.trim().isEmpty) return;
    _controller.clear();
    await context.read<AssistantProvider>().send(
      message,
      Localizations.localeOf(context).toLanguageTag(),
    );
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssistantProvider>();
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Trợ lý phim AI'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildContent(provider)),
            if (provider.isAvailable) _AssistantInput(
              controller: _controller,
              enabled: !provider.isSending,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AssistantProvider provider) {
    if (provider.state == AssistantState.checking) {
      return Center(
        child: Semantics(
          label: 'Đang kiểm tra trợ lý',
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (provider.state == AssistantState.unavailable && provider.messages.isEmpty) {
      return _StatusPanel(
        icon: Icons.smart_toy_outlined,
        message: 'Trợ lý phim hiện chưa khả dụng.',
        actionLabel: 'Thử lại',
        onAction: provider.checkAvailability,
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: provider.messages.length + (provider.isSending ? 1 : 0) +
          (provider.state == AssistantState.error ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < provider.messages.length) {
          return _MessageBubble(
            message: provider.messages[index],
            onChoice: _send,
          );
        }
        if (provider.isSending) {
          return Semantics(
            liveRegion: true,
            label: 'Trợ lý đang trả lời',
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }
        return _StatusPanel(
          icon: Icons.error_outline,
          message: provider.errorMessage ?? '',
          actionLabel: 'Thử lại',
          onAction: () => provider.retry(
            Localizations.localeOf(context).toLanguageTag(),
          ),
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.onChoice});

  final AssistantChatMessage message;
  final ValueChanged<String> onChoice;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Card(
          color: isUser
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(message.content),
                for (final movie in message.response?.movies ?? const <AssistantMovieCard>[])
                  _MovieResultCard(movie: movie),
                if (message.response?.clarificationChoices.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: message.response!.clarificationChoices
                          .map((choice) => ActionChip(
                                label: Text(choice),
                                onPressed: () => onChoice(choice),
                              ))
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MovieResultCard extends StatelessWidget {
  const _MovieResultCard({required this.movie});

  final AssistantMovieCard movie;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${movie.title}, ${movie.duration} phút, ${movie.rating}',
      button: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CinemaSelectionScreen(movieId: movie.id),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 72,
                      height: 104,
                      child: movie.posterUrl.isEmpty
                          ? const ColoredBox(
                              color: Colors.black26,
                              child: Icon(Icons.movie_outlined),
                            )
                          : Image.network(
                              movie.posterUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(movie.title, style: Theme.of(context).textTheme.titleMedium),
                            ),
                            const Icon(Icons.chevron_right, size: 18),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('${movie.duration} phút • ${movie.rating}'),
                        if (movie.genres.isNotEmpty) Text(movie.genres.join(' • ')),
                        if (movie.reason.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(movie.reason, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (movie.upcomingShowtimes.isNotEmpty) ...[
                const SizedBox(height: 8),
                _ShowtimeChips(showtimes: movie.upcomingShowtimes),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ShowtimeChips extends StatelessWidget {
  const _ShowtimeChips({required this.showtimes});

  final List<AssistantShowtimeSummary> showtimes;

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('HH:mm');
    final dateFmt = DateFormat('dd/MM');
    final priceFmt = NumberFormat.compact(locale: 'vi');
    // Group by cinema
    final Map<String, List<AssistantShowtimeSummary>> byCinema = {};
    for (final s in showtimes) {
      byCinema.putIfAbsent(s.cinemaName, () => []).add(s);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: byCinema.entries.map((entry) {
        final cinemaName = entry.key;
        final times = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cinemaName,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: times.map((s) {
                  final label = '${dateFmt.format(s.startTime.toLocal())} ${timeFmt.format(s.startTime.toLocal())} • ${priceFmt.format(s.basePrice)}đ';
                  return Chip(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    labelPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    label: Text(label, style: Theme.of(context).textTheme.labelSmall),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}


class _AssistantInput extends StatelessWidget {
  const _AssistantInput({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.viewInsetsOf(context).bottom + 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Semantics(
              textField: true,
              label: 'Nhắn cho trợ lý phim',
              child: TextField(
                controller: controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 4,
                maxLength: 1000,
                textInputAction: TextInputAction.send,
                onSubmitted: enabled ? (_) => onSend() : null,
                decoration: const InputDecoration(
                  hintText: 'Hỏi về phim, thể loại, hoặc gợi ý hôm nay...',
                  counterText: '',
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            button: true,
            label: 'Gửi tin nhắn',
            child: IconButton.filled(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: enabled ? onSend : null,
              icon: const Icon(Icons.send_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        liveRegion: true,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ),
        ),
      ),
    );
  }
}
