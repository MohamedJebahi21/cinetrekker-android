import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

enum CineTrekkerMotionStyle { full, reduced }

final reducedMotionControllerProvider =
    NotifierProvider<ReducedMotionController, CineTrekkerMotionStyle>(
      ReducedMotionController.new,
    );

class ReducedMotionController extends Notifier<CineTrekkerMotionStyle> {
  static const _storage = FlutterSecureStorage();

  @override
  CineTrekkerMotionStyle build() {
    _load();
    return CineTrekkerMotionStyle.full;
  }

  Future<void> _load() async {
    final value = await _storage.read(
      key: AppConstants.reducedMotionStorageKey,
    );
    state = value == 'reduced'
        ? CineTrekkerMotionStyle.reduced
        : CineTrekkerMotionStyle.full;
  }

  Future<void> setStyle(CineTrekkerMotionStyle style) async {
    state = style;
    await _storage.write(
      key: AppConstants.reducedMotionStorageKey,
      value: style == CineTrekkerMotionStyle.reduced ? 'reduced' : 'full',
    );
  }
}
