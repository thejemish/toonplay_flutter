import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:toonplay/supabase/db_instance.dart';
import 'package:toonplay/screens/intro_screen.dart';
import 'package:toonplay/screens/home_screen.dart';
import 'package:toonplay/screens/category_list_screen.dart';
import 'package:toonplay/screens/reels_screen.dart';
import 'package:toonplay/screens/short_screen.dart';
import 'package:toonplay/screens/favorites_screen.dart';
import 'package:toonplay/theme/theme.dart';
import 'package:toonplay/widgets/custom_bottom_bar.dart';
import 'package:toonplay/widgets/custom_app_bar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();

  await Supabase.initialize(
    url: 'https://acroqlfsthmrfuhkwsjg.supabase.co',
    anonKey: 'sb_publishable_quE_XyZ1lK5DI7VE4bYDKA_JrN4nMr5',
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
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
        StatefulShellRoute.indexedStack(
          branches: [
            _buildHomeBranch(),
            _buildReelsBranch(),
            _buildFavoritesBranch(),
          ],
          builder: (context, state, navigationShell) {
            final currentLocation = state.fullPath ?? '';
            final shouldHideAppBar =
                currentLocation.contains('reels') ||
                currentLocation.contains('short');

            return Scaffold(
              body: navigationShell,
              appBar: shouldHideAppBar ? null : CustomAppBar(),
              bottomNavigationBar: CustomBottomBar(
                currentIndex: navigationShell.currentIndex,
                onTap: (index) => navigationShell.goBranch(index),
              ),
            );
          },
        ),
      ],
      redirect: _handleRedirect,
      refreshListenable: _AuthStateNotifier(),
    );
  }

  // Extract home branch configuration
  StatefulShellBranch _buildHomeBranch() {
    return StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/home',
          name: 'home',
          pageBuilder: (context, state) => _fadeTransition(HomeScreen()),
          routes: [
            GoRoute(
              path: '/category/:slug',
              name: 'category',
              pageBuilder: (context, state) {
                final slug = state.pathParameters["slug"]!;
                final extraData = state.extra as Map<String, dynamic>;
                final categoryName = extraData['category_name'] as String;

                return _slideUpTransition(
                  CategoryListScreen(slug: slug, categoryName: categoryName),
                );
              },
            ),
            GoRoute(
              path: '/short/:slug',
              name: 'short',
              pageBuilder: (context, state) {
                final slug = state.pathParameters["slug"]!;
                final extraData = state.extra as Map<String, dynamic>;
                final data = extraData['data'] as Map<String, dynamic>;

                return _slideUpTransition(
                  ShortsScreen(
                    categorySlug: slug,
                    categoryName: data['category_name'] as String,
                    initialVideoId: data['video_id'] as String,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  // Extract reels branch configuration
  StatefulShellBranch _buildReelsBranch() {
    return StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/reels',
          name: 'reels',
          pageBuilder: (context, state) => _fadeTransition(ReelsScreen()),
        ),
      ],
    );
  }

  // Extract favorites branch configuration
  StatefulShellBranch _buildFavoritesBranch() {
    return StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/favorites',
          name: 'favorites',
          pageBuilder: (context, state) => _fadeTransition(FavoritesScreen()),
        ),
      ],
    );
  }

  // Reusable fade transition
  CustomTransitionPage _fadeTransition(Widget child) {
    return CustomTransitionPage(
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurveTween(curve: Curves.easeInOutCirc).animate(animation),
          child: child,
        );
      },
    );
  }

  // Reusable slide up transition
  CustomTransitionPage _slideUpTransition(Widget child) {
    return CustomTransitionPage(
      transitionDuration: const Duration(milliseconds: 500),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.ease;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.background,
        child: Center(child: child),
      ),
    );
  }

  // Extract redirect logic
  String? _handleRedirect(BuildContext context, GoRouterState state) {
    final isAuthenticated = SupabaseInstance().initialize();
    final currentLocation = state.fullPath ?? '';

    if (isAuthenticated && currentLocation == '/') return '/home';
    if (!isAuthenticated && currentLocation == '/home') return '/';

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Toonplay',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: const [
          Breakpoint(start: 0, end: 380, name: 'MOBILE_SMALL'),
          Breakpoint(start: 381, end: 450, name: 'MOBILE'),
          Breakpoint(start: 451, end: 800, name: TABLET),
          Breakpoint(start: 801, end: 1920, name: DESKTOP),
          Breakpoint(start: 1921, end: double.infinity, name: '4K'),
        ],
      ),
    );
  }
}

// Auth state notifier for router refresh
class _AuthStateNotifier extends ChangeNotifier {
  _AuthStateNotifier() {
    Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }
}
