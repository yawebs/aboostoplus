import 'package:flutter/material.dart';

class Country {
  final String name;
  final String flag;
  bool isSelected;

  Country({required this.name, required this.flag, this.isSelected = false});
}

class Designer {
  final String name;
  final String location;
  final String bio;
  final List<String> tags;
  final String avatarUrl;
  final List<String> portfolioImages;
  bool isFollowing;

  Designer({
    required this.name,
    required this.location,
    required this.bio,
    required this.tags,
    required this.avatarUrl,
    required this.portfolioImages,
    this.isFollowing = false,
  });
}

class Product {
  final String id;
  final String name;
  final String designerName;
  final String type;
  final String description;
  final double price;
  final List<String> imageUrls;
  final List<Color> availableColors;
  final String category;

  Product({
    required this.id,
    required this.name,
    required this.designerName,
    required this.type,
    required this.description,
    required this.price,
    required this.imageUrls,
    required this.availableColors,
    required this.category,
  });
}

class ChatMessage {
  final String text;
  final bool isSender;
  final String time;

  ChatMessage({
    required this.text,
    required this.isSender,
    required this.time,
  });
}

// Sample Data
class SampleData {
  static List<Country> countries = [
    Country(name: 'South Cyprus, Greece', flag: '🇬🇷', isSelected: true),
    Country(name: 'Sweden', flag: '🇸🇪'),
    Country(name: 'United Kingdom UK', flag: '🇬🇧'),
    Country(name: 'United State of America', flag: '🇺🇸'),
    Country(name: 'Italy', flag: '🇮🇹'),
    Country(name: 'Germany', flag: '🇩🇪'),
    Country(name: 'Australia', flag: '🇦🇺'),
    Country(name: 'China', flag: '🇨🇳'),
    Country(name: 'Nigeria', flag: '🇳🇬'),
    Country(name: 'Ghana', flag: '🇬🇭'),
    Country(name: 'South Africa', flag: '🇿🇦'),
  ];

  static List<Designer> designers = [
    Designer(
      name: 'Alexandra Mosquito',
      location: 'Lagos, NG',
      bio:
          'Lorem ipsum dolor sit amet consectetur. Integer volutpat et non pellentesque purus.',
      tags: ['Ready to Wear', 'Asoebi', 'Caftan'],
      avatarUrl: 'https://randomuser.me/api/portraits/women/44.jpg',
      portfolioImages: [
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300',
        'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?w=300',
        'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=300',
      ],
    ),
    Designer(
      name: 'Brown Stitches',
      location: 'Abuja, NG',
      bio:
          'Lorem ipsum dolor sit amet consectetur. Integer volutpat et non pellentesque purus.',
      tags: ['Ready to Wear', 'Asoebi', 'Caftan'],
      avatarUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
      portfolioImages: [
        'https://images.unsplash.com/photo-1552374196-1ab2a1c593e8?w=300',
        'https://images.unsplash.com/photo-1516826957135-700dedea698c?w=300',
        'https://images.unsplash.com/photo-1617137968427-85924c800a22?w=300',
      ],
    ),
    Designer(
      name: 'Alexandra Posco',
      location: 'Cape Town, ZA',
      bio:
          'Lorem ipsum dolor sit amet consectetur. Integer volutpat et non pellentesque purus.',
      tags: ['Custom Design', 'Jewelry'],
      avatarUrl: 'https://randomuser.me/api/portraits/men/22.jpg',
      portfolioImages: [
        'https://images.unsplash.com/photo-1604063782052-58501a0a0be6?w=300',
        'https://images.unsplash.com/photo-1620799140188-3b2a02fd9a77?w=300',
        'https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=300',
      ],
    ),
  ];

  static List<Product> newArrivals = [
    Product(
      id: '1',
      name: 'Ganna Wear Full set',
      designerName: 'Alexandra Mosquito',
      type: 'Custom Design',
      description:
          'Lorem ipsum dolor sit amet consectetur. Id dolor risus eu odio vitae tristique cras. Gravida aliquet pellentesque fermentum mollis nec iaculis diam quam. Nunc elit etiam in proin.',
      price: 120,
      imageUrls: [
        'https://images.unsplash.com/photo-1552374196-1ab2a1c593e8?w=600',
        'https://images.unsplash.com/photo-1539533018257-f8401a929a7e?w=600',
        'https://images.unsplash.com/photo-1617137968427-85924c800a22?w=600',
      ],
      availableColors: [
        const Color(0xFF3D2B1F),
        const Color(0xFFE0E0E0),
        const Color(0xFFFFD700),
        const Color(0xFFFF6B1A),
        const Color(0xFF2196F3),
        const Color(0xFF9C27B0),
        const Color(0xFFE91E63),
        const Color(0xFFFF5722),
      ],
      category: 'Clothes',
    ),
    Product(
      id: '2',
      name: 'Kente Blazer Set',
      designerName: 'Brown Stitches',
      type: 'Ready to Wear',
      description:
          'A premium handcrafted Kente blazer made from authentic Ghanaian fabric. Perfect for formal occasions and cultural celebrations.',
      price: 250,
      imageUrls: [
        'https://images.unsplash.com/photo-1516826957135-700dedea698c?w=600',
        'https://images.unsplash.com/photo-1571945153237-4929e783af4a?w=600',
      ],
      availableColors: [
        const Color(0xFF8B4513),
        const Color(0xFFFFD700),
        const Color(0xFF228B22),
      ],
      category: 'Clothes',
    ),
    Product(
      id: '3',
      name: 'Agbada Royal Set',
      designerName: 'Alexandra Posco',
      type: 'Custom Design',
      description:
          'Magnificent traditional Agbada set with intricate embroidery.',
      price: 380,
      imageUrls: [
        'https://images.unsplash.com/photo-1617137968427-85924c800a22?w=600',
      ],
      availableColors: [
        const Color(0xFFFFFFFF),
        const Color(0xFF8B4513),
        const Color(0xFFFFD700),
      ],
      category: 'Clothes',
    ),
  ];

  static List<ChatMessage> messages = [
    ChatMessage(
      text:
          'Lorem ipsum dolor sit amet consectetur. Id dolor risus eu odio vitae tristique cras. Gravida aliquet pellentesque fermentum mollis nec iaculis diam quam. Nunc elit etiam in proin. Congue vitae phasellus sem integer proin dictumst. Tempor mattis nisi.',
      isSender: false,
      time: '8:30AM',
    ),
    ChatMessage(
      text:
          'Lorem ipsum dolor sit amet consectetur. Id dolor risus eu odio vitae tristique cras. Gravida aliquet pellentesque',
      isSender: false,
      time: '8:30AM',
    ),
  ];
}
