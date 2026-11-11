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
  bool get hasGap => _pending.isNotEmpty;

  /// Adds an event and returns the events that are now ready, in order.
  List<RunEventItem> add(RunEventItem event) {
    if (event.seq <= lastSeq || _pending.containsKey(event.seq)) return const [];
    _pending[event.seq] = event;
    final ready = <RunEventItem>[];
    while (_pending.containsKey(lastSeq + 1)) {
      ready.add(_pending.remove(lastSeq + 1)!);
      lastSeq++;
    }
    return ready;
  }

  List<RunEventItem> addAll(Iterable<RunEventItem> events) =>
      [for (final e in events) ...add(e)];
}
