import 'package:flutter/material.dart';

import '../models/product.dart';

const List<Product> kProducts = [
  Product(
    name: 'Wireless Headphones',
    description: 'Noise-cancelling, 30h battery life',
    price: 129.99,
    icon: Icons.headphones,
    color: Colors.indigo,
  ),
  Product(
    name: 'Smart Watch',
    description: 'Fitness tracking and notifications',
    price: 199.50,
    icon: Icons.watch,
    color: Colors.teal,
  ),
  Product(
    name: 'Mechanical Keyboard',
    description: 'Hot-swappable switches, RGB backlight',
    price: 89.00,
    icon: Icons.keyboard,
    color: Colors.deepOrange,
  ),
  Product(
    name: 'Portable Speaker',
    description: 'Waterproof, 12h playtime',
    price: 59.99,
    icon: Icons.speaker,
    color: Colors.purple,
  ),
  Product(
    name: '4K Monitor',
    description: '27-inch, HDR, USB-C',
    price: 349.00,
    icon: Icons.monitor,
    color: Colors.blueGrey,
  ),
  Product(
    name: 'Ergonomic Mouse',
    description: 'Vertical grip, wireless',
    price: 39.99,
    icon: Icons.mouse,
    color: Colors.green,
  ),
  Product(
    name: 'USB-C Hub',
    description: '7-in-1, HDMI + card reader',
    price: 45.50,
    icon: Icons.cable,
    color: Colors.brown,
  ),
  Product(
    name: 'Webcam 1080p',
    description: 'Autofocus, built-in mic',
    price: 74.99,
    icon: Icons.videocam,
    color: Colors.pink,
  ),
];
