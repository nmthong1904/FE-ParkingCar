import 'package:flutter/material.dart';
import 'package:parkingcar/services-api/auth_service.dart';
import 'package:parkingcar/ui/screen/addproduct_screen.dart';
import 'package:parkingcar/ui/screen/cart_screen.dart';
import 'package:parkingcar/ui/screen/detail_screen.dart';
import 'package:parkingcar/ui/screen/home_screen.dart';
import 'package:parkingcar/ui/screen/login_screen.dart';
import 'package:parkingcar/ui/screen/profile_screen.dart';

// import 'package:parkingcar/ui/screen/add_product_screen.dart'; // Màn hình mới bạn sẽ tạo

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;

  // Danh sách màn hình (Bỏ màn hình Profile ra khỏi mảng cố định để xử lý qua FutureBuilder)
  final List<Widget> _screens = [
    const HomeScreen(),
    const DetailScreen(),
    const CartScreen(),
  ];

  Widget _buildAccountScreen() {
    return FutureBuilder<String?>(
      future: _authService.getToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final token = snapshot.data;
        if (token != null && token.isNotEmpty) {
          return const ProfileScreen(key: ValueKey('ProfileScreen'));
        } else {
          return const LoginScreen(key: ValueKey('LoginScreen'));
        }
      },
    );
  }

  @override
Widget build(BuildContext context) {
  Widget currentScreen = _selectedIndex == 3 ? _buildAccountScreen() : _screens[_selectedIndex];

  return Scaffold(
    resizeToAvoidBottomInset: false, // Quan trọng: Tránh đẩy FAB khi có keyboard
    extendBody: true, // Quan trọng: Giúp FAB và BottomAppBar khớp nhau hơn
    body: currentScreen,

    floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    
    floatingActionButton: FloatingActionButton(
      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AddproductSreen())),
      backgroundColor: Colors.blue,
      shape: const CircleBorder(), // Đảm bảo nút luôn tròn
      child: const Icon(Icons.add, size: 28, color: Colors.white),
    ),

    bottomNavigationBar: BottomAppBar(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      height: 65,
      shape: const CircularNotchedRectangle(), // Tạo khe hở nhẹ cho FAB nếu muốn đẹp hơn
      notchMargin: 8.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTabItem(index: 0, icon: Icons.home, label: 'Trang chủ'),
          _buildTabItem(index: 1, icon: Icons.favorite, label: 'Yêu thích'),
          const SizedBox(width: 40), // Khoảng trống cho FAB
          _buildTabItem(index: 2, icon: Icons.shopping_cart, label: 'Giỏ hàng'),
          _buildTabItem(index: 3, icon: Icons.person, label: 'Tài khoản'),
        ],
      ),
    ),
  );
}

  // Widget con để tạo từng nút Tab
  Widget _buildTabItem({required int index, required IconData icon, required String label}) {
    bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.blue : Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}