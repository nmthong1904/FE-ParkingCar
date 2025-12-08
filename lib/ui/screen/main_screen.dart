import 'package:flutter/material.dart';
import 'package:parkingcar/services-api/auth_service.dart'; // Import AuthService
import 'package:parkingcar/ui/screen/cart_screen.dart';
import 'package:parkingcar/ui/screen/detail_screen.dart';
import 'package:parkingcar/ui/screen/home_screen.dart';
import 'package:parkingcar/ui/screen/register_screen.dart';
import 'package:parkingcar/ui/screen/profile_screen.dart'; // Import màn hình Profile mới

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final AuthService _authService = AuthService(); // Khởi tạo AuthService
  int _selectedIndex = 0;

  // 2. Danh sách các màn hình con (các tab)
  // Lưu ý: Tab "Tài khoản" (index 3) sẽ được định nghĩa riêng trong build()
  final List<Widget> _screens = [
    const HomeScreen(), // Tab 1: Trang chủ
    const DetailScreen(), // Tab 2: Yêu thích
    const CartScreen(), // Tab 3: Giỏ hàng
    // Tab 4: Được thay thế bằng _buildAccountScreen() để kiểm tra trạng thái đăng nhập
  ];

  // 3. Hàm xử lý khi người dùng chọn tab mới
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // ✨ HÀM MỚI: Kiểm tra trạng thái đăng nhập và trả về màn hình phù hợp
  Widget _buildAccountScreen() {
    // Sử dụng FutureBuilder để đợi kết quả kiểm tra token
    // Mỗi khi AuthState thay đổi (Đăng nhập/Đăng xuất), MainScreen sẽ được build lại.
    return FutureBuilder<String?>(
      future: _authService.getToken(), // Giả định AuthService có hàm getToken()
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Đang chờ kiểm tra token
          return const Center(child: CircularProgressIndicator());
        }

        final token = snapshot.data;
        if (token != null && token.isNotEmpty) {
          // Đã đăng nhập: Hiển thị màn hình Profile
          // Key được thêm để ProfileScreen có thể được re-render khi đăng xuất
          return const ProfileScreen(key: ValueKey('ProfileScreen')); 
        } else {
          // Chưa đăng nhập: Hiển thị màn hình Đăng ký
          return const RegisterScreen(key: ValueKey('RegisterScreen'));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tạo danh sách màn hình hoàn chỉnh, bao gồm màn hình Tài khoản có điều kiện
    final allScreens = [..._screens, _buildAccountScreen()]; 

    return Scaffold(
      // 4. Hiển thị màn hình con tương ứng với index đang chọn
      body: IndexedStack(index: _selectedIndex, children: allScreens),

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