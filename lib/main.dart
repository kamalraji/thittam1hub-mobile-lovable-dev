import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'nav.dart';
import 'services/theme_service.dart';
import 'supabase/supabase_config.dart';

/// Main entry point for the application
///
/// This sets up:
/// - Supabase initialization
/// - Theme service for dynamic theme switching
/// - go_router navigation
/// - Material 3 theming with light/dark modes
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await SupabaseConfig.initialize();
    debugPrint('✅ Supabase initialized successfully');
  } catch (e) {
    debugPrint('❌ Failed to initialize Supabase: $e');
  }

  // Initialize theme service
  final themeService = ThemeService();
  await themeService.loadThemeMode();
  
  runApp(
    ChangeNotifierProvider.value(
      value: themeService,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, _) => MaterialApp.router(
        title: 'Dreamflow Starter',
        debugShowCheckedModeBanner: false,

        // Theme configuration
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeService.themeMode,

        // Router configuration
        routerConfig: AppRouter.createRouter(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.surface,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
              style: TextStyle(color: cs.onSurface),
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
