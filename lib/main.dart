import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:parkingcar/ui/screen/main_screen.dart';
import 'firebase_options.dart';
// import 'ui/screen/home_screen.dart';
// import 'ui/screen/detail_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ĐÚNG: Options phải nằm TRONG hàm initializeApp
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kDebugMode) {
    // Chrome dùng 'localhost', Android dùng '10.0.2.2'
    String host = defaultTargetPlatform == TargetPlatform.android ? '10.0.2.2' : 'localhost';
    
    try {
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      
      FirebaseFirestore.instance.settings = Settings(
        host: '$host:8080',
        sslEnabled: false,
        persistenceEnabled: false,
      );
      print("✅ Đã kết nối Emulator tại: $host");
    } catch (e) {
      print("❌ Lỗi kết nối Emulator: $e");
    }
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Navigation Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: MainScreen(), // <<< KHỞI ĐỘNG VỚI MÀN HÌNH CHÍNH MỚI
    );
  }
}
