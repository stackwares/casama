import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../core/backend.dart';
import '../../../core/widgets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../files/file_preview.dart';
import 'computer_thumbnail.dart';
import 'media_kind.dart';

/// A PDF in a chat: its first page as a thumbnail over its name and page count; a tap opens
/// the page viewer. A PDF on the bot's computer shows a first-page picture the computer makes
/// (D-226) instead of downloading the whole file (and waking the computer) just for the card.
class ChatPdfCard extends ConsumerWidget {
  const ChatPdfCard({
    super.key,
    required this.attachment,
    this.computerId,
    required this.onTap,
  });
  final AttachmentRef attachment;
  final String? computerId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;
    final path = attachment.isChatMedia
        ? attachment.path
        : (computerPathFromLink(attachment.path) ?? attachment.path);
    final onComputer = !attachment.isChatMedia && computerId != null;
    final thumb = onComputer
        ? ref.watch(computerThumbnailProvider((computerId!, path))).value
        : null;
    final bytes = attachment.isChatMedia && mediaPluginsAvailable
        ? ref.watch(computerFileProvider((computerId ?? '', path))).value
        : null;
    final tone = skeletonColors(context).bone;
    Widget icon() => Center(
      child: Icon(LucideIcons.fileText, size: 36, color: scheme.primary),
    );
    return SizedBox(
      width: 220,
      child: Material(
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.tileAll,
          side: BorderSide(color: context.appColors.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: attachmentKey(attachment.path),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 150,
                child: ColoredBox(
                  color: tone,
                  child: thumb != null
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Image.memory(
                              thumb.bytes,
                              key: const Key('pdfThumbnail'),
                              fit: BoxFit.fitWidth,
                              alignment: Alignment.topCenter,
                              gaplessPlayback: true,
                              errorBuilder: (_, _, _) => icon(),
                            ),
                          ),
                        )
                      : bytes == null
                      ? icon()
                      : PdfDocumentViewBuilder(
                          documentRef: PdfDocumentRefData(
                            bytes,
                            sourceName: path,
                          ),
                          loadingBuilder: (_) => const SizedBox.expand(),
                          errorBuilder: (_, _, _) => icon(),
                          builder: (context, document) => document == null
                              ? const SizedBox.expand()
                              : Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        12,
                                        16,
                                        0,
                                      ),
                                      child: PdfPageView(
                                        document: document,
                                        pageNumber: 1,
                                        maximumDpi: 120,
                                        alignment: Alignment.topCenter,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.12,
                                              ),
                                              blurRadius: 6,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    PositionedDirectional(
                                      end: 8,
                                      bottom: 8,
                                      child: _PageCount(document.pages.length),
                                    ),
                                  ],
                                ),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attachmentLabel(context.l10n, attachment),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      [
                        'PDF',
                        if (attachment.size > 0)
                          formatBytes(attachment.size, context.l10n.localeName),
                      ].join(' · '),
                      style: context.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageCount extends StatelessWidget {
  const _PageCount(this.count);
  final int count;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Text(
        context.l10n.pdfPageCount(count),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

/// A whole PDF to read: pages one under another, zoomable.
class PdfPages extends StatelessWidget {
  const PdfPages({super.key, required this.bytes, required this.name});
  final Uint8List bytes;
  final String name;

  @override
  Widget build(BuildContext context) => PdfViewer.data(
    bytes,
    sourceName: name,
    params: PdfViewerParams(
      backgroundColor: skeletonColors(context).bone,
      margin: 12,
    ),
  );
}
