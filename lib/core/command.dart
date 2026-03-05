import 'package:flutter/foundation.dart';

import 'errors/app_exception.dart';
import 'result.dart';

typedef CommandAction0 = Future<Result<void>> Function();
typedef CommandAction1<T> = Future<Result<void>> Function(T value);

class Command0 extends ChangeNotifier {
  Command0(this._action);

  final CommandAction0 _action;

  bool _running = false;
  AppException? _error;

  bool get running => _running;
  AppException? get error => _error;

  Future<Result<void>> execute() async {
    if (_running) {
      return const Failure<void>(AppException('Um pedido já está em andamento.'));
    }

    _running = true;
    _error = null;
    notifyListeners();

    final result = await _action();

    _running = false;
    if (result is Failure<void>) {
      _error = result.error;
    }
    notifyListeners();

    return result;
  }

  void clearError() {
    if (_error == null) {
      return;
    }

    _error = null;
    notifyListeners();
  }
}

class Command1<T> extends ChangeNotifier {
  Command1(this._action);

  final CommandAction1<T> _action;

  bool _running = false;
  AppException? _error;

  bool get running => _running;
  AppException? get error => _error;

  Future<Result<void>> execute(T value) async {
    if (_running) {
      return const Failure<void>(AppException('Um pedido já está em andamento.'));
    }

    _running = true;
    _error = null;
    notifyListeners();

    final result = await _action(value);

    _running = false;
    if (result is Failure<void>) {
      _error = result.error;
    }
    notifyListeners();

    return result;
  }

  void clearError() {
    if (_error == null) {
      return;
    }

    _error = null;
    notifyListeners();
  }
}
