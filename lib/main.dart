import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

/// 🔥 SPLASH SCREEN
import 'package:animated_splash_screen/animated_splash_screen.dart';

/// 🔥 HALAMAN (Sudah diubah ke HomePage)
import 'pages/home_page.dart'; // <--- Pastikan nama file & folder sesuai dengan lokasi HomePage kamu

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AnimatedSplashScreen(
        splash: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// 🔥 LOGO
            Image.asset(
              "assets/logo.jpg",
              width: 120,
            ),
            const SizedBox(height: 20),

            /// 🔥 JUDUL
            const Text(
              "SMART FARM CABAI",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),

            /// 🔥 SUBTITLE
            const Text(
              "IoT Monitoring System",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),

        /// 🔥 SETELAH SPLASH LANGSUNG KE HOME
        nextScreen: const HomePage(), // <--- Diubah dari LoginPage() ke HomePage()

        splashIconSize: 300,
        backgroundColor: Colors.black,
        duration: 3000,
        splashTransition: SplashTransition.fadeTransition,
      ),
    );
  }
}