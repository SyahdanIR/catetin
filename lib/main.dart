import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/finance_repository.dart';
import 'shell/navigation_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style for seamless edge-to-edge status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  final repository = FinanceRepository();

  runApp(DompetkuApp(repository: repository));
}

class DompetkuApp extends StatelessWidget {
  final FinanceRepository repository;

  const DompetkuApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dompetku',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: NavigationShell(repository: repository),
    );
  }
}
