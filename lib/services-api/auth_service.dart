import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';

// ===== MODEL =====
class UserProfile {
  final String uid;
  final String username;
  final String fullName;
  final String email;
  final String phone;
  final String? avatarUrl;

  UserProfile({
    required this.uid,
    required this.username,
    required this.fullName,
    required this.email,
    required this.phone,
    this.avatarUrl,
  });

  // BỔ SUNG HÀM NÀY ĐỂ FIX LỖI KHI CẬP NHẬT ẢNH
  UserProfile copyWith({
    String? avatarUrl,
    String? fullName,
    String? phone,
  }) {
    return UserProfile(
      uid: this.uid,
      username: this.username,
      fullName: fullName ?? this.fullName,
      email: this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

 factory UserProfile.fromFirestore(DocumentSnapshot doc) {
  // Thêm kiểm tra dữ liệu tồn tại
  final data = doc.data() as Map<String, dynamic>? ?? {}; 
  
  return UserProfile(
    uid: doc.id,
    username: data['username'] ?? "",
    fullName: data['fullName'] ?? "New User",
    email: data['email'] ?? "",
    phone: data['phone'] ?? "",
    // Quan trọng: avatarUrl phải cho phép null để không lỗi khi chưa có ảnh
    avatarUrl: data['avatarUrl'], 
  );
}
}

class LoginResult {
  final String? token;
  final String? errorMessage;
  final int? statusCode;

  LoginResult({this.token, this.errorMessage, this.statusCode});
}

late FirebaseFunctions _functions;

// ===== SERVICE =====
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  AuthService() {
  if (kDebugMode) {
    final host = kIsWeb ? 'localhost' : '10.0.2.2';

    _functions = FirebaseFunctions.instanceFor(
      region: 'us-central1',
    );
    _functions.useFunctionsEmulator(host, 5001);

    _auth.useAuthEmulator(host, 9099);
    _db.useFirestoreEmulator(host, 8080);

    debugPrint('🔥 Firebase Emulator connected ($host)');
  } else {
    _functions = FirebaseFunctions.instanceFor(
      region: 'us-central1',
    );
  }
}

  // ===== REGISTER =====
  Future<bool> register(
      String username, String password, String email, String phone) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Gửi email xác nhận ngay khi đăng ký
      // await result.user!.sendEmailVerification();

      await _db.collection('users').doc(result.user!.uid).set({
        'username': username.toLowerCase(),
        'email': email,
        'phone': phone,
        'fullName': 'New User',
        'createdAt': FieldValue.serverTimestamp(),
        'isVerified': false, 
      });

      return true;
    } catch (e) {
      debugPrint('Register error: $e');
      return false;
    }
  }

  // ===== LOGIN =====
  Future<LoginResult> login(String identifier, String password) async {
    try {
      String email = identifier;

      // 1. Kiểm tra nếu identifier không phải email, tìm email từ username trong Firestore
      if (!identifier.contains('@')) {
        final query = await _db
            .collection('users')
            .where('username', isEqualTo: identifier.toLowerCase())
            .limit(1)
            .get();

        if (query.docs.isEmpty) {
          return LoginResult(errorMessage: "Username không tồn tại", statusCode: 404);
        }
        email = query.docs.first.get('email');
      }

      // 2. Đăng nhập bằng Email tìm được
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 3. Cập nhật Device ID như cũ
      final deviceId = await getUniqueDeviceId();
      await _db.collection('users').doc(result.user!.uid).update({
        'lastDeviceId': deviceId,
        'lastLogin': FieldValue.serverTimestamp(),
      });

      return LoginResult(
        token: await result.user!.getIdToken(),
        statusCode: 200,
      );
    } catch (e) {
      return LoginResult(errorMessage: e.toString(), statusCode: 500);
    }
  }
  
  // ===== GỬI OTP QUA CLOUD FUNCTION =====
 // 1. Gửi Link xác thực Gmail (Native Firebase)
Future<bool> sendEmailVerification() async {
  try {
    final user = _auth.currentUser;
    if (user != null) {
      await user.sendEmailVerification();
      debugPrint('🔗 Link xác thực đã gửi. Kiểm tra Emulator UI (Tab Auth)');
      return true;
    }
    return false;
  } catch (e) {
    debugPrint('❌ Lỗi gửi link email: $e');
    return false;
  }
}

// 2. Gửi OTP cho Số điện thoại (Native Firebase)
Future<void> verifyPhoneNumber(
  String phoneNumber, {
  required Function(String) onCodeSent,
  required Function(String) onError,
}) async {
  // Tự động chuyển 09xxx thành +849xxx để tránh lỗi E.164
  String formattedPhone = phoneNumber;
  if (phoneNumber.startsWith('0')) {
    formattedPhone = '+84${phoneNumber.substring(1)}';
  } else if (!phoneNumber.startsWith('+')) {
    formattedPhone = '+$phoneNumber';
  }

  await _auth.verifyPhoneNumber(
    phoneNumber: formattedPhone,
    verificationCompleted: (PhoneAuthCredential credential) async {
      await _auth.currentUser?.linkWithCredential(credential);
    },
    verificationFailed: (FirebaseAuthException e) {
      // Đây chính là nơi bắt lỗi định dạng bạn đang gặp
      onError(e.message ?? 'Lỗi xác thực');
    },
    codeSent: (String verificationId, int? resendToken) {
      onCodeSent(verificationId);
      // SAU KHI DÒNG NÀY CHẠY: Hãy nhìn vào Tab LOGS trên trình duyệt của bạn
      debugPrint('📟 Đã gửi yêu cầu. Kiểm tra mã OTP tại Tab Logs của Emulator UI');
    },
    codeAutoRetrievalTimeout: (String verificationId) {},
  );
}

  // Hàm xác nhận mã sau khi bạn lấy mã từ Logs
  Future<bool> confirmPhoneOtp(String verificationId, String smsCode) async {
    try {
      AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await _auth.currentUser?.linkWithCredential(credential);

      // QUAN TRỌNG: Cập nhật đúng field 'isPhoneVerified'
      await _db.collection('users').doc(_auth.currentUser!.uid).update({
        'isPhoneVerified': true, 
        'phone': _auth.currentUser!.phoneNumber,
      });
      return true;
    } catch (e) {
      return false;
    }
  }
  // ===== XÁC THỰC OTP =====
  Future<bool> verifyOtp(String email, String otpCode) async {
    try {
      final result = await _functions.httpsCallable('verifyOtpCode').call({
        'email': email,
        'otp': otpCode,
      });

      if (result.data['success'] == true) {
        // Sau khi Cloud Function xác nhận OTP đúng, ta cập nhật Firestore
        final user = _auth.currentUser;
        if (user != null) {
          await _db.collection('users').doc(user.uid).update({
            'isVerified': true,
          });
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Lỗi xác thực OTP: $e');
      return false;
    }
  }

  // ===== DEVICE ID (AN TOÀN WEB) =====
  Future<String> getUniqueDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();

    if (kIsWeb) {
      final web = await deviceInfo.webBrowserInfo;
      return 'web_${web.browserName}_${web.userAgent.hashCode}';
    }

    final android = await deviceInfo.androidInfo;
    return '${android.id}_${android.model}_${android.device}';
  }

  // ===== CHECK DEVICE =====
  Future<bool> isCurrentDeviceValid() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final currentId = await getUniqueDeviceId();
    final doc = await _db.collection('users').doc(user.uid).get();

    return doc.exists &&
        (doc.data() as Map<String, dynamic>)['lastDeviceId'] == currentId;
  }

  // ===== PROFILE =====
  Future<UserProfile?> fetchUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _db.collection('users').doc(user.uid).get();
    return doc.exists ? UserProfile.fromFirestore(doc) : null;
  }

  Future<void> logout() => _auth.signOut();

  Future<void> updateEmailVerificationStatus(bool status) async {
  final user = _auth.currentUser;
    if (user != null) {
      await _db.collection('users').doc(user.uid).update({
        'isVerified': status,
      });
    }
  }

  Stream<DocumentSnapshot> userStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    // Sử dụng .snapshots() để nhận dữ liệu ngay lập tức và liên tục
    return _db.collection('users').doc(user.uid).snapshots();
  }
  Future<String?> getToken() async {
  return await _auth.currentUser?.getIdToken();
  }
  Future<bool> updateUserProfile(UserProfile profile) async {
    try {
      await _db.collection('users').doc(profile.uid).update({
        'fullName': profile.fullName,
        'email': profile.email,
        'phone': profile.phone,
      });
      return true;
    } catch (e) {
      debugPrint('Update profile error: $e');
      return false;
    }
  }

  String formatEmulatorUrl(String? url) {
  if (url == null) return "";
  
  // Nếu không phải là Emulator (production) thì giữ nguyên
  if (!url.contains('localhost') && !url.contains('10.0.2.2')) return url;

  if (kIsWeb) {
    // Nếu chạy Web, đổi 10.0.2.2 thành localhost
    return url.replaceAll('10.0.2.2', 'localhost');
  } else if (Platform.isAndroid) {
    // Nếu chạy Android, đổi localhost thành 10.0.2.2
    return url.replaceAll('localhost', '10.0.2.2');
  }
  
  return url;
}

  // Update user avatar
  Future<String?> uploadAvatar({File? imageFile, Uint8List? webImage}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Đường dẫn lưu trữ: avatars/uid.jpg
      final storageRef = _storage.ref().child('avatars').child('${user.uid}.jpg');

      // Tải lên dựa trên nền tảng (Web dùng putData, Mobile dùng putFile)
      if (kIsWeb && webImage != null) {
        await storageRef.putData(webImage);
      } else if (imageFile != null) {
        await storageRef.putFile(imageFile);
      } else {
        return null;
      }

      // Lấy URL sau khi upload thành công
      String downloadURL = await storageRef.getDownloadURL();

      // Cập nhật URL vào Firestore của user
      await _db.collection('users').doc(user.uid).update({
        'avatarUrl': formatEmulatorUrl(downloadURL),
      });

      return downloadURL;
    } catch (e) {
      debugPrint('Lỗi upload thực tế: $e');
      return null;
    }
  }
}