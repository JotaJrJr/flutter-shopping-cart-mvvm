import 'package:flutter/foundation.dart';

import 'errors/app_exception.dart';
import 'result.dart';

abstract class CommandBase extends ChangeNotifier {
  bool _running = false;
  AppException? _error;

  bool get running => _running;
  AppException? get error => _error;

  Future<Result<void>> run(Future<Result<void>> Function() action) async {
    if (_running) {
      return const Failure<void>(
        AppException('Um pedido já está em andamento.'),
      );
    }

    _running = true;
    _error = null;
    notifyListeners();

    try {
      final result = await action();
      if (result case Failure<void>()) {
        _error = result.error;
      }
      return result;
    } catch (error) {
      final appException = AppException(error.toString());
      _error = appException;
      return Failure<void>(appException);
    } finally {
      _running = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_error == null) {
      return;
    }

    _error = null;
    notifyListeners();
  }
}

class ListarProdutosCommand extends CommandBase {
  ListarProdutosCommand(this._action);

  final Future<Result<void>> Function() _action;

  Future<Result<void>> execute() => run(_action);
}

class AdicionarProdutoCommand<T> extends CommandBase {
  AdicionarProdutoCommand(this._action);

  final Future<Result<void>> Function(T value) _action;

  Future<Result<void>> execute(T value) => run(() => _action(value));
}

class RemoverProdutoCommand<T> extends CommandBase {
  RemoverProdutoCommand(this._action);

  final Future<Result<void>> Function(T value) _action;

  Future<Result<void>> execute(T value) => run(() => _action(value));
}

class FinalizarCompraCommand extends CommandBase {
  FinalizarCompraCommand(this._action);

  final Future<Result<void>> Function() _action;

  Future<Result<void>> execute() => run(_action);
}
