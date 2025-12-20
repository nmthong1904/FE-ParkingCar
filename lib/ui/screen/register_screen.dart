import 'package:flutter/material.dart';
import 'package:parkingcar/services-api/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController(); 
  final TextEditingController _emailController = TextEditingController(); 
  final TextEditingController _phoneController = TextEditingController(); 

  bool _isLoading = false;

  void _handleRegister() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Mật khẩu không khớp'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isLoading = true);

    // Gọi hàm register mới của AuthService (Firebase)
    final success = await _authService.register(
      _usernameController.text.trim(),
      _passwordController.text,
      _emailController.text.trim(),
      _phoneController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Đăng ký thành công!'), backgroundColor: Colors.green));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Đăng ký thất bại. Email có thể đã tồn tại.'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký Tài khoản'), backgroundColor: Colors.blueAccent),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text('Tạo tài khoản mới', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            const SizedBox(height: 32),
            _buildField(_usernameController, 'Tên người dùng', Icons.person),
            const SizedBox(height: 16),
            _buildField(_emailController, 'Email', Icons.email, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            _buildField(_phoneController, 'Số điện thoại', Icons.phone, keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            _buildField(_passwordController, 'Mật khẩu', Icons.lock, obscure: true),
            const SizedBox(height: 16),
            _buildField(_confirmPasswordController, 'Xác nhận mật khẩu', Icons.check_circle_outline, obscure: true),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), backgroundColor: Colors.blueAccent),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Đăng ký', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool obscure = false, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: const OutlineInputBorder()),
    );
  }
}