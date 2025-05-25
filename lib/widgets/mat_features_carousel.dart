import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

import '../theme/app_theme.dart';

class Feature {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const Feature({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class MatFeaturesCarousel extends StatefulWidget {
  MatFeaturesCarousel({Key? key}) : super(key: key);

  @override
  State<MatFeaturesCarousel> createState() => _MatFeaturesCarouselState();
}

class _MatFeaturesCarouselState extends State<MatFeaturesCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;

  final List<Feature> features = [
    Feature(
      title: 'Pressure Sensing',
      description: 'Detect your weight distribution and posture for perfect alignment',
      icon: Icons.touch_app,
      color: AppColors.primary,
    ),
    Feature(
      title: 'LED Guidance',
      description: 'Visual cues through embedded LEDs to guide your positioning',
      icon: Icons.lightbulb_outline,
      color: AppColors.secondary,
    ),
    Feature(
      title: 'Haptic Feedback',
      description: 'Gentle vibrations to correct your form in real-time',
      icon: Icons.vibration,
      color: AppColors.accent,
    ),
    Feature(
      title: 'Temperature Control',
      description: 'Adjustable heating for comfort during your practice',
      icon: Icons.thermostat,
      color: Colors.deepOrange,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      int page = _pageController.page!.round();
      if (page != _currentPage) {
        setState(() {
          _currentPage = page;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 209, // Increased from 180 to 209 (29px more)
          child: PageView.builder(
            controller: _pageController,
            itemCount: features.length,
            itemBuilder: (context, index) {
              return _buildFeatureCard(context, features[index], index);
            },
          ),
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            features.length,
                (index) => _buildIndicator(index == _currentPage),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(BuildContext context, Feature feature, int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: feature.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: feature.color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0), // Reduced from 20 to 16 for better fit
        child: Row(
          children: [
            Container(
              width: 56, // Reduced from 60 to 56
              height: 56, // Reduced from 60 to 56
              decoration: BoxDecoration(
                color: feature.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14), // Adjusted proportionally
              ),
              child: Icon(
                feature.icon,
                color: feature.color,
                size: 28, // Reduced from 30 to 28
              ),
            ),
            SizedBox(width: 16), // Reduced from 20 to 16
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    feature.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith( // Changed from titleLarge to titleMedium
                      color: feature.color.withOpacity(0.8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6), // Reduced from 8 to 6
                  Text(
                    feature.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}