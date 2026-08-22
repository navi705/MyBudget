import 'package:bloc/bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/presentation/blocs/bloc_lifecycle.dart';

class _Event {}

class _State {}

/// Minimal bloc exercising [BlocShutdownGuard] exactly the way every real
/// bloc in this app is required to: [markClosing] as the very first
/// statement of `close()`, before any await.
class _GuardedBloc extends Bloc<_Event, _State>
    with BlocShutdownGuard<_Event, _State> {
  _GuardedBloc() : super(_State()) {
    on<_Event>((event, emit) {});
  }

  @override
  Future<void> close() async {
    markClosing();
    // Simulates real close() overrides, which always have at least one
    // await (a subscription cancel) between markClosing() and super.close().
    await Future<void>.value();
    return super.close();
  }
}

void main() {
  group('BlocShutdownGuard', () {
    test('isShuttingDown and isClosed both start false', () {
      final bloc = _GuardedBloc();
      expect(bloc.isShuttingDown, isFalse);
      expect(bloc.isClosed, isFalse);
      bloc.close();
    });

    test('isShuttingDown flips synchronously the instant close() is called, '
        'strictly before isClosed does', () async {
      final bloc = _GuardedBloc();

      // close() is deliberately NOT awaited here: markClosing() is the
      // first statement in close(), so it has already run by the time
      // close() returns control to us, well before the await inside
      // close() (or super.close() itself) resolves.
      final closeFuture = bloc.close();

      expect(
        bloc.isShuttingDown,
        isTrue,
        reason:
            'markClosing() runs synchronously as the first statement of '
            'close(), before any await — this is the property every '
            'post-await guard in the real blocs depends on.',
      );
      expect(
        bloc.isClosed,
        isFalse,
        reason:
            'isClosed only flips once the whole close() chain resolves. A '
            'guard written as `if (isClosed) return;` would NOT see the '
            'shutdown here, which is exactly the bug this mixin fixes.',
      );

      await closeFuture;
      expect(bloc.isClosed, isTrue);
      expect(bloc.isShuttingDown, isTrue);
    });

    test('markClosing is idempotent and safe to call multiple times', () {
      final bloc = _GuardedBloc();
      bloc.markClosing();
      bloc.markClosing();
      expect(bloc.isShuttingDown, isTrue);
      bloc.close();
    });
  });
}
