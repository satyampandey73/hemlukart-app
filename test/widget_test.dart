import 'package:flutter_test/flutter_test.dart';
import 'package:hemlukart_app/main.dart';

void main() {
  testWidgets('App renders initial widget tree without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MyApp), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });
}
