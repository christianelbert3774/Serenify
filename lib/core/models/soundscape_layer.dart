/// Data class yang merepresentasikan satu layer soundscape
class SoundscapeLayer {
  final String id;
  final String name;
  final String assetPath;
  final String icon;
  double volume;
  bool isActive;

  SoundscapeLayer({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.icon,
    this.volume = 0.5,
    this.isActive = false,
  });

  SoundscapeLayer copyWith({
    double? volume,
    bool? isActive,
  }) {
    return SoundscapeLayer(
      id: id,
      name: name,
      assetPath: assetPath,
      icon: icon,
      volume: volume ?? this.volume,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Daftar semua soundscape bawaan yang tersedia
final List<SoundscapeLayer> defaultSoundscapes = [
  SoundscapeLayer(
    id: 'rain',
    name: 'Rain Umbrella',
    assetPath: 'assets/audio/rainumbrella.ogg',
    icon: '🌧️',
  ),
  SoundscapeLayer(
    id: 'beach',
    name: 'Beach Waves',
    assetPath: 'assets/audio/beachwaves.ogg',
    icon: '🌊',
  ),
  SoundscapeLayer(
    id: 'bubble',
    name: 'Bubble',
    assetPath: 'assets/audio/bubble.ogg',
    icon: '🫧',
  ),
  SoundscapeLayer(
    id: 'lofi',
    name: 'Lo-Fi',
    assetPath: 'assets/audio/lofi.ogg',
    icon: '🎵',
  ),
  SoundscapeLayer(
    id: 'piano',
    name: 'Piano',
    assetPath: 'assets/audio/piano.ogg',
    icon: '🎹',
  ),
];
