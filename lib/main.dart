import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/network/dio_client.dart';

import 'data/datasources/auth_remote_data_source.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/usecases/login_usecase.dart';
import 'domain/usecases/register_usecase.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/auth/login_screen.dart';

import 'data/datasources/movie_remote_data_source.dart';
import 'data/repositories/movie_repository_impl.dart';
import 'domain/usecases/movie_usecases.dart';
import 'presentation/providers/movie_provider.dart';

import 'data/datasources/cinema_remote_data_source.dart';
import 'data/repositories/cinema_repository_impl.dart';
import 'domain/usecases/cinema_usecases.dart';
import 'presentation/providers/cinema_provider.dart';

import 'data/datasources/booking_remote_data_source.dart';
import 'data/repositories/booking_repository_impl.dart';
import 'domain/usecases/booking_usecases.dart';
import 'presentation/providers/booking_provider.dart';

import 'data/datasources/ticket_remote_data_source.dart';
import 'data/repositories/ticket_repository_impl.dart';
import 'domain/usecases/ticket_usecases.dart';
import 'presentation/providers/ticket_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  final dioClient = DioClient(prefs);

  // Auth Dependencies
  final authRemoteDataSource = AuthRemoteDataSourceImpl(dioClient);
  final authRepository = AuthRepositoryImpl(
    remoteDataSource: authRemoteDataSource,
    prefs: prefs,
  );
  final loginUseCase = LoginUseCase(authRepository);
  final registerUseCase = RegisterUseCase(authRepository);

  // Movie Dependencies
  final movieRemoteDataSource = MovieRemoteDataSourceImpl(dioClient);
  final movieRepository = MovieRepositoryImpl(movieRemoteDataSource);
  final getNowPlayingUseCase = GetNowPlayingMoviesUseCase(movieRepository);
  final getUpcomingUseCase = GetUpcomingMoviesUseCase(movieRepository);

  // Cinema Dependencies
  final cinemaRemoteDataSource = CinemaRemoteDataSourceImpl(dioClient);
  final cinemaRepository = CinemaRepositoryImpl(cinemaRemoteDataSource);
  final getCinemasUseCase = GetCinemasUseCase(cinemaRepository);
  final getShowtimesUseCase = GetShowtimesUseCase(cinemaRepository);

  // Booking Dependencies
  final bookingRemoteDataSource = BookingRemoteDataSourceImpl(dioClient);
  final bookingRepository = BookingRepositoryImpl(bookingRemoteDataSource);
  final getSeatsUseCase = GetSeatsUseCase(bookingRepository);
  final createBookingUseCase = CreateBookingUseCase(bookingRepository);

  // Ticket Dependencies
  final ticketRemoteDataSource = TicketRemoteDataSourceImpl(dioClient);
  final ticketRepository = TicketRepositoryImpl(ticketRemoteDataSource);
  final getMyTicketsUseCase = GetMyTicketsUseCase(ticketRepository);

  runApp(
    MultiProvider(
      providers: [
        Provider<SharedPreferences>.value(value: prefs),
        Provider<DioClient>.value(value: dioClient),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(loginUseCase, registerUseCase),
        ),
        ChangeNotifierProvider(
          create: (_) => MovieProvider(getNowPlayingUseCase, getUpcomingUseCase),
        ),
        ChangeNotifierProvider(
          create: (_) => CinemaProvider(getCinemasUseCase, getShowtimesUseCase),
        ),
        ChangeNotifierProvider(
          create: (_) => BookingProvider(getSeatsUseCase, createBookingUseCase),
        ),
        ChangeNotifierProvider(
          create: (_) => TicketProvider(getMyTicketsUseCase),
        ),
      ],
      child: const MovieBookingApp(),
    ),
  );
}

class MovieBookingApp extends StatelessWidget {
  const MovieBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movie Booking App',
      theme: AppTheme.darkTheme,
      home: const LoginScreen(),
    );
  }
}
