import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_booking_app/presentation/booking_flow/booking_flow_strings.dart';

void main() {
  for (final locale in const [Locale('vi'), Locale('en')]) {
    testWidgets(
        'booking flow strings render without mojibake for ${locale.languageCode}',
        (tester) async {
      late BookingFlowStrings strings;
      await tester.pumpWidget(MaterialApp(
        locale: locale,
        supportedLocales: const [Locale('vi'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(builder: (context) {
          strings = BookingFlowStrings.of(context);
          return Text(
              '${strings.selectSeats}|${strings.concessions}|${strings.review}|'
              '${strings.confirmBooking}|${strings.releaseSeats}|${strings.holdTime}|'
              '${strings.promotion}|${strings.points}|${strings.leaveTitle}|'
              '${strings.releaseFailed}|${strings.stateHeld}|${strings.stateBooked}|'
              '${strings.emptyConcessions}|${strings.quoteUpdating}|'
              '${strings.authenticationRequired}|${strings.holdExpired}|'
              '${strings.seatUnavailable}|${strings.requestFailed}');
        }),
      ));
      final rendered = tester.widget<Text>(find.byType(Text)).data!;
      for (final marker in const [
        'Ã',
        'Ä',
        'Â',
        'á»',
        'áº',
        'â€¦',
        '\uFFFD',
      ]) {
        expect(rendered, isNot(contains(marker)), reason: 'Found $marker');
      }
    });
  }
}
