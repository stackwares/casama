import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/core/widgets.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';

void main() {
  testWidgets(
    'a request that got no answer reads plainly, not as a library or CORS message',
    (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (c) {
              ctx = c;
              return const SizedBox();
            },
          ),
        ),
      );
      final options = RequestOptions(
        path: '/v1/computers/c1/lease',
        method: 'DELETE',
      );
      final noAnswer = DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        message: 'The XMLHttpRequest onError callback was called. ... CORS "simple request" ...',
      );
      expect(
        errorText(ctx, noAnswer),
        "Couldn't reach your Casama server. Check your connection and try again.",
      );
      // A real answer keeps its own message.
      final answered = DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: options, statusCode: 418),
        message: 'Teapot',
      );
      expect(errorText(ctx, answered), 'Teapot');
    },
  );
}
