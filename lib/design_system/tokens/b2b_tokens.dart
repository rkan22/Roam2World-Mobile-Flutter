import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

abstract final class B2BSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
}

abstract final class B2BRadius {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 30;
  static const double pill = 999;
  static const double full = pill;
}

abstract final class B2BMotion {
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration standard = Duration(milliseconds: 280);
}

abstract final class B2BShadows {
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0D0F172A), blurRadius: 24, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> elevated = [
    BoxShadow(color: Color(0x140F172A), blurRadius: 34, offset: Offset(0, 14)),
  ];

  static const List<BoxShadow> hero = [
    BoxShadow(color: Color(0x2607ACE9), blurRadius: 38, offset: Offset(0, 18)),
  ];
}

abstract final class B2BGradients {
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.heroStart, AppColors.heroMiddle, AppColors.heroEnd],
  );

  static const LinearGradient soft = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF8FAFC), Color(0xFFF7F0FF)],
  );
}
