import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final bool ignoreGestures;

  const RatingStars({
    super.key,
    required this.rating,
    this.ignoreGestures = true,
  });

  @override
  Widget build(BuildContext context) {
    return RatingBar.builder(
      initialRating: rating,
      minRating: 1,
      direction: Axis.horizontal,
      allowHalfRating: true,
      ignoreGestures: ignoreGestures,
      itemCount: 5,
      itemSize: 20,
      itemBuilder: (context, _) => const Icon(
        Icons.star,
        color: Colors.orange,
      ),
      onRatingUpdate: (value) {},
    );
  }
}