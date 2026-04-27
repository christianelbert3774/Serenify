import 'dart:math';

class NoiseGenerator {
  final Random _random = Random();

  // White noise: angka random murni antara -1.0 sampai 1.0
  // Setiap sample tidak punya hubungan sama sekali dengan sample sebelumnya
  List<double> generateWhiteNoise(int sampleCount) {
    return List.generate(
      sampleCount,
          (_) => _random.nextDouble() * 2 - 1,
    );
  }

  // Pink noise: algoritma Voss-McCartney
  // Menggabungkan beberapa "baris" random dengan frekuensi update berbeda
  List<double> generatePinkNoise(int sampleCount) {
    const int numRows = 16;
    final List<double> rows = List.filled(numRows, 0.0);
    double runningSum = 0.0;
    final List<double> output = [];

    for (int i = 0; i < sampleCount; i++) {
      // Tentukan baris mana yang di-update di sample ini
      // (pakai trailing zeros dari bilangan biner i)
      int numTrailingZeros = i == 0 ? numRows : _countTrailingZeros(i);
      int rowIndex = numTrailingZeros % numRows;

      // Update baris tersebut dan sesuaikan running sum
      runningSum -= rows[rowIndex];
      rows[rowIndex] = _random.nextDouble() * 2 - 1;
      runningSum += rows[rowIndex];

      // Tambah sedikit white noise, lalu normalize
      double white = _random.nextDouble() * 2 - 1;
      output.add((runningSum + white) / (numRows + 1));
    }

    return output;
  }
  // Helper: hitung berapa trailing zero di representasi biner angka n
  int _countTrailingZeros(int n) {
    int count = 0;
    while (n & 1 == 0) {
      count++;
      n >>= 1;
    }
    return count;
  }

  // Brown noise: cumulative sum dari white noise, lalu normalize
  // Setiap sample = sample sebelumnya + sedikit perubahan random
  // Hasilnya terdengar lebih dalam dan berat dari pink noise
  List<double> generateBrownNoise(int sampleCount) {
    double runningValue = 0.0;
    final List<double> output = [];

    for (int i = 0; i < sampleCount; i++) {
      // Tambahkan perubahan kecil random ke nilai sebelumnya
      runningValue += _random.nextDouble() * 0.2 - 0.1;

      // Clamp: paksa nilai tetap dalam range -1.0 sampai 1.0
      runningValue = runningValue.clamp(-1.0, 1.0);

      output.add(runningValue);
    }

    return output;
  }
}
