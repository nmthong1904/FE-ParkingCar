// lib/screens/MainScreen.dart

import 'package:flutter/material.dart';
import 'package:parkingcar/ui/screen/cart_screen.dart';
// Import các màn hình con sẽ là các tab
import 'package:parkingcar/ui/screen/detail_screen.dart';
import 'package:parkingcar/ui/screen/home_screen.dart';
import 'package:parkingcar/ui/screen/register_screen.dart';
// import 'package:parkingcar/ui/screen/FavoriteScreen.dart'; // Giả định có màn hình Yêu thích
// import 'package:parkingcar/ui/screen/ProfileScreen.dart'; // Giả định có màn hình Tài khoản

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // 1. Quản lý Index của tab đang chọn
  int _selectedIndex = 0;

  // 2. Danh sách các màn hình con (các tab)
  // Đặt DetailScreen (trước là List Pokemon) làm tab đầu tiên
  final List<Widget> _screens = [
    const HomeScreen(), // Tab 1: Trang chủ
    const DetailScreen(), // Tab 2: Yêu thích (List Pokemon)
    const CartScreen(), // Tab 3: Giỏ hàng
    const RegisterScreen(), // Tab 4: Tài khoản
  ];

  // 3. Hàm xử lý khi người dùng chọn tab mới
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 4. Hiển thị màn hình con tương ứng với index đang chọn
      body: IndexedStack(index: _selectedIndex, children: _screens),

      // 5. Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Yêu thích',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Giỏ hàng',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
        ],
        currentIndex: _selectedIndex, // Đánh dấu tab đang hoạt động
        selectedItemColor: Colors.blue, // Thay thế bằng AppColors.primary
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped, // Gọi hàm khi tab được nhấn
      ),
    );
  }
}
