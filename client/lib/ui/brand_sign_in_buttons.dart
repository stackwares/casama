import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// "Continue with Google" and "Continue with Apple", drawn the way Google's and Apple's
/// branding guidelines ask: the full-colour G on a neutral pill, and the Apple logo on a
/// black pill (white in dark mode). Both follow the theme's brightness.

const _googleG =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">'
    '<path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>'
    '<path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>'
    '<path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>'
    '<path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>'
    '</svg>';

const _appleLogo =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 814 1000">'
    '<path d="M788.1 340.9c-5.8 4.5-108.2 62.2-108.2 190.5 0 148.4 130.3 200.9 134.2 202.2-.6 3.2-20.7 71.9-68.7 141.9-42.8 61.6-87.5 123.1-155.5 123.1s-85.5-39.5-164-39.5c-76.5 0-103.7 40.8-165.9 40.8s-105.6-57-155.5-127C46.7 790.7 0 663 0 541.8c0-194.4 126.4-297.5 250.8-297.5 66.1 0 121.2 43.4 162.7 43.4 39.5 0 101.1-46 176.3-46 28.5 0 130.9 2.6 198.3 99.2zm-234-181.5c31.1-36.9 53.1-88.1 53.1-139.3 0-7.1-.6-14.3-1.9-20.1-50.6 1.9-110.8 33.7-147.1 75.8-28.5 32.4-55.1 83.6-55.1 135.5 0 7.8 1.3 15.6 1.9 18.1 3.2.6 8.4 1.3 13.6 1.3 45.4 0 102.5-30.4 135.5-71.3z"/>'
    '</svg>';

/// The Google and Apple marks as the flutter_svg loaders the buttons draw them with, so startup can
/// parse them before the sign-in sheet opens.
const brandMarkLoaders = [SvgStringLoader(_googleG), SvgStringLoader(_appleLogo)];

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Google Identity colours: light #FFFFFF / #747775 / #1F1F1F, dark #131314 / #8E918F / #E3E3E3.
    return _BrandPill(
      label: label,
      onPressed: onPressed,
      background: dark ? const Color(0xFF131314) : Colors.white,
      foreground: dark ? const Color(0xFFE3E3E3) : const Color(0xFF1F1F1F),
      border: dark ? const Color(0xFF8E918F) : const Color(0xFF747775),
      logo: SvgPicture.string(_googleG, width: 20, height: 20),
    );
  }
}

class AppleSignInButton extends StatelessWidget {
  const AppleSignInButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.black : Colors.white;
    return _BrandPill(
      label: label,
      onPressed: onPressed,
      background: dark ? Colors.white : Colors.black,
      foreground: fg,
      logo: SvgPicture.string(
        _appleLogo,
        width: 18,
        height: 20,
        colorFilter: ColorFilter.mode(fg, BlendMode.srcIn),
      ),
    );
  }
}

class _BrandPill extends StatelessWidget {
  const _BrandPill({
    required this.label,
    required this.onPressed,
    required this.background,
    required this.foreground,
    required this.logo,
    this.border,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;
  final Color? border;
  final Widget logo;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: background.withValues(alpha: 0.6),
          disabledForegroundColor: foreground.withValues(alpha: 0.6),
          side: BorderSide(color: border ?? background),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            logo,
            const SizedBox(width: 12),
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}
