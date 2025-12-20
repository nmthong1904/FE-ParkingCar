import 'package:flutter/material.dart';
import 'package:parkingcar/services-api/auth_service.dart';
import 'package:parkingcar/ui/screen/register_screen.dart';
import 'main_screen.dart';

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

  void _onLoginSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Đăng nhập thành công!'), backgroundColor: Colors.green)
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  // Giữ nguyên Dialog cũ nhưng gọi login thực tế từ Firebase
  void _showSessionConflictDialog(String email, String password) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Xác nhận Đăng nhập'),
        content: const Text('Tài khoản này đang hoạt động trên thiết bị khác. Bạn có muốn tiếp tục?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              setState(() => _isLoading = true);
              // Trong Firebase, signIn tự động đá session cũ ở mức độ Client
              final result = await _authService.login(email, password); 
              setState(() => _isLoading = false);
              if (result.token != null) _onLoginSuccess();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Đồng ý', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _handleLogin() async {
    setState(() => _isLoading = true);

    // Lưu ý: Firebase sử dụng Email để đăng nhập
    final email = _usernameController.text.trim();
    final password = _passwordController.text;

    final LoginResult result = await _authService.login(email, password);

    setState(() => _isLoading = false);

    if (result.token != null && result.statusCode == 200) {
      _onLoginSuccess();
    } else if (result.statusCode == 409) {
      _showSessionConflictDialog(email, password);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Lỗi: ${result.errorMessage ?? 'Sai tài khoản hoặc mật khẩu'}'), backgroundColor: Colors.red)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng Nhập'), backgroundColor: Colors.blueAccent),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Đăng nhập', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Tên đăng nhập', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), backgroundColor: Colors.blueAccent),
                child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Đăng nhập', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Chưa có tài khoản?'),
                TextButton(
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                  child: const Text('Đăng ký', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}