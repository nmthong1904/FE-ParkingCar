import 'package:flutter/material.dart';
import 'package:parkingcar/services-api/auth_service.dart'; // Đảm bảo import đúng đường dẫn
import 'login_screen.dart'; // Đảm bảo import đúng đường dẫn màn hình Detail của bạn

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController(); // ✨ THÊM MỚI

  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose(); // ✨ Cập nhật dispose
    super.dispose();
  }

  // === HÀM XỬ LÝ ĐĂNG KÝ MỚI ===
  void _handleRegister() async {
    // ✨ Đổi tên hàm
    setState(() {
      _isLoading = true;
    });

    final username = _usernameController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text; // ✨ Lấy giá trị

    // 1. Kiểm tra xác nhận mật khẩu
    if (password != confirmPassword) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Lỗi: Mật khẩu và xác nhận mật khẩu không khớp.'),
          backgroundColor: Colors.orange,
        ),
      );
      return; // Dừng lại nếu không khớp
    }

    // 2. Gọi hàm register từ AuthService (cần phải tạo hàm này trong AuthService)
    final RegisterResult result = await _authService.register(
      username,
      password,
    ); // ✨ SỬ DỤNG HÀM REGISTER

    setState(() {
      _isLoading = false;
    });

    // 3. Kiểm tra kết quả
    if (result.isSuccess) {
      // Giả định RegisterResult có trường isSuccess
      // ✅ ĐĂNG KÝ THÀNH CÔNG

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đăng ký thành công!'),
          backgroundColor: Colors.green,
        ),
      );

      // CHUYỂN HƯỚNG SANG MÀN HÌNH DETAIL (hoặc màn hình Login)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } else {
      // ❌ THẤT BẠI: Lỗi mạng, username đã tồn tại, hoặc lỗi khác
      final errorMessage =
          result.errorMessage ?? 'Lỗi không xác định trong quá trình đăng ký.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Lỗi: $errorMessage'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký'), // Đã là Đăng ký rồi
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // ... (Phần Text, SizedBox) ...

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
            const SizedBox(height: 16), // ✨ THÊM KHOẢNG CÁCH
            // 3. Trường Confirm Password
            TextFormField(
              // ✨ TRƯỜNG MỚI
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Xác nhận Mật khẩu',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.check_circle_outline),
              ),
            ),
            const SizedBox(height: 24),

            // 4. Nút Đăng ký
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : _handleRegister, // ✨ Gọi _handleRegister
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.blueAccent,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
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
