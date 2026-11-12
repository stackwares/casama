import 'package:material_ui/material_ui.dart';

/// Colors that carry meaning. Surfaces stay neutral; these mark small things only (status dots,
/// risk, results). Read them with `context.appColors`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.positive,
    required this.negative,
    required this.warning,
    required this.info,
    required this.hairline,
    required this.working,
    required this.waiting,
    required this.idle,
    required this.codeBackground,
  });

  final Color positive;
  final Color negative;
  final Color warning;
  final Color info;

  /// Card borders and dividers.
  final Color hairline;

  /// Bot status dots.
  final Color working;
  final Color waiting;
  final Color idle;

  /// Code blocks and tool output.
  final Color codeBackground;

  static const dark = AppColors(
    positive: Color(0xFF5FD49A),
    negative: Color(0xFFFF7A7A),
    warning: Color(0xFFF0A84A),
    info: Color(0xFF6E9BFF),
    hairline: Color(0xFF25272B),
    working: Color(0xFF5FD49A),
    waiting: Color(0xFFF0A84A),
    idle: Color(0xFF6B7079),
    codeBackground: Color(0xFF111214),
  );

  static const light = AppColors(
    positive: Color(0xFF1E8E5A),
    negative: Color(0xFFD93B3B),
    warning: Color(0xFFB86E00),
    info: Color(0xFF2F6FE4),
    hairline: Color(0xFFE3E5E8),
    working: Color(0xFF1FA463),
    waiting: Color(0xFFD08700),
    idle: Color(0xFFA0A5AE),
    codeBackground: Color(0xFFF4F5F7),
  );

  static AppColors of(BuildContext context) => Theme.of(context).extension<AppColors>() ?? (Theme.of(context).brightness == Brightness.dark ? dark : light);

  @override
  AppColors copyWith({
    Color? positive,
    Color? negative,
    Color? warning,
    Color? info,
    Color? hairline,
    Color? working,
    Color? waiting,
    Color? idle,
    Color? codeBackground,
  }) => AppColors(
    positive: positive ?? this.positive,
    negative: negative ?? this.negative,
    warning: warning ?? this.warning,
    info: info ?? this.info,
    hairline: hairline ?? this.hairline,
    working: working ?? this.working,
    waiting: waiting ?? this.waiting,
    idle: idle ?? this.idle,
    codeBackground: codeBackground ?? this.codeBackground,
  );

  @override
  AppColors lerp(covariant AppColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      positive: l(positive, other.positive),
      negative: l(negative, other.negative),
      warning: l(warning, other.warning),
      info: l(info, other.info),
      hairline: l(hairline, other.hairline),
      working: l(working, other.working),
      waiting: l(waiting, other.waiting),
      idle: l(idle, other.idle),
      codeBackground: l(codeBackground, other.codeBackground),
    );
  }
}

extension AppThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  AppColors get appColors => AppColors.of(this);
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
