import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:very_good_coffee/domain/entities/coffee_image.dart';

class CoffeeCard extends StatelessWidget {
  const CoffeeCard({super.key, required this.image});

  final CoffeeImage image;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dpr = MediaQuery.of(context).devicePixelRatio;
        final targetWidth =
            (constraints.maxWidth * dpr).clamp(360.0, 1600.0).toInt();

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.48),
                blurRadius: 15,
                offset: const Offset(5, 10),
              ),
            ],
            color: Theme.of(context).colorScheme.surface,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: CachedNetworkImage(
              imageUrl: image.remoteUrl.toString(),
              imageBuilder: (context, provider) => Image(
                image: ResizeImage(provider, width: targetWidth),
                fit: BoxFit.cover,
                alignment: Alignment.center,
                gaplessPlayback: true,
                filterQuality: FilterQuality.low,
              ),
              placeholder: (_, __) => const _Skeleton(),
              errorWidget: (_, __, ___) => const Center(
                child: Text('Could not load image'),
              ),
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
            ),
          ),
        );
      },
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black12,
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }
}
