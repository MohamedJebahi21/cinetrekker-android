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
