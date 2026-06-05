import 'disposable.dart';
import 'di_logger.dart';

class DiContainer {
  final _services = <Type, dynamic>{};
  final _factories = <Type, Function>{};

  void registerSingleton<T>(T instance) {
    _services[T] = instance;
    DILogger.registerSingleton(T);
  }

  void registerLazySingleton<T>(T Function() factory) {
    _factories[T] = () {
      final instance = factory();
      _services[T] = instance;
      _factories.remove(T);
      return instance;
    };
    DILogger.registerLazySingleton(T);
  }

  void registerFactory<T>(T Function() factory) {
    _factories[T] = factory;
    DILogger.registerFactory(T);
  }

  T get<T>() {
    if (_services.containsKey(T)) {
      DILogger.resolve(T);
      return _services[T] as T;
    }
    if (_factories.containsKey(T)) {
      DILogger.resolve(T);
      return _factories[T]!() as T;
    }
    final error = 'Service of type $T not registered';
    DILogger.error(error);
    throw Exception(error);
  }

  bool isRegistered<T>() =>
      _services.containsKey(T) || _factories.containsKey(T);

  void unregister<T>() {
    if (_services.containsKey(T)) {
      final instance = _services[T];
      if (instance is Disposable) {
        DILogger.dispose(T);
        instance.dispose();
      }
      _services.remove(T);
    }
    _factories.remove(T);
    DILogger.unregister(T);
  }

  void reset() {
    for (final entry in _services.entries) {
      if (entry.value is Disposable) {
        (entry.value as Disposable).dispose();
      }
    }
    _services.clear();
    _factories.clear();
  }
}
