// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:kupon_bbm_app/main.dart';
import 'package:kupon_bbm_app/core/di/dependency_injection.dart' as di;
import 'package:kupon_bbm_app/presentation/providers/dashboard_provider.dart';
import 'package:kupon_bbm_app/presentation/providers/transaksi_provider.dart';
import 'package:kupon_bbm_app/presentation/providers/kupon_provider.dart';
import 'package:kupon_bbm_app/presentation/providers/master_data_provider.dart';
import 'package:kupon_bbm_app/presentation/providers/enhanced_import_provider.dart';
import 'package:kupon_bbm_app/domain/repositories/kupon_repository.dart';
import 'package:kupon_bbm_app/domain/repositories/master_data_repository.dart';
import 'package:kupon_bbm_app/domain/repositories/transaksi_repository_impl.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Initialize dependencies and build app with the required providers.
    await di.initializeDependencies();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => DashboardProvider(di.getIt<KuponRepository>()),
          ),
          ChangeNotifierProvider(
            create: (_) =>
                TransaksiProvider(di.getIt<TransaksiRepositoryImpl>()),
          ),
          ChangeNotifierProvider(
            create: (_) => KuponProvider(di.getIt<KuponRepository>()),
          ),
          ChangeNotifierProvider(
            create: (_) => MasterDataProvider(di.getIt<MasterDataRepository>()),
          ),
          ChangeNotifierProvider(
            create: (_) => di.getIt<EnhancedImportProvider>(),
          ),
        ],
        child: const MyApp(),
      ),
    );

    // Verify that Import page is shown by default (MainPage selected index 0)
    expect(find.text('Import Kupon dari Excel'), findsOneWidget);
  });
}
