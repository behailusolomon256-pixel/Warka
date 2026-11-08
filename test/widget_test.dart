import 'package:flutter_test/flutter_test.dart';
import 'package:warka_news/main.dart';

void main() {
  testWidgets('Warka newsroom home renders', (tester) async {
    await tester.pumpWidget(const WarkaApp());

    expect(find.text('WARKA'), findsOneWidget);
    expect(find.text('The stories that matter.'), findsOneWidget);
  });
}
