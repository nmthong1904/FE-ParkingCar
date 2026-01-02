import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:parkingcar/ui/screen/main_screen.dart';
import 'firebase_options.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Thêm import này
// import 'ui/screen/home_screen.dart';
// import 'ui/screen/detail_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kDebugMode) {
    String host = defaultTargetPlatform == TargetPlatform.android ? '10.0.2.2' : 'localhost';
    
    try {
      // 1. Kết nối Auth
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      
      // 2. Kết nối Firestore
      FirebaseFirestore.instance.settings = Settings(
        host: '$host:8080',
        sslEnabled: false,
        persistenceEnabled: false,
      );

      // 3. QUAN TRỌNG: Kết nối Storage (Thiếu dòng này sẽ gây lỗi 404 khi upload)
      await FirebaseStorage.instance.useStorageEmulator(host, 9199);

      print("✅ Đã kết nối đầy đủ Auth, Firestore, Storage tại: $host");
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
