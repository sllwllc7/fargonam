/// Tugma bir marta bosilganda qayta bosilmasligi uchun guard.
bool _actionBusy = false;

Future<void> guardedAction(Future<void> Function() action) async {
  if (_actionBusy) return;
  _actionBusy = true;
  try {
    await action();
  } finally {
    _actionBusy = false;
  }
}
