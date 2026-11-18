import 'generated/run_events.dart';

/// Orders run events by seq, drops duplicates and reports gaps.
///
/// Live events (Realtime) and catch-up events (GET /v1/runs/{id}/events?after_seq=N)
/// both go through [add]; events are released strictly in seq order.
class RunEventBuffer {
  RunEventBuffer({this.lastSeq = 0});

  /// Highest seq released so far.
  int lastSeq;
  final Map<int, RunEventItem> _pending = {};

  /// True when events after [lastSeq] are held back waiting for a missing seq.
  bool get hasGap => _pending.isNotEmpty || _skipped.isNotEmpty;

  /// Seqs given up on (an event this client can't read), so they never hold the rest back.
  final Set<int> _skipped = {};

  /// Adds an event and returns the events that are now ready, in order.
  List<RunEventItem> add(RunEventItem event) {
    if (event.seq <= lastSeq || _pending.containsKey(event.seq)) return const [];
    _pending[event.seq] = event;
    return _drain();
  }

  /// Gives up on [seq] (it couldn't be parsed) and returns the events that were waiting behind it.
  /// Without this, one unreadable event would stop every later one forever.
  List<RunEventItem> skip(int seq) {
    if (seq <= lastSeq) return const [];
    _pending.remove(seq);
    _skipped.add(seq);
    return _drain();
  }

  List<RunEventItem> _drain() {
    final ready = <RunEventItem>[];
    for (;;) {
      final next = lastSeq + 1;
      if (_skipped.remove(next)) {
        lastSeq = next;
      } else if (_pending.containsKey(next)) {
        ready.add(_pending.remove(next)!);
        lastSeq = next;
      } else {
        break;
      }
    }
    return ready;
  }

  List<RunEventItem> addAll(Iterable<RunEventItem> events) =>
      [for (final e in events) ...add(e)];
}
