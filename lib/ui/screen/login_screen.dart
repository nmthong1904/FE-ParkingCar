import 'package:flutter/material.dart';
import 'package:parkingcar/services-api/auth_service.dart'; // Đảm bảo import đúng đường dẫn
import 'package:parkingcar/ui/screen/register_screen.dart';
import 'main_screen.dart'; // Đảm bảo import đúng đường dẫn màn hình Detail của bạn

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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

  // Tách logic chuyển hướng thành công ra hàm riêng
  void _onLoginSuccess() {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Đăng nhập thành công!'), backgroundColor: Colors.green)
      );
      
      // CHUYỂN HƯỚNG SANG MÀN HÌNH CHÍNH
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
  }

  // ⭐️ HÀM HIỂN THỊ HỘP THOẠI XÁC NHẬN (MỚI) ⭐️
  void _showSessionConflictDialog(String username, String password) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Xác nhận Đăng nhập'),
        content: const Text(
            'Tài khoản này đang hoạt động trên thiết bị khác. Bạn có muốn đăng nhập và đăng xuất thiết bị cũ không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // Hủy
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Đóng hộp thoại
                setState(() => _isLoading = true);
                final forceResult = await _authService.login(username, password, force: true); 

                setState(() => _isLoading = false);
                
                if (forceResult.token != null) {
                    _onLoginSuccess();
                } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('❌ Lỗi: ${forceResult.errorMessage ?? 'Không thể ép buộc đăng nhập.'}'), backgroundColor: Colors.red),
                    );
                }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Đồng ý', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  // === HÀM XỬ LÝ ĐĂNG NHẬP ===
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

   if (result.token != null && result.statusCode == 200) {
      // 1. Đăng nhập THÀNH CÔNG (HTTP 200)
      _onLoginSuccess();

    } else if (result.statusCode == 409) {
      // 2. ❌ XUNG ĐỘT SESSION (HTTP 409)
      // Hiển thị hộp thoại xác nhận
      _showSessionConflictDialog(username, password);
      
    } else {
      // 3. ❌ THẤT BẠI KHÁC (400, 401, 500...)
      final errorMessage = result.errorMessage ?? 'Lỗi không xác định.';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Lỗi: $errorMessage'), backgroundColor: Colors.red)
      );
      print('Lỗi kết nối khi đăng ký: $result.statusCode');

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng Nhập'),
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
                labelText: 'Tên đăng nhập',
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

            // 3. Nút Đăng nhập
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
                        'Đăng nhập',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ),
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Chưa có tài khoản?',
                    style: TextStyle(fontSize: 16),
                  ),
                  TextButton(
                    onPressed: () {
                      // Chuyển sang màn hình Đăng ký và loại bỏ màn hình Đăng nhập
                      Navigator.pushReplacement( 
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
                    },
                    child: const Text(
                      'Đăng ký',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueAccent),
                    ),  
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}