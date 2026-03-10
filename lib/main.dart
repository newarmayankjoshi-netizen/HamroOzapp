import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
// removed unused 'dart:io' import
import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'features/nepali_calendar/presentation/pages/nepali_calendar_page.dart';
import 'guides/guides_page.dart';
import 'jobs_page.dart';
import 'rooms_page.dart';
import 'services_page.dart';
import 'marketplace_page.dart';
import 'events_page.dart';
import 'services/firebase_bootstrap.dart';
import 'services/in_app_notification_service.dart';
import 'auth_page.dart';
import 'profile_page.dart';
import 'tools_page.dart';
import 'settings_page.dart';
import 'chat_page.dart';
import 'admin_dashboard_page.dart';
import 'bookmarks_page.dart';
import 'notifications_page.dart';
import 'services/theme_controller.dart';
import 'services/locale_controller.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:hamro_oz/utils/map_utils.dart';

Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Best-effort: initialize Firebase so Crashlytics can report.
      await FirebaseBootstrap.tryInit();

      // Load theme preference early
      await ThemeController.instance.load();

      // Attach global error handlers (safe even when Firebase isn't configured).
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        if (!kIsWeb) {
          FirebaseCrashlytics.instance.recordFlutterFatalError(details);
        }
      };

      if (!kIsWeb) {
        WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
      }

      runApp(const MyApp());
    },
    (error, stack) {
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
    },
  );
}

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

// Back navigation intent removed — handled by global key handler instead.

class _GlobalBackKeyHandler extends StatefulWidget {
  final Widget child;
  const _GlobalBackKeyHandler({required this.child});

  @override
  State<_GlobalBackKeyHandler> createState() => _GlobalBackKeyHandlerState();
}

class _GlobalBackKeyHandlerState extends State<_GlobalBackKeyHandler> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final navigator = appNavigatorKey.currentState;
    if (navigator == null || !navigator.canPop()) return false;

    final key = event.logicalKey;
    final isBackShortcut =
        key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.browserBack ||
        (key == LogicalKeyboardKey.bracketLeft && HardwareKeyboard.instance.isMetaPressed) ||
        (key == LogicalKeyboardKey.arrowLeft && HardwareKeyboard.instance.isAltPressed);

    if (!isBackShortcut) return false;

    // Best-effort: pop the current route if possible.
    navigator.maybePop();
    return true;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final lightScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFDC2626),
      brightness: Brightness.light,
    ).copyWith(
      secondary: const Color(0xFF2563EB),
      surface: const Color(0xFFF7F7F8),
    );

    final darkScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFDC2626),
      brightness: Brightness.dark,
    ).copyWith(
      secondary: const Color(0xFF2563EB),
    );

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.themeMode,
      builder: (context, currentMode, _) {
        return ValueListenableBuilder<Locale?>(
          valueListenable: LocaleController.instance.locale,
          builder: (context, currentLocale, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'HamroOZ',
              navigatorKey: appNavigatorKey,
              themeMode: currentMode,
              locale: currentLocale,
              localizationsDelegates: [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              theme: ThemeData(
                useMaterial3: true,
                colorScheme: lightScheme,
                scaffoldBackgroundColor: const Color(0xFFF7F7F8),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  centerTitle: true,
                  scrolledUnderElevation: 1,
                  titleTextStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                colorScheme: darkScheme,
                brightness: Brightness.dark,
              ),
              builder: (context, child) => _GlobalBackKeyHandler(
                child: Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (event) {
                    debugPrint('PointerDown at ${event.position} type=${event.runtimeType}');
                  },
                  child: SafeArea(
                    top: false,
                    bottom: true,
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              ),
              home: const _BootstrapGate(),
            );
          },
        );
      },
    );
  }
}



class _BootstrapGate extends StatefulWidget {
  const _BootstrapGate();

  @override
  State<_BootstrapGate> createState() => _BootstrapGateState();
}

class _BootstrapGateState extends State<_BootstrapGate> {
  bool _bootstrapStarted = false;

  @override
  void initState() {
    super.initState();
    // Do not block first paint on bootstrapping.
    // Login screen should appear instantly; Firebase can init in background.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _bootstrapStarted) return;
      _bootstrapStarted = true;
      unawaited(_init());
    });
  }

  Future<void> _init() async {
    try {
      await Future.wait([
        FirebaseBootstrap.tryInit(),
        AuthState.restoreSession(),
      ]);
    } catch (_) {
      // Best-effort bootstrap; app should still render.
    }
    // Trigger rebuild to show correct auth state
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthState.isLoggedIn ? const HomePage() : LoginPage();
  }
}

class FloatingMessageWidget extends StatefulWidget {
  const FloatingMessageWidget({super.key});

  @override
  State<FloatingMessageWidget> createState() => _FloatingMessageWidgetState();
}

class _FloatingMessageWidgetState extends State<FloatingMessageWidget> {
  late Stream<QuerySnapshot> _messagesStream;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = AuthState.currentUserId;
    _initializeMessagesStream();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newUserId = AuthState.currentUserId;
    if (newUserId != _currentUserId) {
      _currentUserId = newUserId;
      _initializeMessagesStream();
    }
  }

  void _initializeMessagesStream() {
    final currentUserId = AuthState.currentUserId;
    if (currentUserId != null && currentUserId.isNotEmpty) {
      try {
        _messagesStream = FirebaseFirestore.instance
            .collection('messages')
            .where('recipientId', isEqualTo: currentUserId)
            .snapshots();
      } catch (e) {
        _messagesStream = Stream.empty();
      }
    } else {
      _messagesStream = Stream.empty();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show for logged-in users
    if (!AuthState.isLoggedIn || AuthState.currentUserId == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _messagesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final messages = snapshot.data!.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .toList();

        final unreadCount = messages.where((msg) => !msg.isRead).length;

        // Don't show if no unread messages
        if (unreadCount == 0) {
          return const SizedBox.shrink();
        }

        return Positioned(
          top: 100, // Position below the app bar
          right: 16,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatPage()),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.message,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$unreadCount new message${unreadCount > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        unreadCount.toString(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  static List<({String title, IconData icon})> getFeatures() {
    final allFeatures = [
      (title: 'Guides', icon: Icons.menu_book),
      (title: 'Jobs', icon: Icons.work),
      (title: 'Rooms', icon: Icons.home),
      (title: 'Services', icon: Icons.store),
      (title: 'Community Events', icon: Icons.event),
      (title: 'Buy & Sell', icon: Icons.shopping_bag),
      (title: 'Tools', icon: Icons.build),
    ];
    
    // Admin-only features
    final adminOnlyTitles = <String>{};
    
    // Features that require authentication
    final authRequiredTitles = <String>{};
    
    // Filter features based on authentication and admin status
    return allFeatures.where((feature) {
      // Hide admin-only features from non-admins
      if (adminOnlyTitles.contains(feature.title) && !AuthState.isAdmin) {
        return false;
      }
      
      // Hide auth-required features from non-logged-in users
      if (authRequiredTitles.contains(feature.title) && !AuthState.isLoggedIn) {
        return false;
      }
      
      return true;
    }).toList();
  }

  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  Widget _buildHomeContent(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.builder(
                    itemCount: HomePage.getFeatures().length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.05,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemBuilder: (context, index) {
                      final features = HomePage.getFeatures();
                      return FeatureCard(
                        title: features[index].title,
                        icon: features[index].icon,
                        onTap: () {
                          if (features[index].title == "Jobs") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => JobsPage()),
                            );
                          } else if (features[index].title == "Rooms") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => RoomsPage()),
                            );
                          } else if (features[index].title == "Services") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ServicesPage()),
                            );
                          } else if (features[index].title == "Buy & Sell") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const MarketplacePage()),
                            );
                          } else if (features[index].title == "Community Events") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const FindEventsByStatePage()),
                            );
                          } else if (features[index].title == "Messages") {
                            setState(() => _selectedIndex = 1);
                          } else if (features[index].title == "Tools") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ToolsPage()),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => GuidesPage()),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Floating message notification shown only on home
          const FloatingMessageWidget(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    

    Widget body;
    switch (_selectedIndex) {
      case 1:
         body = const ChatPage(embedInScaffold: false);
        break;
      case 2:
        body = NepaliCalendarPage();
        break;
      case 3:
        body = Theme(
          data: Theme.of(context).copyWith(
            appBarTheme: const AppBarTheme(toolbarHeight: 0, elevation: 0),
          ),
          child: const ProfilePage(),
        );
        break;
      case 0:
      default:
        body = _buildHomeContent(context);
    }

    final String titleText;
    if (_selectedIndex == 0) {
      titleText = AppLocalizations.of(context)?.appTitle ?? 'HamroOZ';
    } else if (_selectedIndex == 1) {
      titleText = AppLocalizations.of(context)?.messages ?? 'Messages';
    } else if (_selectedIndex == 2) {
      titleText = AppLocalizations.of(context)?.calendar ?? 'Calendar';
    } else {
      titleText = AppLocalizations.of(context)?.profile ?? 'Profile';
    }

    final Widget tappableTitle = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.deferToChild,
          onTap: () => setState(() => _selectedIndex = 0),
          child: Text(titleText),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: tappableTitle,
        actions: [
          // Notifications bell icon with unread badge
          if (AuthState.isLoggedIn && AuthState.currentUserId != null)
            StreamBuilder<int>(
              stream: InAppNotificationService.streamUnreadCount(AuthState.currentUserId!),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;
                return IconButton(
                  icon: Badge(
                    isLabelVisible: unreadCount > 0,
                    label: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(fontSize: 10),
                    ),
                    child: const Icon(Icons.notifications_outlined),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => NotificationsPage()),
                    );
                  },
                  tooltip: 'Notifications',
                );
              },
            ),
          // Messages unread badge merged into top toolbar
          if (AuthState.isLoggedIn && AuthState.currentUserId != null)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .where('recipientId', isEqualTo: AuthState.currentUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();

                final unreadCount = snapshot.data!.docs
                  .where((doc) => !((toStringKeyMap(doc.data())['isRead'] ?? false)))
                  .length;

                if (unreadCount == 0) return const SizedBox.shrink();

                return GestureDetector(
                  onTap: () => setState(() => _selectedIndex = 1),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.message, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          unreadCount.toString(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () async {
              final currentUser = AuthState.currentUser;
              final isAdmin = currentUser?.role == 'Admin' || currentUser?.email == 'hamroozapp@gmail.com';

              final loc = AppLocalizations.of(context);
              final navigator = Navigator.of(context);
              final selected = await showMenu<String>(
                context: context,
                position: RelativeRect.fromLTRB(MediaQuery.of(context).size.width, kToolbarHeight, 0, 0),
                items: [
                  PopupMenuItem<String>(
                    value: 'bookmarks',
                    child: Row(
                      children: [
                        const Icon(Icons.bookmark, size: 20),
                        const SizedBox(width: 12),
                        Text('Bookmarks'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'settings',
                    child: Row(
                      children: [
                        const Icon(Icons.settings, size: 20),
                        const SizedBox(width: 12),
                        Text(loc?.settings ?? 'Settings'),
                      ],
                    ),
                  ),
                  if (isAdmin)
                    PopupMenuItem<String>(
                      value: 'admin_dashboard',
                      child: Row(
                        children: [
                          const Icon(Icons.admin_panel_settings, size: 20),
                          const SizedBox(width: 12),
                          Text(loc?.adminDashboard ?? 'Admin Dashboard'),
                        ],
                      ),
                    ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                        children: [
                          const Icon(Icons.logout, size: 20),
                          const SizedBox(width: 12),
                          Text(loc?.logout ?? 'Logout'),
                        ],
                    ),
                  ),
                ],
              );

              if (selected == null) return;
              if (selected == 'bookmarks') {
                navigator.push(MaterialPageRoute(builder: (_) => const BookmarksPage()));
              } else if (selected == 'settings') {
                navigator.push(MaterialPageRoute(builder: (_) => const SettingsPage()));
              } else if (selected == 'admin_dashboard') {
                navigator.push(MaterialPageRoute(builder: (_) => const AdminDashboardPage()));
              } else if (selected == 'logout') {
                await AuthState.logout();
                if (!mounted) return;
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF2563EB),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        selectedIconTheme: const IconThemeData(color: Colors.white),
        unselectedIconTheme: const IconThemeData(color: Colors.white70),
        showUnselectedLabels: true,
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: AppLocalizations.of(context)?.home ?? 'Home'),
          BottomNavigationBarItem(
            icon: AuthState.isLoggedIn && AuthState.currentUserId != null
                ? StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('messages')
                        .where('recipientId', isEqualTo: AuthState.currentUserId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      int unreadCount = 0;
                      if (snapshot.hasData) {
                        unreadCount = snapshot.data!.docs
                            .where((doc) => !((toStringKeyMap(doc.data())['isRead'] ?? false)))
                            .length;
                      }

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.message),
                          if (unreadCount > 0)
                            Positioned(
                              right: -6,
                              top: -6,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                child: Center(
                                  child: Text(
                                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  )
                : const Icon(Icons.message),
            label: AppLocalizations.of(context)?.messages ?? 'Messages',
          ),
          BottomNavigationBarItem(icon: const Icon(Icons.calendar_month), label: AppLocalizations.of(context)?.calendar ?? 'Calendar'),
          BottomNavigationBarItem(icon: const Icon(Icons.person), label: AppLocalizations.of(context)?.profile ?? 'Profile'),
        ],
      ),
      // Floating calendar FAB removed per request.
    );
  }
}

class FeatureCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const FeatureCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
  return Card(
    clipBehavior: Clip.antiAlias, // Crucial: clips the image to card corners
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: InkWell( // Keeps the card tappable
      onTap: onTap,
      child: Stack(
        children: [
          // 1. The Full-Card Background Image for special feature tiles
          if (title == 'Guides')
            Positioned.fill(
              child: Image.asset(
                'assets/guides_card.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return SvgPicture.asset(
                    'assets/guides_card.svg',
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),

          // Jobs card uses a dedicated artwork too
          if (title == 'Jobs')
            Positioned.fill(
              child: Image.asset(
                'assets/jobs.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Fall back to a plain colored container if the asset fails
                  return Container(color: Theme.of(context).colorScheme.primaryContainer);
                },
              ),
            ),

          // Rooms card uses a dedicated artwork as well
          if (title == 'Rooms')
            Positioned.fill(
              child: Image.asset(
                'assets/rooms.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: Theme.of(context).colorScheme.primaryContainer);
                },
              ),
            ),

          // Services card uses a dedicated artwork too
          if (title == 'Services')
            Positioned.fill(
              child: Image.asset(
                'assets/services.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: Theme.of(context).colorScheme.primaryContainer);
                },
              ),
            ),

          // Community Events card uses a dedicated artwork too
          if (title == 'Community Events')
            Positioned.fill(
              child: Image.asset(
                'assets/community_events.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: Theme.of(context).colorScheme.primaryContainer);
                },
              ),
            ),

            // Marketplace / Buy & Sell card artwork
            if (title == 'Marketplace' || title == 'Buy & Sell')
              Positioned.fill(
                child: Image.asset(
                  'assets/marketplace.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(color: Theme.of(context).colorScheme.primaryContainer);
                  },
                ),
              ),

            // Tools card artwork (image-backed)
            if (title == 'Tools')
              Positioned.fill(
                child: Image.asset(
                  'assets/tools.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(color: Theme.of(context).colorScheme.primaryContainer);
                  },
                ),
              ),

          // 2. The Content Layer (Icon + Text)
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Allows stack to size correctly
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != 'Guides' && title != 'Jobs' && title != 'Rooms' && title != 'Services' && title != 'Community Events' && title != 'Buy & Sell' && title != 'Marketplace' && title != 'Tools') ...[
                  // Standard icon layout for other cards
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.primaryContainer,
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 14),
                ] else ...[
                  // Spacer to push text down if image is the background
                  const Spacer(),
                ],
                // Hide labels for image-backed feature tiles to show artwork only
                if (!(title == 'Guides' || title == 'Jobs' || title == 'Rooms' || title == 'Services' || title == 'Community Events' || title == 'Buy & Sell' || title == 'Marketplace' || title == 'Tools'))
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                      letterSpacing: 0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
}
/// Deferred loader for JobsPage - loads the heavy page on demand

