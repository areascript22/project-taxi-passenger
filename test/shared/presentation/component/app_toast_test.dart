import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/core/theme/app_colors.dart';
import 'package:passenger_app/core/theme/app_theme.dart';
import 'package:passenger_app/shared/presentation/component/app_toast.dart';
import 'package:toastification/toastification.dart';

void main() {
  // `toastification` es un singleton global compartido por todos los tests del
  // archivo: si un test falla con un toast todavía en pantalla, el siguiente
  // arranca con un overlay ya desmontado y no muestra nada. Limpiarlo acá evita
  // que un fallo real se multiplique en fallos fantasma.
  tearDown(() => toastification.dismissAll(delayForAnimation: false));

  // Monta un MaterialApp real (con el tema de la app, que es de donde AppToast
  // saca los colores) y expone un botón que dispara el toast, porque
  // toastification necesita un Overlay montado y un context vivo.
  Widget harness({required void Function(BuildContext context) onTap}) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => onTap(context),
                child: const Text('disparar'),
              ),
            ),
          );
        },
      ),
    );
  }

  // Ojo: NO usar pumpAndSettle acá. El toast se auto-cierra, así que
  // pumpAndSettle avanza el reloj hasta después del cierre y el assert no
  // encuentra nada. Tampoco sirve un solo pump grande: toastification inserta
  // el OverlayEntry en un post-frame callback y recién después corre la
  // animación de entrada, así que hace falta más de un frame.
  Future<void> showToast(WidgetTester tester) async {
    await tester.tap(find.text('disparar'));
    await tester.pump();
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  // El test falla si quedan timers pendientes al desmontar el árbol, y el
  // auto-close es justamente un timer: hay que drenarlo al final de cada test.
  Future<void> drainToast(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  // El fondo del toast lo pinta un Container dentro del overlay; se busca por
  // color para no acoplarse al árbol interno de toastification.
  //
  // Se comparan los ARGB y no los Color directo: el estilo fillColored pasa el
  // color por toMaterialColor, y Color.== también compara runtimeType, así que
  // MaterialColor(0xFF16C79A) != Color(0xFF16C79A) aunque pinten igual.
  bool hasContainerWithColor(WidgetTester tester, Color color) {
    return tester.widgetList<Container>(find.byType(Container)).any((container) {
      final decoration = container.decoration;
      return decoration is BoxDecoration &&
          decoration.color?.toARGB32() == color.toARGB32();
    });
  }

  testWidgets('success shows the message with the semantic success color', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        onTap:
            (context) => AppToast.success(context, message: 'Todo salió bien'),
      ),
    );

    await showToast(tester);

    expect(find.text('Todo salió bien'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(hasContainerWithColor(tester, AppColors.light.success), isTrue);

    await drainToast(tester);
  });

  testWidgets('error shows the message with the theme error color', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        onTap: (context) => AppToast.error(context, message: 'Algo falló'),
      ),
    );

    await showToast(tester);

    expect(find.text('Algo falló'), findsOneWidget);
    expect(find.byIcon(Icons.error_rounded), findsOneWidget);
    expect(
      hasContainerWithColor(tester, AppTheme.light.colorScheme.error),
      isTrue,
    );

    await drainToast(tester);
  });

  test('the two variants are distinguishable by color', () {
    expect(AppColors.light.success, isNot(AppTheme.light.colorScheme.error));
    expect(AppColors.dark.success, isNot(AppTheme.dark.colorScheme.error));
  });

  testWidgets('renders title and message when a title is provided', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        onTap:
            (context) => AppToast.error(
              context,
              title: 'Sin conexión',
              message: 'Revisa tu internet',
            ),
      ),
    );

    await showToast(tester);

    expect(find.text('Sin conexión'), findsOneWidget);
    expect(find.text('Revisa tu internet'), findsOneWidget);

    await drainToast(tester);
  });

  testWidgets('auto-closes after its duration', (tester) async {
    await tester.pumpWidget(
      harness(
        onTap: (context) => AppToast.success(context, message: 'Temporal'),
      ),
    );

    await showToast(tester);
    expect(find.text('Temporal'), findsOneWidget);

    await drainToast(tester);

    expect(find.text('Temporal'), findsNothing);
  });
}
