import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/core/theme/app_theme.dart';
import 'package:passenger_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:passenger_app/features/auth/presentation/screen/sign_in_screen.dart';
import 'package:passenger_app/l10n/app_localizations.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

void main() {
  late _MockAuthBloc bloc;

  setUpAll(() async {
    // La fuente por defecto de los tests (Ahem) es mucho mas ancha que la real:
    // se carga Roboto del SDK para que el layout se mida con texto de verdad.
    final loader = FontLoader('Roboto');
    for (final weight in ['regular', 'medium', 'bold', 'black']) {
      loader.addFont(
        File('${Platform.environment['FLUTTER_ROOT'] ?? 'C:/flutter'}/bin/cache/artifacts/material_fonts/roboto-$weight.ttf')
            .readAsBytes()
            .then((bytes) => ByteData.view(Uint8List.fromList(bytes).buffer)),
      );
    }
    await loader.load();
    registerFallbackValue(AuthSignInWithGoogle());
  });

  setUp(() {
    bloc = _MockAuthBloc();
    when(() => bloc.state).thenReturn(AuthInitial());
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    ThemeData? theme,
    Locale locale = const Locale('es'),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.light,
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<AuthBloc>.value(
          value: bloc,
          child: const SignInView(),
        ),
      ),
    );
    // Las animaciones de entrada y el Lottie corren en bucle: se avanza un
    // tiempo fijo en vez de esperar a que "terminen".
    await tester.pump(const Duration(seconds: 2));
  }

  testWidgets('shows brand, headline, tagline, Google button and benefits',
      (tester) async {
    await pumpScreen(tester);

    expect(find.text('TaxiGo'), findsOneWidget);
    expect(find.text('Tu taxi, a un toque'), findsOneWidget);
    expect(
      find.text('Pide un taxi seguro en Riobamba, en segundos.'),
      findsOneWidget,
    );
    expect(find.text('Continuar con Google'), findsOneWidget);
    expect(find.text('Conductores verificados'), findsOneWidget);
    expect(find.text('Respuesta rápida'), findsOneWidget);
    expect(find.text('Seguimiento y chat'), findsOneWidget);
    // La pantalla ya no usa el saludo genérico.
    expect(find.textContaining('Bienvenido'), findsNothing);
  });

  testWidgets('is translated to English', (tester) async {
    await pumpScreen(tester, locale: const Locale('en'));

    expect(find.text('Your taxi, one tap away'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('tapping the Google button asks the bloc to sign in',
      (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Continuar con Google'));

    verify(() => bloc.add(any(that: isA<AuthSignInWithGoogle>()))).called(1);
  });

  testWidgets('while loading it shows a spinner and the button is disabled',
      (tester) async {
    when(() => bloc.state).thenReturn(AuthLoading());
    await pumpScreen(tester);

    expect(find.text('Continuar con Google'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  group('layout without overflow', () {
    final sizes = <String, Size>{
      'small phone': const Size(320, 568),
      'regular phone': const Size(390, 844),
      'large phone': const Size(430, 932),
      'landscape-ish short': const Size(360, 480),
    };

    for (final entry in sizes.entries) {
      for (final dark in [false, true]) {
        testWidgets('${entry.key} ${dark ? 'dark' : 'light'}', (tester) async {
          await pumpScreen(
            tester,
            size: entry.value,
            theme: dark ? AppTheme.dark : AppTheme.light,
          );

          expect(tester.takeException(), isNull);
          expect(find.text('Continuar con Google'), findsOneWidget);
        });
      }
    }
  });
}
