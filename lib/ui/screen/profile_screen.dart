import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:parkingcar/services-api/auth_service.dart'; // Giả định AuthService có sẵn
import 'package:device_info_plus/device_info_plus.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isSaving = false;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _deviceName = "Đang tải..."; // ⭐️ Biến lưu tên thiết bị
  
  // Hàm giả định tải dữ liệu từ API
  // Hàm tải dữ liệu từ API
  // ⭐️ Hàm mới: Lấy thông tin thiết bị
  Future<void> _loadDeviceInfo() async {
  final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  String name = "Không xác định";

  try {
    // ⭐️ SỬ DỤNG KỸ THUẬT Platform.is... từ 'dart:io' (chỉ hoạt động trên Native Android/iOS/Desktop)
    // Nếu bạn đang chạy Web, bạn phải dùng thư viện dart:html
    
    // Nếu bạn đang chạy trên Emulator/Thiết bị Android
    if (defaultTargetPlatform == TargetPlatform.android) {
        final AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
        name = androidInfo.model ?? 'Android Device'; 
    } 
    // Nếu bạn đang chạy trên Emulator/Thiết bị iOS
    else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
        name = iosInfo.name ?? 'iOS Device';
    } 
    // Xử lý các trường hợp khác như Web, Linux, Windows, macOS
    else {
        // Ví dụ cơ bản cho các nền tảng còn lại
        name = 'Device: ${defaultTargetPlatform.toString().split('.').last}';
    }

  } catch (e) {
    name = 'Lỗi tải thông tin: $e';
    print('Lỗi tải device info: $e'); // ⭐️ In ra lỗi để debug
  }

  setState(() {
    _deviceName = name;
  });
}

Future<void> _fetchUserProfile() async {
  setState(() => _isLoading = true);

  // ⭐️ THAY ĐỔI CHÍNH Ở ĐÂY ⭐️
  final fetchedProfile = await _authService.fetchUserProfile();
  // ⭐️ ********************* ⭐️

  if (fetchedProfile != null) {
    setState(() {
        _userProfile = fetchedProfile;
        // ⭐️ BƯỚC QUAN TRỌNG: Phải gán giá trị mới cho Controller
        _fullNameController.text = fetchedProfile.fullName; 
        _emailController.text = fetchedProfile.email;
        _phoneController.text = fetchedProfile.phone;
      });
    
  } else {
     // Xử lý trường hợp không tải được hồ sơ (ví dụ: hiển thị lỗi, đăng xuất)
     ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(content: Text('❌ Không thể tải thông tin người dùng.'), backgroundColor: Colors.red),);
  }
  
  setState(() {
    _isLoading = false;
  });
}

  // Hàm giả định lưu thông tin
  Future<void> _handleSaveProfile() async {
    if (_userProfile == null) return;

    setState(() => _isSaving = true);

    final updatedProfile = UserProfile(
      username: _userProfile!.username,
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
    );
    

    // TRONG THỰC TẾ, GỬI updatedProfile LÊN API
    // Ví dụ: final success = await _authService.updateUserProfile(updatedProfile);
    // await Future.delayed(const Duration(milliseconds: 1000)); 
    // ⭐️ GỌI API THỰC TẾ
    // ⭐️ BỎ DÒNG GIẢ LẬP: final success = true; 
    final success = await _authService.updateUserProfile(updatedProfile);

    setState(() => _isSaving = false);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Lưu thông tin thành công!'), backgroundColor: Colors.green),
      );
      // Cập nhật lại UI
      // ⭐️ GỌI LẠI HÀM FETCH ĐỂ TẢI DỮ LIỆU MỚI TỪ SERVER
      await _fetchUserProfile();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('❌ Lỗi khi lưu thông tin. Kiểm tra server.'), backgroundColor: Colors.red),
      );
    }
  }
  
  // Hàm Đăng xuất
  void _handleLogout() async {
    await _authService.logout();
    // Sau khi đăng xuất, cần gọi setState ở MainScreen (sẽ xử lý ở file MainScreen)
    // Hiện tại chỉ cần thông báo và để MainScreen tự re-render.
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã đăng xuất.'), backgroundColor: Colors.orange),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _loadDeviceInfo();
  }
  
  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin Tài khoản'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage('assets/default_avatar.png'), // Thay bằng ảnh thật
                    child: Icon(Icons.person, size: 60, color: Colors.white),
                    backgroundColor: Colors.blueGrey,
                  ),
                  const SizedBox(height: 30),

                  // Trường Tên đầy đủ
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Họ và Tên',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                      prefixIcon: Icon(Icons.badge),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Trường Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                      prefixIcon: Icon(Icons.email),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Trường Số điện thoại
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ⭐️ TRƯỜNG THÔNG TIN THIẾT BỊ (CHỈ ĐỌC)
                    TextFormField(
                      readOnly: true, // ⭐️ Đặt là chỉ đọc
                      initialValue: _deviceName, // ⭐️ Hiển thị tên thiết bị
                      decoration: const InputDecoration(
                        labelText: 'Thông tin Thiết bị',
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                        prefixIcon: Icon(Icons.devices),
                      ),
                    ),
                    const SizedBox(height: 40),

                  // Nút Lưu thông tin
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleSaveProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Lưu thông tin',
                              style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}