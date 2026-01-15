import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:thittam1hub/main.dart';
import 'package:thittam1hub/models/circle.dart';
import 'package:thittam1hub/models/space.dart';
import 'package:thittam1hub/pages/event_detail_page.dart';
import 'package:thittam1hub/pages/discover_page.dart';
import 'package:thittam1hub/pages/impact/impact_hub_page.dart';
import 'package:thittam1hub/pages/impact/circle_chat_page.dart';
import 'package:thittam1hub/pages/impact/space_room_page.dart';
import 'package:thittam1hub/supabase/supabase_config.dart';
import 'package:thittam1hub/pages/auth/sign_in_page.dart';
import 'package:thittam1hub/pages/auth/sign_up_page.dart';
import 'package:thittam1hub/pages/profile/profile_page.dart';
import 'package:thittam1hub/pages/profile/edit_profile_page.dart';
import 'package:thittam1hub/pages/profile/qr_code_page.dart';
import 'package:thittam1hub/pages/profile/settings_page.dart';
import 'package:thittam1hub/pages/chat/chat_page.dart';
import 'package:thittam1hub/pages/chat/message_thread_page.dart';
import 'package:thittam1hub/pages/chat/new_message_page.dart';
import 'package:thittam1hub/models/models.dart';

/// GoRouter configuration for app navigation
class AppRouter {
  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: AppRoutes.discover,
      refreshListenable:
          GoRouterRefreshStream(SupabaseConfig.auth.onAuthStateChange),
      redirect: (context, state) {
        final loggedIn = SupabaseConfig.auth.currentUser != null;
        final loggingIn = state.matchedLocation == AppRoutes.signIn ||
            state.matchedLocation == AppRoutes.signUp;

        if (!loggedIn) {
          return loggingIn ? null : AppRoutes.signIn;
        }

        if (loggedIn && loggingIn) {
          return AppRoutes.discover;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.signIn,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SignInPage()),
        ),
        GoRoute(
          path: AppRoutes.signUp,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SignUpPage()),
        ),
        ShellRoute(
          builder: (context, state, child) => _RootShell(child: child),
          routes: [
            GoRoute(
              path: AppRoutes.home,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: MyHomePage(title: 'Dashboard')),
            ),
            GoRoute(
              path: AppRoutes.discover,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: DiscoverPage()),
            ),
            GoRoute(
              path: AppRoutes.impact,
              pageBuilder: (context, state) => const NoTransitionPage(child: ImpactHubPage()),
            ),
            GoRoute(
              path: AppRoutes.chat,
              pageBuilder: (context, state) => const NoTransitionPage(child: ChatPage()),
              routes: [
                GoRoute(
                  path: 'new',
                  pageBuilder: (context, state) => const NoTransitionPage(child: NewMessagePage()),
                ),
                GoRoute(
                  path: ':channelId',
                  pageBuilder: (context, state) {
                    final id = state.pathParameters['channelId']!;
                    final extra = state.extra; // may be null
                    if (extra is WorkspaceChannel) {
                      return NoTransitionPage(child: MessageThreadPage(channelId: id, channel: extra));
                    }
                    if (extra is Map) {
                      final map = Map<String, dynamic>.from(extra as Map);
                      return NoTransitionPage(
                        child: MessageThreadPage(
                          channelId: id,
                          dmUserId: map['dmUserId'] as String?,
                          dmUserName: map['dmUserName'] as String?,
                          dmUserAvatar: map['dmUserAvatar'] as String?,
                        ),
                      );
                    }
                    return NoTransitionPage(child: MessageThreadPage(channelId: id));
                  },
                ),
              ],
            ),
            GoRoute(
              path: AppRoutes.profile,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: ProfilePage()),
            ),
            // Event detail
            GoRoute(
              path: '/events/:id',
              pageBuilder: (context, state) {
                final id = state.pathParameters['id']!;
                return NoTransitionPage(child: EventDetailPage(eventId: id));
              },
            ),
            // Circle Chat Page
            GoRoute(
              path: '/circles/:id',
              pageBuilder: (context, state) {
                final circle = state.extra as Circle?;
                if (circle != null) {
                  return NoTransitionPage(child: CircleChatPage(circle: circle));
                } else {
                  // Handle the case where the circle is not passed
                  return const NoTransitionPage(child: _PlaceholderPage(title: 'Error'));
                }
              },
            ),
            // Space Room Page
            GoRoute(
              path: '/spaces/:id',
              pageBuilder: (context, state) {
                final space = state.extra as Space?;
                if (space != null) {
                  return NoTransitionPage(child: SpaceRoomPage(space: space));
                } else {
                  return const NoTransitionPage(child: _PlaceholderPage(title: 'Error'));
                }
              },
            ),
            // Profile routes
            GoRoute(
              path: '/profile/edit',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: EditProfilePage()),
            ),
            GoRoute(
              path: '/profile/qr',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: QrCodePage()),
            ),
            GoRoute(
              path: '/profile/settings',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: SettingsPage()),
            ),
            GoRoute(
              path: '/profile/registrations',
              pageBuilder: (context, state) => const NoTransitionPage(
                  child: _PlaceholderPage(title: 'My Registrations')),
            ),
            GoRoute(
              path: '/profile/saved',
              pageBuilder: (context, state) => const NoTransitionPage(
                  child: _PlaceholderPage(title: 'Saved Events')),
            ),
          ],
        ),
      ],
    );
  }
}

/// Route path constants
class AppRoutes {
  static const String home = '/';
  static const String discover = '/discover';
  static const String impact = '/impact';
  static const String chat = '/chat';
  static const String profile = '/profile';
  static const String signIn = '/signin';
  static const String signUp = '/signup';
}

class _RootShell extends StatefulWidget {
  final Widget child;
  const _RootShell({required this.child});
  @override
  State<_RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<_RootShell> {
  int _indexFromLocation(String location) {
    if (location.startsWith(AppRoutes.discover)) return 1;
    if (location.startsWith(AppRoutes.impact)) return 2;
    if (location.startsWith(AppRoutes.chat)) return 3;
    if (location.startsWith(AppRoutes.profile)) return 4;
    return 0;
  }

  void _onTap(int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.discover);
        break;
      case 2:
        context.go(AppRoutes.impact);
        break;
      case 3:
        context.go(AppRoutes.chat);
        break;
      case 4:
        context.go(AppRoutes.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final idx = _indexFromLocation(GoRouterState.of(context).uri.toString());
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: _onTap,
        height: 64,
        indicatorColor:
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.explore_outlined), label: 'Discover'),
          NavigationDestination(
              icon: Icon(Icons.volunteer_activism_outlined),
              selectedIcon: Icon(Icons.volunteer_activism),
              label: 'Impact'),
          NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'Chat'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }
}

/// Simple GoRouter refresh helper that listens to a stream
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class _PlaceholderPage extends StatelessWidget {
  final String title;
  const _PlaceholderPage({required this.title});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.hourglass_empty,
              size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text('$title coming soon',
              style: Theme.of(context).textTheme.titleLarge),
        ]),
      ),
    );
  }
}
