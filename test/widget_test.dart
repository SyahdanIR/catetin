import 'package:flutter_test/flutter_test.dart';
import 'package:dompetku/main.dart';
import 'package:dompetku/data/database/app_database.dart';
import 'package:dompetku/data/repositories/finance_repository.dart';
import 'package:drift/native.dart';

void main() {
  testWidgets('Dompetku smoke test - dashboard renders greeting and tabs',
      (WidgetTester tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    final repository = FinanceRepository(database: database);
    await repository.init();
    await tester.pumpWidget(DompetkuApp(repository: repository));

    // Verify personalized greeting renders
    expect(find.text('Halo, Syahdan!'), findsOneWidget);

    // Verify bottom nav items
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Scan Struk'), findsOneWidget);
    expect(find.text('Transaksi'), findsOneWidget);
    expect(find.text('Report'), findsOneWidget);

    await database.close();
  });
}
