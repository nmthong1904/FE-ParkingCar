import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:parkingcar/services-api/auth_service.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:parkingcar/ui/screen/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  UserProfile? _userProfile;
  // Thêm biến lưu trữ Subscription ở đầu class _ProfileScreenState
  StreamSubscription? _userSubscription;
  bool _isLoading = true;
  bool _isSaving = false;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String _deviceName = "Đang tải...";
  String _platformName = '';

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _loadDeviceInfo();
    _startDeviceCheckListener(); // Bắt đầu lắng nghe thiết bị
  }

  @override
  void dispose() {
    _userSubscription?.cancel(); // Quan trọng: Phải hủy lắng nghe khi thoát screen
    super.dispose();
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
  String currentDeviceId = await _authService.getUniqueDeviceId();

  _userSubscription = _authService.userStream().listen((snapshot) {
    if (snapshot.exists && snapshot.data() != null) {
      final data = snapshot.data() as Map<String, dynamic>;
      final String? lastDeviceId = data['lastDeviceId'];

      // NẾU ID TRÊN CLOUD KHÁC ID MÁY NÀY -> THÔNG BÁO VÀ ĐĂNG XUẤT
      if (lastDeviceId != null && lastDeviceId != currentDeviceId) {
        _showDeviceConflictDialog();
      } else {
        // Nếu trùng khớp thì cập nhật UI như bình thường
        setState(() {
          _userProfile = UserProfile.fromFirestore(snapshot);
          _fullNameController.text = _userProfile!.fullName;
          _emailController.text = _userProfile!.email;
          _phoneController.text = _userProfile!.phone;
          _isLoading = false;
        });
      }
    }
  });
}
void _showDeviceConflictDialog() {
  // Hủy lắng nghe ngay lập tức để tránh hiện nhiều Dialog
  _userSubscription?.cancel();

  showDialog(
    context: context,
    barrierDismissible: false, // Bắt buộc người dùng phải bấm nút
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning, color: Colors.orange),
          SizedBox(width: 10),
          Text('Thông báo'),
        ],
      ),
      content: const Text('Tài khoản của bạn vừa đăng nhập ở một thiết bị khác. Bạn sẽ bị đăng xuất khỏi thiết bị này.'),
      actions: [
        TextButton(
          onPressed: () => _handleLogout(),
          child: const Text('ĐỒNG Ý'),
        ),
      ],
    ),
  );
}

  Future<void> _fetchUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _authService.fetchUserProfile();
      if (profile != null) {
        setState(() {
          _userProfile = profile;
          _fullNameController.text = profile.fullName;
          _emailController.text = profile.email;
          _phoneController.text = profile.phone;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Lỗi tải Profile từ Firestore')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSaveProfile() async {
    if (_userProfile == null) return;
    setState(() => _isSaving = true);

    final updated = UserProfile(
      uid: _userProfile!.uid,
      username: _userProfile!.username,
      fullName: _fullNameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
    );

    final success = await _authService.updateUserProfile(updated);
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Đã cập nhật Firestore'), backgroundColor: Colors.green));
    }
  }

  void _handleLogout() async {
    await _authService.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin Tài khoản'),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _handleLogout)],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
                  const SizedBox(height: 30),
                  _buildField(_fullNameController, 'Họ và Tên', Icons.badge),
                  const SizedBox(height: 20),
                  _buildField(_emailController, 'Email', Icons.email, readOnly: true),
                  const SizedBox(height: 20),
                  _buildField(_phoneController, 'Số điện thoại', Icons.phone),
                  const SizedBox(height: 20),
                  TextFormField(
                    initialValue: '$_platformName | $_deviceName',
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Thiết bị hiện tại', prefixIcon: Icon(Icons.devices), border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleSaveProfile,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(vertical: 15)),
                      child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Lưu thay đổi', style: TextStyle(color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool readOnly = false}) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: const OutlineInputBorder()),
    );
  }
}