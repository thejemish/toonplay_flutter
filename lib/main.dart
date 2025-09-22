import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:toonplay/supabase/db_instance.dart';

// Screens
import 'package:toonplay/screens/intro_screen.dart';
import 'package:toonplay/screens/home_screen.dart';
import 'package:toonplay/screens/category_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();

  await Supabase.initialize(
    url: 'https://acroqlfsthmrfuhkwsjg.supabase.co',
    anonKey: 'sb_publishable_quE_XyZ1lK5DI7VE4bYDKA_JrN4nMr5',
  );

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() {
    return _MyAppState();
  }
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          name: 'intro',
          builder: (context, state) => IntroScreen(),
        ),
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => HomeScreen(),
        ),
        GoRoute(
          path: '/category/:slug',
          name: 'category',
          builder: (context, state) {
            final slug = state.pathParameters["slug"]!;
            return CategoryListScreen(slug: slug);
          },
        ),
      ],
      redirect: (BuildContext context, GoRouterState state) {
        final bool isAuthenticated = SupabaseInstance().initialize();
        final String currentLocation = state.fullPath ?? '';

        // If user is authenticated and on intro page, redirect to home
        if (isAuthenticated && currentLocation == '/') {
          return '/home';
        }

        // If user is not authenticated and trying to access home, redirect to intro
        if (!isAuthenticated && currentLocation == '/home') {
          return '/';
        }

        // No redirect needed
        return null;
      },
      // Add this to handle authentication state changes
      refreshListenable: _AuthStateNotifier(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Toonplay',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}

// Create a notifier that listens to Supabase auth state changes
class _AuthStateNotifier extends ChangeNotifier {
  _AuthStateNotifier() {
    // Listen to auth state changes and notify the router
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      notifyListeners();
    });
  }
}
