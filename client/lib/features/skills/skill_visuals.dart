import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';

/// Icons, colors and labels for skills: catalog skills name a Lucide icon (`icon` in
/// skills/catalog.json); anything unknown falls back to its category's icon, then a book.

/// The icons catalog skills may name. Unknown names fall back, so the server can add new ones
/// before the app knows them.
const _skillIcons = <String, IconData>{
  'notebook-pen': LucideIcons.notebookPen,
  'calendar-clock': LucideIcons.calendarClock,
  'calendar-check': LucideIcons.calendarCheck,
  'mail': LucideIcons.mail,
  'inbox': LucideIcons.inbox,
  'scale': LucideIcons.scale,
  'spell-check': LucideIcons.spellCheck,
  'wand-sparkles': LucideIcons.wandSparkles,
  'megaphone': LucideIcons.megaphone,
  'list-tree': LucideIcons.listTree,
  'file-search': LucideIcons.fileSearch,
  'columns-3': LucideIcons.columns3,
  'badge-check': LucideIcons.badgeCheck,
  'file-text': LucideIcons.fileText,
  'file-pen': LucideIcons.filePen,
  'presentation': LucideIcons.presentation,
  'clipboard-list': LucideIcons.clipboardList,
  'binoculars': LucideIcons.binoculars,
  'newspaper': LucideIcons.newspaper,
  'layout-dashboard': LucideIcons.layoutDashboard,
  'app-window': LucideIcons.appWindow,
  'graduation-cap': LucideIcons.graduationCap,
  'sheet': LucideIcons.sheet,
  'sigma': LucideIcons.sigma,
  'chart-line': LucideIcons.chartLine,
  'wallet': LucideIcons.wallet,
  'receipt': LucideIcons.receipt,
  'git-pull-request': LucideIcons.gitPullRequest,
  'bug': LucideIcons.bug,
  'database': LucideIcons.database,
  'plane': LucideIcons.plane,
  'utensils': LucideIcons.utensils,
  'gift': LucideIcons.gift,
  'dumbbell': LucideIcons.dumbbell,
  'code': LucideIcons.code,
  'sparkles': LucideIcons.sparkles,
};

const _categoryIcons = <String, IconData>{
  'work': LucideIcons.briefcase,
  'writing': LucideIcons.penLine,
  'research': LucideIcons.telescope,
  'data': LucideIcons.table2,
  'money': LucideIcons.coins,
  'build': LucideIcons.code,
  'life': LucideIcons.compass,
};

/// Light and dark shades per category, so tiles stay readable in both themes.
const _categoryColors = <String, (Color, Color)>{
  'work': (Color(0xFF2563EB), Color(0xFF7AA7FF)),
  'writing': (Color(0xFF9333EA), Color(0xFFC79BFF)),
  'research': (Color(0xFF0D9488), Color(0xFF5FD4C8)),
  'data': (Color(0xFF16A34A), Color(0xFF6FD99A)),
  'money': (Color(0xFFD97706), Color(0xFFF5B85C)),
  'build': (Color(0xFF4F46E5), Color(0xFF9D97FF)),
  'life': (Color(0xFFDB2777), Color(0xFFF58BBE)),
};

IconData skillCategoryIcon(String? category) =>
    _categoryIcons[category] ?? LucideIcons.bookOpen;

IconData skillIcon({String? icon, String? category}) =>
    _skillIcons[icon] ?? skillCategoryIcon(category);

/// The category's tint; skills without one use the theme's primary color.
Color skillCategoryColor(BuildContext context, String? category) {
  final pair = _categoryColors[category];
  if (pair == null) return context.colorScheme.primary;
  return context.isDark ? pair.$2 : pair.$1;
}

String skillCategoryLabel(BuildContext context, String category) {
  final l10n = context.l10n;
  return switch (category) {
    'work' => l10n.skillCategoryWork,
    'writing' => l10n.skillCategoryWriting,
    'research' => l10n.skillCategoryResearch,
    'data' => l10n.skillCategoryData,
    'money' => l10n.skillCategoryMoney,
    'build' => l10n.skillCategoryBuild,
    'life' => l10n.skillCategoryLife,
    _ =>
      category.isEmpty
          ? category
          : '${category[0].toUpperCase()}${category.substring(1)}',
  };
}

/// `meeting-notes` → `Meeting notes`, for titles; the slug stays visible as the `/` command.
String skillTitle(String name) {
  final words = [
    for (final w in name.split(RegExp('[-_]+')))
      if (w.isNotEmpty) _acronyms.contains(w) ? w.toUpperCase() : w,
  ];
  if (words.isEmpty) return name;
  final first = words.first;
  words[0] = '${first[0].toUpperCase()}${first.substring(1)}';
  return words.join(' ');
}

const _acronyms = {
  'csv',
  'sql',
  'pdf',
  'docx',
  'xlsx',
  'pptx',
  'api',
  'ai',
  'pr',
  'seo',
  'ui',
  'ux',
  'url',
  'json',
  'html',
  'css',
};

/// A rounded tile with the skill's icon on a soft wash of its category color.
class SkillIconTile extends StatelessWidget {
  const SkillIconTile({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
  });
  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color.withValues(alpha: context.isDark ? 0.2 : 0.12),
      borderRadius: BorderRadius.circular(
        size >= 56 ? AppRadius.card : AppRadius.icon + 2,
      ),
    ),
    alignment: Alignment.center,
    child: Icon(icon, size: size * 0.5, color: color),
  );
}
