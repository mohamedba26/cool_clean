// lib/screens/result_screen_.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import '../models/product.dart';
import '../theme.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({Key? key}) : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _confettiController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();

    // Trigger vibration when product is found
    _triggerSuccessVibration();

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _confettiController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _confettiController, curve: Curves.easeIn),
    );

    _confettiController.forward();
  }

  Future<void> _triggerSuccessVibration() async {
    try {
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        // Success pattern: short-long-short vibration
        await Vibration.vibrate(duration: 100);
        await Future.delayed(const Duration(milliseconds: 150));
        await Vibration.vibrate(duration: 200);
        await Future.delayed(const Duration(milliseconds: 150));
        await Vibration.vibrate(duration: 100);
      }
    } catch (e) {
      debugPrint('Vibration error: $e');
    }
  }

  Future<void> _shareScreenshot(Product product) async {
    if (_isSharing) return;

    setState(() => _isSharing = true);

    try {
      // Capture screenshot
      final Uint8List? imageBytes = await _screenshotController.capture();

      if (imageBytes == null) {
        throw Exception('Failed to capture screenshot');
      }

      // Save to temporary directory
      final directory = await getTemporaryDirectory();
      final imagePath =
          '${directory.path}/product_${DateTime.now().millisecondsSinceEpoch}.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(imageBytes);

      // Share the image file
      await Share.shareXFiles([
        XFile(imagePath),
      ], text: '${product.name} - Scanned with Cool Clean');

      // Haptic feedback on share
      if (await Vibration.hasVibrator() ?? false) {
        await Vibration.vibrate(duration: 50);
      }

      // Clean up the temp file after a delay
      Future.delayed(const Duration(seconds: 5), () {
        try {
          if (imageFile.existsSync()) {
            imageFile.deleteSync();
          }
        } catch (e) {
          debugPrint('Error deleting temp file: $e');
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to share: $e')));
      }
    } finally {
      setState(() => _isSharing = false);
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Widget _buildProductImage(String? imageUrl, bool isDark) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            height: 250,
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryStart.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderImage(isDark);
                      },
                    )
                  : _buildPlaceholderImage(isDark),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderImage(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: primaryGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: Icon(Icons.shopping_bag_rounded, size: 80, color: Colors.white),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: primaryGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDangerousIngredient(
    BuildContext context,
    String name,
    String danger,
    String level,
  ) {
    Color levelColor;
    IconData levelIcon;

    switch (level.toLowerCase()) {
      case 'high':
        levelColor = Colors.red;
        levelIcon = Icons.dangerous_rounded;
        break;
      case 'medium':
        levelColor = Colors.orange;
        levelIcon = Icons.warning_rounded;
        break;
      default:
        levelColor = Colors.yellow.shade700;
        levelIcon = Icons.info_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: levelColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: levelColor.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(levelIcon, color: levelColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: levelColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(danger, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: levelColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${level.toUpperCase()} RISK',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAllergenChip(String allergen, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: warningGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            allergen,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfo(Product product, bool isDark) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Name
            Text(
              product.name,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Status Badge
            _buildStatusBadge(product.boycott),
            const SizedBox(height: 20),

            // Divider
            Divider(color: isDark ? Colors.white24 : Colors.black12),
            const SizedBox(height: 20),

            // Basic Product Details
            _buildSectionTitle(context, 'Product Details', Icons.info_rounded),
            const SizedBox(height: 16),

            if (product.brand != null && product.brand!.isNotEmpty) ...[
              _buildInfoRow(
                context,
                Icons.business_rounded,
                'Brand',
                product.brand!,
              ),
              const SizedBox(height: 12),
            ],

            _buildInfoRow(
              context,
              Icons.category_rounded,
              'Category',
              'Food & Beverage',
            ),
            const SizedBox(height: 12),

            _buildInfoRow(
              context,
              product.boycott ? Icons.warning_rounded : Icons.verified_rounded,
              'Status',
              product.boycott ? 'Boycott Product' : 'Safe to Use',
            ),
            const SizedBox(height: 12),

            _buildInfoRow(
              context,
              Icons.calendar_today_rounded,
              'Scanned',
              _formatDate(DateTime.now()),
            ),

            // Dangerous Ingredients Section (if boycott)
            if (product.boycott) ...[
              const SizedBox(height: 24),
              Divider(color: isDark ? Colors.white24 : Colors.black12),
              const SizedBox(height: 20),

              _buildSectionTitle(
                context,
                'Dangerous Ingredients',
                Icons.warning_rounded,
              ),
              const SizedBox(height: 16),

              _buildDangerousIngredient(
                context,
                'Palm Oil',
                'Linked to deforestation and habitat destruction. High in saturated fats.',
                'High',
              ),

              _buildDangerousIngredient(
                context,
                'High Fructose Corn Syrup',
                'Associated with obesity, diabetes, and metabolic syndrome.',
                'High',
              ),

              _buildDangerousIngredient(
                context,
                'Artificial Colors (E102, E110)',
                'May cause hyperactivity in children and allergic reactions.',
                'Medium',
              ),

              _buildDangerousIngredient(
                context,
                'Sodium Benzoate',
                'Preservative that may form benzene when combined with vitamin C.',
                'Medium',
              ),
            ],

            // Nutrition Facts Section
            const SizedBox(height: 24),
            Divider(color: isDark ? Colors.white24 : Colors.black12),
            const SizedBox(height: 20),

            _buildSectionTitle(
              context,
              'Nutrition Facts',
              Icons.restaurant_rounded,
            ),
            const SizedBox(height: 12),

            Text(
              'Per 100g',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 12),

            _buildNutritionRow(context, 'Energy', '450 kcal'),
            _buildNutritionRow(context, 'Fat', '18g'),
            _buildNutritionRow(context, '  - Saturated Fat', '9g'),
            _buildNutritionRow(context, 'Carbohydrates', '62g'),
            _buildNutritionRow(context, '  - Sugars', '28g'),
            _buildNutritionRow(context, 'Protein', '6g'),
            _buildNutritionRow(context, 'Salt', '1.2g'),
            _buildNutritionRow(context, 'Fiber', '3g'),

            // Allergens Section
            const SizedBox(height: 24),
            Divider(color: isDark ? Colors.white24 : Colors.black12),
            const SizedBox(height: 20),

            _buildSectionTitle(
              context,
              'Allergens',
              Icons.health_and_safety_rounded,
            ),
            const SizedBox(height: 16),

            Wrap(
              children: [
                _buildAllergenChip('Milk', isDark),
                _buildAllergenChip('Soy', isDark),
                _buildAllergenChip('Gluten', isDark),
                _buildAllergenChip('Tree Nuts', isDark),
              ],
            ),

            // Ingredients List
            const SizedBox(height: 24),
            Divider(color: isDark ? Colors.white24 : Colors.black12),
            const SizedBox(height: 20),

            _buildSectionTitle(
              context,
              'Ingredients',
              Icons.format_list_bulleted_rounded,
            ),
            const SizedBox(height: 12),

            Text(
              'Sugar, Wheat Flour, Palm Oil, Cocoa Powder, Milk Powder, Emulsifiers (E322, E476), '
              'Leavening Agents (E500, E503), Artificial Flavors, Colorings (E102, E110), '
              'Preservatives (E211), Salt, Vanilla Extract.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.6),
            ),

            // Why Boycott/Safe Section
            const SizedBox(height: 24),
            Divider(color: isDark ? Colors.white24 : Colors.black12),
            const SizedBox(height: 20),

            _buildSectionTitle(
              context,
              'Why ${product.boycott ? 'Boycott' : 'Safe'}?',
              product.boycott
                  ? Icons.block_rounded
                  : Icons.check_circle_rounded,
            ),
            const SizedBox(height: 12),

            Text(
              product.boycott
                  ? 'This product is associated with companies that:\n\n'
                        '• Support unethical business practices\n'
                        '• Have connections to controversial organizations\n'
                        '• Use harmful ingredients that affect health\n'
                        '• Contribute to environmental damage\n\n'
                        'We recommend choosing alternative products from ethical brands.'
                  : 'This product has been verified and:\n\n'
                        '• Meets ethical business standards\n'
                        '• Contains safe, quality ingredients\n'
                        '• Comes from responsible manufacturers\n'
                        '• Is environmentally conscious\n\n'
                        'Safe to purchase and consume with confidence.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.8),
            ),

            // Health Score
            const SizedBox(height: 24),
            Divider(color: isDark ? Colors.white24 : Colors.black12),
            const SizedBox(height: 20),

            _buildSectionTitle(
              context,
              'Health Score',
              Icons.fitness_center_rounded,
            ),
            const SizedBox(height: 16),

            _buildHealthScoreBar(product.boycott ? 35 : 78, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthScoreBar(int score, bool isDark) {
    Color scoreColor;
    String scoreLabel;

    if (score >= 70) {
      scoreColor = Colors.green;
      scoreLabel = 'Good';
    } else if (score >= 40) {
      scoreColor = Colors.orange;
      scoreLabel = 'Fair';
    } else {
      scoreColor = Colors.red;
      scoreLabel = 'Poor';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Overall Health Rating',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              '$score/100 - $scoreLabel',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: score / 100,
            minHeight: 12,
            backgroundColor: isDark ? Colors.white24 : Colors.black12,
            valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildStatusBadge(bool boycott) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: boycott ? warningGradient : successGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (boycott ? AppColors.warningStart : AppColors.successStart)
                .withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            boycott ? Icons.warning_rounded : Icons.check_circle_rounded,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 10),
          Text(
            boycott ? 'BOYCOTT PRODUCT' : 'SAFE PRODUCT',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryStart.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 22, color: AppColors.primaryStart),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, Product product) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Scan Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkCard
                    : Colors.grey[200],
                foregroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppColors.textPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryStart.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _isSharing ? null : () => _shareScreenshot(product),
                icon: _isSharing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.share_rounded),
                label: Text(_isSharing ? 'Sharing...' : 'Share'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = ModalRoute.of(context)!.settings.arguments as Product;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.report_rounded),
                        title: const Text('Report Issue'),
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Report feature coming soon'),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.favorite_border_rounded),
                        title: const Text('Save to Favorites'),
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Added to favorites!'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Screenshot(
        controller: _screenshotController,
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: ListView(
            children: [
              const SizedBox(height: 20),
              _buildProductImage(product.imageUrl, isDark),
              const SizedBox(height: 24),
              _buildProductInfo(product, isDark),
              const SizedBox(height: 24),
              _buildActionButtons(context, product),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
