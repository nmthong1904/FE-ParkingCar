import 'package:flutter/material.dart';
import 'package:parkingcar/services-api/auth_service.dart'; // Đảm bảo import đúng đường dẫn
import 'detail_screen.dart'; // Đảm bảo import đúng đường dẫn màn hình Detail của bạn

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;


  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // === HÀM XỬ LÝ ĐĂNG KÝ ===
  void _handleLogin() async {
    setState(() {
      _isLoading = true;

    });

    final username = _usernameController.text;
    final password = _passwordController.text;

    // Gọi hàm login từ AuthService
    // final result = await _authService.login(username, password);
    final LoginResult result = await _authService.login(username, password); // Code mới

    setState(() {
      _isLoading = false;
    });

    // Kiểm tra kết quả
    if (result.token != null) {
      // Giả định Token dài hơn 50 ký tự -> ĐĂNG NHẬP THÀNH CÔNG
      
      // Hiển thị thông báo và chuyển hướng
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Đăng ký thành công!'), backgroundColor: Colors.green)
      );
      
      // CHUYỂN HƯỚNG SANG MÀN HÌNH DETAIL
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DetailScreen()), // Thay bằng màn hình Detail của bạn
      );
    } else {
      // ❌ THẤT BẠI: Lỗi mạng, mật khẩu sai, hoặc lỗi khác
      final errorMessage = result.errorMessage ?? 'Lỗi không xác định.';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Lỗi: $errorMessage'), backgroundColor: Colors.red)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Kiểm tra kết nối Backend',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // 1. Trường Username
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Tên đăng ký',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Trường Password
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 24),

            // 3. Nút Đăng ký
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.blueAccent,
                ),
                child: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Đăng ký',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}