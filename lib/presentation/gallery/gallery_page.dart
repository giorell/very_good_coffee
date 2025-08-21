import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:very_good_coffee/domain/entities/coffee_image.dart';
import 'package:very_good_coffee/core/image_prefetch.dart';
import 'package:very_good_coffee/domain/repositories/alexflip_coffee_repository.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});
  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage>
    with AutomaticKeepAliveClientMixin {
  final _items = <CoffeeImage>[];
  final _controller = ScrollController();
  bool _loading = false;
  static const _batch = 12;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadMore();
    _controller.addListener(() {
      if (_controller.position.pixels >
          _controller.position.maxScrollExtent * 0.8) {
        _loadMore();
      }
    });
  }

  Future<void> _loadMore() async {
    if (_loading) return;
    _loading = true;
    final repo = context.read<AlexFlipCoffeeRepository>();
    final batch = await repo.fetchBatch(_batch);
    await warmCache(
      batch.map((e) => e.remoteUrl),
      maxConcurrent: 2,
      delayBetween: const Duration(milliseconds: 100),
    );
    if (!mounted) return;
    setState(() {
      _items.addAll(batch);
      _loading = false;
    });
  }

  Future<void> _refresh() async {
    setState(_items.clear);
    await _loadMore();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 1200
        ? 4
        : width >= 800
            ? 3
            : 2;
    final itemCount = _items.length + (_loading ? 1 : 0);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: GridView.builder(
        controller: _controller,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 9 / 14,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index >= _items.length) return const _GridSkeleton();
          final img = _items[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: img.remoteUrl.toString(),
              fit: BoxFit.cover,
              alignment: Alignment.center,
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
              placeholder: (_, __) => const _GridSkeleton(),
            ),
          );
        },
      ),
    );
  }
}

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
