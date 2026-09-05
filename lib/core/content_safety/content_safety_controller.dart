import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

class CineTrekkerContentSafety {
  const CineTrekkerContentSafety({
    required this.maturityRating,
    required this.showAge,
    required this.adultContentEnabled,
    required this.strictFilteringEnabled,
    required this.moderateFilteringEnabled,
  });

  factory CineTrekkerContentSafety.defaults() {
    return const CineTrekkerContentSafety(
      maturityRating: 'none',
      showAge: false,
      adultContentEnabled: false,
      strictFilteringEnabled: true,
      moderateFilteringEnabled: false,
    );
  }

  final String maturityRating;
  final bool showAge;
  final bool adultContentEnabled;
  final bool strictFilteringEnabled;
  final bool moderateFilteringEnabled;

  factory CineTrekkerContentSafety.fromJson(Map<String, dynamic> json) {
    return CineTrekkerContentSafety(
      maturityRating: json['maturityRating'] as String? ?? 'none',
      showAge: json['showAge'] as bool? ?? false,
      adultContentEnabled: json['adultContentEnabled'] as bool? ?? false,
      strictFilteringEnabled: json['strictFilteringEnabled'] as bool? ?? true,
      moderateFilteringEnabled:
          json['moderateFilteringEnabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'maturityRating': maturityRating,
      'showAge': showAge,
      'adultContentEnabled': adultContentEnabled,
      'strictFilteringEnabled': strictFilteringEnabled,
      'moderateFilteringEnabled': moderateFilteringEnabled,
    };
  }

  CineTrekkerContentSafety copyWith({
    String? maturityRating,
    bool? showAge,
    bool? adultContentEnabled,
    bool? strictFilteringEnabled,
    bool? moderateFilteringEnabled,
  }) {
    return CineTrekkerContentSafety(
      maturityRating: maturityRating ?? this.maturityRating,
      showAge: showAge ?? this.showAge,
      adultContentEnabled: adultContentEnabled ?? this.adultContentEnabled,
      strictFilteringEnabled:
          strictFilteringEnabled ?? this.strictFilteringEnabled,
      moderateFilteringEnabled:
          moderateFilteringEnabled ?? this.moderateFilteringEnabled,
    );
  }
}

final contentSafetyControllerProvider =
    NotifierProvider<ContentSafetyController, CineTrekkerContentSafety>(
      ContentSafetyController.new,
    );

class ContentSafetyController extends Notifier<CineTrekkerContentSafety> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  CineTrekkerContentSafety build() {
    _load();
    return CineTrekkerContentSafety.defaults();
  }

  Future<void> _load() async {
    final value = await _storage.read(
      key: AppConstants.contentSafetyStorageKey,
    );
    if (value == null || value.isEmpty) {
      return;
    }

    final decoded = jsonDecode(value);
    if (decoded is Map<String, dynamic>) {
      state = CineTrekkerContentSafety.fromJson(decoded);
    }
  }

  Future<void> setPreferences(CineTrekkerContentSafety preferences) async {
    state = preferences;
    await _storage.write(
      key: AppConstants.contentSafetyStorageKey,
      value: jsonEncode(preferences.toJson()),
    );
  }

  Future<void> clearPreferences() async {
    state = CineTrekkerContentSafety.defaults();
    await _storage.delete(key: AppConstants.contentSafetyStorageKey);
  }
}
