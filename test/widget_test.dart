import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memoryflow/app.dart';

void main() {
  testWidgets('Welcome screen renders the brand and CTA', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MemoryFlowApp()));
    await tester.pump();

    expect(find.text('MemoryFlow'), findsOneWidget);
    expect(find.text('Get started →'), findsOneWidget);
    expect(find.text('AI MEMORY CONCIERGE'), findsOneWidget);
  });
}
