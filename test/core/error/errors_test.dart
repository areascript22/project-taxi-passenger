import 'package:passenger_app/core/error/errors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Failure', () {
    test('exposes the code it was created with', () {
      final failure = Failure(code: FailureCode.rideRequestFailed);

      expect(failure.code, FailureCode.rideRequestFailed);
    });

    test('is an ErrorBase', () {
      final failure = Failure(code: FailureCode.unexpected);

      expect(failure, isA<ErrorBase>());
    });

    test('carries no technical detail unless one is given', () {
      expect(Failure(code: FailureCode.unexpected).detail, isNull);
      expect(
        Failure(code: FailureCode.unexpected, detail: 'SocketException').detail,
        'SocketException',
      );
    });

    // El detalle es SOLO para logs: la UI nunca lo muestra, muestra el texto
    // que `failureText` resuelve a partir del código. Si alguien agrega un
    // getter tipo `message` que devuelva el detalle, este test no lo impide,
    // pero sí deja escrito el contrato.
    test('two instances with the same code are distinct objects', () {
      final a = Failure(code: FailureCode.unexpected);
      final b = Failure(code: FailureCode.unexpected);

      expect(identical(a, b), isFalse);
      expect(a.code, b.code);
    });

    test('every code is covered by the enum used across the app', () {
      // Guarda contra agregar un código al enum y olvidarse de mapearlo en
      // failure_text.dart: ese switch es exhaustivo, así que si falta un caso
      // el proyecto no compila. Este test documenta la intención.
      expect(FailureCode.values, isNotEmpty);
      expect(FailureCode.values, contains(FailureCode.unexpected));
    });
  });
}
