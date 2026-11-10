import 'package:kasama_sdk/kasama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/widgets.dart';

import '../../l10n/generated/app_localizations.dart';

/// The words for each kind of device data (D-149).
String deviceKindLabel(AppLocalizations l10n, DeviceKind kind) => switch (kind) {
  DeviceKind.calendar => l10n.deviceKindCalendar,
  DeviceKind.reminders => l10n.deviceKindReminders,
  DeviceKind.contacts => l10n.deviceKindContacts,
  DeviceKind.places => l10n.deviceKindPlaces,
  DeviceKind.photos => l10n.deviceKindPhotos,
  DeviceKind.health => l10n.deviceKindHealth,
  DeviceKind.notifications => l10n.deviceKindNotifications,
  DeviceKind.activity => l10n.deviceKindActivity,
};

IconData deviceKindIcon(DeviceKind kind) => switch (kind) {
  DeviceKind.calendar => LucideIcons.calendar,
  DeviceKind.reminders => LucideIcons.listTodo,
  DeviceKind.contacts => LucideIcons.contact,
  DeviceKind.places => LucideIcons.mapPin,
  DeviceKind.photos => LucideIcons.image,
  DeviceKind.health => LucideIcons.heartPulse,
  DeviceKind.notifications => LucideIcons.bellRing,
  DeviceKind.activity => LucideIcons.activity,
};

/// Default retention (days), matching the server.
int defaultRetentionDays(DeviceKind kind) => switch (kind) {
  DeviceKind.places || DeviceKind.photos || DeviceKind.notifications => 90,
  _ => 365,
};
