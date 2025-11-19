import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:parkingcar/services-api/constants.dart'; // Import file constants

const storage = FlutterSecureStorage();

class AuthService {
  
  // Hàm xử lý Đăng nhập và lưu JWT Token
  Future<String?> login(String username, String password) async {
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
      );

      if (response.statusCode == 200) {
        // Đăng nhập thành công!
        final data = jsonDecode(response.body);
        final token = data['token'];
        
        // 🔑 LƯU TOKEN AN TOÀN
        await storage.write(key: 'jwt_token', value: token);
        
        print('✅ Đăng nhập thành công, Token đã lưu.');
        return token; // Trả về token
      } else {
        // Đăng nhập thất bại (401 Unauthorized, 400 Bad Request)
        final errorData = jsonDecode(response.body);
        return errorData['message'] ?? 'Đăng nhập thất bại.'; 
      }
    } catch (e) {
      print('Lỗi kết nối mạng: $e');
      return 'Lỗi kết nối: Không thể truy cập server.';
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