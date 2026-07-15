import 'transport.dart';

/// The next request/response handler in a middleware chain.
typedef TransportNext = Future<TransportResponse> Function(
    TransportRequest request);

/// The next streaming handler in a middleware chain.
typedef TransportStreamNext = Stream<TransportEvent> Function(
    TransportRequest request);

/// Composable behavior that can inspect or transform transport requests.
abstract class TransportMiddleware {
  const TransportMiddleware();

  Future<TransportResponse> intercept(
    TransportRequest request,
    TransportNext next,
  ) {
    return next(request);
  }

  Stream<TransportEvent> interceptStream(
    TransportRequest request,
    TransportStreamNext next,
  ) {
    return next(request);
  }
}

/// Executes middleware in registration order around a terminal adapter call.
class TransportMiddlewarePipeline {
  TransportMiddlewarePipeline([List<TransportMiddleware> middleware = const []])
      : middleware = List.unmodifiable(middleware);

  final List<TransportMiddleware> middleware;

  Future<TransportResponse> send(
    TransportRequest request,
    TransportNext terminal,
  ) {
    Future<TransportResponse> dispatch(int index, TransportRequest current) {
      if (index == middleware.length) return terminal(current);
      return middleware[index].intercept(
        current,
        (nextRequest) => dispatch(index + 1, nextRequest),
      );
    }

    return dispatch(0, request);
  }

  Stream<TransportEvent> openStream(
    TransportRequest request,
    TransportStreamNext terminal,
  ) {
    Stream<TransportEvent> dispatch(int index, TransportRequest current) {
      if (index == middleware.length) return terminal(current);
      return middleware[index].interceptStream(
        current,
        (nextRequest) => dispatch(index + 1, nextRequest),
      );
    }

    return dispatch(0, request);
  }
}
