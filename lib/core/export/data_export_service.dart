import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/media_models.dart';

/// Service responsible for exporting CineTrekker tracking, watchlist,
/// and profile data to offline files in JSON backup and CSV exports.
class DataExportService {
  const DataExportService();

  /// Escapes a single CSV field value according to RFC-4180 rules.
  static String escapeCsvValue(dynamic value) {
    if (value == null) return '';
    final str = value.toString();
    if (str.contains(',') ||
        str.contains('"') ||
        str.contains('\n') ||
        str.contains('\r')) {
      return '"${str.replaceAll('"', '""')}"';
    }
    return str;
  }

  /// Builds a standard RFC-4180 CSV string from headers and rows.
  static String buildCsv(List<String> headers, List<List<dynamic>> rows) {
    final buffer = StringBuffer();
    buffer.writeln(headers.map(escapeCsvValue).join(','));
    for (final row in rows) {
      buffer.writeln(row.map(escapeCsvValue).join(','));
    }
    return buffer.toString();
  }

  /// Builds a CSV with Letterboxd-like movie columns. Import compatibility is not guaranteed.
  static String buildLetterboxdWatchedCsv(List<UserMediaItem> items) {
    final headers = ['Title', 'Year', 'Rating10', 'WatchedDate', 'Review', 'TMDB_ID'];
    final rows = <List<dynamic>>[];

    for (final item in items) {
      String year = '';
      if (item.releaseDate != null && item.releaseDate!.isNotEmpty) {
        year = item.releaseDate!.split('-').first;
      }

      String watchedDate = '';
      if (item.watchedAt != null && item.watchedAt!.isNotEmpty) {
        watchedDate = item.watchedAt!.split('T').first;
      }

      rows.add([
        item.title,
        year,
        item.rating != null && item.rating! > 0 ? item.rating : '',
        watchedDate,
        item.note ?? '',
        item.mediaId,
      ]);
    }

    return buildCsv(headers, rows);
  }

  /// Builds a CSV with movie watchlist columns. Import compatibility is not guaranteed.
  static String buildLetterboxdWatchlistCsv(List<UserMediaItem> items) {
    final headers = ['Title', 'Year', 'TMDB_ID'];
    final rows = <List<dynamic>>[];

    for (final item in items) {
      String year = '';
      if (item.releaseDate != null && item.releaseDate!.isNotEmpty) {
        year = item.releaseDate!.split('-').first;
      }
      rows.add([
        item.title,
        year,
        item.mediaId,
      ]);
    }

    return buildCsv(headers, rows);
  }

  /// Shares a full JSON backup payload as a downloadable file via the system share sheet.
  Future<ShareResult> exportAndShareJson({
    required Map<String, dynamic> payload,
    String filenamePrefix = 'cinetrekker-backup',
  }) async {
    final tempDir = await getTemporaryDirectory();
    final now = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final file = File('${tempDir.path}/${filenamePrefix}_$now.json');

    final jsonString = const JsonEncoder.withIndent('  ').convert(payload);
    await file.writeAsString(jsonString, flush: true);

    return Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'CineTrekker Backup ($now)',
      text: 'My CineTrekker tracking backup archive ($now)',
    );
  }

  /// Shares watched and watchlist CSV files; no third-party import compatibility is guaranteed.
  Future<ShareResult> exportAndShareLetterboxdCsv({
    required List<UserMediaItem> watched,
    required List<UserMediaItem> watchlist,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final now = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;

    final files = <XFile>[];

    if (watched.isNotEmpty) {
      final watchedCsv = buildLetterboxdWatchedCsv(watched);
      final watchedFile = File('${tempDir.path}/cinetrekker_watched_$now.csv');
      await watchedFile.writeAsString(watchedCsv, flush: true);
      files.add(XFile(watchedFile.path, mimeType: 'text/csv'));
    }

    if (watchlist.isNotEmpty) {
      final watchlistCsv = buildLetterboxdWatchlistCsv(watchlist);
      final watchlistFile = File('${tempDir.path}/cinetrekker_watchlist_$now.csv');
      await watchlistFile.writeAsString(watchlistCsv, flush: true);
      files.add(XFile(watchlistFile.path, mimeType: 'text/csv'));
    }

    if (files.isEmpty) {
      // Create empty placeholder file if neither list has items
      final emptyFile = File('${tempDir.path}/cinetrekker_library_$now.csv');
      await emptyFile.writeAsString(
        'Title,Year,Rating10,WatchedDate,Review,TMDB_ID\n',
        flush: true,
      );
      files.add(XFile(emptyFile.path, mimeType: 'text/csv'));
    }

    return Share.shareXFiles(
      files,
      subject: 'CineTrekker CSV Export ($now)',
      text: 'CineTrekker Library CSV Export',
    );
  }
}
