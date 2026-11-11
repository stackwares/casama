import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/distribution.dart';

/// Desktop context (SPEC: Desktop context; D-152): what the quick-ask hotkey attaches, read only at
/// the moment it's pressed — the front app and window title, the selected text, the browser tab —
/// and a screenshot only when the person adds one. macOS uses Accessibility and Apple Events,
/// Windows UI Automation, Linux X11 tools.
class DesktopContext {
  const DesktopContext({this.app, this.window, this.selection, this.url, this.tabTitle});
  final String? app;
  final String? window;
  final String? selection;
  final String? url;
  final String? tabTitle;
  bool get isEmpty => app == null && window == null && selection == null && url == null;
}

typedef Run = Future<ProcessResult> Function(String exe, List<String> args);
Future<ProcessResult> _run(String exe, List<String> args) => Process.run(exe, args);

bool get desktopContextSupported => !kIsWeb && !isMacAppStoreBuild && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

const _browsers = {'Google Chrome', 'Arc', 'Brave Browser', 'Microsoft Edge', 'Chromium', 'Vivaldi', 'Opera'};

class DesktopContextReader {
  DesktopContextReader({Run? run, String? platform}) : _r = run ?? _run, _platform = platform ?? (kIsWeb ? 'web' : Platform.operatingSystem);
  final Run _r;
  final String _platform;

  Future<String?> _out(String exe, List<String> args) async {
    try {
      final r = await _r(exe, args).timeout(const Duration(seconds: 2));
      if (r.exitCode != 0) return null;
      final t = '${r.stdout}'.trim();
      return t.isEmpty ? null : t;
    } catch (_) {
      return null;
    }
  }

  /// Reads what's in front (call it before Kasama's own window comes forward).
  Future<DesktopContext> capture() async {
    switch (_platform) {
      case 'macos':
        final front = await _out('osascript', [
          '-e',
          'tell application "System Events" to set p to first application process whose frontmost is true',
          '-e',
          'set n to name of p',
          '-e',
          'set t to ""',
          '-e',
          'try',
          '-e',
          'tell application "System Events" to set t to name of front window of p',
          '-e',
          'end try',
          '-e',
          'return n & linefeed & t',
        ]);
        final lines = front?.split('\n') ?? const [];
        final app = lines.isNotEmpty ? lines[0] : null;
        final window = lines.length > 1 && lines[1].isNotEmpty ? lines[1] : null;
        final selection = await _out('osascript', [
          '-l',
          'JavaScript',
          '-e',
          "var se=Application('System Events');var p=se.processes.whose({frontmost:true})[0];var e=p.attributes.byName('AXFocusedUIElement').value();e.attributes.byName('AXSelectedText').value()",
        ]);
        String? url, tab;
        if (app != null && _browsers.contains(app)) {
          final t = await _out('osascript', ['-e', 'tell application "$app" to return (URL of active tab of front window) & linefeed & (title of active tab of front window)']);
          (url, tab) = _pair(t);
        } else if (app == 'Safari') {
          final t = await _out('osascript', ['-e', 'tell application "Safari" to return (URL of front document) & linefeed & (name of front document)']);
          (url, tab) = _pair(t);
        }
        return DesktopContext(app: app, window: window, selection: selection, url: url, tabTitle: tab);
      case 'linux':
        final window = await _out('xdotool', ['getactivewindow', 'getwindowname']);
        final pid = await _out('xdotool', ['getactivewindow', 'getwindowpid']);
        final app = pid == null ? null : await _out('cat', ['/proc/$pid/comm']);
        final selection = await _out('xclip', ['-o', '-selection', 'primary']) ?? await _out('xsel', ['-o', '-p']);
        return DesktopContext(app: app, window: window, selection: selection);
      case 'windows':
        // The foreground window's title and process, and the focused element's selected text (UI Automation).
        final out = await _out('powershell', [
          '-NoProfile',
          '-Command',
          r'''Add-Type @"
using System;using System.Runtime.InteropServices;using System.Text;
public class W{[DllImport("user32.dll")]public static extern IntPtr GetForegroundWindow();[DllImport("user32.dll")]public static extern int GetWindowText(IntPtr h,StringBuilder s,int n);[DllImport("user32.dll")]public static extern uint GetWindowThreadProcessId(IntPtr h,out uint p);}
"@
$h=[W]::GetForegroundWindow();$s=New-Object System.Text.StringBuilder 512;[void][W]::GetWindowText($h,$s,512);$p=0;[void][W]::GetWindowThreadProcessId($h,[ref]$p)
$n=(Get-Process -Id $p).ProcessName;$sel=''
try{Add-Type -AssemblyName UIAutomationClient;$e=[System.Windows.Automation.AutomationElement]::FocusedElement;$tp=$e.GetCurrentPattern([System.Windows.Automation.TextPattern]::Pattern);$sel=($tp.GetSelection()|%{$_.GetText(4000)}) -join ''}catch{}
"$n`n$($s.ToString())`n$sel"''',
        ]);
        final parts = out?.split('\n') ?? const [];
        String? at(int i) => parts.length > i && parts[i].trim().isNotEmpty ? parts[i].trim() : null;
        return DesktopContext(app: at(0), window: at(1), selection: parts.length > 2 ? (parts.sublist(2).join('\n').trim().isEmpty ? null : parts.sublist(2).join('\n').trim()) : null);
      default:
        return const DesktopContext();
    }
  }

  (String?, String?) _pair(String? t) {
    if (t == null) return (null, null);
    final i = t.indexOf('\n');
    return i < 0 ? (t, null) : (t.substring(0, i), t.substring(i + 1));
  }

  /// Just the front app and window title (the activity recap samples this; never the selection).
  Future<DesktopContext> captureWindow() async {
    switch (_platform) {
      case 'macos':
        final front = await _out('osascript', [
          '-e',
          'tell application "System Events" to set p to first application process whose frontmost is true',
          '-e',
          'set n to name of p',
          '-e',
          'set t to ""',
          '-e',
          'try',
          '-e',
          'tell application "System Events" to set t to name of front window of p',
          '-e',
          'end try',
          '-e',
          'return n & linefeed & t',
        ]);
        final lines = front?.split('\n') ?? const [];
        return DesktopContext(app: lines.isNotEmpty ? lines[0] : null, window: lines.length > 1 && lines[1].isNotEmpty ? lines[1] : null);
      case 'linux':
        final pid = await _out('xdotool', ['getactivewindow', 'getwindowpid']);
        return DesktopContext(app: pid == null ? null : await _out('cat', ['/proc/$pid/comm']), window: await _out('xdotool', ['getactivewindow', 'getwindowname']));
      default:
        final c = await capture();
        return DesktopContext(app: c.app, window: c.window);
    }
  }

  /// A full-screen screenshot (only when the person asks for one).
  Future<Uint8List?> screenshot() async {
    final f = File('${Directory.systemTemp.path}/kasama-shot-${DateTime.now().microsecondsSinceEpoch}.png');
    try {
      final ok = switch (_platform) {
        'macos' => await _out('screencapture', ['-x', '-t', 'png', f.path]) != null || f.existsSync(),
        'linux' => await _out('gnome-screenshot', ['-f', f.path]) != null || f.existsSync() || await _out('import', ['-window', 'root', f.path]) != null || f.existsSync(),
        'windows' =>
          await _out('powershell', [
                    '-NoProfile',
                    '-Command',
                    'Add-Type -AssemblyName System.Windows.Forms,System.Drawing;\$b=[System.Windows.Forms.SystemInformation]::VirtualScreen;\$i=New-Object System.Drawing.Bitmap \$b.Width,\$b.Height;\$g=[System.Drawing.Graphics]::FromImage(\$i);\$g.CopyFromScreen(\$b.Left,\$b.Top,0,0,\$i.Size);\$i.Save("${f.path}")',
                  ]) !=
                  null ||
              f.existsSync(),
        _ => false,
      };
      if (!ok || !f.existsSync()) return null;
      return await f.readAsBytes();
    } finally {
      if (f.existsSync()) f.deleteSync();
    }
  }
}

/// The context read when the hotkey was pressed, waiting for the quick-ask window.
class PendingDesktopContext extends Notifier<DesktopContext?> {
  @override
  DesktopContext? build() => null;
  void set(DesktopContext? c) => state = c;
}

final pendingDesktopContextProvider = NotifierProvider<PendingDesktopContext, DesktopContext?>(PendingDesktopContext.new);
final desktopContextReaderProvider = Provider<DesktopContextReader>((ref) => DesktopContextReader());

/// The block added to the message: what was selected and where it came from (only the parts kept).
String formatDesktopContext(DesktopContext c, {bool selection = true, bool window = true, bool tab = true}) {
  final where = [if (window && c.app != null) c.app!, if (window && c.window != null && c.window != c.app) c.window!].join(' — ');
  final lines = <String>[
    if (where.isNotEmpty) 'From: $where',
    if (tab && c.url != null) 'Browser tab: ${c.tabTitle != null ? '${c.tabTitle} ' : ''}(${c.url})',
    if (selection && c.selection != null) 'Selected text:\n${c.selection!.length > 8000 ? '${c.selection!.substring(0, 8000)}…' : c.selection!}',
  ];
  return lines.join('\n');
}
