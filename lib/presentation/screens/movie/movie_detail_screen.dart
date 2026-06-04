import 'package:flutter/material.dart';
import '../../../domain/entities/movie.dart';
import '../../../core/theme/app_colors.dart';
import '../cinema/cinema_selection_screen.dart';

class MovieDetailScreen extends StatelessWidget {
  final Movie movie;

  const MovieDetailScreen({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
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
            // Poster
            SizedBox(
              height: 400,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  movie.posterUrl.isNotEmpty 
                      ? Image.network(movie.posterUrl, fit: BoxFit.cover)
                      : Container(color: Colors.grey.shade800, child: const Icon(Icons.movie, size: 100)),
                  Container(
                    decoration: BoxDecoration(
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
            // Details
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildTag(movie.rating, Colors.orange),
                      const SizedBox(width: 8),
                      _buildTag('${movie.duration} min', Colors.blueGrey),
                      const SizedBox(width: 8),
                      _buildTag(movie.language, Colors.deepPurple),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Synopsis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    movie.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
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
                MaterialPageRoute(builder: (_) => CinemaSelectionScreen(movie: movie))
              );
            },
            child: const Text('Book Ticket', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
