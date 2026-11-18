/// A card's button tapped on another device reaches this computer over the companion's socket as
/// `{"type":"permission","permission":"<id>","do":"request|open_settings|relaunch"}` (D-376). The
/// companion hands it here; [PermissionsReporter] sets the handler while signed in.
typedef CompanionPermissionHandler = Future<void> Function(Map<String, dynamic> message);

CompanionPermissionHandler? companionPermissionHandler;
