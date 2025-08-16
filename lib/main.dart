import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:vanguard/theme.dart';
import 'package:vanguard/core/di/service_locator.dart';
import 'package:vanguard/core/services/theme_service.dart';
import 'package:vanguard/presentation/pages/home/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await initServiceLocator();

  // Set up notification listeners
  AwesomeNotifications().setListeners(
    onActionReceivedMethod: NotificationController.onActionReceivedMethod,
    onNotificationCreatedMethod:
        NotificationController.onNotificationCreatedMethod,
    onNotificationDisplayedMethod:
        NotificationController.onNotificationDisplayedMethod,
    onDismissActionReceivedMethod:
        NotificationController.onDismissActionReceivedMethod,
  );

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  runApp(const DakkaApp());
}

class NotificationController {
  /// Called when notification is created
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {
    // Handle notification creation
  }

  /// Called when notification is displayed
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {
    // Handle notification display
  }

  /// Called when notification is dismissed
  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {
    // Handle notification dismissal
  }

  /// Called when user taps on notification
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    // Handle notification tap
    final payload = receivedAction.payload;
    if (payload != null) {
      final type = payload['type'];

      switch (type) {
        case 'reminder':
        case 'due':
          // Navigate to task details or show task
          break;
        case 'challenge':
          // Navigate to challenge view
          break;
        case 'challenge_progress':
          // Show challenge progress
          break;
        case 'challenge_success':
          // Show success celebration
          break;
      }
    }
  }
}

class DakkaApp extends StatelessWidget {
  const DakkaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sl<ThemeService>(),
      builder: (context, _) {
        final themeService = sl<ThemeService>();

        return MaterialApp(
          title: 'Dakka - دقة',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeService.themeMode,
          locale: themeService.locale,
          supportedLocales: const [
            Locale('ar'), // Arabic
            Locale('en'), // English
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          builder: (context, child) {
            return Directionality(
              textDirection:
                  themeService.isRTL ? TextDirection.rtl : TextDirection.ltr,
              child: child!,
            );
          },
          home: const HomePage(),
        );
      },
    );
  }
}
