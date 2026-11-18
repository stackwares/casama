/// Not on the web: the browser's Permissions API doesn't exist here.
Future<String> webPermissionState(String id) async => 'unavailable';

Future<String> webPermissionRequest(String id) async => 'unavailable';
