import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/trip_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/user_provider.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/trip_detail_screen.dart';
import 'screens/booking_history_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/create_trip_screen.dart';
import 'screens/chat_screen_with_online_call.dart'; // Use chat screen with online call
import 'package:ha_phuong_app/providers/socket_provider.dart';
import 'services/push_notification_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/navigation_service.dart';
import 'screens/voice_call_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushNotificationService.initialize();
  runApp(
    MultiProvider(
      providers: [
        // Lazy loading providers để tăng tốc startup
        ChangeNotifierProvider.value(value: TripProvider()),
        ChangeNotifierProvider.value(value: BookingProvider()),
        ChangeNotifierProvider.value(value: UserProvider()),
        ChangeNotifierProvider.value(value: ChatProvider()),
        ChangeNotifierProvider(create: (_) => SocketProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GarageBooking',
      navigatorKey: NavigationService.navigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue.shade600,
          brightness: Brightness.light,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('vi'), Locale('en')],
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/trips': (context) => MainNavigationScreen(),
        '/trip_detail': (context) => TripDetailScreen(),
        '/booking_history': (context) => BookingHistoryScreen(),
        '/create_trip': (context) => CreateTripScreen(),
        '/voice_call_entry': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map?;
          if (args == null) return const SizedBox.shrink();
          final channelName = args['channelName'] as String? ?? '';
          final callerName = args['callerName'] as String? ?? 'Người gọi';
          final callerRole = args['callerRole'] as String? ?? 'user';
          if (channelName.isEmpty) return const SizedBox.shrink();
          return VoiceCallScreen(
            channelName: channelName,
            targetUserName: callerName,
            targetUserRole: callerRole,
            isIncoming: true,
          );
        },
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/chat') {
          final args = settings.arguments as Map<String, dynamic>?;
          if (args != null) {
            return MaterialPageRoute(
              builder: (context) => ChatScreenWithOnlineCall(
                // Use ChatScreenWithOnlineCall
                chatRoomId: args['chatRoomId'],
                chatRoomName: args['chatRoomName'],
                targetUserName: args['targetUserName'],
                targetUserRole: args['targetUserRole'],
                targetUserId: args['targetUserId'],
              ),
            );
          }
        }
        return null;
      },
    );
  }
}
