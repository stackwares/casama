/// Daemon inside each Casama computer.
library;

export 'src/mcp_address.dart';
export 'src/mcp_bridge.dart' show LocalMcpServer, McpBridge, McpBridgeError;
export 'src/mcp_oauth.dart' hide JsonMap;
export 'src/server.dart';
export 'src/thumbnails.dart' show ThumbnailKind, ThumbnailTools, ToolResult, thumbnailKindFor;
