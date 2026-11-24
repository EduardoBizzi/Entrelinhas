import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 56});
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Entrelinhas, sua biblioteca pessoal',
    child: ClipRRect(
      borderRadius: BorderRadius.circular(size * .25),
      child: Image.asset(
        'assets/brand/icon.png',
        width: size,
        height: size,
        errorBuilder: (_, _, _) => Container(
          width: size,
          height: size,
          color: AppTheme.forest,
          child: Icon(
            Icons.auto_stories_rounded,
            color: Colors.white,
            size: size * .6,
          ),
        ),
      ),
    ),
  );
}
