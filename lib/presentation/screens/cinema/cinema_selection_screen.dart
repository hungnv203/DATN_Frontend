import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/cinema_provider.dart';
import '../../providers/movie_provider.dart';
import '../seat/seat_selection_screen.dart';

class CinemaSelectionScreen extends StatefulWidget {
  final String movieId;

  const CinemaSelectionScreen({super.key, required this.movieId});

  @override
  State<CinemaSelectionScreen> createState() => _CinemaSelectionScreenState();
}

class _CinemaSelectionScreenState extends State<CinemaSelectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CinemaProvider>();
      context.read<MovieProvider>().fetchMovieDetails(widget.movieId);
      provider.fetchCinemas().then((_) {
        provider.fetchShowtimes(widget.movieId);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CinemaProvider>();
    final movieProvider = context.watch<MovieProvider>();
    final movie = movieProvider.selectedMovie;
    final dates = List.generate(7, (index) => DateTime.now().add(Duration(days: index)));

    return Scaffold(
      appBar: AppBar(
        title: Text(movie?.title ?? 'Chọn suất chiếu'),
      ),
      body: provider.state == CinemaState.loading && provider.cinemas.isEmpty
          ? const Center(child: SpinKitFadingCircle(color: AppColors.primary))
          : provider.state == CinemaState.error && provider.cinemas.isEmpty
              ? Center(child: Text(provider.errorMessage ?? 'Không thể tải lịch chiếu. Vui lòng thử lại.', style: const TextStyle(color: AppColors.error)))
              : Column(
                  children: [
                    // Date Selector
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: dates.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemBuilder: (context, index) {
                          final date = dates[index];
                          final isSelected = provider.selectedDate.day == date.day && 
                                             provider.selectedDate.month == date.month;
                          return GestureDetector(
                            onTap: () => provider.selectDate(date, widget.movieId),
                            child: Container(
                              width: 60,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Th${date.month}',
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${date.day}',
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : AppColors.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(height: 1, color: Colors.grey),
                    // Cinemas & Showtimes List
                    Expanded(
                      child: provider.state == CinemaState.loading
                          ? const Center(child: SpinKitFadingCircle(color: AppColors.primary))
                          : ListView.builder(
                              itemCount: provider.cinemas.length,
                              itemBuilder: (context, index) {
                                final cinema = provider.cinemas[index];
                                // Filter showtimes for this cinema implicitly by checking rooms.
                                // In a real app, API might return nested, but here we filter by matching Room's cinemaId.
                                final cinemaShowtimes = provider.showtimes.where((st) {
                                  return st.room?.cinemaId == cinema.id &&
                                         st.startTime.year == provider.selectedDate.year &&
                                         st.startTime.month == provider.selectedDate.month &&
                                         st.startTime.day == provider.selectedDate.day;
                                }).toList();

                                return ExpansionTile(
                                  initiallyExpanded: provider.selectedCinema?.id == cinema.id,
                                  onExpansionChanged: (expanded) {
                                    if (expanded) {
                                      provider.selectCinema(
                                        cinema,
                                        widget.movieId,
                                      );
                                    }
                                  },
                                  title: Text(cinema.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(cinema.address, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  children: [
                                    if (cinemaShowtimes.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Text('Không có suất chiếu nào trong ngày đã chọn.'),
                                      )
                                    else
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Wrap(
                                          spacing: 12,
                                          runSpacing: 12,
                                          children: cinemaShowtimes.map((st) {
                                            return InkWell(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        SeatSelectionScreen(
                                                      showtimeId: st.id,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: AppColors.primary),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  DateFormat('HH:mm').format(st.startTime),
                                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
