import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/homepage.dart';
import 'screens/camera_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/records_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bread Classifier',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF57C00), // warm orange
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFDF3E8), // warm cream
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/camera': (context) => const CameraScreen(),
        '/analytics': (context) => const AnalyticsScreen(),
        '/records': (context) => const RecordsScreen(),
      },
    );
  }
}
