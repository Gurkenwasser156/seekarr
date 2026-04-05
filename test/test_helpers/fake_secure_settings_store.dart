import 'package:seekarr/features/settings/data/settings_service.dart';

class FakeSecureSettingsStore implements SecureSettingsStore {
  final Map<String, String> _storage = {};

  @override
  Future<void> delete({required String key}) async {
    _storage.remove(key);
  }

  @override
  Future<String?> read({required String key}) async {
    return _storage[key];
  }

  @override
  Future<void> write({required String key, required String value}) async {
    _storage[key] = value;
  }
}
