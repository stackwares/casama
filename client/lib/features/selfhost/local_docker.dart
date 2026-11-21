import 'package:casama_sdk/casama_link.dart';

import 'docker_check.dart';
import 'local_server.dart';

/// Whether [apiUrl] is the server this app installed on this computer and Docker is why it
/// doesn't answer (closed after a restart, or quit from its menu). The "can't reach" bar and the
/// launch screen then say so and offer to open Docker; the server's containers start again by
/// themselves once Docker is up (`restart: unless-stopped`).
Future<bool> localDockerDown(
  String apiUrl, {
  LocalServerManager? manager,
  DockerCheck? docker,
}) async {
  if (!localServerSupported) return false;
  try {
    final local = await (manager ?? LocalServerManager()).installed();
    if (local == null) return false;
    final using = Uri.tryParse(apiUrl);
    final own = Uri.parse(local.url);
    if (using == null ||
        using.port != own.port ||
        !RemoteAccessSettings.isLoopback(using.host)) {
      return false;
    }
    return await (docker ?? DockerCheck()).state() != DockerState.ready;
  } catch (_) {
    return false;
  }
}

/// Tests replace these.
Future<bool> Function(String apiUrl) checkLocalDocker = localDockerDown;
Future<bool> Function() openDocker = () => DockerCheck().open();
bool Function() canOpenDocker = () => DockerCheck().isMac;
