import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typefaces (D-087, D-163). These ship with the app, with the weights the theme uses, and work
/// offline. Any other Google Font downloads the first time it's picked and is cached after that.
const bundledFonts = {'Libre Baskerville', 'Lato', 'Google Sans', 'Noto Serif', 'Fraunces', 'Figtree'};

const defaultBodyFont = 'Lato';
const defaultHeadingFont = 'Libre Baskerville';

/// A short list for interface and body text; the picker can also search every Google Font.
const curatedBodyFonts = [
  'Lato',
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
  'Roboto',
];

/// Headline faces: serifs and characterful display sans.
const curatedHeadingFonts = [
  'Libre Baskerville',
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
