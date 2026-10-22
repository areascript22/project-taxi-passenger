import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:passenger_app/core/routing/app_routes.dart';
import 'package:passenger_app/features/booking/presentation/component/booking_header.dart';
import 'package:passenger_app/l10n/app_localizations.dart';
import 'package:passenger_app/shared/profile_photo/presentation/cubit/profile_photo_cubit.dart';

void main() {
  Future<void> pump(WidgetTester tester, ProfilePhotoCubit photo) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: BookingHeader()),
        ),
        GoRoute(
          path: profileRoute.route,
          builder: (_, _) => const Scaffold(body: Text('PERFIL')),
        ),
      ],
    );
    return tester.pumpWidget(
      BlocProvider.value(
        value: photo,
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('es'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
  }

  testWidgets('tocar el avatar abre la pantalla de perfil', (tester) async {
    await pump(tester, ProfilePhotoCubit());

    await tester.tap(find.byTooltip('Abrir mi perfil'));
    await tester.pumpAndSettle();

    expect(find.text('PERFIL'), findsOneWidget);
  });

  testWidgets('sin foto muestra el icono de persona', (tester) async {
    await pump(tester, ProfilePhotoCubit());

    expect(find.byIcon(Icons.person_outline), findsOneWidget);
  });
}
