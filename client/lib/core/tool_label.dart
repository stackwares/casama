/// A connection's tool as people know it: `local_mcp.t3code_104fa0.t3_show_thread` reads as
/// "t3_show_thread (t3code)". The kind prefix and the 6-hex suffix that keeps names unique mean
/// nothing to someone approving it. Built-in tools (shell.exec) keep their names. Same rule as the
/// server's approval summaries.
String toolLabel(String tool) {
  final m = RegExp(r'^(?:mcp|local_mcp|computer_mcp|composio)\.([^.]+)\.(.+)$')
      .firstMatch(tool);
  if (m == null) return tool;
  final server = m.group(1)!.replaceFirst(RegExp(r'_[0-9a-f]{6}$'), '');
  return '${m.group(2)} ($server)';
}
