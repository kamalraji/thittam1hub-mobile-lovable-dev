import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'nav.dart';
import 'services/theme_service.dart';
import 'services/cache_service.dart';
import 'services/connectivity_service.dart';
import 'services/background_sync_service.dart';
import 'services/offline_action_queue.dart';
import 'supabase/supabase_config.dart';

/// Main entry point for the application
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await SupabaseConfig.initialize();
    debugPrint('✅ Supabase initialized successfully');
  } catch (e) {
    debugPrint('❌ Failed to initialize Supabase: $e');
  }

  // Initialize cache service for offline support
  try {
    await CacheService.instance.init();
    debugPrint('✅ CacheService initialized successfully');
  } catch (e) {
    debugPrint('❌ Failed to initialize CacheService: $e');
  }

  // Initialize connectivity monitoring
  try {
    await ConnectivityService.instance.init();
    debugPrint('✅ ConnectivityService initialized successfully');
  } catch (e) {
    debugPrint('❌ Failed to initialize ConnectivityService: $e');
  }

  // Initialize offline action queue
  try {
    await OfflineActionQueue.instance.init();
    debugPrint('✅ OfflineActionQueue initialized successfully');
  } catch (e) {
    debugPrint('❌ Failed to initialize OfflineActionQueue: $e');
  }

  // Initialize background sync
  try {
    BackgroundSyncService.instance.init();
    debugPrint('✅ BackgroundSyncService initialized successfully');
  } catch (e) {
    debugPrint('❌ Failed to initialize BackgroundSyncService: $e');
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
      builder: (context, themeService, _) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => MaterialApp.router(
          title: 'Thittam1hub',
          debugShowCheckedModeBanner: false,

          // Theme configuration with smooth transition
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeService.themeMode,
          
          // Smooth theme transition animation
          builder: (context, child) {
            return AnimatedTheme(
              data: Theme.of(context),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              child: child ?? const SizedBox.shrink(),
            );
          },

          // Router configuration
          routerConfig: AppRouter.createRouter(),
        ),
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
