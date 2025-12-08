import 'package:flutter/material.dart';
import 'package:parkingcar/services-api/auth_service.dart'; // Đảm bảo import đúng đường dẫn
import 'login_screen.dart'; // Đảm bảo import đúng đường dẫn màn hình Login của bạn

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  
  // Controllers cho 5 trường dữ liệu
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController(); 
  final TextEditingController _emailController = TextEditingController(); 
  final TextEditingController _phoneController = TextEditingController(); 

  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // === HÀM XỬ LÝ ĐĂNG KÝ MỚI ===
  void _handleRegister() async {
    setState(() {
      _isLoading = true;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    // 1. Kiểm tra xác nhận mật khẩu tại Frontend (Nên có)
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

    // 2. Gọi hàm register từ AuthService (TRUYỀN ĐỦ 5 THAM SỐ)
    final RegisterResult result = await _authService.register(
      username,
      password,
      confirmPassword, // ✨ THAM SỐ MỚI
      email, // ✨ THAM SỐ MỚI
      phone, // ✨ THAM SỐ MỚI
    ); 

    setState(() {
      _isLoading = false;
    });

    // 3. Kiểm tra kết quả
    if (result.isSuccess) {
      // ✅ ĐĂNG KÝ THÀNH CÔNG
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đăng ký thành công!'),
          backgroundColor: Colors.green,
        ),
      );

      // CHUYỂN HƯỚNG SANG MÀN HÌNH Login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } else {
      // ❌ THẤT BẠI
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
        title: const Text('Đăng ký Tài khoản'), 
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Tạo tài khoản mới',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
              const SizedBox(height: 32),

              // 1. Trường Username
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Tên đăng ký',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 16), 
              
              // 3. Trường Confirm Password
              TextFormField(
                controller: _confirmPasswordController, // ✅ ĐÃ SỬA CONTROLLER
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Xác nhận Mật khẩu',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                  prefixIcon: Icon(Icons.check_circle_outline),
                ),
              ),
              const SizedBox(height: 16),

              // 4. Trường Email
              TextFormField(
                controller: _emailController, // ✅ ĐÃ SỬA CONTROLLER
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16), 

              // 5. Trường Phone
              TextFormField(
                controller: _phoneController, // ✅ ĐÃ SỬA CONTROLLER
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 32),

              // 6. Nút Đăng ký
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister, 
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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
                          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
               // 7. Chuyển sang màn hình Đăng nhập
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Đã có tài khoản?',
                    style: TextStyle(fontSize: 16),
                  ),
                  TextButton(
                    onPressed: () {
                      // Chuyển sang màn hình Đăng nhập và loại bỏ màn hình Đăng ký
                      Navigator.pushReplacement( 
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    child: const Text(
                      'Đăng nhập',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueAccent),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}