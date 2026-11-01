import 'package:flutter_test/flutter_test.dart';
import 'package:cinetrekker_android/core/export/data_export_service.dart';
import 'package:cinetrekker_android/core/models/media_models.dart';

void main() {
  group('DataExportService CSV RFC-4180 escaping', () {
    test('regular values are unchanged', () {
      expect(DataExportService.escapeCsvValue('Inception'), 'Inception');
      expect(DataExportService.escapeCsvValue('2010'), '2010');
      expect(DataExportService.escapeCsvValue(''), '');
      expect(DataExportService.escapeCsvValue(null), '');
    });

    test('values with commas are wrapped in quotes', () {
      expect(
        DataExportService.escapeCsvValue('Everything Everywhere, All at Once'),
        '"Everything Everywhere, All at Once"',
      );
    });

    test('values with double quotes escape internal quotes', () {
      expect(
        DataExportService.escapeCsvValue('The "Masterpiece" Film'),
        '"The ""Masterpiece"" Film"',
      );
    });

    test('values with newlines are enclosed in quotes', () {
      expect(
        DataExportService.escapeCsvValue('Line 1\nLine 2'),
        '"Line 1\nLine 2"',
      );
    });
  });

  group('Letterboxd CSV Generation', () {
    final mockWatched = <UserMediaItem>[
      const UserMediaItem(
        id: '1',
        mediaId: 550,
        mediaType: 'movie',
        userId: 'u123',
        title: 'Fight Club',
        releaseDate: '1999-10-15',
        rating: 9.5,
        addedAt: '2026-05-20T20:00:00Z',
        watchedAt: '2026-05-20T20:00:00Z',
        note: 'Exceptional, one of the best.',
      ),
      const UserMediaItem(
        id: '2',
        mediaId: 680,
        mediaType: 'movie',
        userId: 'u123',
        title: 'Pulp Fiction',
        releaseDate: '1994-09-10',
        rating: 10.0,
        addedAt: '2026-06-12T19:30:00Z',
        watchedAt: '2026-06-12T19:30:00Z',
        note: 'Classic "Tarantino" dialogue.',
      ),
    ];

    test('builds Letterboxd watched CSV with proper headers and row fields', () {
      final csv = DataExportService.buildLetterboxdWatchedCsv(mockWatched);
      final lines = csv.trim().split('\n');

      expect(lines.length, 3);
      expect(lines[0], 'Title,Year,Rating10,WatchedDate,Review,TMDB_ID');
      expect(lines[1], 'Fight Club,1999,9.5,2026-05-20,"Exceptional, one of the best.",550');
      expect(lines[2], 'Pulp Fiction,1994,10.0,2026-06-12,"Classic ""Tarantino"" dialogue.",680');
    });

    test('builds Letterboxd watchlist CSV', () {
      final mockWatchlist = <UserMediaItem>[
        UserMediaItem(
          id: '3',
          mediaId: 157336,
          mediaType: 'movie',
          userId: 'u123',
          title: 'Interstellar',
          releaseDate: '2014-11-05',
          addedAt: '2026-07-01T00:00:00Z',
        ),
      ];

      final csv = DataExportService.buildLetterboxdWatchlistCsv(mockWatchlist);
      final lines = csv.trim().split('\n');

      expect(lines.length, 2);
      expect(lines[0], 'Title,Year,TMDB_ID');
      expect(lines[1], 'Interstellar,2014,157336');
    });
  });
}
