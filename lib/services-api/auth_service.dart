import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:parkingcar/services-api/constants.dart'; // Import file constants

const storage = FlutterSecureStorage();

// Định nghĩa một lớp để chứa kết quả (Token HOẶC Lỗi)
class LoginResult {
  final String? token;
  final String? errorMessage;

  LoginResult({this.token, this.errorMessage});

  // Factory constructor cho thành công
  factory LoginResult.success(String token) {
    return LoginResult(token: token, errorMessage: null);
  }

  // Factory constructor cho thất bại/lỗi
  factory LoginResult.failure(String error) {
    return LoginResult(token: null, errorMessage: error);
  }
}

class AuthService {
  
  // Hàm xử lý Đăng nhập và lưu JWT Token
  Future<LoginResult> login(String username, String password) async {
  final url = '$authEndpoint/login';

    try {
    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'username': username,
        'password': password,
      }),
    ).timeout(const Duration(seconds: 5), onTimeout: () {
      throw TimeoutException('Yêu cầu hết thời gian chờ: Server không phản hồi.');
    });

    if (response.statusCode == 200) {
      // ✅ THÀNH CÔNG: LƯU VÀ TRẢ VỀ TOKEN
      final data = jsonDecode(response.body);
      final token = data['token'];
      
      await storage.write(key: 'jwt_token', value: token);
      print('✅ Đăng nhập thành công, Token đã lưu.');
      
      return LoginResult.success(token);
    } else {
      // ❌ THẤT BẠI TỪ SERVER (401, 400 - Mật khẩu/Tài khoản sai)
      final errorData = jsonDecode(response.body);
      final errorMessage = errorData['message'] ?? 'Lỗi đăng nhập không xác định.';
      
      return LoginResult.failure(errorMessage);
    }
  } 
  on TimeoutException {
    // ❌ LỖI MẠNG: TIMEOUT (Server Tắt/Mạng kém)
    return LoginResult.failure('Lỗi kết nối: Server mất quá nhiều thời gian để phản hồi (Timeout).');
  } 
  on Exception catch (e) {
    // ❌ LỖI MẠNG: SOCKET EXCEPTION (Server Tắt/Địa chỉ sai)
    print('Lỗi kết nối mạng: $e');
    return LoginResult.failure('Lỗi kết nối: Server không hoạt động hoặc địa chỉ API sai.');
  }
}

  // Hàm đọc Token đã lưu (dùng để xác thực các request sau này)
  Future<String?> getToken() async {
    return await storage.read(key: 'jwt_token');
  }
  
  // Hàm Đăng xuất (xóa token)
  Future<void> logout() async {
    await storage.delete(key: 'jwt_token');
  }
}