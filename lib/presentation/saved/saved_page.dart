import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:very_good_coffee/domain/repositories/alexflip_coffee_repository.dart';
import 'package:very_good_coffee/domain/entities/coffee_image.dart';
import 'package:very_good_coffee/presentation/brew_swipe/bloc/brew_swipe_bloc.dart';

class SavedPage extends StatefulWidget {
  const SavedPage({super.key});
  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Future<void> _delete(CoffeeImage img) async {
    final repo = context.read<AlexFlipCoffeeRepository>();
    repo.removeFavoriteById(img.id);
    await DefaultCacheManager().removeFile(img.remoteUrl.toString());
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocListener<BrewSwipeBloc, BrewSwipeState>(
      listenWhen: (prev, curr) => prev.current?.id != curr.current?.id,
      listener: (context, state) {
        if (mounted) setState(() {});
      },
      child: Builder(builder: (context) {
        final repo = context.read<AlexFlipCoffeeRepository>();
        final items = repo.favorites;

        if (items.isEmpty) {
          return const Center(child: Text('No saved images yet'));
        }

        final w = MediaQuery.of(context).size.width;
        final cols = w >= 1200
            ? 4
            : w >= 800
                ? 3
                : 2;

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 9 / 14,
          ),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final img = items[i];
            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    key: ValueKey('saved_${img.id}'),
                    imageUrl: img.remoteUrl.toString(),
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                    placeholder: (_, __) => const DecoratedBox(
                      decoration: BoxDecoration(color: Colors.black12),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.black54,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _delete(img),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child:
                              Icon(Icons.delete_outline, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
