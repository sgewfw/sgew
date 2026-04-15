// lib/features/begehung/widgets/cached_image_widget.dart
// Zentrales Widget für Netzwerk-Bilder.
// Für Caching: flutter pub add cached_network_image
// Dann die CachedNetworkImage-Imports einkommentieren.

import 'package:flutter/material.dart';
import '../../../constants/suewag_colors.dart';

// TODO: Einkommentieren wenn cached_network_image installiert:
// import 'package:cached_network_image/cached_network_image.dart';

class CachedImageWidget extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const CachedImageWidget({
    super.key, required this.imageUrl,
    this.fit = BoxFit.cover, this.width, this.height, this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: Mit cached_network_image ersetzen wenn Package installiert
    final image = Image.network(
      imageUrl, fit: fit, width: width, height: height,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          color: const Color(0xFFF0F1F3),
          child: Center(child: CircularProgressIndicator(
            strokeWidth: 2, color: SuewagColors.primary,
            value: progress.expectedTotalBytes != null
                ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes! : null,
          )),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFFF0F1F3),
        child: const Center(child: Icon(Icons.broken_image_outlined, size: 32, color: Color(0xFFBBC0C7))),
      ),
    );
    if (borderRadius != null) return ClipRRect(borderRadius: borderRadius!, child: image);
    return image;
  }
}
