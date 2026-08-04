import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/network/dio_client.dart';

import 'data/datasources/auth_remote_data_source.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/usecases/login_usecase.dart';
import 'domain/usecases/logout_usecase.dart';
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
import 'data/repositories/seat_realtime_repository_impl.dart';

import 'data/datasources/ticket_remote_data_source.dart';
import 'data/repositories/ticket_repository_impl.dart';
import 'domain/usecases/ticket_usecases.dart';
import 'presentation/providers/ticket_provider.dart';

import 'data/datasources/review_remote_data_source.dart';
import 'data/repositories/review_repository_impl.dart';
import 'domain/usecases/review_usecases.dart';
import 'presentation/providers/review_provider.dart';

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
  final logoutUsecase = LogoutUsecase(authRepository);

  // Movie Dependencies
  final movieRemoteDataSource = MovieRemoteDataSourceImpl(dioClient);
  final movieRepository = MovieRepositoryImpl(movieRemoteDataSource);
  final getNowPlayingUseCase = GetNowPlayingMoviesUseCase(movieRepository);
  final getUpcomingUseCase = GetUpcomingMoviesUseCase(movieRepository);
  final getMovieDiscoveryUseCase = GetMovieDiscoveryUseCase(movieRepository);
  final getMovieDetailsUseCase = GetMovieDetailsUseCase(movieRepository);

  // Cinema Dependencies
  final cinemaRemoteDataSource = CinemaRemoteDataSourceImpl(dioClient);
  final cinemaRepository = CinemaRepositoryImpl(cinemaRemoteDataSource);
  final getCinemasUseCase = GetCinemasUseCase(cinemaRepository);
  final getShowtimesUseCase = GetShowtimesUseCase(cinemaRepository);
  final getShowtimeByIdUseCase = GetShowtimeByIdUseCase(cinemaRepository);

  // Booking Dependencies
  final bookingRemoteDataSource = BookingRemoteDataSourceImpl(dioClient);
  final bookingRepository = BookingRepositoryImpl(bookingRemoteDataSource);
  final getSeatsUseCase = GetSeatsUseCase(bookingRepository);
  final createSeatHoldUseCase = CreateSeatHoldUseCase(bookingRepository);
  final getOwnedSeatHoldUseCase = GetOwnedSeatHoldUseCase(bookingRepository);
  final replaceSeatHoldUseCase = ReplaceSeatHoldUseCase(bookingRepository);
  final releaseSeatHoldUseCase = ReleaseSeatHoldUseCase(bookingRepository);
  final getConcessionsUseCase = GetConcessionsUseCase(bookingRepository);
  final createBookingUseCase = CreateBookingUseCase(bookingRepository);
  final quoteBookingUseCase = QuoteBookingUseCase(bookingRepository);
  final getLoyaltyWalletUseCase = GetLoyaltyWalletUseCase(bookingRepository);
  final getBookingByIdUseCase = GetBookingByIdUseCase(bookingRepository);
  final createPaymentUrlUseCase = CreatePaymentUrlUseCase(bookingRepository);
  final seatRealtimeRepository = SeatRealtimeRepositoryImpl(dioClient, prefs);

  // Ticket Dependencies
  final ticketRemoteDataSource = TicketRemoteDataSourceImpl(dioClient);
  final ticketRepository = TicketRepositoryImpl(ticketRemoteDataSource);
  final getMyTicketsUseCase = GetMyTicketsUseCase(ticketRepository);

  // Review Dependencies
  final reviewRemoteDataSource = ReviewRemoteDataSourceImpl(dioClient);
  final reviewRepository = ReviewRepositoryImpl(reviewRemoteDataSource);
  final getMovieReviewsUseCase = GetMovieReviewsUseCase(reviewRepository);
  final getRatingSummaryUseCase = GetRatingSummaryUseCase(reviewRepository);
  final submitReviewUseCase = SubmitReviewUseCase(reviewRepository);

  runApp(
    MultiProvider(
      providers: [
        Provider<SharedPreferences>.value(value: prefs),
        Provider<DioClient>.value(value: dioClient),
        ChangeNotifierProvider(
          create: (_) =>
              AuthProvider(loginUseCase, registerUseCase, logoutUsecase),
        ),
        ChangeNotifierProvider(
          create: (_) => MovieProvider(
            getNowPlayingUseCase,
            getUpcomingUseCase,
            getMovieDiscoveryUseCase,
            getMovieDetailsUseCase,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => CinemaProvider(
            getCinemasUseCase,
            getShowtimesUseCase,
            getShowtimeByIdUseCase,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => BookingProvider(
            getSeatsUseCase,
            createSeatHoldUseCase,
            getOwnedSeatHoldUseCase,
            replaceSeatHoldUseCase,
            releaseSeatHoldUseCase,
            getConcessionsUseCase,
            createBookingUseCase,
            quoteBookingUseCase,
            getLoyaltyWalletUseCase,
            getBookingByIdUseCase,
            createPaymentUrlUseCase,
            seatRealtimeRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => TicketProvider(getMyTicketsUseCase),
        ),
        ChangeNotifierProvider(
          create: (_) => ReviewProvider(
            getMovieReviewsUseCase,
            getRatingSummaryUseCase,
            submitReviewUseCase,
          ),
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
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const LoginScreen(),
    );
  }
}
