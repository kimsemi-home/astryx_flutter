import 'transport.dart';

/// Runtime registry that keeps UI and domain code independent of adapters.
class TransportRegistry {
  TransportRegistry([Iterable<TransportAdapter> adapters = const []]) {
    for (final adapter in adapters) {
      register(adapter);
    }
  }

  final Map<AstryxProtocol, TransportAdapter> _adapters = {};

  Iterable<TransportAdapter> get adapters => _adapters.values;

  void register(TransportAdapter adapter, {bool replace = false}) {
    if (!replace && _adapters.containsKey(adapter.protocol)) {
      throw StateError(
          'An adapter for ${adapter.protocol.name} is registered.');
    }
    final previous = _adapters[adapter.protocol];
    if (replace && !identical(previous, adapter)) previous?.close();
    _adapters[adapter.protocol] = adapter;
  }

  bool supports(AstryxProtocol protocol, [TransportCapability? capability]) {
    final adapter = _adapters[protocol];
    if (adapter == null) return false;
    return capability == null || adapter.capabilities.contains(capability);
  }

  T adapter<T extends TransportAdapter>(AstryxProtocol protocol) {
    final value = _adapters[protocol];
    if (value == null) {
      throw StateError('No adapter registered for ${protocol.name}.');
    }
    if (value is! T) {
      throw StateError(
        '${protocol.name} is ${value.runtimeType}, not the requested $T.',
      );
    }
    return value;
  }

  Future<TransportResponse> send(TransportRequest request) {
    return adapter<TransportAdapter>(request.protocol).send(request);
  }

  Stream<TransportEvent> openStream(TransportRequest request) {
    return adapter<TransportAdapter>(request.protocol).openStream(request);
  }

  void close() {
    for (final adapter in _adapters.values) {
      adapter.close();
    }
    _adapters.clear();
  }
}
