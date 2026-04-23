import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'admin/admin_dashboard.dart';
import 'admin/admin_login.dart';
import 'providers/event_provider.dart';
import 'providers/user_provider.dart';
import 'screens/about_screen.dart';
import 'screens/accessibility_settings_screen.dart';
import 'screens/contact_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/wishlist_screen.dart';
import 'services/event_service.dart';
import 'services/notification_service.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const EventBridgeApp());
}

class EventBridgeApp extends StatelessWidget {
  const EventBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EventProvider()..loadEvents()),
        ChangeNotifierProvider(create: (_) => EventService()),
        ChangeNotifierProvider(
          create: (_) =>
              UserProvider()..initializeNotifications(NotificationService()),
        ),
      ],
      child: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'EventBridge',
            locale: Locale(userProvider.languageCode),
            builder: (context, child) {
              final mediaQuery = MediaQuery.of(context);
              return MediaQuery(
                data: mediaQuery.copyWith(
                  textScaler: TextScaler.linear(userProvider.textScaleFactor),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: userProvider.themeMode,
            home: const SplashScreen(),
            routes: {
              LoginScreen.routeName: (_) => const LoginScreen(),
              SignupScreen.routeName: (_) => const SignupScreen(),
              HomeScreen.routeName: (_) => const HomeScreen(),
              WishlistScreen.routeName: (_) => const WishlistScreen(),
              WalletScreen.routeName: (_) => const WalletScreen(),
              NotificationsScreen.routeName: (_) => const NotificationsScreen(),
              AboutScreen.routeName: (_) => const AboutScreen(),
              ContactScreen.routeName: (_) => const ContactScreen(),
              AccessibilitySettingsScreen.routeName: (_) =>
                  const AccessibilitySettingsScreen(),
              AdminLoginScreen.routeName: (_) => const AdminLoginScreen(),
              AdminDashboardScreen.routeName: (_) =>
                  const AdminDashboardScreen(),
            },
          );
        },
      ),
    );
  }
}
