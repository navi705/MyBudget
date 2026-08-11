import 'package:bloc/bloc.dart';

/// Guards state/event delivery during the window `Bloc.close()` leaves open.
///
/// In bloc 9.1.0, `Bloc.close()` closes the event controller FIRST and only
/// flips `isClosed` at the very end, and it does not wait for in-flight
/// handlers - it cancels their emitters, which completes their futures
/// immediately while the handler bodies keep running. So a handler sitting on
/// an `await` when `close()` starts still sees `isClosed == false`, proceeds
/// past a bare `if (isClosed) return;` guard, and its later `add()` throws
/// "Bad state: Cannot add new events after calling close". `isClosed` alone
/// is therefore not a safe guard for anything that resumes after an `await`.
///
/// Mix this in, call [markClosing] as the very first statement of an
/// overridden `close()` (before any `await`), and guard every post-await
/// `add()`/`emit()`/resubscribe with [isShuttingDown] instead of bare
/// `isClosed`.
mixin BlocShutdownGuard<Event, State> on Bloc<Event, State> {
  bool _closeRequested = false;

  /// Set synchronously as the first statement of `close()`, before any await.
  void markClosing() {
    _closeRequested = true;
  }

  /// Guard for anything that resumes after an `await`. `isClosed` on its own is
  /// not enough: Bloc.close() closes the event controller first and only flips
  /// `isClosed` at the very end, and it does not wait for in-flight handlers -
  /// so a handler resuming in that window sees `isClosed == false` while add()
  /// already throws "Cannot add new events after calling close".
  bool get isShuttingDown => _closeRequested || isClosed;
}
