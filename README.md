NAMA APP (Belum ditentukan)
Noise Generator & Soundscape App for Android
Project README & Context Document
Oleh: Christian Elbert
Teknik Informatika — Universitas Riau | https://christianelbert.vercel.app

1. Latar Belakang Proyek
Siapa Pembuatnya
Christian Elbert, mahasiswa S1 Teknik Informatika Universitas Riau, IPK 3.82. Stack yang sudah dikuasai: Vue.js, Node.js, Laravel, Python, Kotlin, MySQL, JavaScript (lengkapnya bisa dilihat di web saya, ini hanya overview).
Mengapa Proyek Ini Dibuat
•	Mengisi portofolio dengan proyek yang benar-benar dipakai orang, bukan SaaS pajangan
•	Model aplikasi perorangan seperti ilovepdf — berguna untuk satu user tanpa membutuhkan user lain
•	100% gratis, tidak ada monetisasi, murni portofolio dan kontribusi publik
•	Bisa dikembangkan solo tanpa bergantung goodwill pihak lain

Gap di Market yang Diisi
Aplikasi noise/soundscape yang ada saat ini (Noisli, Brain.fm, A Soft Murmur, myNoise) memiliki masalah bersama:
•	Berbasis web — tidak bisa offline
•	Memerlukan subscription berbayar
•	UI ketinggalan zaman (myNoise terakhir didesain ulang 2012)
•	Tidak ada kontrol granular yang terasa intuitif untuk user biasa
•	Tidak ada yang menggabungkan: offline + modern + gratis + kontrol penuh sekaligus

2. Keputusan Platform & Tech Stack
Platform: Android Only
Alasan memilih mobile bukan desktop:
•	User lebih sering pakai HP untuk tidur, relaksasi, dan kerja mobile
•	Lebih masuk akal menaruh HP di kasur daripada laptop
•	Lebih portable — bisa digunakan di mana saja

Alasan tidak memilih iOS (untuk saat ini):
•	Tidak punya Mac — Xcode (tools wajib iOS) hanya berjalan di macOS
•	Apple Developer Account $99/tahun
•	Tidak punya device iOS untuk testing
•	iOS bisa dipertimbangkan di masa depan jika sudah punya akses Mac

Google Play: Biaya publish sekali bayar $25, berlaku seumur hidup. Jauh lebih mudah dan murah dari App Store.

Tech Stack: Flutter (Dart)
Alasan memilih Flutter:
•	Satu codebase untuk Android (dan iOS di masa depan jika diperlukan)
•	Dart mudah dipelajari bagi yang sudah tahu JavaScript — sintaks sangat mirip
•	Package audio Flutter sudah sangat matang (just_audio, audio_session)
•	Community besar, dokumentasi lengkap, banyak tutorial

Opsi	Pertimbangan
Flutter (Dipilih)	Satu codebase, audio package matang, Dart mirip JS
React Native	Audio handling lebih rumit, banyak workaround
Kotlin Native	Android only, tidak bisa expand ke iOS suatu saat



Backend & Hosting
⚡ Tidak ada backend. Aplikasi ini 100% offline. Tidak ada server, tidak ada API call, tidak ada biaya hosting sama sekali. Semua data tersimpan lokal di device user.

3. Fitur Lengkap Aplikasi
3.1 Fitur MVP (Wajib Ada Sebelum Launch)
Noise Generator (Programatik — 0 byte storage)
Ketiga noise ini di-generate secara real-time oleh kode. Tidak membutuhkan file audio sama sekali.
•	White Noise: semua frekuensi sama rata, efektif memblokir suara sekitar yang tidak konsisten
•	Pink Noise: frekuensi rendah lebih dominan, lebih natural di telinga, membantu konsentrasi dan tidur
•	Brown Noise: frekuensi rendah sangat dominan, terdengar seperti angin kencang atau air terjun jauh, sangat populer di komunitas ADHD

Soundscape Layers (File Audio .ogg)
Layer ambient yang bisa di-mix satu sama lain. Setiap layer punya volume slider independen dengan ui dan animasi menarik. User bisa aktifkan beberapa sekaligus.
•	Hujan ringan
•	Hujan deras
•	Kafe / coffee shop
•	Api unggun / fireplace
•	Ombak pantai
•	Kipas angin
•	Kereta malam
•	dan sound ambient lainnya yang akan ditambahkan berikutnya

Equalizer Visual 5-Band
Label intuitif alih-alih angka teknis: "lebih hangat ↔ lebih sejuk", "lebih dalam ↔ lebih cerah". Di balik layar tetap memanipulasi frekuensi audio secara presisi via AndroidEqualizer.

Custom Audio Import
User bisa import file .mp3, .wav, .flac dari storage HP mereka. File yang diimport muncul sebagai layer di mixer — bisa di-mix dengan noise dan soundscape bawaan. File disalin ke folder private aplikasi agar tidak rusak jika file asli dihapus.

Preset System
Simpan kombinasi suara favorit dengan nama custom (contoh: "Sesi coding", "Tidur siang", "Baca buku"). Preset tersimpan lokal di device.

Timer
Set durasi berapa lama suara berjalan. Opsi: stop langsung atau fade out bertahap. Berguna untuk sesi Pomodoro atau sebelum tidur.

Background Playback
Audio tetap berjalan saat aplikasi diminimize. Notification bar control (play/pause/stop).

3.2 Fitur Post-Launch (Iterasi Berdasarkan Feedback)
•	Binaural Beats — frekuensi berbeda di kiri/kanan telinga: Fokus (40Hz), Relaksasi (10Hz), Tidur (4Hz)
•	Schedule Otomatis — "mulai pink noise jam 22:00, fade out 30 menit, lalu stop"
•	Audio Visualizer — representasi visual frekuensi, membuat aplikasi terasa premium. bisa dengan melakukan aliran warna warna sesuai suasana juga, tentukan saja nanti pendekatan terbaiknya.
•	On-Demand Download Soundscape — bundle awal kecil, soundscape tambahan bisa diunduh in-app
•	Widget Homescreen Android — kontrol ambient tanpa perlu buka aplikasi

4. Strategi Optimasi Ukuran Aplikasi
Target ukuran install awal: di bawah 30-40MB. Dicapai dengan kombinasi empat strategi:

Strategi	Dampak
Format .ogg	File hujan 5 menit .ogg 128kbps ≈ 4-5MB (vs .wav mentah ≈ 50MB+)
Durasi pendek + seamless loop	Cukup 30-60 detik per file. File 60 detik .ogg ≈ 500KB-1MB
Generate noise programatik	White/pink/brown noise = 0 byte storage, di-generate real-time
On-demand download	Bundle 5-8 soundscape inti, sisanya download in-app gratis

5. Sumber Audio & Lisensi
Sumber	Keterangan
Freesound.org	Filter CC0 (bebas tanpa credit) atau CC BY (wajib credit). Terbesar dan terlengkap.
Pixabay Audio	Semua konten CC0. Lebih mudah dari Freesound, kualitas konsisten.
Zapsplat	Gratis dengan akun, kualitas profesional, minta credit di aplikasi.
Rekam Sendiri	Paling bersih lisensinya. Kamu pemilik penuh audionya.

Credits Page: Ada halaman Credits di dalam aplikasi yang mencantumkan semua sumber audio beserta nama creator dan lisensinya. Best practice industri bahkan untuk CC0.

6. Arsitektur Proyek
Struktur Folder Flutter
appname/
├── android/                          # Android-specific configs
├── lib/
│   ├── main.dart                     # Entry point
│   ├── app.dart                      # MaterialApp, routing, theme
│   ├── core/
│   │   ├── audio/
│   │   │   ├── noise_generator.dart  # White/pink/brown via PCM
│   │   │   ├── audio_mixer.dart      # Mix multiple AudioSource
│   │   │   └── equalizer_service.dart# 5-band EQ
│   │   ├── storage/
│   │   │   ├── preset_repository.dart
│   │   │   └── custom_audio_repository.dart
│   │   └── models/
│   │       ├── soundscape_layer.dart
│   │       ├── preset.dart
│   │       └── noise_type.dart
│   ├── features/
│   │   ├── home/          # Layar utama mixer
│   │   ├── soundscapes/   # Grid semua soundscape
│   │   ├── presets/       # Daftar preset tersimpan
│   │   ├── timer/         # Timer widget
│   │   ├── equalizer/     # Visual EQ sliders
│   │   └── settings/      # Settings + Credits
│   └── shared/
│       ├── widgets/       # Volume slider, noise card
│       └── theme/         # Light/Dark theme, warna
├── assets/
│   └── audio/             # .ogg files (7 soundscape inti)
└── pubspec.yaml

Dependencies Utama (pubspec.yaml)
Package	Fungsi
just_audio: ^0.9.36	Core audio playback
audio_session: ^0.1.18	Handle audio focus & interruptions
just_audio_background: ^0.0.1-beta.11	Background playback + notification
flutter_riverpod: ^2.4.0	State management
hive_flutter: ^1.1.0	Fast local storage untuk preset
file_picker: ^6.1.1	Import audio custom dari storage HP
path_provider: ^2.1.1	Akses direktori lokal aplikasi

State Management: Riverpod
// Provider untuk semua active layers
final activeLayersProvider = StateNotifierProvider<LayersNotifier, List<SoundscapeLayer>>(
  (ref) => LayersNotifier(),
);

// Provider untuk noise yang aktif
final activeNoiseProvider = StateNotifierProvider<NoiseNotifier, NoiseState>(
  (ref) => NoiseNotifier(ref.read(audioMixerProvider)),
);

Catatan Teknis Penting
Noise Generation via PCM Buffer
White noise, pink noise, dan brown noise TIDAK menggunakan file audio — di-generate programatik secara real-time:
// White noise: random float -1.0 sampai 1.0
List<double> generateWhiteNoise(int sampleCount) {
  final random = Random();
  return List.generate(sampleCount, (_) => random.nextDouble() * 2 - 1);
}
// Pink noise: filter white noise dengan algoritma Voss-McCartney
// Brown noise: cumulative sum dari white noise, lalu normalize

Custom Audio — Private Storage Pattern
Future<String> importAudioFile(String sourcePath) async {
  final appDir = await getApplicationDocumentsDirectory();
  final customAudioDir = Directory("${appDir.path}/custom_audio");
  await customAudioDir.create(recursive: true);
  final fileName = path.basename(sourcePath);
  final destPath = "${customAudioDir.path}/$fileName";
  await File(sourcePath).copy(destPath);
  return destPath; // Path permanen, tidak bergantung file asli
}

7. Desain UI/UX
Prinsip Desain
•	light/Dark theme — menggunakan pendekatan tema yang berbeda
•	Minimal dan calm — tidak ada elemen yang "teriak", tidak ada warna mencolok
•	Satu layar utama — semua kontrol utama accessible tanpa navigasi dalam
•	Haptic feedback pada toggle dan slider untuk feel yang premium

Palet Warna
tentukan yang terbaik sesuai tema yang digunakan
Layout Layar Utama (hanya gambaran, boleh berbeda tergantung situasi/pendekatan)
[Header: app logo + Settings icon]

[Noise Type Cards — horizontal scroll]
  [○ White]  [● Pink]  [○ Brown]
  (tap untuk aktifkan, ada indicator aktif)

[Master Volume Slider]

[Active Layers — vertical list]
  [🌧 Hujan Ringan    ──●────  45%  ×]
  [☕ Kafe            ────●──  60%  ×]
  [+ Tambah Layer]

[Bottom Bar]
  [Presets]  [Timer: 45:00]  [EQ]

8. Timeline Pengerjaan (8 Minggu MVP)
Fase 1 — Fondasi Audio (Minggu 1-2)
Target: Audio engine berfungsi stabil. Jangan lanjut ke fase berikutnya sebelum ini benar-benar solid.

Minggu 1
•	Setup Flutter project dan install semua dependencies ✅
•	Implementasi noise_generator.dart — generate white noise via PCM buffer 
•	Implementasi pink noise (algoritma Voss-McCartney)
•	Implementasi brown noise (cumulative sum dari white noise)
•	Unit test: pastikan noise ter-generate tanpa artefak atau lag

Minggu 2
•	Implementasi audio_mixer.dart — mix noise + soundscape .ogg sekaligus
•	Setup just_audio untuk playback file .ogg dari assets/
•	Test mixing 3-4 layer secara bersamaan tanpa degradasi performa
•	Setup audio_session untuk handle focus (saat telepon masuk, dll)

Fase 2 — UI Utama dan Core Features (Minggu 3-4)
Target: Aplikasi bisa dipakai sehari-hari meski belum sempurna.

Minggu 3
•	Buat UI utama (home_screen.dart) dengan light/dark theme
•	Implementasi soundscape_grid.dart — grid dengan toggle + volume slider
•	Implementasi noise type selector (cards white/pink/brown)
•	Koneksikan UI dengan audio engine via Riverpod

Minggu 4
•	Implementasi preset system (simpan/load kombinasi aktif)
•	Implementasi timer widget
•	Setup background playback (just_audio_background)
•	Test: pastikan audio tetap jalan saat HP dikunci

Fase 3 — Fitur Tambahan (Minggu 5-6)
Target: Fitur MVP lengkap.

Minggu 5
•	Implementasi equalizer via AndroidEqualizer
•	Implementasi custom audio import — file picker + copy ke private storage
•	Integrasi custom audio sebagai layer di mixer

Minggu 6
•	Settings screen + Credits screen (daftar sumber audio + lisensi)
•	Polish UI — animasi, micro-interaction, visual konsisten
•	Testing di berbagai ukuran layar Android
•	Fix bugs, optimasi performa

Fase 4 — Finishing dan Launch (Minggu 7-8)
Target: Publish ke Google Play Store.

Minggu 7
•	App icon, splash screen
•	Buat signed APK / App Bundle untuk release
•	Setup Google Play Console, buat store listing
•	Screenshot aplikasi untuk Play Store

Minggu 8
•	Soft launch (publish ke Play Store)
•	Post ke komunitas: Reddit r/androidapps, komunitas developer Indonesia
•	Tambahkan ke portofolio christianelbert.vercel.app

Fase 5 — Post-Launch Iteration (Bulan 3-5)
•	Binaural beats
•	Schedule otomatis (timer lebih canggih)
•	Audio visualizer
•	On-demand download soundscape tambahan
•	Widget homescreen Android

9. Status Proyek Saat Ini
Yang Sudah Diputuskan
•	✅ Platform: Android only
•	✅ Tech Stack: Flutter (Dart)
•	✅ Fitur MVP sudah didefinisikan lengkap
•	✅ Arsitektur folder sudah dirancang
•	✅ Timeline 8 minggu sudah dibuat
•	✅ Strategi optimasi ukuran sudah direncanakan
•	✅ Sumber audio sudah diidentifikasi

Yang Belum Dikerjakan
•	❌ Implementasi noise generator
•	❌ Pengumpulan file audio dari Freesound/Pixabay
•	❌ Coding aplikasi

Christian Elbert • Universitas Riau • April 2026
