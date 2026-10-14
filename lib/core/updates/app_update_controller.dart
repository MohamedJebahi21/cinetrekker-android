import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';
import 'app_update_service.dart';

final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  return AppUpdateService();
});

enum AppUpdateStatus { idle, checking, upToDate, updateAvailable, error }

class AppUpdateState {
  const AppUpdateState({
    this.status = AppUpdateStatus.idle,
    this.updateInfo,
    this.errorMessage,
    this.lastCheckedAt,
  });

  final AppUpdateStatus status;
  final AppUpdateInfo? updateInfo;
  final String? errorMessage;
  final DateTime? lastCheckedAt;

  bool get isChecking => status == AppUpdateStatus.checking;
  bool get hasUpdate =>
      status == AppUpdateStatus.updateAvailable &&
      (updateInfo?.hasUpdate ?? false);
  bool get isUpToDate => status == AppUpdateStatus.upToDate;
  bool get hasError => status == AppUpdateStatus.error;

  AppUpdateState copyWith({
    AppUpdateStatus? status,
    AppUpdateInfo? updateInfo,
    String? errorMessage,
    DateTime? lastCheckedAt,
  }) {
    return AppUpdateState(
      status: status ?? this.status,
      updateInfo: updateInfo ?? this.updateInfo,
      errorMessage: errorMessage,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
    );
  }
}

class AppUpdateController extends StateNotifier<AppUpdateState> {
  AppUpdateController(this._service) : super(const AppUpdateState());

  final AppUpdateService _service;

  Future<AppUpdateInfo?> checkForUpdates({bool isManual = false}) async {
    state = state.copyWith(
      status: AppUpdateStatus.checking,
      errorMessage: null,
    );
    try {
      final info = await _service.fetchLatestRelease();
      state = state.copyWith(
        status: info.hasUpdate
            ? AppUpdateStatus.updateAvailable
            : AppUpdateStatus.upToDate,
        updateInfo: info,
        lastCheckedAt: DateTime.now(),
      );
      return info;
    } catch (error) {
      state = state.copyWith(
        status: AppUpdateStatus.error,
        errorMessage: 'Unable to check for updates: $error',
        lastCheckedAt: DateTime.now(),
      );
      return null;
    }
  }

  Future<bool> openUpdatePage() async {
    final targetUrl =
        state.updateInfo?.releaseUrl ?? AppConstants.githubReleasesPageUrl;
    final uri = Uri.parse(targetUrl);
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<bool> openDirectDownload() async {
    final downloadUrl = state.updateInfo?.apkDownloadUrl ??
        state.updateInfo?.releaseUrl ??
        AppConstants.githubReleasesPageUrl;
    final uri = Uri.parse(downloadUrl);
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

final appUpdateControllerProvider =
    StateNotifierProvider<AppUpdateController, AppUpdateState>((ref) {
  final service = ref.watch(appUpdateServiceProvider);
  return AppUpdateController(service);
});
