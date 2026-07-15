import 'package:flutter/material.dart';

import 'astryx_palette.dart';

/// Source metadata for the upstream Astryx neutral theme port.
abstract final class AstryxSource {
  static const package = '@astryxdesign/theme-neutral';
  static const version = '0.1.5';
  static const commit = 'c4c1f5b4430b5b83470219bd382465ff1bc7b69e';
  static const repository = 'https://github.com/facebook/astryx';
}

/// Radius tokens from Astryx neutral.
abstract final class AstryxRadii {
  static const none = 4.0;
  static const inner = 6.0;
  static const element = 10.0;
  static const container = 12.0;
  static const page = 28.0;
  static const full = 9999.0;
}

/// Motion tokens from Astryx neutral.
abstract final class AstryxMotion {
  static const fast = Duration(milliseconds: 125);
  static const medium = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 700);
}

/// Light and dark semantic color tokens from Astryx neutral.
abstract final class AstryxTokens {
  static const light = AstryxPalette(
    surface: Color(0xFFFFFFFF),
    body: Color(0xFFF1F1F1),
    card: Color(0xFFFFFFFF),
    popover: Color(0xFFFFFFFF),
    muted: Color(0xFFF1F1F1),
    accent: Color(0xFF262626),
    accentMuted: Color(0xFFF1F1F1),
    neutral: Color(0x0F000000),
    overlay: Color(0x80000000),
    overlayHover: Color(0x0D000000),
    overlayPressed: Color(0x1A000000),
    textPrimary: Color(0xFF171717),
    textSecondary: Color(0xFF737373),
    textDisabled: Color(0xFFA3A3A3),
    onAccent: Color(0xFFFFFFFF),
    success: Color(0xFF007004),
    error: Color(0xFFA50C25),
    warning: Color(0xFF745B00),
    successMuted: Color(0xFFC5E5C0),
    errorMuted: Color(0xFFFACECB),
    warningMuted: Color(0xFFF8DA9D),
    border: Color(0xFFEBEBEB),
    borderEmphasized: Color(0xFFD4D4D4),
    categories: _lightCategories,
  );

  static const dark = AstryxPalette(
    surface: Color(0xFF262626),
    body: Color(0xFF1B1B1B),
    card: Color(0xFF1B1B1B),
    popover: Color(0xFF1B1B1B),
    muted: Color(0xFF1B1B1B),
    accent: Color(0xFFEBEBEB),
    accentMuted: Color(0xFF262626),
    neutral: Color(0x1AFFFFFF),
    overlay: Color(0xCC000000),
    overlayHover: Color(0x0DFFFFFF),
    overlayPressed: Color(0x1AFFFFFF),
    textPrimary: Color(0xFFFAFAFA),
    textSecondary: Color(0xFFA3A3A3),
    textDisabled: Color(0xFF525252),
    onAccent: Color(0xFF171717),
    success: Color(0xFF9FE59B),
    error: Color(0xFFFFC6C1),
    warning: Color(0xFFFDCF4F),
    successMuted: Color(0x3D84C980),
    errorMuted: Color(0x3DFF9E97),
    warningMuted: Color(0x3DDEB433),
    border: Color(0x1AFFFFFF),
    borderEmphasized: Color(0xFF525252),
    categories: _darkCategories,
  );

  static const _lightCategories = <AstryxCategory, AstryxCategoryColors>{
    AstryxCategory.red: AstryxCategoryColors(
      background: Color(0xFFFACECB),
      border: Color(0xFFE6BAB8),
      icon: Color(0xFF89001A),
      text: Color(0xFF89001A),
    ),
    AstryxCategory.orange: AstryxCategoryColors(
      background: Color(0xFFFAD0B5),
      border: Color(0xFFE6BDA2),
      icon: Color(0xFF6E3500),
      text: Color(0xFF6E3500),
    ),
    AstryxCategory.yellow: AstryxCategoryColors(
      background: Color(0xFFF8DA9D),
      border: Color(0xFFE4C279),
      icon: Color(0xFF584400),
      text: Color(0xFF584400),
    ),
    AstryxCategory.green: AstryxCategoryColors(
      background: Color(0xFFC5E5C0),
      border: Color(0xFFB2D1AC),
      icon: Color(0xFF0C5700),
      text: Color(0xFF0C5700),
    ),
    AstryxCategory.teal: AstryxCategoryColors(
      background: Color(0xFFA5E3D6),
      border: Color(0xFF94D6C8),
      icon: Color(0xFF005348),
      text: Color(0xFF005348),
    ),
    AstryxCategory.cyan: AstryxCategoryColors(
      background: Color(0xFFA3E0EF),
      border: Color(0xFF91D3E3),
      icon: Color(0xFF00505F),
      text: Color(0xFF00505F),
    ),
    AstryxCategory.blue: AstryxCategoryColors(
      background: Color(0xFFC4DDFB),
      border: Color(0xFFB1C9E7),
      icon: Color(0xFF00458C),
      text: Color(0xFF00458C),
    ),
    AstryxCategory.purple: AstryxCategoryColors(
      background: Color(0xFFECCEF3),
      border: Color(0xFFD8BBDF),
      icon: Color(0xFF700084),
      text: Color(0xFF700084),
    ),
    AstryxCategory.pink: AstryxCategoryColors(
      background: Color(0xFFFCCADC),
      border: Color(0xFFE7B7C8),
      icon: Color(0xFF83004B),
      text: Color(0xFF83004B),
    ),
    AstryxCategory.gray: AstryxCategoryColors(
      background: Color(0xFFE5E5E5),
      border: Color(0xFFD4D4D4),
      icon: Color(0xFF525252),
      text: Color(0xFF262626),
    ),
  };

  static const _darkCategories = <AstryxCategory, AstryxCategoryColors>{
    AstryxCategory.red: AstryxCategoryColors(
      background: Color(0x3DFF9E97),
      border: Color(0xFFFF6F6C),
      icon: Color(0xFFFF9E97),
      text: Color(0xFFFFC6C1),
    ),
    AstryxCategory.orange: AstryxCategoryColors(
      background: Color(0x3DFFA258),
      border: Color(0xFFE2883E),
      icon: Color(0xFFFFA258),
      text: Color(0xFFFFC9A2),
    ),
    AstryxCategory.yellow: AstryxCategoryColors(
      background: Color(0x3DDEB433),
      border: Color(0xFFC0990E),
      icon: Color(0xFFDEB433),
      text: Color(0xFFFDCF4F),
    ),
    AstryxCategory.green: AstryxCategoryColors(
      background: Color(0x3D84C980),
      border: Color(0xFF69AD67),
      icon: Color(0xFF84C980),
      text: Color(0xFF9FE59B),
    ),
    AstryxCategory.teal: AstryxCategoryColors(
      background: Color(0x3D7EC6B8),
      border: Color(0xFF63AB9D),
      icon: Color(0xFF7EC6B8),
      text: Color(0xFF99E2D3),
    ),
    AstryxCategory.cyan: AstryxCategoryColors(
      background: Color(0x3D83C2D4),
      border: Color(0xFF67A7B8),
      icon: Color(0xFF83C2D4),
      text: Color(0xFF9EDEF0),
    ),
    AstryxCategory.blue: AstryxCategoryColors(
      background: Color(0x3D9EB7FF),
      border: Color(0xFF6D9CFE),
      icon: Color(0xFF9EB7FF),
      text: Color(0xFFC7D3FF),
    ),
    AstryxCategory.purple: AstryxCategoryColors(
      background: Color(0x3DF297FF),
      border: Color(0xFFDD74F0),
      icon: Color(0xFFF297FF),
      text: Color(0xFFFAC1FF),
    ),
    AstryxCategory.pink: AstryxCategoryColors(
      background: Color(0x3DFF99C3),
      border: Color(0xFFF273AA),
      icon: Color(0xFFFF99C3),
      text: Color(0xFFFFC3DA),
    ),
    AstryxCategory.gray: AstryxCategoryColors(
      background: Color(0x1AFFFFFF),
      border: Color(0xFF262626),
      icon: Color(0xFFA3A3A3),
      text: Color(0xFFE5E5E5),
    ),
  };
}
