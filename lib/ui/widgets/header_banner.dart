import 'package:flutter/material.dart';
import 'package:parkingcar/style/app_colors.dart'; // Đường dẫn tới file màu của bạn

class HeaderBanner extends StatelessWidget {
  final String title; // cho phép truyền tiêu đề động
  final double height;
  final Color? color;
  final Widget? child; // có thể thêm nội dung khác như hình ảnh, icon...

  const HeaderBanner({
    super.key,
    this.title = 'Ưu đãi hôm nay 🚗',
    this.height = 160,
    this.color,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Nền banner
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: color ?? AppColors.primary,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
        ),

        // Nội dung (text hoặc widget tuỳ chọn)
        Positioned.fill(
          child: Align(
            alignment: Alignment.center,
            child: child ??
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
          ),
        ),
      ],
    );
  }
}
