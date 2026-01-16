import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:thittam1hub/main.dart';
import 'package:thittam1hub/models/circle.dart';
import 'package:thittam1hub/models/space.dart';
import 'package:thittam1hub/models/impact_profile.dart';
import 'package:thittam1hub/pages/event_detail_page.dart';
import 'package:thittam1hub/pages/discover_page.dart';
import 'package:thittam1hub/pages/impact/impact_hub_page.dart';
import 'package:thittam1hub/pages/impact/circle_chat_page.dart';
import 'package:thittam1hub/pages/impact/space_room_page.dart';
import 'package:thittam1hub/pages/impact/profile_detail_page.dart';
import 'package:thittam1hub/supabase/supabase_config.dart';
import 'package:thittam1hub/pages/auth/sign_in_page.dart';
import 'package:thittam1hub/pages/auth/sign_up_page.dart';
import 'package:thittam1hub/pages/profile/profile_page.dart';
import 'package:thittam1hub/pages/profile/edit_profile_page.dart';
import 'package:thittam1hub/pages/profile/qr_code_page.dart';
import 'package:thittam1hub/pages/profile/settings_page.dart';
import 'package:thittam1hub/pages/profile/tickets_page.dart';
import 'package:thittam1hub/pages/profile/ticket_detail_page.dart';
import 'package:thittam1hub/pages/chat/chat_page.dart';
import 'package:thittam1hub/pages/chat/message_thread_page.dart';
import 'package:thittam1hub/pages/chat/new_message_page.dart';
import 'package:thittam1hub/models/models.dart';
import 'package:thittam1hub/models/user_ticket.dart';
import 'package:thittam1hub/utils/hero_animations.dart';

/// Custom fade-slide page transition
CustomTransitionPage<T> _buildPageTransition<T>(Widget child, GoRouterState state) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fadeAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      final slideAnimation = Tween<Offset>(
        begin: const Offset(0, 0.03),
        end: Offset.zero,
      ).animate(fadeAnimation);
      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: slideAnimation,
          child: child,
        ),
      );
    },
  );
}

/// Hero-enabled page transition for event detail navigation
CustomTransitionPage<T> _buildHeroPageTransition<T>(Widget child, GoRouterState state) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: HeroConfig.duration,
    reverseTransitionDuration: HeroConfig.reverseDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Fade for non-hero content
      final fadeAnimation = CurvedAnimation(
        parent: animation,
        curve: HeroConfig.curve,
      );
      
      // Subtle scale effect for background
      final scaleAnimation = Tween<double>(
        begin: 0.97,
        end: 1.0,
      ).animate(fadeAnimation);
      
      return FadeTransition(
        opacity: fadeAnimation,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: child,
        ),
      );
    },
  );
}

/// GoRouter configuration for app navigation
class AppRouter {
  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: AppRoutes.discover,
      refreshListenable: GoRouterRefreshStream(SupabaseConfig.auth.onAuthStateChange),
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
          pageBuilder: (context, state) => _buildPageTransition(const SignInPage(), state),
        ),
        GoRoute(
          path: AppRoutes.signUp,
          pageBuilder: (context, state) => _buildPageTransition(const SignUpPage(), state),
        ),
        ShellRoute(
          builder: (context, state, child) => _RootShell(child: child),
          routes: [
            GoRoute(
              path: AppRoutes.home,
              pageBuilder: (context, state) => const NoTransitionPage(child: MyHomePage(title: 'Dashboard')),
            ),
            GoRoute(
              path: AppRoutes.discover,
              pageBuilder: (context, state) => const NoTransitionPage(child: DiscoverPage()),
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
                  pageBuilder: (context, state) => _buildPageTransition(const NewMessagePage(), state),
                ),
                GoRoute(
                  path: ':channelId',
                  pageBuilder: (context, state) {
                    final id = state.pathParameters['channelId']!;
                    final extra = state.extra;
                    if (extra is WorkspaceChannel) {
                      return _buildPageTransition(MessageThreadPage(channelId: id, channel: extra), state);
                    }
                    if (extra is Map) {
                      final map = Map<String, dynamic>.from(extra as Map);
                      return _buildPageTransition(
                        MessageThreadPage(
                          channelId: id,
                          dmUserId: map['dmUserId'] as String?,
                          dmUserName: map['dmUserName'] as String?,
                          dmUserAvatar: map['dmUserAvatar'] as String?,
                        ),
                        state,
                      );
                    }
                    return _buildPageTransition(MessageThreadPage(channelId: id), state);
                  },
                ),
              ],
            ),
            GoRoute(
              path: AppRoutes.profile,
              pageBuilder: (context, state) => const NoTransitionPage(child: ProfilePage()),
            ),
            GoRoute(
              path: '/events/:id',
              pageBuilder: (context, state) {
                final id = state.pathParameters['id']!;
                final event = state.extra as Event?;
                return _buildHeroPageTransition(
                  EventDetailPage(eventId: id, event: event),
                  state,
                );
              },
            ),
            GoRoute(
              path: '/circles/:id',
              pageBuilder: (context, state) {
                final circle = state.extra as Circle?;
                if (circle != null) {
                  return _buildPageTransition(CircleChatPage(circle: circle), state);
                } else {
                  return _buildPageTransition(const _PlaceholderPage(title: 'Error'), state);
                }
              },
            ),
            GoRoute(
              path: '/spaces/:id',
              pageBuilder: (context, state) {
                final space = state.extra as Space?;
                if (space != null) {
                  return _buildPageTransition(SpaceRoomPage(space: space), state);
                } else {
                  return _buildPageTransition(const _PlaceholderPage(title: 'Error'), state);
                }
              },
            ),
            GoRoute(
              path: '/impact/profile/:id',
              pageBuilder: (context, state) {
                final id = state.pathParameters['id']!;
                final profile = state.extra as ImpactProfile?;
                return _buildHeroPageTransition(
                  ProfileDetailPage(profileId: id, profile: profile),
                  state,
                );
              },
            ),
            GoRoute(
              path: '/profile/edit',
              pageBuilder: (context, state) => _buildPageTransition(const EditProfilePage(), state),
            ),
            GoRoute(
              path: '/profile/qr',
              pageBuilder: (context, state) => _buildPageTransition(const QrCodePage(), state),
            ),
            GoRoute(
              path: '/profile/settings',
              pageBuilder: (context, state) => _buildPageTransition(const SettingsPage(), state),
            ),
            GoRoute(
              path: '/profile/tickets',
              pageBuilder: (context, state) => _buildPageTransition(
                const TicketsPage(),
                state,
              ),
            ),
            GoRoute(
              path: '/profile/tickets/:id',
              pageBuilder: (context, state) {
                final id = state.pathParameters['id']!;
                final ticket = state.extra as UserTicket?;
                return _buildHeroPageTransition(
                  TicketDetailPage(registrationId: id, ticket: ticket),
                  state,
                );
              },
            ),
            GoRoute(
              path: '/profile/saved',
              pageBuilder: (context, state) => _buildPageTransition(
                const _PlaceholderPage(title: 'Saved Events'),
                state,
              ),
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
    final cs = Theme.of(context).colorScheme;
    final idx = _indexFromLocation(GoRouterState.of(context).uri.toString());
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: _onTap,
        height: 56,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        backgroundColor: cs.surface,
        indicatorColor: cs.primary.withValues(alpha: 0.15),
        surfaceTintColor: Colors.transparent,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, size: 22),
            selectedIcon: Icon(Icons.home, size: 22, color: cs.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined, size: 22),
            selectedIcon: Icon(Icons.explore, size: 22, color: cs.primary),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.volunteer_activism_outlined, size: 22),
            selectedIcon: Icon(Icons.volunteer_activism, size: 22, color: cs.primary),
            label: 'Impact',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline, size: 22),
            selectedIcon: Icon(Icons.chat_bubble, size: 22, color: cs.primary),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, size: 22),
            selectedIcon: Icon(Icons.person, size: 22, color: cs.primary),
            label: 'Profile',
          ),
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
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_empty, size: 40, color: cs.primary),
            const SizedBox(height: 10),
            Text(
              '$title coming soon',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }
}
