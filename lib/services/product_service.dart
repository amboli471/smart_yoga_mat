import 'package:flutter/material.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final bool isNew;
  final String category;
  final String detailsUrl;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.isNew,
    required this.category,
    required this.detailsUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      price: (json['price'] as num).toDouble(),
      isNew: json['isNew'] as bool,
      category: json['category'] as String,
      detailsUrl: json['detailsUrl'] as String,
    );
  }
}

class Feature {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final bool isNew;

  const Feature({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.isNew,
  });

  factory Feature.fromJson(Map<String, dynamic> json) {
    return Feature(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      isNew: json['isNew'] as bool,
    );
  }
}

class ProductService extends ChangeNotifier {
  List<Product> _products = [];
  List<Feature> _features = [];
  bool _isLoading = true;
  String? _error;

  List<Product> get products => _products;
  List<Feature> get features => _features;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ProductService() {
    _loadProducts();
    _loadFeatures();
  }

  Future<void> _loadProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      // In a real app, we would fetch from Firebase
      // For the prototype, we'll use hardcoded data with working image URLs
      await Future.delayed(Duration(seconds: 1));

      _products = [
        Product(
          id: 'mat-pro',
          name: 'YogaFlex Pro Mat',
          description: 'Our premium smart yoga mat with pressure sensors and LED guidance',
          imageUrl: 'https://images.pexels.com/photos/4498155/pexels-photo-4498155.jpeg?auto=compress&cs=tinysrgb&w=500',
          price: 199.99,
          isNew: true,
          category: 'Mats',
          detailsUrl: 'https://example.com/products/yogaflex-pro',
        ),
        Product(
          id: 'mat-lite',
          name: 'YogaFlex Lite',
          description: 'A lighter version of our smart mat with essential features',
          imageUrl: 'https://images.pexels.com/photos/4056535/pexels-photo-4056535.jpeg?auto=compress&cs=tinysrgb&w=500',
          price: 149.99,
          isNew: false,
          category: 'Mats',
          detailsUrl: 'https://example.com/products/yogaflex-lite',
        ),
        Product(
          id: 'blocks',
          name: 'Smart Yoga Blocks',
          description: 'Yoga blocks that sync with your mat for perfect alignment',
          imageUrl: 'https://images.pexels.com/photos/3822672/pexels-photo-3822672.jpeg?auto=compress&cs=tinysrgb&w=500',
          price: 49.99,
          isNew: true,
          category: 'Accessories',
          detailsUrl: 'https://example.com/products/smart-blocks',
        ),
        Product(
          id: 'strap',
          name: 'YogaFlex Strap',
          description: 'Smart strap with tension sensors to improve your stretches',
          imageUrl: 'https://images.pexels.com/photos/4325484/pexels-photo-4325484.jpeg?auto=compress&cs=tinysrgb&w=500',
          price: 29.99,
          isNew: false,
          category: 'Accessories',
          detailsUrl: 'https://example.com/products/yogaflex-strap',
        ),
      ];

      _error = null; // Clear any previous errors
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading products: $e');
      _error = 'Failed to load products';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFeatures() async {
    try {
      // In a real app, we would fetch from Firebase
      // For the prototype, we'll use hardcoded data with working image URLs
      await Future.delayed(Duration(seconds: 1));

      _features = [
        Feature(
          id: 'pose-detection',
          name: 'Advanced Pose Detection',
          description: 'Our new AI algorithm can detect and correct 50+ yoga poses with higher accuracy',
          imageUrl: 'https://images.pexels.com/photos/4056723/pexels-photo-4056723.jpeg?auto=compress&cs=tinysrgb&w=500',
          isNew: true,
        ),
        Feature(
          id: 'custom-routines',
          name: 'Custom Routines',
          description: 'Create and save your own yoga routines with our improved routine builder',
          // Changed to a working image URL
          imageUrl: 'https://images.pexels.com/photos/3822888/pexels-photo-3822888.jpeg?auto=compress&cs=tinysrgb&w=500',
          isNew: true,
        ),
        Feature(
          id: 'haptic-feedback',
          name: 'Haptic Feedback',
          description: 'Feel gentle vibrations guiding you to perfect alignment in each pose',
          imageUrl: 'https://images.pexels.com/photos/3759661/pexels-photo-3759661.jpeg?auto=compress&cs=tinysrgb&w=500',
          isNew: false,
        ),
      ];

      notifyListeners();
    } catch (e) {
      print('Error loading features: $e');
      _error = 'Failed to load features';
      notifyListeners();
    }
  }

  Future<void> refreshData() async {
    _error = null; // Clear any previous errors
    await _loadProducts();
    await _loadFeatures();
  }
}