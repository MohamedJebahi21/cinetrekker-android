import 'package:dio/dio.dart';
import '../constants/app_constants.dart';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.currentVersion,
    this.latestVersion,
    this.releaseTitle,
    this.releaseNotes,
    this.releaseUrl,
    this.apkDownloadUrl,
    this.hasUpdate = false,
    this.publishedAt,
  });

  final String currentVersion;
  final String? latestVersion;
  final String? releaseTitle;
  final String? releaseNotes;
  final String? releaseUrl;
  final String? apkDownloadUrl;
  final bool hasUpdate;
  final DateTime? publishedAt;

  Map<String, dynamic> toJson() => {
    'currentVersion': currentVersion,
    'latestVersion': latestVersion,
    'releaseTitle': releaseTitle,
    'releaseNotes': releaseNotes,
    'releaseUrl': releaseUrl,
    'apkDownloadUrl': apkDownloadUrl,
    'hasUpdate': hasUpdate,
    'publishedAt': publishedAt?.toIso8601String(),
  };

  /// Compares two version strings (e.g. "1.1.4" vs "1.1.3", or "v1.1.4" vs "1.1.3+6").
  /// Returns 1 if v1 > v2, -1 if v1 < v2, 0 if equal.
  static int compareVersions(String v1, String v2) {
    final clean1 = _cleanVersion(v1);
    final clean2 = _cleanVersion(v2);

    final parts1 = clean1.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final parts2 = clean2.split('.').map((p) => int.tryParse(p) ?? 0).toList();

    final maxLen = parts1.length > parts2.length ? parts1.length : parts2.length;
    for (var i = 0; i < maxLen; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }

    final b1 = _extractBuild(v1);
    final b2 = _extractBuild(v2);
    if (b1 > 0 && b2 > 0) {
      if (b1 > b2) return 1;
      if (b1 < b2) return -1;
    }

    return 0;
  }

  static int _extractBuild(String v) {
    if (v.contains('+')) {
      final parts = v.split('+');
      if (parts.length > 1) {
        final digits = parts[1].replaceAll(RegExp(r'\D'), '');
        return int.tryParse(digits) ?? 0;
      }
    }
    return 0;
  }

  static String _cleanVersion(String v) {
    var s = v.trim();
    if (s.startsWith('v') || s.startsWith('V')) {
      s = s.substring(1);
    }
    final plusIdx = s.indexOf('+');
    if (plusIdx != -1) {
      s = s.substring(0, plusIdx);
    }
    final dashIdx = s.indexOf('-');
    if (dashIdx != -1) {
      s = s.substring(0, dashIdx);
    }
    return s.trim();
  }
}

class AppUpdateService {
  AppUpdateService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 15),
                headers: const {
                  'Accept': 'application/vnd.github.v3+json',
                  'User-Agent': 'CineTrekker-Android',
                },
              ),
            );

  final Dio _dio;

  Future<AppUpdateInfo> fetchLatestRelease({
    String currentVersion = AppConstants.appVersion,
    String endpoint = AppConstants.githubReleasesLatestApiUrl,
  }) async {
    final response = await _dio.get<dynamic>(endpoint);
    final rawData = response.data;
    if (rawData == null || rawData is! Map) {
      throw Exception('Invalid response format from release server');
    }

    final data = Map<String, dynamic>.from(rawData);

    final tagName = (data['tag_name'] as String?)?.trim() ?? '';
    final releaseTitle = (data['name'] as String?)?.trim() ?? tagName;
    final htmlUrl = (data['html_url'] as String?)?.trim() ??
        AppConstants.githubReleasesPageUrl;
    final body = (data['body'] as String?)?.trim();
    final publishedStr = data['published_at'] as String?;
    final publishedAt =
        publishedStr != null ? DateTime.tryParse(publishedStr) : null;

    String? apkUrl;
    final assets = data['assets'] as List<dynamic>?;
    if (assets != null) {
      for (final asset in assets) {
        if (asset is Map) {
          final assetMap = Map<String, dynamic>.from(asset);
          final name = (assetMap['name'] as String?)?.toLowerCase() ?? '';
          if (name.endsWith('.apk')) {
            apkUrl = assetMap['browser_download_url'] as String?;
            break;
          }
        }
      }
    }

    final cleanedTag = tagName.startsWith('v') || tagName.startsWith('V')
        ? tagName.substring(1)
        : tagName;

    final hasUpdate = cleanedTag.isNotEmpty &&
        AppUpdateInfo.compareVersions(cleanedTag, currentVersion) > 0;

    return AppUpdateInfo(
      currentVersion: currentVersion,
      latestVersion: cleanedTag.isNotEmpty ? cleanedTag : null,
      releaseTitle: releaseTitle.isNotEmpty ? releaseTitle : null,
      releaseNotes: body,
      releaseUrl: htmlUrl,
      apkDownloadUrl: apkUrl,
      hasUpdate: hasUpdate,
      publishedAt: publishedAt,
    );
  }
}
