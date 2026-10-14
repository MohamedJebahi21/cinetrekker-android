import 'package:flutter_test/flutter_test.dart';
import 'package:cinetrekker_android/core/updates/app_update_service.dart';
import 'package:cinetrekker_android/core/updates/app_update_controller.dart';

void main() {
  group('AppUpdateInfo.compareVersions', () {
    test('returns 1 when remote version is higher than current', () {
      expect(AppUpdateInfo.compareVersions('1.1.4', '1.1.3'), 1);
      expect(AppUpdateInfo.compareVersions('v1.2.0', '1.1.3'), 1);
      expect(AppUpdateInfo.compareVersions('2.0.0', '1.1.3'), 1);
      expect(AppUpdateInfo.compareVersions('v1.1.3+7', '1.1.3+6'), 1);
    });

    test('returns 0 when versions are equal', () {
      expect(AppUpdateInfo.compareVersions('1.1.3', '1.1.3'), 0);
      expect(AppUpdateInfo.compareVersions('v1.1.3', '1.1.3'), 0);
      expect(AppUpdateInfo.compareVersions('v1.1.3', '1.1.3+6'), 0);
      expect(AppUpdateInfo.compareVersions('1.1.3+6', '1.1.3+6'), 0);
    });

    test('returns -1 when remote version is lower than current', () {
      expect(AppUpdateInfo.compareVersions('1.1.2', '1.1.3'), -1);
      expect(AppUpdateInfo.compareVersions('v1.0.9', '1.1.3'), -1);
      expect(AppUpdateInfo.compareVersions('1.1.3+5', '1.1.3+6'), -1);
    });

    test('handles suffixes and formatting cleanly', () {
      expect(AppUpdateInfo.compareVersions('v1.1.4-beta', '1.1.3'), 1);
      expect(AppUpdateInfo.compareVersions('1.1.4+10', '1.1.4+5'), 1);
    });
  });

  group('AppUpdateState', () {
    test('initial state defaults to idle', () {
      const state = AppUpdateState();
      expect(state.status, AppUpdateStatus.idle);
      expect(state.isChecking, isFalse);
      expect(state.hasUpdate, isFalse);
      expect(state.isUpToDate, isFalse);
      expect(state.hasError, isFalse);
    });

    test('hasUpdate returns true only when status is updateAvailable with update', () {
      const info = AppUpdateInfo(
        currentVersion: '1.1.3',
        latestVersion: '1.1.4',
        hasUpdate: true,
      );
      const state = AppUpdateState(
        status: AppUpdateStatus.updateAvailable,
        updateInfo: info,
      );
      expect(state.hasUpdate, isTrue);
      expect(state.isChecking, isFalse);
    });

    test('copyWith updates fields correctly', () {
      const state = AppUpdateState();
      final updated = state.copyWith(
        status: AppUpdateStatus.checking,
        errorMessage: 'Temporary error',
      );
      expect(updated.status, AppUpdateStatus.checking);
      expect(updated.errorMessage, 'Temporary error');
      expect(updated.isChecking, isTrue);
    });
  });

  group('AppUpdateInfo serialization', () {
    test('toJson creates expected map', () {
      const info = AppUpdateInfo(
        currentVersion: '1.1.3',
        latestVersion: '1.1.4',
        releaseTitle: 'CineTrekker v1.1.4',
        releaseNotes: 'Fixed bugs and added features',
        releaseUrl: 'https://github.com/MohamedJebahi21/cinetrekker-android/releases/tag/v1.1.4',
        apkDownloadUrl: 'https://github.com/MohamedJebahi21/cinetrekker-android/releases/download/v1.1.4/cinetrekker.apk',
        hasUpdate: true,
      );

      final json = info.toJson();
      expect(json['currentVersion'], '1.1.3');
      expect(json['latestVersion'], '1.1.4');
      expect(json['hasUpdate'], isTrue);
      expect(json['apkDownloadUrl'], contains('.apk'));
    });
  });
}
