import 'dart:async';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

Future<void> warmCache(
  Iterable<Uri> urls, {
  int maxConcurrent = 2,
  Duration delayBetween = const Duration(milliseconds: 120),
  int maxRetries = 3,
}) async {
  final cm = DefaultCacheManager();
  final list = urls.toList();
  var index = 0;

  Future<void> worker() async {
    while (true) {
      // All done
      if (index >= list.length) break;

      // Grab next URL (single isolate, so this is safe enough)
      final current = list[index++];
      final url = current.toString();

      int attempt = 0;
      var backoff = const Duration(milliseconds: 200);

      while (true) {
        try {
          // This stores the file in the shared cache used by CachedNetworkImage
          await cm.downloadFile(url);
          break; // success
        } on HttpExceptionWithStatus catch (e) {
          // Retry only for transient server/ratelimit errors
          final code = e.statusCode;
          final retryable = code == 429 ||
              code == 500 ||
              code == 502 ||
              code == 503 ||
              code == 504;
          if (retryable && attempt < maxRetries) {
            attempt++;
            await Future.delayed(backoff);
            backoff *= 2; // exponential backoff
            continue;
          }
          // Non-retryable or too many attempts — skip
          break;
        } catch (_) {
          if (attempt >= maxRetries) break;
          attempt++;
          await Future.delayed(backoff);
          backoff *= 2;
        }
      }

      // Gentle gap between requests to avoid bursts
      if (delayBetween > Duration.zero) {
        await Future.delayed(delayBetween);
      }
    }
  }

  // Small worker pool limits concurrency.
  final workers = List.generate(maxConcurrent, (_) => worker());
  await Future.wait(workers);
}
