import 'package:flutter/material.dart';
// import 'detail_screen.dart';
// import 'login_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giỏ hàng')),
      body: Center(
           child: Text('Giỏ hàng'),
      ),
    );
  }
}
