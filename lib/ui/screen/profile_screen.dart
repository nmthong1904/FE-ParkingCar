import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parkingcar/services-api/auth_service.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:parkingcar/ui/screen/main_screen.dart'; // Thêm để check emailVerified

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  UserProfile? _userProfile;
  StreamSubscription? _userSubscription;
  Timer? _authTimer; // Timer để check trạng thái email liên tục (cho emulator link)
  
  bool _isLoading = true;
  bool _isSaving = false;
  String? _verificationId; // Lưu ID xác thực SDT

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  String _deviceName = "Đang tải...";
  String _platformName = '';
  bool _isEmailVerified = false;
  bool _isPhoneVerified = false; // Thêm biến này

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
    _startDeviceCheckListener();
    _startAuthStatusListener(); // Theo dõi trạng thái click link xác thực
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _authTimer?.cancel();
    super.dispose();
  }

  // Hàm che giấu thông tin
  String _maskValue(String value) {
    if (value.isEmpty) return "";
    // Nếu là email, ta có thể mask phần sau chữ @ hoặc sau 5 ký tự đầu
    if (value.length <= 5) return value;
    String prefix = value.substring(0, 5);
    return '$prefix' + '*' * (value.length - 5);
  }

  // Lắng nghe trạng thái link xác thực (Cực kỳ hữu ích cho Emulator)
  void _startAuthStatusListener() {
  FirebaseAuth.instance.userChanges().listen((user) async {
    if (user != null && user.emailVerified) {
      // Nếu Auth báo đã verify nhưng Firestore vẫn là false
      // thì tiến hành cập nhật Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'isVerified': true});
          
      print("✅ Đã đồng bộ trạng thái Verified vào Firestore");
    }
  });
}

  Future<void> _loadDeviceInfo() async {
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    String name = "Thiết bị Emulator";
    String platform = kIsWeb ? 'Web' : defaultTargetPlatform.name;
    try {
      if (!kIsWeb) {
        if (defaultTargetPlatform == TargetPlatform.android) {
          final info = await deviceInfoPlugin.androidInfo;
          name = info.model;
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          final info = await deviceInfoPlugin.iosInfo;
          name = info.name;
        }
      }
    } catch (_) {}
    if (mounted) setState(() { _deviceName = name; _platformName = platform; });
  }

  Future<void> _startDeviceCheckListener() async {
  // 1. Lấy Device ID của máy hiện tại trước
  final String currentDeviceId = await _authService.getUniqueDeviceId();

  // 2. Bắt đầu lắng nghe Stream
  _userSubscription = _authService.userStream().listen((snapshot) {
    if (!snapshot.exists || snapshot.data() == null) {
      debugPrint("Dữ liệu User không tồn tại trên Firestore!");
      setState(() => _isLoading = false);
      return;
    }

    final data = snapshot.data() as Map<String, dynamic>;
    final user = FirebaseAuth.instance.currentUser;

    // 3. KIỂM TRA CONFLICT DEVICE
    // Giả sử field trên Firestore là 'deviceId'
    String? cloudDeviceId = data['lastDeviceId'];
    if (cloudDeviceId != null && cloudDeviceId != currentDeviceId) {
      _showDeviceConflictDialog(); // Hiện Dialog cảnh báo
      return; // Dừng xử lý các bước load dữ liệu phía dưới
    }

    // 4. CẬP NHẬT GIAO DIỆN
    if (mounted) {
      setState(() {
        _userProfile = UserProfile.fromFirestore(snapshot);
        
        // Cập nhật trạng thái xác thực
        _isEmailVerified = data['isVerified'] ?? false || (user?.emailVerified ?? false);
        _isPhoneVerified = data['isPhoneVerified'] ?? false;

        // CHỈ cập nhật controller nếu người dùng chưa bắt đầu gõ (giữ dữ liệu cũ)
        // Hoặc nếu đây là lần đầu tiên load dữ liệu (_isLoading vẫn đang true)
        if (_isLoading) {
          _fullNameController.text = _userProfile?.fullName ?? "";
          
          _emailController.text = _isEmailVerified 
              ? _maskValue(_userProfile!.email) 
              : _userProfile!.email;
              
          _phoneController.text = _isPhoneVerified 
              ? _maskValue(_userProfile!.phone) 
              : _userProfile!.phone;
        }

        _isLoading = false; // Tắt vòng xoay loading
      });
    }
  }, onError: (error) {
    debugPrint("Lỗi Stream: $error");
    setState(() => _isLoading = false);
  });
}

  // ===== XỬ LÝ XÁC THỰC EMAIL (GỬI LINK) =====
  Future<void> _handleVerifyEmail() async {
    setState(() => _isSaving = true);
    // Bạn cần viết hàm sendEmailVerification trong AuthService trỏ vào _auth.currentUser.sendEmailVerification()
    bool success = await _authService.sendEmailVerification(); 
    setState(() => _isSaving = false);

    if (success) {
      Fluttertoast.showToast(
        msg: "🔗 Link xác thực đã gửi! Mở Emulator UI (4000) để click.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM, // Hiển thị ở dưới nhưng không đẩy layout
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  // ===== XỬ LÝ XÁC THỰC SĐT (GỬI OTP) =====
  Future<void> _handleVerifyPhone() async {
  final phone = _phoneController.text.trim();
  if (phone.isEmpty) return;

  await _authService.verifyPhoneNumber(
    phone,
    onCodeSent: (verificationId) {
      setState(() {
        _verificationId = verificationId;
      });
      // QUAN TRỌNG: Truyền tham số isPhone: true ở đây
      _showOtpInputDialog(phone, isPhone: true); 
    },
    onError: (error) { setState(() => _isSaving = false);
        Fluttertoast.showToast(
          msg: "❌ $error",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM, // Hiển thị ở dưới nhưng không đẩy layout
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
      );
    },
  );
}

  // ===== DIALOG NHẬP OTP CHO SĐT =====
  void _showOtpInputDialog(String target, {bool isPhone = false}) {
    List<TextEditingController> controllers = List.generate(6, (index) => TextEditingController());
    List<FocusNode> focusNodes = List.generate(6, (index) => FocusNode());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(isPhone ? 'Xác thực Số điện thoại' : 'Xác thực Email'),
        content: SizedBox(
          width: double.maxFinite, // Đảm bảo Row có không gian để giãn cách
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, // 1. GIÃN CÁCH CÁC Ô ĐỀU NHAU
            children: List.generate(6, (index) {
              return SizedBox(
                width: 40,
                height: 50,
                child: TextField(
                  controller: controllers[index],
                  focusNode: focusNodes[index],
                  autofocus: index == 0, // Tự động focus vào ô đầu tiên
                  keyboardType: TextInputType.number, // 2. HIỂN THỊ BÀN PHÍM SỐ
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  // Tăng cường hiển thị ký tự để không bị mất số
                  style: const TextStyle(
                    fontSize: 22, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.black
                  ),
                  decoration: InputDecoration(
                    counterText: "", 
                    contentPadding: EdgeInsets.zero,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    // Tự động chuyển ô khi nhập hoặc xóa
                    if (value.length == 1 && index < 5) {
                      focusNodes[index + 1].requestFocus();
                    } else if (value.isEmpty && index > 0) {
                      focusNodes[index - 1].requestFocus();
                    }
                  },
                ),
              );
            }),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('HỦY')),
         ElevatedButton(
            onPressed: () async {
              String fullOtp = controllers.map((e) => e.text).join();
              if (fullOtp.length < 6) return;

              bool success = false;
              if (isPhone) {
                // ĐÚNG: Xác thực SĐT qua Firebase Native
                if (_verificationId != null) {
                  success = await _authService.confirmPhoneOtp(_verificationId!, fullOtp);
                }
              } else {
                // ĐÚNG: Xác thực Email qua Cloud Function của bạn
                success = await _authService.verifyOtp(target, fullOtp);
              }

              if (success) {
                Navigator.pop(context);
                 Fluttertoast.showToast(
                    msg: "✅ Thành công!",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM, // Hiển thị ở dưới nhưng không đẩy layout
                    backgroundColor: Colors.green,
                    textColor: Colors.white,
                    fontSize: 16.0,
                );
              } else {
                 Fluttertoast.showToast(
                    msg: "❌ Mã không đúng",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM, // Hiển thị ở dưới nhưng không đẩy layout
                    backgroundColor: Colors.green,
                    textColor: Colors.white,
                    fontSize: 16.0,
                );
              }
            },
            child: const Text('XÁC NHẬN'),
          )
        ],
      ),
    );
  }

  Future<void> _handleSaveProfile() async {
    if (_userProfile == null) return;
    setState(() => _isSaving = true);

    // LOGIC KIỂM TRA:
    // Nếu text trong ô nhập giống với bản đã mask, nghĩa là người dùng không sửa.
    // Khi đó ta giữ nguyên giá trị cũ từ database (_userProfile!.email)
    
    String finalEmail = _emailController.text == _maskValue(_userProfile!.email)
        ? _userProfile!.email
        : _emailController.text;

    String finalPhone = _phoneController.text == _maskValue(_userProfile!.phone)
        ? _userProfile!.phone
        : _phoneController.text;

    final updated = UserProfile(
      avatarUrl: _userProfile!.avatarUrl,
      uid: _userProfile!.uid,
      username: _userProfile!.username,
      fullName: _fullNameController.text, // Họ tên lấy trực tiếp vì không mask
      email: finalEmail,
      phone: finalPhone,
    );
    final success = await _authService.updateUserProfile(updated);
    setState(() => _isSaving = false);
    if (success) {
        Fluttertoast.showToast(
           msg: "✅ Đã cập nhật thông tin",
           toastLength: Toast.LENGTH_SHORT,
           gravity: ToastGravity.BOTTOM, // Hiển thị ở dưới nhưng không đẩy layout
           backgroundColor: Colors.green,
           textColor: Colors.white,
           fontSize: 16.0,
      );
    }
  }

  Future<void> _pickImage() async {
  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _isSaving = true);
      
      String? url;
      if (kIsWeb) {
        Uint8List bytes = await image.readAsBytes();
        url = await _authService.uploadAvatar(webImage: bytes);
      } else {
        url = await _authService.uploadAvatar(imageFile: File(image.path));
      }

      if (url != null && mounted) {
        setState(() {
          _userProfile = _userProfile?.copyWith(avatarUrl: url); // Sử dụng copyWith đã thêm
          _isSaving = false;
        });
      }
    }
  }
  void _handleLogout() async {
    await _authService.logout();
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const MainScreen()), (route) => false);
  }

  void _showDeviceConflictDialog() {
    _userSubscription?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Thông báo'),
        content: const Text('Tài khoản đã đăng nhập ở thiết bị khác.'),
        actions: [TextButton(onPressed: _handleLogout, child: const Text('ĐỒNG Ý'))],
      ),
    );
  }
  void _showLogoutConfirmation() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Xác nhận'),
      content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản này không?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(), // Đóng Dialog nếu chọn Không
          child: const Text('HỦY'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(); // Đóng Dialog
            _handleLogout(); // Thực hiện đăng xuất
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('ĐĂNG XUẤT', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin Tài khoản')),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          // Sử dụng NetworkImage để tải ảnh từ URL
                          backgroundImage: _userProfile?.avatarUrl != null ? NetworkImage(_authService.formatEmulatorUrl(_userProfile!.avatarUrl)) : null,
                          child: _userProfile?.avatarUrl == null ? const Icon(Icons.person, size: 50) : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),                  
                  const SizedBox(height: 30),
                  _buildField(_fullNameController, 'Họ và Tên', Icons.badge),
                  const SizedBox(height: 20),
                  _buildVerifiedInput(
                    controller: _emailController, 
                    label: 'Email', 
                    icon: Icons.email, 
                    isVerified: _isEmailVerified, 
                    onVerify: _handleVerifyEmail
                  ),
                  const SizedBox(height: 20),
                  _buildVerifiedInput(
                    controller: _phoneController, 
                    label: 'Số điện thoại', 
                    icon: Icons.phone, 
                    isVerified: _isPhoneVerified, 
                    onVerify: _handleVerifyPhone
                  ),
                  const SizedBox(height: 20),
                  _buildReadOnlyField('$_platformName | $_deviceName', 'Thiết bị hiện tại', Icons.devices),
                  const SizedBox(height: 40),
                  _buildSaveButton(),
                  const SizedBox(height: 10),
                  SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:_showLogoutConfirmation,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 83, 83, 83), padding: const EdgeInsets.symmetric(vertical: 15)),
                        child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
                      ),
                    )
                 ],
              ),
            ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: const OutlineInputBorder()),
    );
  }

  Widget _buildReadOnlyField(String value, String label, IconData icon) {
    return TextFormField(
      initialValue: value,
      readOnly: true,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: const OutlineInputBorder()),
    );
  }

 Widget _buildVerifiedInput({required TextEditingController controller, required String label, required IconData icon, required bool isVerified, required VoidCallback onVerify}) {
    return TextFormField(
      controller: controller,
      readOnly: isVerified, // KHÓA CHỈNH SỬA NẾU ĐÃ XÁC THỰC
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        suffixIcon: isVerified 
          ? const Icon(Icons.verified, color: Colors.green)
          : TextButton(onPressed: onVerify, child: const Text('XÁC THỰC')),
        fillColor: isVerified ? Colors.grey[100] : null,
        filled: isVerified,
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _handleSaveProfile,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(vertical: 15)),
        child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Lưu thay đổi', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}