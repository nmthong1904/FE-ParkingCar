// product_model.dart
import 'package:parkingcar/data/sample_data.dart'; // Chứa các hàm fetch...
// file: product_model.dart (Phần đã chỉnh sửa)

class Product {
  // ... (Định nghĩa lớp không đổi)
  final String name;
  final String description;
  final String imageUrl;
  final String typeAvatarUrl;
  final List<String> types; // Đây là List<String>
  final String generation; // Đây là String

  Product({
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.typeAvatarUrl,
    required this.types,
    required this.generation,
  });

    // Factory Constructor đã được chỉnh sửa
    factory Product.fromPokemonJson(Map<String, dynamic> json, {required String generationData}) {
    // 1. Lấy Tên
    final String pokemonName = (json['name'] as String).toUpperCase();

    // 2. Lấy Hình ảnh
    final String officialArtworkUrl = json['sprites']['other']['official-artwork']['front_default'] ?? 
                                      json['sprites']['front_default'] ?? 
                                      'https://placehold.co/120x150/f0f0f0/000000?text=No+Image';

    // 3. Lấy Hệ (Type) và tạo List<String>
    final List typesJson = json['types'] as List;
    final List<String> typesList = typesJson.map<String>((typeInfo) {
      return (typeInfo['type']['name'] as String); // GIỮ CHỮ THƯỜNG để dùng trong hàm ánh xạ URL
    }).toList();
    
    // Lấy Type chính (Type đầu tiên)
    final String primaryType = typesList.isNotEmpty ? typesList[0] : 'unknown';
    
    // --- Lấy URL Avatar Type ---
    final String typeAvatarUrl = getTypeIconPath(primaryType);
    final String typesDescription = 'Hệ: ${typesList.join(' / ')}';

    return Product(
      name: pokemonName,
      description: typesDescription,
      imageUrl: officialArtworkUrl,
      
      // Dùng ID Pokémon làm avatar
      typeAvatarUrl: typeAvatarUrl, 
      
      // Gán List<String> vào trường types
      types: typesList, 
      
      // Dữ liệu generation phải được truyền vào (vì nó cần 1 API call khác)
      generation: generationData, 
    );
  }
}