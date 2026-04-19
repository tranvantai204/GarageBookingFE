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
import 'screens/chat_screen_with_online_call.dart';
import 'package:ha_phuong_app/providers/socket_provider.dart';
import 'services/push_notification_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/navigation_service.dart';
import 'screens/voice_call_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushNotificationService.initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: TripProvider()),
        ChangeNotifierProvider.value(value: BookingProvider()),
        ChangeNotifierProvider.value(value: UserProvider()),
        ChangeNotifierProvider.value(value: ChatProvider()),
        ChangeNotifierProvider(create: (_) => SocketProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GarageBooking - Nhà xe Hà Phương',
      debugShowCheckedModeBanner: false,
      navigatorKey: NavigationService.navigatorKey,
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('vi'), Locale('en')],
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/trips': (context) => const MainNavigationScreen(),
        '/trip_detail': (context) => const TripDetailScreen(),
        '/booking_history': (context) => const BookingHistoryScreen(),
        '/create_trip': (context) => const CreateTripScreen(),
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
