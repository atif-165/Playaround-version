import 'dart:async';

/// Stream transformer that debounces events by [duration].
class DebounceStreamTransformer<T> extends StreamTransformerBase<T, T> {
  DebounceStreamTransformer(this.duration);

  final Duration duration;

  @override
  Stream<T> bind(Stream<T> stream) {
    late StreamController<T> controller;
    StreamSubscription<T>? subscription;
    Timer? timer;

    void emit(T event) {
      if (!controller.isClosed) {
        controller.add(event);
      }
    }

    void onData(T event) {
      timer?.cancel();
      timer = Timer(duration, () => emit(event));
    }

    void onDone() {
      timer?.cancel();
      controller.close();
    }

    controller = StreamController<T>.broadcast(onListen: () {
      subscription = stream.listen(
        onData,
        onError: controller.addError,
        onDone: onDone,
      );
    }, onCancel: () async {
      timer?.cancel();
      await subscription?.cancel();
    });

    return controller.stream;
  }
}

extension DebounceStreamExtension<T> on Stream<T> {
  Stream<T> debounceTime(Duration duration) =>
      transform(DebounceStreamTransformer<T>(duration));
}
