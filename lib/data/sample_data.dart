// file: lib/data/sample_data.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'product_model.dart'; // Đảm bảo import Product Model

// ---  HÀM GỌI POKÉAPI (Dữ liệu động) ---

Future<List<Product>> fetchPokemons({int offset = 0, int limit = 8}) async {
  // 1. GỌI API ĐẦU TIÊN: Lấy danh sách tên và URL
  final url = "https://pokeapi.co/api/v2/pokemon?offset=$offset&limit=$limit";
  final res = await http.get(Uri.parse(url));

  if (res.statusCode != 200) {
    throw Exception('Failed to load initial Pokemon list');
  }

  final json = jsonDecode(res.body);
  final List results = json["results"];

  List<Product> pokemons = [];

  // Sử dụng Future.wait để thực hiện các cuộc gọi chi tiết song song
  final List<Future<Product>> fetchDetailsFutures = results.map((item) async {
    final name = item["name"];
    final id = results.indexOf(item) + offset + 1; // ID là index + offset + 1
    final detailUrl = item["url"]; // URL chi tiết của từng Pokemon

    // 2. GỌI API THỨ HAI: Lấy thông tin chi tiết (types)
    final detailRes = await http.get(Uri.parse(detailUrl));
    if (detailRes.statusCode != 200) {
      // Xử lý lỗi hoặc trả về một Product không đầy đủ
      return Product(
        name: name.toUpperCase(),
        description: "Error loading details",
        imageUrl: "",
        typeAvatarUrl: "",
        types: [], // Thêm trường types
        generation: "", // Thêm trường generation
      );
    }
    
    final detailJson = jsonDecode(detailRes.body);
    
    // --- Lấy HỆ (TYPES) ---
    final List typesData = detailJson["types"];
    final List<String> types = typesData.map<String>((typeInfo) {
      return typeInfo["type"]["name"];
    }).toList();

    // --- Lấy GENERATION ---
    // Để lấy generation, bạn cần gọi API Species của Pokemon đó.
    final speciesUrl = detailJson["species"]["url"];
    final speciesRes = await http.get(Uri.parse(speciesUrl));

    String generation = "N/A";
    if (speciesRes.statusCode == 200) {
      final speciesJson = jsonDecode(speciesRes.body);
      // Generation nằm trong trường "generation" của species
      generation = speciesJson["generation"]["name"] ?? "N/A";
      // Chuyển đổi từ 'generation-x' thành 'Generation X'
      generation = generation.replaceAll('generation-', 'Generation ').toUpperCase();
    }
    // Đặt hàm này trong file helper hoặc ngay trước hàm fetchPokemons

    // 3. TẠO MODEL PRODUCT ĐẦY ĐỦ
    return Product(
      name: name.toUpperCase(),
      description: types.join('/').toUpperCase(), // Cập nhật mô tả
      imageUrl:
          "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png",
      typeAvatarUrl: "",
      types: types, // Thêm dữ liệu hệ
      generation: generation, // Thêm dữ liệu thế hệ
    );
  }).toList();
  // Chờ tất cả các Futures hoàn thành
  pokemons = await Future.wait(fetchDetailsFutures);

  return pokemons;
}

// file: lib/data/sample_data.dart hoặc helper file

String getTypeIconPath(String typeName) {
  final normalizedType = typeName.toLowerCase();
  // Trả về đường dẫn asset cục bộ
  // Ví dụ: assets/type_icons/grass.png
  return 'assets/$normalizedType.png'; 
}