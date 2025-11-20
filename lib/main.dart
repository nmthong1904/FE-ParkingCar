import 'package:flutter/material.dart';
import 'package:parkingcar/ui/screen/main_screen.dart';
// import 'ui/screen/home_screen.dart';
// import 'ui/screen/detail_screen.dart';

void main() {
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
