# Changelog — McdWallet

Semua perubahan penting pada proyek **McdWallet** akan didokumentasikan di berkas ini. Format rilis ini merujuk pada standar [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) dan menggunakan [Semantic Versioning](https://semver.org/).

---

## [1.0.0] — 2026-05-25

Rilis stabil pertama aplikasi McdWallet dengan seluruh modul inti manajemen transaksi bulanan, sistem pemantauan limit anggaran reaktif, multi-dompet, analitik grafik interaktif, ekspor laporan, biaya admin transfer, kalkulasi saldo historis, keamanan PIN biometrik, pemindai struk otomatis (OCR Receipt Scanner) hibrida cerdas, serta pemantau kurs asing (Forex Monitoring) modern.

### Ditambahkan
*   **Pemantau Kurs Asing (Forex Monitoring)**:
    *   **Wise/Revolut-Style Dashboard**: Panel horizontal scrollable card minimalis premium yang menampilkan kartu kurs mata uang asing pilihan secara dinamis lengkap dengan bendera visual, nama mata uang, nilai tukar real-time terhadap IDR, serta panah indikator tren pergerakan nilai tukar.
    *   **Kalkulator Konversi Cepat (Converter Sheet)**: Mengintegrasikan deteksi ketukan pada setiap kartu kurs asing untuk memunculkan modal bottom sheet kalkulator konversi valas interaktif. Mendukung sinkronisasi reaktif dua arah (input Valas <-> IDR) secara *real-time* saat pengguna mengetik, tombol preset nilai instan (+10, +50, +100, +500, +1.000 valas, dan Rp50k, Rp100k, Rp500k, Rp1jt, Rp5jt IDR), serta 100% aman digunakan secara offline/luring menggunakan data cache lokal terbaru.
    *   **Integrasi API Bebas Kunci (Keyless)**: Menggunakan public API dari `open.er-api.com` (didukung ExchangeRate-API via Cloudflare CDN) sebagai sumber data real-time berkinerja tinggi, menjamin stabilitas 100% tanpa risiko kegagalan otentikasi kunci API komersial.
    *   **Auto-Update Latar Belakang & Caching Pintar**: Sistem refresh otomatis latar belakang berbasis durasi cache 1 jam menggunakan `SharedPreferences` untuk menyimpan data kurs secara lokal. Dilengkapi cooldown refresh manual selama 5 menit guna mencegah pemborosan pemanggilan API dan menghemat kuota internet pengguna.
    *   **Pencarian & Seleksi Reaktif**: Lembar pilihan (bottom sheet) dinamis untuk mencari, memilih, dan membatasi pemantauan hingga 5 mata uang asing favorit secara reaktif (disimpan secara permanen dalam memori lokal perangkat).
    *   **Model Data Adaptif & Presisi**: Konversi dan pembulatan dinamis untuk nominal besar (>= Rp100 dibulatkan tanpa desimal agar pas dalam kartu visual yang sempit, sedangkan nominal kecil tetap presisi dengan 2 digit desimal).
*   **Pemindai Struk Otomatis (OCR Receipt Scanner)**:
    *   **Hibrida Cerdas Multi-LLM**: Mengintegrasikan API super cepat **Groq (LLaMA 3.3 70B)** sebagai pemroses utama online (~100ms) untuk pengenalan JSON terstruktur yang sangat presisi, didukung oleh fallback **Gemini API (gemini-1.5-flash)**.
    *   **Offline-First Google ML Kit**: Layanan offline on-device menggunakan `google_mlkit_text_recognition` sebagai pemindai mandiri tanpa membutuhkan kuota atau jaringan internet.
    *   **Filter Noise Status Bar & UI Screenshot**: Modul filter `_isNoiseLine` pada `ocr_service.dart` untuk otomatis mengabaikan teks kecepatan internet ponsel (`53,1 K/s`), carrier state (`VoLTE`, `4G`), baterai (`69%`), jam, dan elemen UI screenshot media sosial (seperti `LinkedIn`, `Bagikan`, `Simpan`, `Buka >`).
    *   **Koreksi Cerdas Angka Ribuan**: Pemrosesan `_extractAmountsFromLine` yang secara cerdas merekonstruksi angka ribuan yang terpotong desimal sen akibat keterbatasan OCR (misal `10.000` atau `25.000` terbaca `10.00` atau `25.00`), menjamin nominal belanja tetap terbaca tepat.
    *   **Penyaringan Konteks Tanggal**: Mengabaikan angka tanggal transaksi struk (seperti tanggal `04` dan `2025` dari `04/04/2025`) dari daftar kandidat nominal belanja agar tidak menimbulkan kerancuan.
    *   **Tombol Ikon Murni "Foto Ulang"**: Mengubah tombol foto ulang menjadi icon-only button berbasis ikon kamera minimalis (`LucideIcons.camera`) untuk keselarasan desain visual yang seimbang.
    *   **Lembar Scanner Interaktif Glassmorphic**: Modal bottom sheet modern dilengkapi denyutan laser Emerald saat proses pemindaian sedang berlangsung, picker galeri/kamera, dan formulir verifikasi pra-isi.
    *   **Pengisian Formulir Otomatis**: Tombol pemindai cepat pada AppBar transaksi yang secara otomatis mengisi nominal, nama toko, tanggal struk, dan otomatis melampirkan berkas foto ke dalam Supabase Storage.
    *   **Ketergantungan Baru**: Menambahkan paket `google_mlkit_text_recognition`, `google_generative_ai`, dan `http: ^1.2.1` ke dalam berkas `pubspec.yaml`.
*   **Manajemen Transaksi Mutasi (CRUD)**: Pencatatan mutasi pengeluaran, pemasukan, dan transfer dalam satu form terpadu dengan reload balance reaktif.
*   **Biaya Admin Transfer**: Fasilitas penambahan biaya administrasi ketika melakukan transfer saldo antar-dompet lengkap dengan trigger database update saldo di Supabase PostgreSQL.
*   **Visualisasi Saldo Awal & Saldo Akhir**: Monthly Summary Card pada daftar riwayat transaksi yang secara matematis menghitung saldo awal dan saldo akhir historis bulanan menggunakan sistem rollback transaksi.
*   **True Lazy Scroll Virtualization**: Struktur list riwayat transaksi datar (*flattening*) dengan viewport virtualization memanfaatkan single `ListView.builder` untuk menjamin performa gulir super mulus (60/120 FPS).
*   **Sistem Limit Anggaran (Budgeting)**: Progress bar limit anggaran bulanan reaktif yang berubah warna secara dinamis (Emerald/Amber/Rose) dilengkapi pemicuan local notification status bar saat batas pengeluaran terlampaui.
*   **Dasbor Analitik Keuangan**: Grafik tren garis arus kas melengkung ganda (*Cashflow Line Chart*) dan diagram lingkaran distribusi pengeluaran (*Pie Chart*) interaktif berbasis `fl_chart`.
*   **Keamanan PIN & Biometrik**: Proteksi kode keamanan PIN lokal yang diintegrasikan secara native dengan pemindaian biometrik (`local_auth`).
*   **Ekspor Data Laporan**: Bottom sheet pengeksporan mutasi transaksi ke berkas standard CSV dan ringkasan teks indah yang siap disalin untuk dibagikan ke WhatsApp.

### Diperbaiki
*   **Keyboard Layout Bottom Overflow**: Merancang ulang layout modal bottom sheet `OcrScannerSheet` dengan menggunakan `SingleChildScrollView` dan transisi `AnimatedPadding` bermedium kurva *Ease-Out Quad* berdurasi 150 milidetik. Bug overflow sebesar 68px saat keyboard aktif kini **teratasi 100%**.
*   **Pencegahan Horizontal Layout Overflow**: Mengganti baris mendatar `Row` pada kolom Rekomendasi Kategori menjadi widget `Wrap` reaktif (`spacing: 8` dan `runSpacing: 6`). Masalah visual `Right Overflowed by 5.8 pixels` pada rasio layar smartphone sempit kini **teratasi 100%** dengan melipat badge ke bawah secara alami.
*   **Optimasi Centering Ikon Button**: Meningkatkan widget global `CustomButton` agar secara cerdas tidak menyisipkan jarak spasi pemisah jika teks diset kosong (`text: ''`), menjamin posisi ikon murni berada tepat di tengah-tengah tombol.
