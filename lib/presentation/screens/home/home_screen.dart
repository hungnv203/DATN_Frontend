import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/movie.dart';
import '../../../domain/entities/movie_discovery.dart';
import '../../../domain/entities/genre.dart';
import '../../providers/movie_provider.dart';
import '../movie/movie_detail_screen.dart';
import '../profile/profile_screen.dart';
import '../assistant/assistant_screen.dart';
import '../../providers/assistant_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MovieProvider>().fetchMovies();
      context.read<AssistantProvider>().checkAvailability();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.select<MovieProvider, MovieState>((value) => value.state);

    return Scaffold(
      floatingActionButton: context.select<AssistantProvider, AssistantState>(
        (value) => value.state,
      ) == AssistantState.ready
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AssistantScreen()),
              ),
              icon: const Icon(Icons.smart_toy_outlined),
              label: const Text('Trợ lý AI'),
            )
          : null,
      body: SafeArea(
        child: switch (state) {
          MovieState.loading => const Center(child: SpinKitFadingCircle(color: AppColors.primary)),
          MovieState.error => _ErrorState(
              message: context.read<MovieProvider>().errorMessage ?? 'Không thể tải danh sách phim.',
              onRetry: context.read<MovieProvider>().fetchMovies,
            ),
          _ => const _MovieDiscoverView(),
        },
      ),
    );
  }
}

class _MovieDiscoverView extends StatelessWidget {
  const _MovieDiscoverView();

  @override
  Widget build(BuildContext context) {
    final nowPlaying = context.select<MovieProvider, List<Movie>>((value) => value.nowPlayingMovies);
    final upcoming = context.select<MovieProvider, List<Movie>>((value) => value.upcomingMovies);
    final discovery = context.select<MovieProvider, MovieDiscovery?>((value) => value.discovery);
    final selectedGenreId = context.select<MovieProvider, String?>((value) => value.selectedGenreId);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MOVIE BOOKING', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800, letterSpacing: 1.4)),
                      const SizedBox(height: 4),
                      Text('Chọn câu chuyện tối nay', style: Theme.of(context).textTheme.headlineSmall),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Hồ sơ cá nhân',
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                  icon: const Icon(Icons.person_outline_rounded),
                ),
              ],
            ),
          ),
        ),
        if (discovery != null && discovery.featured.isNotEmpty)
          _MovieSection(
            title: '🎬 Phim nổi bật',
            subtitle: 'Được yêu thích dựa trên lượt xem và vé bán',
            movies: discovery.featured,
          ),
        const SliverToBoxAdapter(
          child: _GenreFilterBar(),
        ),
        if (selectedGenreId != null) ...[
          _MovieSection(
            title: '🎯 Phim đang chiếu',
            subtitle: 'Phim thuộc thể loại đã chọn',
            movies: nowPlaying,
          ),
          _MovieSection(
            title: '⏳ Phim sắp chiếu',
            subtitle: 'Phim sắp khởi chiếu thuộc thể loại này',
            movies: upcoming,
          ),
        ] else ...[
          if (discovery != null && discovery.trending.isNotEmpty)
            _MovieSection(
              title: '🔥 Đang hot',
              subtitle: 'Có lượt đặt vé cao nhất trong 7 ngày qua',
              movies: discovery.trending,
            ),
          if (discovery != null && discovery.bestSelling.isNotEmpty)
            _MovieSection(
              title: '💰 Bán chạy',
              subtitle: 'Những bộ phim bán được nhiều vé nhất',
              movies: discovery.bestSelling,
            ),
          if (discovery != null && discovery.newReleases.isNotEmpty)
            _MovieSection(
              title: '🆕 Phim mới',
              subtitle: 'Khởi chiếu trong 14 ngày gần đây',
              movies: discovery.newReleases,
            ),
          _MovieSection(
            title: '🎟️ Đang chiếu',
            subtitle: 'Các bộ phim hiện có lịch chiếu tại rạp',
            movies: nowPlaying,
          ),
          _MovieSection(
            title: '⏳ Sắp chiếu',
            subtitle: 'Lên lịch cho buổi xem tiếp theo',
            movies: discovery?.upcoming ?? upcoming,
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ],
    );
  }
}

class _GenreFilterBar extends StatelessWidget {
  const _GenreFilterBar();

  @override
  Widget build(BuildContext context) {
    final genres = context.select<MovieProvider, List<Genre>>((value) => value.genres);
    final selectedId = context.select<MovieProvider, String?>((value) => value.selectedGenreId);

    if (genres.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.category_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Thể loại phim',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
              ),
              if (selectedId != null) ...[
                const Spacer(),
                GestureDetector(
                  onTap: () => context.read<MovieProvider>().filterByGenre(null),
                  child: const Text(
                    'Đặt lại',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _GenreChip(
                  label: 'Tất cả',
                  isSelected: selectedId == null,
                  onTap: () => context.read<MovieProvider>().filterByGenre(null),
                ),
                ...genres.map((g) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _GenreChip(
                        label: g.name,
                        isSelected: selectedId == g.id,
                        onTap: () => context.read<MovieProvider>().filterByGenre(g.id),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  const _GenreChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      backgroundColor: AppColors.surfaceHigh,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : AppColors.textSecondary,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.transparent,
        ),
      ),
    );
  }
}

class _MovieSection extends StatelessWidget {
  const _MovieSection({required this.title, required this.subtitle, required this.movies});

  final String title;
  final String subtitle;
  final List<Movie> movies;

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ),
        if (movies.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Card(child: Padding(padding: EdgeInsets.all(24), child: Text('Chưa có phim trong danh mục này.'))),
            ),
          )
        else
          SliverToBoxAdapter(
            child: SizedBox(
              height: 304,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: movies.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) => _MovieCard(movie: movies[index]),
              ),
            ),
          ),
      ],
    );
  }
}

class _MovieCard extends StatelessWidget {
  const _MovieCard({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 174,
      child: Semantics(
        button: true,
        label: 'Xem chi tiết phim ${movie.title}',
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MovieDetailScreen(movieId: movie.id),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SizedBox.expand(
                    child: movie.posterUrl.isEmpty
                        ? const ColoredBox(color: AppColors.surfaceHigh, child: Icon(Icons.movie_outlined, size: 44))
                        : Image.network(
                            movie.posterUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const ColoredBox(color: AppColors.surfaceHigh, child: Icon(Icons.broken_image_outlined, size: 40)),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(movie.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded, size: 15, color: AppColors.textSecondary),
                          const SizedBox(width: 5),
                          Text('${movie.duration} phút', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                          if (movie.genres.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  movie.genres.first,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 52, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text('Chưa thể tải phim', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Thử lại')),
            ],
          ),
        ),
      ),
    );
  }
}
