import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/movie.dart';
import '../../../domain/entities/movie_discovery.dart';
import '../../providers/movie_provider.dart';
import '../movie/movie_detail_screen.dart';
import '../profile/profile_screen.dart';

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
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.select<MovieProvider, MovieState>((value) => value.state);

    return Scaffold(
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
            subtitle: 'Được yêu thích dựa trên lượt xem và đánh giá',
            movies: discovery.featured,
          ),
        if (discovery != null && discovery.trending.isNotEmpty)
          _MovieSection(
            title: '🔥 Đang hot',
            subtitle: 'Có lượt đặt vé cao nhất trong 7 ngày qua',
            movies: discovery.trending,
          ),
        if (discovery != null && discovery.topRated.isNotEmpty)
          _MovieSection(
            title: '⭐ Đánh giá cao',
            subtitle: 'Nhận điểm trung bình cao nhất từ khán giả',
            movies: discovery.topRated,
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
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ],
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
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: movie))),
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
