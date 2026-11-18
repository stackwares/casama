import 'package:flutter_test/flutter_test.dart';
import 'package:casama/core/tool_label.dart';

void main() {
  test('connection tools read as their own name and server', () {
    expect(
      toolLabel('local_mcp.t3code_104fa0.t3_show_thread'),
      't3_show_thread (t3code)',
    );
    expect(toolLabel('mcp.github.create_issue'), 'create_issue (github)');
    expect(toolLabel('shell.exec'), 'shell.exec');
    expect(toolLabel('coding.delegate'), 'coding.delegate');
  });
}
