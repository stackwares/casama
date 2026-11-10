import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typefaces (D-087). These four ship with the app, with every weight, and work offline. Any other
/// Google Font downloads the first time it's picked and is cached after that.
const bundledFonts = {'Google Sans', 'Noto Serif', 'Fraunces', 'Figtree'};

const defaultBodyFont = 'Google Sans';
const defaultHeadingFont = 'Noto Serif';

/// A short list for interface and body text; the picker can also search every Google Font.
const curatedBodyFonts = [
  'Google Sans',
  'Figtree',
  'Inter',
  'Plus Jakarta Sans',
  'DM Sans',
  'Manrope',
  'Nunito',
  'Outfit',
  'Poppins',
  'Lexend',
  'Work Sans',
  'Rubik',
  'Sora',
  'Urbanist',
  'Quicksand',
  'Onest',
  'Geist',
  'Atkinson Hyperlegible',
  'IBM Plex Sans',
  'Noto Sans',
  'Source Sans 3',
  'Open Sans',
  'Lato',
  'Roboto',
];

/// Headline faces: serifs and characterful display sans.
const curatedHeadingFonts = [
  'Noto Serif',
  'Fraunces',
  'Playfair Display',
  'Instrument Serif',
  'DM Serif Display',
  'Young Serif',
  'Lora',
  'Newsreader',
  'Source Serif 4',
  'Merriweather',
  'EB Garamond',
  'Crimson Pro',
  'Libre Baskerville',
  'Bricolage Grotesque',
  'Space Grotesk',
  'Fredoka',
  'Baloo 2',
  'Google Sans',
  'Figtree',
];

/// Every Google Font family the picker can search.
List<String> allGoogleFonts() => GoogleFonts.asMap().keys.toList();

/// [base] in [family]: bundled families by name (every weight available), others through
/// google_fonts (downloaded on first use). Unknown families fall back to [base].
TextStyle fontStyle(String family, TextStyle base) {
  if (bundledFonts.contains(family)) return base.copyWith(fontFamily: family);
  try {
    return GoogleFonts.getFont(family, textStyle: base);
  } catch (_) {
    return base;
  }
}
