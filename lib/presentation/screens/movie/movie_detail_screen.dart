import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_notification.dart';
import '../../../domain/entities/movie.dart';
import '../../providers/review_provider.dart';
import '../cinema/cinema_selection_screen.dart';

class MovieDetailScreen extends StatefulWidget {
  final Movie movie;

  const MovieDetailScreen({super.key, required this.movie});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReviewProvider>().loadMovieReviews(widget.movie.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reviewProvider = context.watch<ReviewProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 400,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  widget.movie.posterUrl.isNotEmpty
                      ? Image.network(widget.movie.posterUrl, fit: BoxFit.cover)
                      : Container(
                          color: Colors.grey.shade800,
                          child: const Icon(Icons.movie, size: 100),
                        ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.background,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.movie.title,
                    style: Theme.of(context)
                        .textTheme
                        .displayLarge
                        ?.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildTag(widget.movie.rating, Colors.orange),
                      const SizedBox(width: 8),
                      _buildTag('${widget.movie.duration} min', Colors.blueGrey),
                      const SizedBox(width: 8),
                      _buildTag(widget.movie.language, Colors.deepPurple),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Synopsis',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.movie.description,
                    style:
                        Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 28),
                  _ReviewSection(
                    movie: widget.movie,
                    provider: reviewProvider,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CinemaSelectionScreen(movie: widget.movie),
                ),
              );
            },
            child: const Text(
              'Book Ticket',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({
    required this.movie,
    required this.provider,
  });

  final Movie movie;
  final ReviewProvider provider;

  @override
  Widget build(BuildContext context) {
    final summary = provider.summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Audience reviews',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _showReviewDialog(context),
              icon: const Icon(Icons.rate_review),
              label: const Text('Review'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber),
            const SizedBox(width: 6),
            Text(
              summary == null || summary.totalReviews == 0
                  ? 'No ratings yet'
                  : '${summary.averageRating.toStringAsFixed(1)} / 5 (${summary.totalReviews})',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (provider.state == ReviewState.loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (provider.reviews.isEmpty)
          const Text(
            'Be the first audience member to review this movie.',
            style: TextStyle(color: AppColors.textSecondary),
          )
        else
          ...provider.reviews.take(5).map((review) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          review.userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      Text('${review.rating}'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(review.comment),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('dd/MM/yyyy').format(review.createdAt),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Future<void> _showReviewDialog(BuildContext pageContext) async {
    int selectedRating = 5;
    bool isSubmitting = false;
    final controller = TextEditingController();

    await showDialog<void>(
      context: pageContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              scrollable: true,
              title: const Text('Rate this movie'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    label: 'Movie rating: $selectedRating out of 5 stars',
                    child: Row(
                      children: List.generate(5, (index) {
                        final rating = index + 1;
                        return Expanded(
                          child: IconButton(
                            tooltip: '$rating star${rating == 1 ? '' : 's'}',
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 48,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            onPressed: isSubmitting
                                ? null
                                : () {
                                    setDialogState(() {
                                      selectedRating = rating;
                                    });
                                  },
                            icon: Icon(
                              rating <= selectedRating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: Colors.amber,
                              size: 32,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    enabled: !isSubmitting,
                    minLines: 3,
                    maxLines: 3,
                    maxLength: 500,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Comment',
                      hintText: 'Share what you thought about the movie',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.end,
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                    setDialogState(() {
                      isSubmitting = true;
                    });
                    final ok = await provider.submitReview(
                      movie.id,
                      selectedRating,
                      controller.text.trim(),
                    );
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                    if (!pageContext.mounted) return;
                    if (ok) {
                      AppNotification.showSuccess(
                        pageContext,
                        'Review submitted.',
                      );
                    } else {
                      AppNotification.showError(
                        pageContext,
                        provider.errorMessage ?? 'Could not submit review.',
                      );
                    }
                  },
                  child: isSubmitting
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();
  }
}
