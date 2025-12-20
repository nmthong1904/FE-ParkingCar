import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Để dùng kDebugMode

// --- 1. MODEL DỮ LIỆU ---
class UserProfile {
  final String uid;
  final String username;
  final String fullName;
  final String email;
  final String phone;

  UserProfile({
    required this.uid,
    required this.username,
    required this.fullName,
    required this.email,
    required this.phone,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      username: data['username'] ?? '',
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'fullName': fullName,
      'email': email,
      'phone': phone,
    };
  }
}

// Kết quả đăng nhập tương đương với cấu trúc cũ của bạn
class LoginResult {
  final String? token;
  final String? errorMessage;
  final int? statusCode;

  LoginResult({this.token, this.errorMessage, this.statusCode});
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AuthService() {
    // === 2. CẤU HÌNH FIREBASE EMULATOR ===
    // Tự động trỏ về Emulator nếu đang chạy ở mode Debug
    if (kDebugMode) {
      String host = "10.0.2.2"; // Mặc định cho Android Emulator
      // Nếu bạn dùng máy ảo iOS hoặc Web, có thể đổi thành 'localhost'
      
      try {
        _auth.useAuthEmulator(host, 9099);
        _db.useFirestoreEmulator(host, 8080);
        print("DEBUG: Đã kết nối tới Firebase Emulator ($host)");
      } catch (e) {
        print("DEBUG: Emulator đã được cấu hình trước đó.");
      }
    }
  }

  // Lấy Token (Firebase quản lý tự động, nhưng vẫn trả về nếu bạn cần)
  Future<String?> getToken() async {
    return await _auth.currentUser?.getIdToken();
  }

  // === 3. ĐĂNG KÝ (Sử dụng Firebase Auth + Firestore) ===
  Future<bool> register(String username, String password, String email, String phone) async {
    try {
      // 1. Tạo tài khoản trong Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Lưu thông tin bổ sung vào Firestore (Thay cho PostgreSQL)
      if (result.user != null) {
        await _db.collection('users').doc(result.user!.uid).set({
          'username': username,
          'email': email,
          'phone': phone,
          'fullName': 'New User',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return true;
    } catch (e) {
      print('Lỗi Đăng ký Firebase: $e');
      return false;
    }
  }


  // Biến cờ để bỏ qua kiểm tra ngay sau khi đăng nhập
  bool isInitializingSession = false;  
  // === 4. ĐĂNG NHẬP ===
  Future<LoginResult> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
     if (result.user != null) {
        // Đánh dấu đây là phiên vừa đăng nhập để tránh "tự đá mình"
        isInitializingSession = true; 

        // SỬ DỤNG CHUNG HÀM getUniqueDeviceId
        String deviceId = await getUniqueDeviceId();
        
        await _db.collection('users').doc(result.user!.uid).update({
          'lastDeviceId': deviceId,
          'lastLogin': FieldValue.serverTimestamp(),
        });
        
        return LoginResult(token: await result.user?.getIdToken(), statusCode: 200);
      }
      return LoginResult(errorMessage: "Lỗi đăng nhập", statusCode: 401);
    } catch (e) {
      return LoginResult(errorMessage: e.toString(), statusCode: 500);
    }
  }

  // === 5. LẤY PROFILE (TỪ FIRESTORE) ===
  Future<UserProfile?> fetchUserProfile() async {
    User? user = _auth.currentUser;
    if (user == null) return null;

    try {
      DocumentSnapshot doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Lỗi lấy Profile Firestore: $e');
      return null;
    }
  }

  // === 6. CẬP NHẬT PROFILE ===
  Future<bool> updateUserProfile(UserProfile profile) async {
    try {
      await _db.collection('users').doc(profile.uid).update({
        'fullName': profile.fullName,
        'email': profile.email,
        'phone': profile.phone,
      });
      return true;
    } catch (e) {
      print('Lỗi cập nhật Profile Firestore: $e');
      return false;
    }
  }

  // === 7. ĐĂNG XUẤT ===
  Future<void> logout() async {
    await _auth.signOut();
  }
//   // Hàm bổ trợ để lấy ID duy nhất của thiết bị
//   Future<String> _getDeviceId() async {
//   if (kDebugMode) {
//     // Trong mode Debug, bạn có thể cộng thêm tên model để phân biệt các máy ảo
//     final deviceInfo = DeviceInfoPlugin();
//     if (Platform.isAndroid) {
//       final info = await deviceInfo.androidInfo;
//       return "${info.id}_${info.model}_${info.device}"; // Kết hợp ID + Model (ví dụ: QM1A_Pixel_7)
//     }
//   }
  
//   // Logic thực tế cho Production
//   final deviceInfo = DeviceInfoPlugin();
//   if (Platform.isAndroid) {
//     final androidInfo = await deviceInfo.androidInfo;
//     return androidInfo.id; 
//   } else if (Platform.isIOS) {
//     final iosInfo = await deviceInfo.iosInfo;
//     return iosInfo.identifierForVendor ?? "unknown_ios";
//   }
//   return "unknown_device";
// }

  // HÀM KIỂM TRA THIẾT BỊ HỢP LỆ (Quan trọng)
  Future<bool> isCurrentDeviceValid() async {
    User? user = _auth.currentUser;
    if (user == null) return false;

    String currentId = await getUniqueDeviceId();
    DocumentSnapshot doc = await _db.collection('users').doc(user.uid).get();
    
    if (doc.exists) {
      String? savedId = (doc.data() as Map<String, dynamic>)['lastDeviceId'];
      return savedId == currentId;
    }
    return false;
  }
 // HÀM DUY NHẤT ĐỂ LẤY ID - Dùng cho cả Login và Kiểm tra
  Future<String> getUniqueDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (kIsWeb) return "web_browser";

    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      // Kết hợp các trường này để đảm bảo Pixel 4 và Pixel 7 khác ID nhau trên Emulator
      return "${info.id}_${info.model}_${info.device}"; 
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      return info.identifierForVendor ?? "unknown_ios";
    }
    return "unknown_device";
  }

  // Stream để các màn hình lắng nghe
  Stream<DocumentSnapshot> userStream() {
    String uid = _auth.currentUser?.uid ?? '';
    return _db.collection('users').doc(uid).snapshots();
  }
}