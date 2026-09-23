import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/core/error/errors.dart';

void main() {
  group('Failure', () {
    test('expone el mensaje con el que se construye', () {
      final failure = Failure(message: 'algo salió mal');

      expect(failure.message, 'algo salió mal');
    });

    test('es una instancia de ErrorBase', () {
      final failure = Failure(message: 'error');

      expect(failure, isA<ErrorBase>());
    });
  });
}
