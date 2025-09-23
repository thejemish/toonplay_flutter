import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:toonplay/supabase/db_instance.dart';

// Screens
import 'package:toonplay/screens/intro_screen.dart';
import 'package:toonplay/screens/home_screen.dart';
import 'package:toonplay/screens/category_list_screen.dart';
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
        StatefulShellRoute.indexedStack(
          branches: [
            // Home branch (index 0)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  name: 'home',
                  pageBuilder: (context, state) {
                    return CustomTransitionPage(
                      child: HomeScreen(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                              opacity: CurveTween(
                                curve: Curves.easeInOutCirc,
                              ).animate(animation),
                              child: child,
                            );
                          },
                    );
                  },
                  routes: [
                    GoRoute(
                      path: '/category/:slug',
                      name: 'category',
                      pageBuilder: (context, state) {
                        final slug = state.pathParameters["slug"]!;

                        return CustomTransitionPage(
                          transitionDuration: Duration(milliseconds: 500),
                          reverseTransitionDuration: Duration(
                            milliseconds: 300,
                          ),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                                const begin = Offset(0.0, 1.0);
                                const end =
                                    Offset.zero; // End at the original position
                                const curve = Curves.ease;

                                var tween = Tween(
                                  begin: begin,
                                  end: end,
                                ).chain(CurveTween(curve: curve));

                                return SlideTransition(
                                  position: animation.drive(tween),
                                  child: child,
                                );
                              },
                          child: Container(
                            width: double.infinity,
                            height: double.infinity,
                            color: AppColors.background,
                            child: Center(
                              child: CategoryListScreen(slug: slug),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                // Category detail page as child of home
              ],
            ),
            // Reels branch (index 1)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/reels',
                  name: 'reels',
                  pageBuilder: (context, state) {
                    return CustomTransitionPage(
                      child:
                          HomeScreen(), // Replace with your ReelsScreen when ready
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                              opacity: CurveTween(
                                curve: Curves.easeInOutCirc,
                              ).animate(animation),
                              child: child,
                            );
                          },
                    );
                  },
                ),
              ],
            ),
            // Favorites branch (index 2)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/favorites',
                  name: 'favorites',
                  pageBuilder: (context, state) {
                    return CustomTransitionPage(
                      child:
                          HomeScreen(), // Replace with your FavoritesScreen when ready
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                              opacity: CurveTween(
                                curve: Curves.easeInOutCirc,
                              ).animate(animation),
                              child: child,
                            );
                          },
                    );
                  },
                ),
              ],
            ),
          ],
          builder: (context, state, navigationShell) {
            final extraData = state.path;
            print('===== extraData ===== $extraData');
            return Scaffold(
              body: navigationShell,
              appBar: CustomAppBar(),
              bottomNavigationBar: CustomBottomBar(
                currentIndex: navigationShell.currentIndex,
                onTap: (index) {
                  // Fixed: Pass the tapped index instead of current index
                  navigationShell.goBranch(index);
                },
              ),
            );
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
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: [
          const Breakpoint(start: 0, end: 380, name: 'MOBILE_SMALL'),
          const Breakpoint(start: 381, end: 450, name: 'MOBILE'),
          const Breakpoint(start: 451, end: 800, name: TABLET),
          const Breakpoint(start: 801, end: 1920, name: DESKTOP),
          const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
        ],
      ),
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
