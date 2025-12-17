import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Modern App Colors with enhanced gradients
class AppColors {
  // Primary gradient colors - Deep Purple to Blue
  static const Color primaryStart = Color(0xFF667EEA);
  static const Color primaryEnd = Color(0xFF764BA2);
  
  // Secondary gradient colors - Cyan to Blue
  static const Color secondaryStart = Color(0xFF00D2FF);
  static const Color secondaryEnd = Color(0xFF3A7BD5);
  
  // Success gradient - Green tones
  static const Color successStart = Color(0xFF00E396);
  static const Color successEnd = Color(0xFF06B88D);
  
  // Warning gradient - Orange to Red
  static const Color warningStart = Color(0xFFFF6B6B);
  static const Color warningEnd = Color(0xFFEE5A6F);
  
  // Accent colors
  static const Color accentGreen = Color(0xFF00E396);
  static const Color accentOrange = Color(0xFFFF6B6B);
  static const Color accentYellow = Color(0xFFFFD93D);
  static const Color accentPurple = Color(0xFF9D50BB);
  
  // Neutral colors
  static const Color background = Color(0xFFF8F9FE);
  static const Color darkBackground = Color(0xFF1A1A2E);
  static const Color cardBackground = Colors.white;
  static const Color darkCard = Color(0xFF16213E);
  static const Color textPrimary = Color(0xFF2D3142);
  static const Color textSecondary = Color(0xFF9094A6);
  static const Color textDark = Color(0xFFE4E6EB);
  
  // Glassmorphism effects
  static Color glassBackground = Colors.white.withOpacity(0.15);
  static Color glassBorder = Colors.white.withOpacity(0.2);
  static Color glassBlur = Colors.white.withOpacity(0.1);
}

// Enhanced Gradients
LinearGradient primaryGradient = const LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AppColors.primaryStart, AppColors.primaryEnd],
);

LinearGradient secondaryGradient = const LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AppColors.secondaryStart, AppColors.secondaryEnd],
);

LinearGradient successGradient = const LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AppColors.successStart, AppColors.successEnd],
);

LinearGradient warningGradient = const LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AppColors.warningStart, AppColors.warningEnd],
);

// Animated gradient for special effects
LinearGradient rainbowGradient = const LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFF667EEA),
    Color(0xFF764BA2),
    Color(0xFFFF6B6B),
    Color(0xFFFFD93D),
  ],
);

ThemeData buildTheme({bool isDark = false}) {
  final base = isDark ? ThemeData.dark() : ThemeData.light();
  final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
  final cardColor = isDark ? AppColors.darkCard : AppColors.cardBackground;
  final textColor = isDark ? AppColors.textDark : AppColors.textPrimary;
  
  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.primaryStart,
      secondary: AppColors.secondaryStart,
      surface: cardColor,
      background: bgColor,
      error: AppColors.warningStart,
    ),
    scaffoldBackgroundColor: bgColor,
    textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.poppins(
        fontSize: 40,
        fontWeight: FontWeight.bold,
        color: textColor,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textColor,
        letterSpacing: -0.5,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      headlineLarge: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        color: textColor,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        color: isDark ? AppColors.textDark.withOpacity(0.7) : AppColors.textSecondary,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 12,
        color: isDark ? AppColors.textDark.withOpacity(0.6) : AppColors.textSecondary,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: textColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    ),
    cardTheme: CardThemeData(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: isDark ? 4 : 8,
      shadowColor: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryStart,
        side: BorderSide(
          color: AppColors.primaryStart,
          width: 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.primaryStart.withOpacity(0.1),
      labelStyle: GoogleFonts.poppins(
        color: AppColors.primaryStart,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 8,
      backgroundColor: AppColors.primaryStart,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
  );
}

// Animation durations
class AnimationDurations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);
}

// Border Radius
class AppBorderRadius {
  static const double small = 12.0;
  static const double medium = 16.0;
  static const double large = 24.0;
  static const double extraLarge = 32.0;
}

// Spacing
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}
