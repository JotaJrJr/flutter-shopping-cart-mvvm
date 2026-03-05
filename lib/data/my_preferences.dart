import 'package:shared_preferences/shared_preferences.dart';

class MyPreferences {
  static final MyPreferences _instance = MyPreferences._internal();

  factory MyPreferences() {
    return _instance;
  }

  MyPreferences._internal();

  final userId = Cached<String?>('userId', null);
  final cartSnapshotJson = Cached<String>('cartSnapshotJson', '');
}

class Cached<T> {
  final String key;
  final T defaultValue;
  final T Function(String)? decoder;
  final String Function(T)? encoder;

  T? _value;
  bool _loaded = false;

  Cached(this.key, this.defaultValue, {this.decoder, this.encoder});

  Future<T> get value async {
    if (!_loaded) {
      final prefs = await SharedPreferences.getInstance();
      _value = await _readFromPrefs(prefs);
      _loaded = true;
    }
    return _value ?? defaultValue;
  }

  Future<void> save(T newValue) async {
    final prefs = await SharedPreferences.getInstance();
    _value = newValue;
    _loaded = true;

    if (encoder != null) {
      await prefs.setString(key, encoder!(newValue));
    } else if (newValue is String) {
      await prefs.setString(key, newValue);
    } else if (newValue is bool) {
      await prefs.setBool(key, newValue);
    } else if (newValue is int) {
      await prefs.setInt(key, newValue);
    } else if (newValue is double) {
      await prefs.setDouble(key, newValue);
    } else {
      throw UnsupportedError("Unsupported type: $T");
    }
  }

  Future<T?> _readFromPrefs(SharedPreferences prefs) async {
    if (decoder != null) {
      final str = prefs.getString(key);
      return str != null ? decoder!(str) : defaultValue;
    }

    final Object? raw = prefs.get(key);
    if (raw is T) {
      return raw;
    } else {
      return defaultValue;
    }
  }
}
