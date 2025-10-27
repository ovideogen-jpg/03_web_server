import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class ManualFirebaseOptions {
  static const apiKey = "AIzaSyCkbBKnFz3_XLVZolhzC89kEnBst-GTQPA";
  static const authDomain = "o3-gen.firebaseapp.com";
  static const databaseURL = "https://o3-gen-default-rtdb.firebaseio.com";
  static const projectId = "o3-gen";
  static const storageBucket = "o3-gen.appspot.com";
  static const messagingSenderId = "245728314587";
  static const appId = "1:245728314587:web:9bbbd18693ae05438fe";
  static const measurementId = "G-ZS4NQGKK8E";
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // ✅ Check if Firebase is already initialized
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: ManualFirebaseOptions.apiKey,
          appId: ManualFirebaseOptions.appId,
          messagingSenderId: ManualFirebaseOptions.messagingSenderId,
          projectId: ManualFirebaseOptions.projectId,
          authDomain: ManualFirebaseOptions.authDomain,
          storageBucket: ManualFirebaseOptions.storageBucket,
          databaseURL: ManualFirebaseOptions.databaseURL,
          measurementId: ManualFirebaseOptions.measurementId,
        ),
      );
      print("✅ Firebase connected successfully");
    } else {
      print("⚠️ Firebase already initialized, skipping...");
    }
  } catch (e) {
    print("❌ Firebase connection failed: $e");
  }

  // ✅ SharedPreferences logic
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? emailid = prefs.getString('saved_email');

  String initialRoute = (emailid == null) ? 'login' : 'home';

  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Image Animation Generator",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      routes: {
        'login': (context) => AnimationHome(),
        'home': (context) => AnimationHome(),
      },
      initialRoute: initialRoute,
    );
  }
}
