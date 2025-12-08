import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// Giả định file constants có định nghĩa 'authEndpoint'
import 'package:parkingcar/services-api/constants.dart'; 

const storage = FlutterSecureStorage();

// Đăng ký (Không thay đổi, chỉ cần isSuccess/errorMessage)
class RegisterResult {
  final bool isSuccess;
  final String? errorMessage;

  RegisterResult({required this.isSuccess, this.errorMessage});
}

// Định nghĩa một lớp để chứa kết quả Đăng nhập
class LoginResult {
  final String? token;
  final String? errorMessage;
  final String? role; // ✨ THÊM TRƯỜNG ROLE

  LoginResult({this.token, this.errorMessage, this.role});

  // Factory constructor cho thành công (nhận thêm role)
  factory LoginResult.success(String token, String role) {
    return LoginResult(token: token, errorMessage: null, role: role);
  }

  // Factory constructor cho thất bại/lỗi
  factory LoginResult.failure(String error) {
    return LoginResult(token: null, errorMessage: error, role: null);
  }
}

// Mô hình dữ liệu Người dùng cho Profile
class UserProfile {
  final String username;
  final String fullName;
  final String email;
  final String phone;   

  UserProfile({
    required this.username,
    required this.fullName,
    required this.email,
    required this.phone,
  });

  // Factory constructor để tạo đối tượng từ JSON response
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      // Sử dụng toán tử null-aware (??) để cung cấp giá trị mặc định là chuỗi rỗng
      username: json['username'] ?? '',
      fullName: json['fullName'] ?? '', 
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}

class AuthService {

  // Key để lưu token
  static const _tokenKey = 'jwt_token'; 
  final _storage = const FlutterSecureStorage();
  // Thay thế bằng URL API của Node.js Backend
  final String _baseUrl = "http://10.0.0.108:3000/api/auth"; 

  // === 2.1. Quản lý Token ===

  // Lấy token từ bộ nhớ an toàn
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Lưu token vào bộ nhớ an toàn
  Future<void> _saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

 // === 2.2. Đăng ký (Register) ===

  Future<RegisterResult> register(String username, String password, String confirmPassword, String email, String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
          'confirmPassword': confirmPassword,
          'email': email,
          'phone': phone,
          'full_name': 'New User' // Thêm trường full_name mặc định
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201) { // 201 Created
        // Đăng ký thành công, thường API trả về token ngay
        final token = data['token'];
        if (token != null) {
          await _saveToken(token);
        }
        return RegisterResult(isSuccess: true);
      } else {
        // Đăng ký thất bại
        return RegisterResult(isSuccess: false, errorMessage: data['message'] ?? 'Lỗi đăng ký không xác định.');
      }
    } catch (e) {
      print('Lỗi kết nối khi đăng ký: $e');
      return RegisterResult(isSuccess: false, errorMessage: 'Không thể kết nối đến máy chủ.');
    }
  }

   // === 2.3. Đăng nhập (Login) ===

  Future<LoginResult> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'password': password}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        final token = data['token'];
        if (token != null) {
          await _saveToken(token);
          // Trả về kết quả thành công với token
          return LoginResult(token: token); 
        }
        // Thiếu token trong response thành công
        return LoginResult(errorMessage: 'Đăng nhập thành công nhưng thiếu token.'); 
      } else {
        // Đăng nhập thất bại (Ví dụ: sai mật khẩu, 401 Unauthorized)
        final errorMessage = data['message'] ?? 'Tên đăng nhập hoặc mật khẩu không đúng.';
        return LoginResult(errorMessage: errorMessage); 
      }
    } catch (e) {
      print('Lỗi kết nối khi đăng nhập: $e');
      // Lỗi mạng hoặc server không phản hồi
      return LoginResult(errorMessage: 'Không thể kết nối đến máy chủ.');
    }
  }

  // Hàm đọc Role đã lưu (MỚI)
  Future<String?> getUserRole() async {
    return await storage.read(key: 'user_role');
  }

   // === 2.4. Đăng xuất (Logout) ===

  Future<void> logout() async {
    // Xóa token khỏi bộ nhớ an toàn
    await _storage.delete(key: _tokenKey);
  }

  // === 2.5. Lấy Profile (Fetch Profile - Mã đã có) ===

  // Tải thông tin Profile từ Backend (Được bảo vệ bằng Token)
  Future<UserProfile?> fetchUserProfile() async {
  final token = await getToken();
  if (token == null) {
    print('DEBUG: Không tìm thấy Token. Chưa đăng nhập hoặc Token đã bị xóa.');
    return null;
  }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Gửi token để xác thực
        },
      );

     if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('DEBUG: Profile tải thành công. Data: $data');
        return UserProfile.fromJson(data); 
      } else if (response.statusCode == 401) {
        print('DEBUG: Lỗi 401 - Token hết hạn/không hợp lệ.');
        await logout();
        return null;
      } else {
        // Xử lý các lỗi khác (404, 500)
        print('DEBUG: Lỗi Status Code ${response.statusCode}. Body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('DEBUG: LỖI KHI FETCH PROFILE (Mạng/JSON Parsing): $e');
      return null;
    }
    
  }

  // === 2.6. updateUserProfile 
  Future<bool> updateUserProfile(UserProfile updatedProfile) async {
    final token = await getToken();
    if (token == null) return false;

    try {
        final response = await http.patch( // Hoặc PUT, tùy thuộc vào Backend
            Uri.parse('$_baseUrl/profile/update'), // Endpoint API Backend
            headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
            },
            body: json.encode({
                // Chỉ gửi các trường cần cập nhật
                'fullName': updatedProfile.fullName,
                'email': updatedProfile.email,
                'phone': updatedProfile.phone,
            }),
        );

        if (response.statusCode == 200) {
            return true;
        } else {
            print('Lỗi cập nhật Profile: ${response.body}');
            return false;
        }
    } catch (e) {
        print('Lỗi mạng khi cập nhật profile: $e');
        return false;
    }
}
  
}