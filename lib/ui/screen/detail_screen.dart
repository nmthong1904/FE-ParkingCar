// file: lib/ui/detail_screen.dart

import 'package:flutter/material.dart';
import 'package:parkingcar/data/sample_data.dart'; // Chứa các hàm fetch...
import 'package:parkingcar/data/product_model.dart';
import 'package:parkingcar/style/app_colors.dart'; // Giả định AppColors có sẵn
import 'package:parkingcar/ui/screen/card_item.dart'; // Giả định HeaderBanner có sẵn

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  
  final ScrollController _scrollController = ScrollController();
  final List<Product> _pokemons = [];
  bool _isLoading = false;
  int _offset = 0;
  final int _limit = 8; // Số Pokémon mỗi lần load
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchPokemons();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _fetchPokemons();
    }
  }

  Future<void> _fetchPokemons() async {
    setState(() => _isLoading = true);
    try {
      final newPokemons = await fetchPokemons(offset: _offset, limit: _limit);
      setState(() {
        _offset += newPokemons.length;
        _pokemons.addAll(newPokemons);
        if (newPokemons.length < _limit) _hasMore = false;
      });
    } catch (e) {
      // Xử lý lỗi nếu cần
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('List Pokemon'),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
     body:  CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3/4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildProductCard(_pokemons[index]),
                childCount: _pokemons.length,
              ),
            ),
          ),

          if (_isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  // 🔹 Product Card (Render từng item)
  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        // Khi click vào item, chuyển đến màn hình chi tiết
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CardItem(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Hình ảnh sản phẩm/Pokémon
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                child: Image.network(
                  product.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.error_outline, size: 40)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    product.generation,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                        Row(
                          children: product.types.map((type) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 3),
                              child: Image.asset(
                                getTypeIconPath(type),
                                width: 16,
                                height: 16,
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.description, style: const TextStyle(fontSize: 12, color: Colors.blue)),
                        ],
                      ), 
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}