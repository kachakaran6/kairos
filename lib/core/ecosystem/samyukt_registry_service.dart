import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SamyuktAppStatus { published, comingSoon, unknown }

class SamyuktAppItem {
  const SamyuktAppItem({
    required this.id,
    required this.appName,
    required this.packageName,
    required this.description,
    required this.status,
    required this.iconUrl,
    required this.playStoreUrl,
    this.tagline,
    this.category,
    this.featured = false,
  });

  final String id;
  final String appName;
  final String packageName;
  final String description;
  final SamyuktAppStatus status;
  final String iconUrl;
  final String playStoreUrl;
  final String? tagline;
  final String? category;
  final bool featured;

  bool get isPublished => status == SamyuktAppStatus.published;
  bool get isComingSoon => status == SamyuktAppStatus.comingSoon;

  factory SamyuktAppItem.fromJson(
    Map<String, dynamic> json, {
    required String assetBase,
  }) {
    final rawStatus = (json['status'] as String? ?? '').trim().toLowerCase();
    final status = switch (rawStatus) {
      'production' || 'published' => SamyuktAppStatus.published,
      'coming_soon' || 'comingsoon' => SamyuktAppStatus.comingSoon,
      _ => SamyuktAppStatus.unknown,
    };

    final rawIcon = (json['iconUrl'] as String? ?? '').trim();
    final resolvedIcon = resolveAssetUrl(rawIcon, assetBase: assetBase);

    return SamyuktAppItem(
      id: (json['id'] as String? ?? '').trim(),
      appName: (json['appName'] as String? ?? json['name'] as String? ?? 'App')
          .trim(),
      packageName: (json['packageName'] as String? ?? '').trim(),
      description:
          (json['description'] as String? ?? json['tagline'] as String? ?? '')
              .trim(),
      status: status,
      iconUrl: resolvedIcon,
      playStoreUrl: (json['playStoreUrl'] as String? ?? '').trim(),
      tagline: (json['tagline'] as String?)?.trim(),
      category: (json['category'] as String?)?.trim(),
      featured: json['featured'] as bool? ?? false,
    );
  }

  static String resolveAssetUrl(String rawPath, {required String assetBase}) {
    if (rawPath.isEmpty) return '';
    if (rawPath.startsWith('http://') || rawPath.startsWith('https://')) {
      return rawPath;
    }
    // Clean relative leading slashes or /images/ prefix
    var clean = rawPath.startsWith('/') ? rawPath.substring(1) : rawPath;
    if (clean.startsWith('images/')) {
      clean = clean.substring('images/'.length);
    }
    final base = assetBase.endsWith('/') ? assetBase : '$assetBase/';
    return '$base$clean';
  }
}

class SamyuktRegistryResult {
  const SamyuktRegistryResult({
    required this.apps,
    required this.isFromCache,
    this.errorMessage,
  });

  final List<SamyuktAppItem> apps;
  final bool isFromCache;
  final String? errorMessage;
}

final samyuktRegistryServiceProvider = Provider<SamyuktRegistryService>((ref) {
  return SamyuktRegistryService();
});

class SamyuktRegistryService {
  static const String registryUrl =
      'https://raw.githubusercontent.com/kachakaran6/Application-json/main/app.json';
  static const String assetBaseUrl =
      'https://raw.githubusercontent.com/kachakaran6/Application-json/main/images/';
  static const String cacheKey = 'samyukt_cached_apps_registry_json_v2';

  /// Fetches apps from GitHub JSON registry with offline cache fallback and strict filtering.
  Future<SamyuktRegistryResult> fetchAppsCatalog({
    bool forceRefresh = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (!forceRefresh) {
      final cachedJson = prefs.getString(cacheKey);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final parsed = parseRegistryJson(cachedJson);
        if (parsed.isNotEmpty) {
          // Asynchronously revalidate in background
          unawaited(_fetchRemoteAndCache(prefs));
          return SamyuktRegistryResult(apps: parsed, isFromCache: true);
        }
      }
    }

    return _fetchRemoteAndCache(prefs);
  }

  Future<SamyuktRegistryResult> _fetchRemoteAndCache(
    SharedPreferences prefs,
  ) async {
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10);
      final request = await client.getUrl(Uri.parse(registryUrl));
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final apps = parseRegistryJson(body);

        if (apps.isNotEmpty) {
          await prefs.setString(cacheKey, body);
          return SamyuktRegistryResult(apps: apps, isFromCache: false);
        }
      }
    } catch (_) {}

    // Fallback to cache if network fails
    final cached = prefs.getString(cacheKey);
    if (cached != null && cached.isNotEmpty) {
      final cachedApps = parseRegistryJson(cached);
      return SamyuktRegistryResult(
        apps: cachedApps,
        isFromCache: true,
        errorMessage: 'Offline — showing cached catalog',
      );
    }

    return const SamyuktRegistryResult(
      apps: [],
      isFromCache: false,
      errorMessage:
          'Unable to load application catalog. Check your connection.',
    );
  }

  /// Strictly filters apps[] array and excludes websites[] and disallowed statuses.
  List<SamyuktAppItem> parseRegistryJson(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) return const [];

      final appsArray = decoded['apps'];
      if (appsArray is! List) return const [];

      final allowedStatuses = {'production', 'published', 'coming_soon'};
      final results = <SamyuktAppItem>[];

      for (final item in appsArray) {
        if (item is! Map<String, dynamic>) continue;

        final rawStatus = (item['status'] as String? ?? '')
            .trim()
            .toLowerCase();
        if (!allowedStatuses.contains(rawStatus)) {
          // Strictly exclude: draft, in_progress, closed_testing, and unknown
          continue;
        }

        final app = SamyuktAppItem.fromJson(item, assetBase: assetBaseUrl);
        // Ensure id and appName exist
        if (app.id.isNotEmpty && app.appName.isNotEmpty) {
          results.add(app);
        }
      }

      return results;
    } catch (_) {
      return const [];
    }
  }
}
