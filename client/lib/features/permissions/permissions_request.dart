/// What a `device.permission_needed` event asked for (D-376).
class PermissionsRequest {
  const PermissionsRequest({required this.deviceRef, required this.deviceName, required this.platform, required this.permissions, required this.reason, required this.botId});
  final String deviceRef;
  final String deviceName;
  final String platform;
  final List<String> permissions;
  final String reason;
  final String botId;
}
