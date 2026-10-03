import 'package:flutter/material.dart';

class Product {
  final String name;
  final String description;
  final double price;
  final IconData icon;
  final Color color;

  const Product({
    required this.name,
    required this.description,
    required this.price,
    required this.icon,
    required this.color,
  });
}
