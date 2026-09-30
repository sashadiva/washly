import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The Home hero banner. Renders a bundled asset if present, otherwise a
/// branded gradient fallback so it ALWAYS renders (Requirement 18.2). The
/// greeting overlays the banner.
class HeroBanner extends StatelessWidget {
  final String greeting;
  final String? assetPath;

  const HeroBanner({
    super.key,
    required this.greeting,
    this.assetPath = 'assets/hero_banner.jpg',
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Stack(
        children: [
          // Branded gradient underneath — the guaranteed fallback.
          Container(
            height: 150,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
            ),
          ),
          // The asset on top, if it exists. errorBuilder keeps the gradient
          // visible when the asset is missing so the build never breaks.
          if (assetPath != null)
            Positioned.fill(
              child: Image.asset(
                assetPath!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          // Greeting overlay.
          Positioned(
            left: AppSpacing.lg,
            bottom: AppSpacing.lg,
            right: AppSpacing.lg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Washly',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  greeting,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
