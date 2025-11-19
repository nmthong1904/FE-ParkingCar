import 'package:flutter/material.dart';
import 'package:parkingcar/style/app_colors.dart';
import 'package:parkingcar/data/product_model.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final bool isFeatured;

  const ProductCard({super.key, required this.product, required this.isFeatured});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + tên người dùng
          Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundImage: NetworkImage(product.typeAvatarUrl),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.types.join(' / '),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text(product.generation ,
                      style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(
                            product.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.secondary,
                              child: Center(
                                child: Text(product.name,
                                    style: const TextStyle(color: Colors.black54)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (isFeatured)
                        Text(
                          product.description,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 15,
                  right: 15,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.5),
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
