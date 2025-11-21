import 'package:flutter/material.dart';

import '../../../theming/colors.dart';

class ChatBubbleColors {
  final Color outgoing;
  final Color incoming;

  const ChatBubbleColors({
    required this.outgoing,
    required this.incoming,
  });

  static const defaults = ChatBubbleColors(
    outgoing: Color(0xFFFFC56F),
    incoming: Color(0xFF1C1A3C),
  );

  Map<String, dynamic> toJson() => {
        'outgoing': _colorToHex(outgoing),
        'incoming': _colorToHex(incoming),
      };

  factory ChatBubbleColors.fromJson(Map<String, dynamic> json) {
    return ChatBubbleColors(
      outgoing: _colorFromHex(json['outgoing'] as String?, defaults.outgoing),
      incoming: _colorFromHex(json['incoming'] as String?, defaults.incoming),
    );
  }

  static String _colorToHex(Color color) =>
      color.value.toRadixString(16).padLeft(8, '0');

  static Color _colorFromHex(String? value, Color fallback) {
    if (value == null) return fallback;
    final cleaned = value.replaceAll('#', '');
    return Color(int.parse(cleaned, radix: 16));
  }

  ChatBubbleColors copyWith({Color? outgoing, Color? incoming}) {
    return ChatBubbleColors(
      outgoing: outgoing ?? this.outgoing,
      incoming: incoming ?? this.incoming,
    );
  }
}

/// Enum for different chat background types
enum ChatBackgroundType {
  solid,
  gradient,
  pattern,
  customImage,
}

/// Model for chat background configuration
class ChatBackground {
  final String id;
  final String name;
  final ChatBackgroundType type;
  final Color? solidColor;
  final Gradient? gradient;
  final String? patternAsset;
  final String? imageUrl;
  final Color? textColor;
  final ChatBubbleColors? bubbleColors;

  const ChatBackground({
    required this.id,
    required this.name,
    required this.type,
    this.solidColor,
    this.gradient,
    this.patternAsset,
    this.imageUrl,
    this.textColor,
    this.bubbleColors,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString(),
      'imageUrl': imageUrl,
    };
  }

  /// Create from JSON
  factory ChatBackground.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final type = json['type'] as String?;
    final imageUrl = json['imageUrl'] as String?;

    // If it's a custom image, create it
    if (type == 'ChatBackgroundType.customImage' && imageUrl != null) {
      return ChatBackground(
        id: id,
        name: 'Custom Wallpaper',
        type: ChatBackgroundType.customImage,
        imageUrl: imageUrl,
        textColor: Colors.white,
        bubbleColors: ChatBubbleColors.defaults,
      );
    }

    return ChatBackgrounds.all.firstWhere(
      (bg) => bg.id == id,
      orElse: () => ChatBackgrounds.defaultBackground,
    );
  }
}

/// Predefined chat backgrounds
class ChatBackgrounds {
  // Default background
  static const defaultBackground = ChatBackground(
    id: 'default',
    name: 'Default Dark',
    type: ChatBackgroundType.gradient,
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF1B1848),
        Color(0xFF080612),
      ],
    ),
    textColor: Colors.white,
    bubbleColors: ChatBubbleColors.defaults,
  );

  // Solid color backgrounds
  static const darkGray = ChatBackground(
    id: 'dark_gray',
    name: 'Dark Gray',
    type: ChatBackgroundType.solid,
    solidColor: Color(0xFF1A1A1A),
    textColor: Colors.white,
    bubbleColors: ChatBubbleColors.defaults,
  );

  static const midnight = ChatBackground(
    id: 'midnight',
    name: 'Midnight',
    type: ChatBackgroundType.solid,
    solidColor: Color(0xFF0D1117),
    textColor: Colors.white,
    bubbleColors: ChatBubbleColors.defaults,
  );

  static const darkBlue = ChatBackground(
    id: 'dark_blue',
    name: 'Dark Blue',
    type: ChatBackgroundType.solid,
    solidColor: Color(0xFF0A192F),
    textColor: Colors.white,
    bubbleColors: ChatBubbleColors.defaults,
  );

  static const charcoal = ChatBackground(
    id: 'charcoal',
    name: 'Charcoal',
    type: ChatBackgroundType.solid,
    solidColor: Color(0xFF2D2D2D),
    textColor: Colors.white,
    bubbleColors: ChatBubbleColors.defaults,
  );

  static const deepPurple = ChatBackground(
    id: 'deep_purple',
    name: 'Deep Purple',
    type: ChatBackgroundType.solid,
    solidColor: Color(0xFF1A0B2E),
    textColor: Colors.white,
    bubbleColors: ChatBubbleColors.defaults,
  );

  // Gradient backgrounds
  static const blueGradient = ChatBackground(
    id: 'blue_gradient',
    name: 'Blue Ocean',
    type: ChatBackgroundType.gradient,
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF0F2027),
        Color(0xFF203A43),
        Color(0xFF2C5364),
      ],
    ),
    textColor: Colors.white,
    bubbleColors: ChatBubbleColors.defaults,
  );

  static const purpleGradient = ChatBackground(
    id: 'purple_gradient',
    name: 'Purple Dream',
    type: ChatBackgroundType.gradient,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF1A0B2E),
        Color(0xFF3E2C6E),
        Color(0xFF6247AA),
      ],
    ),
    textColor: Colors.white,
    bubbleColors: ChatBubbleColors.defaults,
  );

  static const greenGradient = ChatBackground(
    id: 'green_gradient',
    name: 'Forest Green',
    type: ChatBackgroundType.gradient,
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF0F2027),
        Color(0xFF1A4D2E),
        Color(0xFF2D5F3F),
      ],
    ),
    textColor: Colors.white,
    bubbleColors: ChatBubbleColors.defaults,
  );

  static const sunsetGradient = ChatBackground(
    id: 'sunset_gradient',
    name: 'Sunset',
    type: ChatBackgroundType.gradient,
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF1A0B2E),
        Color(0xFF4E2A5E),
        Color(0xFF6B3E4E),
      ],
    ),
    textColor: Colors.white,
    bubbleColors: ChatBubbleColors.defaults,
  );

  static const nightSkyGradient = ChatBackground(
    id: 'night_sky_gradient',
    name: 'Night Sky',
    type: ChatBackgroundType.gradient,
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF000428),
        Color(0xFF004e92),
      ],
    ),
    textColor: Colors.white,
    bubbleColors: ChatBubbleColors.defaults,
  );

  static const cosmicGradient = ChatBackground(
    id: 'cosmic_gradient',
    name: 'Cosmic',
    type: ChatBackgroundType.gradient,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF1F1C2C),
        Color(0xFF928DAB),
      ],
    ),
    textColor: Colors.white,
  );

  static const oceanGradient = ChatBackground(
    id: 'ocean_gradient',
    name: 'Deep Ocean',
    type: ChatBackgroundType.gradient,
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF141E30),
        Color(0xFF243B55),
      ],
    ),
    textColor: Colors.white,
  );

  static const roseGradient = ChatBackground(
    id: 'rose_gradient',
    name: 'Rose',
    type: ChatBackgroundType.gradient,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF2C1A3E),
        Color(0xFF4A2C5E),
        Color(0xFF6B3E6E),
      ],
    ),
    textColor: Colors.white,
  );

  // Premium 4K Quality Wallpapers
  static const auroraGradient = ChatBackground(
    id: 'aurora_gradient',
    name: 'Aurora Borealis',
    type: ChatBackgroundType.gradient,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF0F2027),
        Color(0xFF203A43),
        Color(0xFF2C5364),
        Color(0xFF0F4C75),
      ],
      stops: [0.0, 0.3, 0.7, 1.0],
    ),
    textColor: Colors.white,
  );

  static const galaxyGradient = ChatBackground(
    id: 'galaxy_gradient',
    name: 'Deep Galaxy',
    type: ChatBackgroundType.gradient,
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF000000),
        Color(0xFF1B0039),
        Color(0xFF3B0066),
        Color(0xFF1B0039),
        Color(0xFF000000),
      ],
      stops: [0.0, 0.25, 0.5, 0.75, 1.0],
    ),
    textColor: Colors.white,
  );

  static const nebulaPurple = ChatBackground(
    id: 'nebula_purple',
    name: 'Purple Nebula',
    type: ChatBackgroundType.gradient,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF1A0033),
        Color(0xFF33006B),
        Color(0xFF6B1B9A),
        Color(0xFF8B2CA0),
      ],
      stops: [0.0, 0.3, 0.7, 1.0],
    ),
    textColor: Colors.white,
  );

  static const midnightCity = ChatBackground(
    id: 'midnight_city',
    name: 'Midnight City',
    type: ChatBackgroundType.gradient,
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF0A0E27),
        Color(0xFF1A1F3A),
        Color(0xFF2C3E50),
      ],
    ),
    textColor: Colors.white,
  );

  static const emeraldForest = ChatBackground(
    id: 'emerald_forest',
    name: 'Emerald Forest',
    type: ChatBackgroundType.gradient,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF0B3D0B),
        Color(0xFF0F5132),
        Color(0xFF1B4D3E),
        Color(0xFF134E4A),
      ],
      stops: [0.0, 0.3, 0.7, 1.0],
    ),
    textColor: Colors.white,
  );

  static const crimsonDusk = ChatBackground(
    id: 'crimson_dusk',
    name: 'Crimson Dusk',
    type: ChatBackgroundType.gradient,
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF1A0000),
        Color(0xFF330000),
        Color(0xFF4D0000),
        Color(0xFF660000),
      ],
      stops: [0.0, 0.3, 0.7, 1.0],
    ),
    textColor: Colors.white,
  );

  static const sapphireDepth = ChatBackground(
    id: 'sapphire_depth',
    name: 'Sapphire Depth',
    type: ChatBackgroundType.gradient,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF001F3F),
        Color(0xFF003366),
        Color(0xFF004D7A),
        Color(0xFF003D5C),
      ],
      stops: [0.0, 0.3, 0.7, 1.0],
    ),
    textColor: Colors.white,
  );

  static const northernLights = ChatBackground(
    id: 'northern_lights',
    name: 'Northern Lights',
    type: ChatBackgroundType.gradient,
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF001233),
        Color(0xFF003D5B),
        Color(0xFF005B7F),
        Color(0xFF008B9C),
      ],
      stops: [0.0, 0.3, 0.7, 1.0],
    ),
    textColor: Colors.white,
  );

  static const amethystDream = ChatBackground(
    id: 'amethyst_dream',
    name: 'Amethyst Dream',
    type: ChatBackgroundType.gradient,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF1A001A),
        Color(0xFF330033),
        Color(0xFF4D004D),
        Color(0xFF660066),
      ],
      stops: [0.0, 0.3, 0.7, 1.0],
    ),
    textColor: Colors.white,
  );

  static const volcanicNight = ChatBackground(
    id: 'volcanic_night',
    name: 'Volcanic Night',
    type: ChatBackgroundType.gradient,
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF1A0A00),
        Color(0xFF331A00),
        Color(0xFF4D2600),
        Color(0xFF662200),
      ],
      stops: [0.0, 0.3, 0.7, 1.0],
    ),
    textColor: Colors.white,
  );

  // Pattern backgrounds
  static const dots = ChatBackground(
    id: 'dots',
    name: 'Dots Pattern',
    type: ChatBackgroundType.pattern,
    solidColor: Color(0xFF0D1117),
    textColor: Colors.white,
  );

  static const grid = ChatBackground(
    id: 'grid',
    name: 'Grid Pattern',
    type: ChatBackgroundType.pattern,
    solidColor: Color(0xFF0F1419),
    textColor: Colors.white,
  );

  /// All available backgrounds
  static const List<ChatBackground> all = [
    defaultBackground,
    darkGray,
    midnight,
    darkBlue,
    charcoal,
    deepPurple,
    blueGradient,
    purpleGradient,
    greenGradient,
    sunsetGradient,
    nightSkyGradient,
    cosmicGradient,
    oceanGradient,
    roseGradient,
    // Premium 4K Wallpapers
    auroraGradient,
    galaxyGradient,
    nebulaPurple,
    midnightCity,
    emeraldForest,
    crimsonDusk,
    sapphireDepth,
    northernLights,
    amethystDream,
    volcanicNight,
    // Patterns
    dots,
    grid,
  ];

  /// Get background by ID
  static ChatBackground getById(String id) {
    return all.firstWhere(
      (bg) => bg.id == id,
      orElse: () => defaultBackground,
    );
  }
}
