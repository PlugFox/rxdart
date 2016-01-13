library rx.observable.tween;

import 'package:rxdart/src/observable/stream.dart';

enum Ease {
  LINEAR, IN, OUT, IN_OUT
}

typedef double Sampler(double startValue, double changeInTime, int currentTimeMs, int durationMs);

class TweenObservable<T extends double> extends StreamObservable<T> with ControllerMixin<T> {

  TweenObservable(double startValue, double changeInTime, Duration duration, int intervalMs, Ease ease, bool asBroadcastStream) {
    StreamSubscription subscription;

    controller = new StreamController<T>(sync: true,
        onListen: () {
          Sampler sampler;

          switch (ease) {
            case Ease.LINEAR:   sampler = linear;     break;
            case Ease.IN:       sampler = easeIn;     break;
            case Ease.OUT:      sampler = easeOut;    break;
            case Ease.IN_OUT:   sampler = easeInOut;  break;
          }

          final Stream<T> stream = sample(sampler, startValue, changeInTime, duration.inMilliseconds, intervalMs);

          subscription = stream.listen(controller.add,
              onError: (e, s) => throwError(e, s),
              onDone: controller.close);
        },
        onCancel: () => subscription.cancel()
    );

    final StreamObservable<T> observable = new StreamObservable<T>()..setStream(asBroadcastStream ? controller.stream.asBroadcastStream() : controller.stream);

    setStream(observable.interval(new Duration(milliseconds: intervalMs)));
  }

  Stream sample(Sampler sampler, double startValue, double changeInTime, int durationMs, int intervalMs) async* {
    int currentTimeMs = 0;

    yield startValue;

    while (currentTimeMs < durationMs) {
      currentTimeMs += intervalMs;

      yield sampler(startValue, changeInTime, currentTimeMs, durationMs);
    }

    yield startValue + changeInTime;
  }

}

Sampler get linear => (double startValue, double changeInTime, int currentTimeMs, int durationMs) => changeInTime * currentTimeMs / durationMs + startValue;

Sampler get easeIn => (double startValue, double changeInTime, int currentTimeMs, int durationMs) {
  final double t = currentTimeMs / durationMs;

  return changeInTime * t * t + startValue;
};

Sampler get easeOut => (double startValue, double changeInTime, int currentTimeMs, int durationMs) {
  final double t = currentTimeMs / durationMs;

  return -changeInTime * t * (t - 2) + startValue;
};

Sampler get easeInOut => (double startValue, double changeInTime, int currentTimeMs, int durationMs) {
  double t = currentTimeMs / (durationMs / 2);

  if (t < 1.0) return changeInTime / 2 * t * t + startValue;

  t--;

  return -changeInTime / 2 * (t * (t - 2) - 1) + startValue;
};