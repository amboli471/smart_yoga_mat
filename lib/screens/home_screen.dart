import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';

import '../services/mat_connection_service.dart';
import '../widgets/connection_status_widget.dart';
import '../widgets/mat_features_carousel.dart';
import '../widgets/home_action_button.dart';
import 'connection_screen.dart';
import 'control_panel_screen.dart';
import 'music_screen.dart';
import 'product_showcase_screen.dart';
import 'update_screen.dart';
import 'analytics_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final matService = Provider.of<MatConnectionService>(context);
    final isConnected = matService.status == ConnectionStatus.connected;
    
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(context),
            SliverToBoxAdapter(
              child: FadeIn(
                duration: const Duration(milliseconds: 800),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome to your',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Smart Yoga Experience',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Connect to your mat to begin your personalized yoga journey',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: ConnectionStatusWidget(),
            ),
            SliverToBoxAdapter(
              child: FadeInUp(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 300),
                child: MatFeaturesCarousel(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: FadeInUp(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 500),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: HomeActionButton(
                              title: isConnected ? 'Disconnect' : 'Connect',
                              icon: isConnected ? Icons.bluetooth_disabled : Icons.bluetooth,
                              color: isConnected 
                                  ? Theme.of(context).colorScheme.error 
                                  : Theme.of(context).colorScheme.primary,
                              onTap: () {
                                if (isConnected) {
                                  matService.disconnect();
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ConnectionScreen(),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: HomeActionButton(
                              title: 'Control',
                              icon: Icons.play_circle_outline,
                              color: Theme.of(context).colorScheme.secondary,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ControlPanelScreen(),
                                  ),
                                );
                              },
                              disabled: !isConnected,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: HomeActionButton(
                              title: 'Sounds',
                              icon: Icons.music_note,
                              color: Theme.of(context).colorScheme.tertiary,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MusicScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: HomeActionButton(
                              title: 'Products',
                              icon: Icons.shopping_bag_outlined,
                              color: Colors.purple,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductShowcaseScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: HomeActionButton(
                              title: 'Updates',
                              icon: Icons.system_update,
                              color: Colors.teal,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UpdateScreen(),
                                  ),
                                );
                              },
                              disabled: !isConnected,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: HomeActionButton(
                              title: 'Analytics',
                              icon: Icons.bar_chart,
                              color: Colors.deepOrange,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AnalyticsScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      snap: true,
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(
              Icons.self_improvement,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'YogaFlex',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.settings_outlined),
          onPressed: () {
            // Navigate to settings screen
          },
        ),
      ],
    );
  }
}