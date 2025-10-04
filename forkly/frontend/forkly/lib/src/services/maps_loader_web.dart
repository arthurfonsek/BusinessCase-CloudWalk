import 'dart:async';
import 'dart:html' as html; // web only

Completer<void>? _gmapsLoaded;

Future<void> ensureGoogleMapsLoaded(String apiKey) async {
  if (_gmapsLoaded != null) {
    return _gmapsLoaded!.future;
  }
  _gmapsLoaded = Completer<void>();

  final script = html.ScriptElement()
    ..type = 'text/javascript'
    ..async = true
    ..defer = true
    ..src = 'https://maps.googleapis.com/maps/api/js?key=${Uri.encodeComponent(apiKey)}';

  script.onLoad.first.then((_) {
    if (!_gmapsLoaded!.isCompleted) _gmapsLoaded!.complete();
  });
  script.onError.first.then((_) {
    if (!_gmapsLoaded!.isCompleted) {
      _gmapsLoaded!.completeError(StateError('Failed to load Google Maps JS'));
    }
  });

  html.document.head!.append(script);

  return _gmapsLoaded!.future;
}
