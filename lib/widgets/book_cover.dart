import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BookCover extends StatelessWidget {
  const BookCover({super.key, this.url, this.width = 56, this.height = 78});
  final String? url;
  final double width;
  final double height;
  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.forest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.menu_book_rounded,
        color: const Color(0xFFE6DBBD),
        size: width * .5,
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: url == null
          ? fallback
          : Image.network(
              url!,
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
              loadingBuilder: (_, child, progress) =>
                  progress == null ? child : fallback,
            ),
    );
  }
}
