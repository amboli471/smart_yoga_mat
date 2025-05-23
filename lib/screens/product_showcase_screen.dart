import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';

import '../services/product_service.dart';
import '../theme/app_theme.dart';
import '../widgets/feature_card.dart';
import '../widgets/product_card.dart';

class ProductShowcaseScreen extends StatelessWidget {
  const ProductShowcaseScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final productService = Provider.of<ProductService>(context);
    final isLoading = productService.isLoading;
    final error = productService.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products & Features'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => productService.refreshData(),
          ),
        ],
      ),
      body: isLoading
          ? _buildLoadingView()
          : error != null
          ? _buildErrorView(error, productService)
          : _buildContent(context, productService),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading products...'),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error, ProductService productService) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              'Error Loading Products',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => productService.refreshData(),
              icon: Icon(Icons.refresh),
              label: Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ProductService productService) {
    final products = productService.products;
    final features = productService.features;

    return RefreshIndicator(
      onRefresh: () => productService.refreshData(),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New Features',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Check out the latest updates for your smart yoga mat',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),

            // Features List
            SizedBox(
              height: 309,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: features.length,
                itemBuilder: (context, index) {
                  final feature = features[index];

                  return FadeInRight(
                    duration: Duration(milliseconds: 600),
                    delay: Duration(milliseconds: index * 100),
                    child: FeatureCard(feature: feature),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Our Products',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Explore our collection of smart yoga products',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),

            // Products Grid - Better aspect ratio and spacing
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.68, // Adjusted for better proportions
                  crossAxisSpacing: 12, // Reduced spacing
                  mainAxisSpacing: 12,   // Reduced spacing
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];

                  return FadeInUp(
                    duration: Duration(milliseconds: 600),
                    delay: Duration(milliseconds: index * 100),
                    child: ProductCard(product: product),
                  );
                },
              ),
            ),

            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}