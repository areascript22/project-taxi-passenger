import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/shared/presentation/component/app_version.dart';

void main() {
  group('displayAppVersion', () {
    test('quita el sufijo de flavor y el build number', () {
      expect(displayAppVersion(rawVersion: '1.0.7-dev+19'), '1.0.7');
    });

    test('quita solo el build number', () {
      expect(displayAppVersion(rawVersion: '1.0.5+18'), '1.0.5');
    });

    test('quita solo el sufijo', () {
      expect(displayAppVersion(rawVersion: '1.0.7-dev'), '1.0.7');
    });

    test('deja intacta una versión limpia', () {
      expect(displayAppVersion(rawVersion: '1.0.7'), '1.0.7');
    });

    test('quita un pre-release con puntos', () {
      expect(displayAppVersion(rawVersion: '2.1.0-rc.1+40'), '2.1.0');
    });

    test('ignora espacios alrededor', () {
      expect(displayAppVersion(rawVersion: ' 1.0.7-dev+19 '), '1.0.7');
    });
  });
}
