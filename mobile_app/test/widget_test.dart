import 'package:flutter_test/flutter_test.dart';
import 'package:qroutex/main.dart';

void main() {
  testWidgets('App initialization test', (WidgetTester tester) async {
    await tester.pumpWidget(const QRouteXApp(isLoggedIn: false));
    expect(find.byType(QRouteXApp), findsOneWidget);
  });
}
