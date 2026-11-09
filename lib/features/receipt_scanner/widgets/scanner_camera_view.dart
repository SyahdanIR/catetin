import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/meemo_mascot.dart';

class ScannerCameraView extends StatefulWidget {
  final VoidCallback onCapture;
  final VoidCallback onPickGallery;

  const ScannerCameraView({
    super.key,
    required this.onCapture,
    required this.onPickGallery,
  });

  @override
  State<ScannerCameraView> createState() => _ScannerCameraViewState();
}

class _ScannerCameraViewState extends State<ScannerCameraView>
    with SingleTickerProviderStateMixin {
  late AnimationController _laserController;
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _laserController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 380,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Dark camera viewfinder
        borderRadius: BorderRadius.circular(AppBorders.radiusLarge),
        border: Border.all(
          color: AppColors.border,
          width: AppBorders.borderWidthThick,
        ),
        boxShadow: AppShadows.tactileStandard,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppBorders.radiusLarge - 2),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Viewfinder Grid & Mock Receipt Silhouette
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),

            // Mock Receipt Target Frame
            Container(
              width: 230,
              height: 260,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary,
                  width: 2.0,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Animated Scanning Laser Line
                  AnimatedBuilder(
                    animation: _laserController,
                    builder: (context, child) {
                      return Positioned(
                        top: 20 + (_laserController.value * 210),
                        left: 10,
                        right: 10,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.highlight,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.highlight.withValues(alpha: 0.8),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Center Guidance
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const MeemoMascot(
                        size: 48,
                        mood: MeemoMood.scanning,
                        showShadow: false,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Posisikan struk dalam bingkai',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Top Flash & Info Controls
            Positioned(
              top: 14,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppBorders.radiusSmall),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.income,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Kamera Aktif',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() => _isFlashOn = !_isFlashOn);
                    },
                    icon: Icon(
                      _isFlashOn
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                      color: _isFlashOn ? AppColors.highlight : Colors.white,
                      size: 22,
                    ),
                    tooltip: 'Flash',
                  ),
                ],
              ),
            ),

            // Bottom Shutter & Gallery Controls
            Positioned(
              bottom: 14,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Gallery Pick Button
                  IconButton(
                    onPressed: widget.onPickGallery,
                    icon: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white),
                      ),
                      child: const Icon(
                        Icons.photo_library_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    tooltip: 'Buka Galeri Foto',
                  ),

                  // Big Center Shutter Button
                  GestureDetector(
                    onTap: widget.onCapture,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.border,
                          width: 3.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            offset: const Offset(0, 3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Tips Button
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Tips: Pastikan struk pencahayaannya cukup dan tidak terlipat.',
                          ),
                        ),
                      );
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white),
                      ),
                      child: const Icon(
                        Icons.lightbulb_outline_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    tooltip: 'Tips Pemindaian',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
