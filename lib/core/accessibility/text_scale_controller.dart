import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

enum CineTrekkerTextScaleStyle { system, large, xLarge }

final _storage = FlutterSecureStorage();

final textScaleControllerProvider =
    NotifierProvider<TextScaleController, CineTrekkerTextScaleStyle>(
      TextScaleController.new,
    );

class TextScaleController extends Notifier<CineTrekkerTextScaleStyle> {
  @override
  CineTrekkerTextScaleStyle build() {
    _load();
    return CineTrekkerTextScaleStyle.system;
  }

  Future<void> _load() async {
    final value = await _storage.read(key: AppConstants.textScaleStorageKey);
    state = switch (value) {
      'large' => CineTrekkerTextScaleStyle.large,
      'xLarge' => CineTrekkerTextScaleStyle.xLarge,
      _ => CineTrekkerTextScaleStyle.system,
    };
  }

  double? get textScaleFactor {
    return switch (state) {
      CineTrekkerTextScaleStyle.system => null,
      CineTrekkerTextScaleStyle.large => 1.15,
      CineTrekkerTextScaleStyle.xLarge => 1.3,
    };
  }

  Future<void> setScale(CineTrekkerTextScaleStyle style) async {
    state = style;
    await _storage.write(
      key: AppConstants.textScaleStorageKey,
      value: switch (style) {
        CineTrekkerTextScaleStyle.system => 'system',
        CineTrekkerTextScaleStyle.large => 'large',
        CineTrekkerTextScaleStyle.xLarge => 'xLarge',
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Continuous font size scale (0.85×–1.30×). Default: 1.0 (no scaling).
// When set to any value other than 1.0 this takes precedence over the
// legacy CineTrekkerTextScaleStyle enum in app.dart.
// ---------------------------------------------------------------------------

final fontSizeScaleControllerProvider =
    NotifierProvider<FontSizeScaleController, double>(
      FontSizeScaleController.new,
    );

class FontSizeScaleController extends Notifier<double> {
  static const double minScale = 0.85;
  static const double maxScale = 1.30;
  static const double defaultScale = 1.0;

  @override
  double build() {
    _load();
    return defaultScale;
  }

  Future<void> _load() async {
    final raw = await _storage.read(
      key: AppConstants.fontSizeScaleStorageKey,
    );
    if (raw != null) {
      final parsed = double.tryParse(raw);
      if (parsed != null && parsed >= minScale && parsed <= maxScale) {
        state = parsed;
        return;
      }
    }
    state = defaultScale;
  }

  Future<void> setScale(double scale) async {
    final clamped = scale.clamp(minScale, maxScale);
    state = clamped;
    await _storage.write(
      key: AppConstants.fontSizeScaleStorageKey,
      value: clamped.toStringAsFixed(2),
    );
  }

  Future<void> reset() => setScale(defaultScale);
}
