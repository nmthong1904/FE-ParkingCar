import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:parkingcar/services-api/auth_service.dart';
import 'package:parkingcar/ui/screen/main_screen.dart';
import 'package:flutter/foundation.dart'; // Để dùng kIsWeb

class AddproductSreen extends StatefulWidget {
  const AddproductSreen({super.key});

  @override
  State<AddproductSreen> createState() => _AddproductState();
}

// Danh sách 5 loại sản phẩm cố định
final List<String> _categories = [
  'Xe sedan',
  'Xe SUV',
  'Xe bán tải',
  'Xe điện',
  'Phụ kiện xe'
];
String? _selectedCategory; // Biến lưu loại sản phẩm được chọn

class _AddproductState extends State<AddproductSreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  File? _image;
  bool _isUploading = false;
  Uint8List? _webImage; // Dùng cho Web (cần import 'dart:typed_data')


  // Hàm chọn ảnh từ thư viện
  Future<void> _pickImage() async {
  final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
  
  if (pickedFile != null) {
    if (kIsWeb) {
      // Trên Web: Phải đọc file thành bytes ngay lập tức
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _webImage = bytes;
      });
    } else {
      // Trên Android: Dùng File path bình thường
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }
}

 Future<void> _saveProduct() async {
  final AuthService _authService = AuthService();
  final User? user = FirebaseAuth.instance.currentUser;

  // Kiểm tra đăng nhập
  if (user == null) {
    Fluttertoast.showToast(msg: "Vui lòng đăng nhập!");
    return;
  }

  // Kiểm tra các trường dữ liệu trống
  if (_nameController.text.isEmpty ||
      _priceController.text.isEmpty ||
      _descriptionController.text.isEmpty ||
      (_image == null && _webImage == null) ||
      _selectedCategory == null) {
    Fluttertoast.showToast(msg: "Vui lòng nhập đầy đủ thông tin!", backgroundColor: Colors.orange);
    return;
  }

  setState(() => _isUploading = true);

  try {
    // --- BƯỚC MỚI: LẤY FULLNAME TỪ FIRESTORE ---
    String displayName = "Người dùng ẩn danh"; // Giá trị mặc định
    
    // Giả sử document ID trong collection 'users' trùng với user.uid của Firebase Auth
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (userDoc.exists && userDoc.data() != null) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      // Lấy trường 'fullname' từ tài liệu người dùng
      displayName = userData['fullname'] ?? "Không có tên";
    }
    // ------------------------------------------

    // Xử lý upload ảnh (giữ nguyên logic của bạn)
    String fileName = 'products/${DateTime.now().millisecondsSinceEpoch}.jpg';
    Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
    UploadTask uploadTask;
    if (kIsWeb) {
      uploadTask = storageRef.putData(_webImage!, SettableMetadata(contentType: 'image/jpeg'));
    } else {
      uploadTask = storageRef.putFile(_image!);
    }
    TaskSnapshot snapshot = await uploadTask;
    String rawUrl = await snapshot.ref.getDownloadURL();
    String finalImageUrl = _authService.formatEmulatorUrl(rawUrl);

    // LƯU SẢN PHẨM VÀO FIRESTORE
    await FirebaseFirestore.instance.collection('products').add({
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'price': double.parse(_priceController.text.trim()).toInt(), 
      'category': _selectedCategory,
      'imageUrl': finalImageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      // Thông tin người sở hữu
      'userId': user.uid,
      'userEmail': user.email,
      'phoneNumber': user.phoneNumber,
      'Owner': displayName, // Đây là biến fullname lấy từ Firestore
    });

    Fluttertoast.showToast(msg: "✅ Thêm sản phẩm thành công!", backgroundColor: Colors.green);

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScreen()), (route) => false);
    }
  } catch (e) {
    debugPrint("Lỗi: $e");
    Fluttertoast.showToast(msg: "❌ Lỗi: ${e.toString()}", backgroundColor: Colors.red);
  } finally {
    if (mounted) setState(() => _isUploading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm sản phẩm'),
        leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios), // Bạn có thể đổi icon tùy thích
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const MainScreen()), (route) => false);
          },
        ),
      ),
      body: _isUploading 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Ô chọn ảnh
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey),
                    ),
                   child: kIsWeb
                    ? (_webImage != null 
                        ? Image.memory(_webImage!, fit: BoxFit.cover) // Web dùng bộ nhớ byte
                        : const Icon(Icons.add_a_photo))
                    : (_image != null 
                        ? Image.file(_image!, fit: BoxFit.cover) // Android dùng tệp
                        : const Icon(Icons.add_a_photo)),
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Loại sản phẩm',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  },
                  validator: (value) => value == null ? 'Vui lòng chọn loại sản phẩm' : null,
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Tên sản phẩm', border: OutlineInputBorder()),
                ),
                 const SizedBox(height: 15),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Mô tả sản phẩm', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Giá sản phẩm', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveProduct,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    child: const Text('LƯU SẢN PHẨM', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}