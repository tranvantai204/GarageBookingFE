import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/trip_provider.dart';
import 'providers/booking_provider.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/trip_detail_screen.dart';
import 'screens/booking_history_screen.dart';
import 'screens/login_screen.dart';
import 'screens/create_trip_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TripProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
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
      title: 'Đặt xe Hà Phương',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/trips': (context) => MainNavigationScreen(),
        '/trip_detail': (context) => TripDetailScreen(),
        '/booking_history': (context) => BookingHistoryScreen(),
        '/create_trip': (context) => CreateTripScreen(),
      },
    );
  }
}
