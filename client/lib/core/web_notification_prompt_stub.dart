/// Phones and desktops ask through the system prompt, not a browser button.
void bindNotificationButton(
  Object element, {
  required String label,
  required String background,
  required String foreground,
  required void Function() onPressed,
}) {}

Future<String> takeWebNotificationPermission() async => 'default';
