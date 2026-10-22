import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/shared/presentation/component/network_avatar.dart';

void main() {
  Future<void> pump(WidgetTester tester, {String? url}) => tester.pumpWidget(
    MaterialApp(
      home: Center(child: NetworkAvatar(photoUrl: url, size: 48)),
    ),
  );

  testWidgets('sin URL muestra el icono de persona y no pide imagen', (
    tester,
  ) async {
    await pump(tester);

    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.byType(CachedNetworkImage), findsNothing);
  });

  testWidgets('con URL vacía muestra el icono de persona', (tester) async {
    await pump(tester, url: '');

    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.byType(CachedNetworkImage), findsNothing);
  });

  testWidgets('con URL usa CachedNetworkImage con esa URL', (tester) async {
    await pump(tester, url: 'https://x/a.jpg');

    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.imageUrl, 'https://x/a.jpg');
    expect(image.fit, BoxFit.cover);
  });

  testWidgets('mide el tamaño pedido', (tester) async {
    await pump(tester);

    expect(tester.getSize(find.byType(NetworkAvatar)), const Size(48, 48));
  });
}
