import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../core/constants/app_colors.dart';
import 'rating_stars.dart';

class BusinessCard extends StatelessWidget {
  final String title;
  final String description;
  final String imageUrl;
  final Uint8List? imageBytes;
  final bool imageIsIllustrative;
  final double rating;
  final VoidCallback onTap;

  const BusinessCard({
    super.key,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.imageBytes,
    this.imageIsIllustrative = false,
    required this.rating,
    required this.onTap,
  });

  Widget _buildBusinessImage(String url) {
    late final Widget image;
    if (imageBytes != null && imageBytes!.isNotEmpty) {
      image = Image.memory(
        imageBytes!,
        width: 90,
        height: 90,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildImageFallback(),
      );
    } else if (url.isEmpty) {
      image = _buildImageFallback();
    } else {
      image = url.startsWith('assets/')
          ? Image.asset(
              url,
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildImageFallback(),
            )
          : Image.network(
              url,
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildImageFallback(),
            );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          image,
          if (imageIsIllustrative)
            Container(
              margin: const EdgeInsets.all(4),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Ilustrativa',
                style: TextStyle(color: Colors.white, fontSize: 8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageFallback() {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.store_rounded,
        size: 45,
        color: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            _buildBusinessImage(imageUrl),

            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  RatingStars(rating: rating),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(color: AppColors.greyText),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
