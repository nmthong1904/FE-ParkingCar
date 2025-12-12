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
  final int? statusCode; // ⭐️ CẦN THÊM STATUS CODE ⭐️

  LoginResult({this.token, this.errorMessage, this.role, this.statusCode});

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

class SessionInvalidatedException implements Exception {
  final String message;
  SessionInvalidatedException(this.message);
  
  @override
  String toString() => 'SessionInvalidatedException: $message';
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

  Future<LoginResult> login(String username, String password, {bool force = false}) async {
  try {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      // Gửi tham số force lên Backend
      body: json.encode({'username': username, 'password': password, 'force': force}), 
    );

    // ⭐️ BƯỚC 1: XỬ LÝ 409 CONFLICT ⭐️
    if (response.statusCode == 409) {
      // Decode an toàn và trả về 409 để Frontend hiển thị Dialog
      try {
        final data = json.decode(response.body);
        final errorMessage = data['message'] ?? 'Xung đột session.';
        return LoginResult(errorMessage: errorMessage, statusCode: 409);
      } catch (e) {
        // Lỗi giải mã 409 body (Server không gửi JSON chuẩn)
        return LoginResult(errorMessage: 'Lỗi 409: Dữ liệu phản hồi không hợp lệ.', statusCode: 409);
      }
    }

    // ⭐️ BƯỚC 2: XỬ LÝ 200 SUCCESS hoặc 401/400 (Phải có body JSON) ⭐️
    if (response.body.isEmpty) {
        return LoginResult(errorMessage: 'Phản hồi trống từ máy chủ.', statusCode: response.statusCode);
    }

    final data = json.decode(response.body);
    
    if (response.statusCode == 200) {
      final token = data['token'];
      final role = data['role']; 
      if (token != null) {
        await _saveToken(token);
        return LoginResult(token: token, role: role, statusCode: 200); 
      }
      return LoginResult(errorMessage: 'Đăng nhập thành công nhưng thiếu token.', statusCode: 200); 
    } 
    
    // Xử lý các lỗi khác (401, 400, 500) sau khi đã decode
    else {
      final errorMessage = data['message'] ?? 'Tên đăng nhập hoặc mật khẩu không đúng.';
      return LoginResult(errorMessage: errorMessage, statusCode: response.statusCode); 
    }
    
  } catch (e) {
    print('Lỗi kết nối hoặc giải mã khi đăng nhập: $e');
    // Bắt lỗi mạng, lỗi giải mã JSON ban đầu, hoặc lỗi Server Crash (500)
    return LoginResult(errorMessage: 'Không thể kết nối hoặc lỗi server.', statusCode: 503); 
  }
}

  Future<LoginResult> forceLogin(String username, String password) async {
  try {
    final response = await http.post(
      Uri.parse('$_baseUrl/login/force'), // ⚠️ Đảm bảo endpoint này đúng: /auth/login/force hay /login/force?
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'password': password}),
    );
    
    final data = json.decode(response.body);

    if (response.statusCode == 200) {
      final token = data['token'];
      final role = data['role']; // Giả định backend trả về role
      if (token != null) {
        await _saveToken(token);
        // Thành công ép buộc đăng nhập
        return LoginResult(token: token, role: role, statusCode: 200); 
      }
      return LoginResult(errorMessage: 'Ép buộc đăng nhập thành công nhưng thiếu token.', statusCode: 200);
    } else {
      // Thất bại khi force login (ví dụ: sai mật khẩu trong quá trình nhập lại, hoặc lỗi server)
      final errorMessage = data['message'] ?? 'Lỗi khi ép buộc đăng nhập.';
      return LoginResult(errorMessage: errorMessage, statusCode: response.statusCode);
    }
  } catch (e) {
    print('Lỗi kết nối khi force login: $e');
    return LoginResult(errorMessage: 'Không thể kết nối đến máy chủ.', statusCode: 503);
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
      } 
      // ⭐️ BẮT 401 UNAUTHORIZED ⭐️
    else if (response.statusCode == 401) {
      final data = json.decode(response.body);
      final message = data['message'] ?? '';
      
      // So sánh với thông báo lỗi từ verifyToken của Backend
      if (message.contains('Phiên đăng nhập đã hết hạn hoặc bị đăng nhập từ thiết bị khác')) {
          // Xóa token cũ ngay lập tức
          await logout(); 
          
          // Ném Custom Exception để UI bắt và hiển thị Dialog
          throw SessionInvalidatedException(message); 
      }
      
      // Xử lý các lỗi 401 khác (ví dụ: Token hết hạn thông thường)
      return null; 
    }
    
    return null; // Xử lý các lỗi khác (500, etc.)
  } on SessionInvalidatedException catch (e) {
      // Re-throw để hàm gọi nó có thể bắt
      rethrow; 
  } catch (e) {
    print('Lỗi lấy thông tin Profile: $e');
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