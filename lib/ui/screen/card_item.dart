import 'package:flutter/material.dart';
import 'package:parkingcar/data/product_model.dart';
import 'package:parkingcar/data/sample_data.dart';
import 'package:parkingcar/style/app_colors.dart';

class CardItem extends StatelessWidget {
  final Product product;

  const CardItem({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Hình ảnh sản phẩm
            Image.network(
              product.imageUrl,
              width: double.infinity,
              
            ),
            const SizedBox(height: 16),
            // Tên sản phẩm
            Text(
              product.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Mô tả sản phẩm
            Text(
              product.description,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            // Thông tin người tạo sản phẩm
            Row(
              children: [
                  Row(
                    children: product.types.map((type) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Image.asset(
                          getTypeIconPath(type),
                          width: 32,
                          height: 32,
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.typeAvatarUrl, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    Text(product.generation, style: const TextStyle(fontSize: 12, color: Colors.blue)),
                  ],
                ),
                
              ],
            ),
          ],
        ),
      ),
    );
  }
}

