import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main.dart');
});

final onboardingStorageProvider = Provider<OnboardingStorage>((ref) {
  return OnboardingStorage(ref.watch(sharedPreferencesProvider));
});

final onboardingCompletedProvider =
    NotifierProvider<OnboardingController, bool>(OnboardingController.new);

class OnboardingController extends Notifier<bool> {
  @override
  bool build() {
    return ref.watch(onboardingStorageProvider).isCompleted;
  }

  Future<void> markCompleted() async {
    await ref.read(onboardingStorageProvider).markCompleted();
    state = true;
  }
}

class OnboardingStorage {
  const OnboardingStorage(this._preferences);

  static const _completedKey = 'onboarding.completed';

  final SharedPreferences _preferences;

  bool get isCompleted => _preferences.getBool(_completedKey) ?? false;

  Future<void> markCompleted() async {
    await _preferences.setBool(_completedKey, true);
  }
}
