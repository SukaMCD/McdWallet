# Changelog — McdWallet

Semua perubahan penting pada proyek **McdWallet** akan didokumentasikan di berkas ini. Format rilis ini merujuk pada standar [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) dan menggunakan [Semantic Versioning](https://semver.org/).

---

## [1.0.1] — 2026-05-25

Rilis pembaruan ini menghadirkan fitur **Pemindai Struk Otomatis (OCR Receipt Scanner)** hibrida online-offline yang cerdas dan berkinerja tinggi, perbaikan layout bottom sheet, serta optimasi tombol visual.

### Ditambahkan
*   **Hibrida Cerdas Multi-LLM**: Mengintegrasikan API super cepat **Groq (LLaMA 3.3 70B)** sebagai pemroses utama online (~100ms) untuk pengenalan JSON terstruktur yang sangat presisi, didukung oleh fallback **Gemini API (gemini-1.5-flash)**.
*   **Offline-First Google ML Kit**: Layanan offline on-device menggunakan `google_mlkit_text_recognition` sebagai pemindai mandiri tanpa membutuhkan kuota atau jaringan internet.
*   **Filter Noise Status Bar & UI Screenshot**: Modul filter `_isNoiseLine` pada `ocr_service.dart` untuk otomatis mengabaikan teks kecepatan internet ponsel (`53,1 K/s`), carrier state (`VoLTE`, `4G`), baterai (`69%`), jam, dan elemen UI screenshot media sosial (seperti `LinkedIn`, `Bagikan`, `Simpan`, `Buka >`).
*   **Koreksi Cerdas Angka Ribuan**: Pemrosesan `_extractAmountsFromLine` yang secara cerdas merekonstruksi angka ribuan yang terpotong desimal sen akibat keterbatasan OCR (misal `10.000` atau `25.000` terbaca `10.00` atau `25.00`), menjamin nominal belanja tetap terbaca tepat.
*   **Penyaringan Konteks Tanggal**: Mengabaikan angka tanggal transaksi struk (seperti tanggal `04` dan `2025` dari `04/04/2025`) dari daftar kandidat nominal belanja agar tidak menimbulkan kerancuan.
*   **Tombol Ikon Murni "Foto Ulang"**: Mengubah tombol foto ulang menjadi icon-only button berbasis ikon kamera minimalis (`LucideIcons.camera`) untuk keselarasan desain visual yang seimbang.
*   **Lembar Scanner Interaktif Glassmorphic**: Modal bottom sheet modern dilengkapi denyutan laser Emerald saat proses pemindaian sedang berlangsung, picker galeri/kamera, dan formulir verifikasi pra-isi.
*   **Pengisian Formulir Otomatis**: Tombol pemindai cepat pada AppBar transaksi yang secara otomatis mengisi nominal, nama toko, tanggal struk, dan otomatis melampirkan berkas foto ke dalam Supabase Storage.
*   **Ketergantungan Baru**: Menambahkan paket `google_mlkit_text_recognition`, `google_generative_ai`, dan `http: ^1.2.1` ke dalam berkas `pubspec.yaml`.

### Diperbaiki
*   **Keyboard Layout Bottom Overflow**: Merancang ulang layout modal bottom sheet `OcrScannerSheet` dengan menggunakan `SingleChildScrollView` dan transisi `AnimatedPadding` bermedium kurva *Ease-Out Quad* berdurasi 150 milidetik. Bug overflow sebesar 68px saat keyboard aktif kini **teratasi 100%**.
*   **Pencegahan Horizontal Layout Overflow**: Mengganti baris mendatar `Row` pada kolom Rekomendasi Kategori menjadi widget `Wrap` reaktif (`spacing: 8` dan `runSpacing: 6`). Masalah visual `Right Overflowed by 5.8 pixels` pada rasio layar smartphone sempit kini **teratasi 100%** dengan melipat badge ke bawah secara alami.
*   **Optimasi Centering Ikon Button**: Meningkatkan widget global `CustomButton` agar secara cerdas tidak menyisipkan jarak spasi pemisah jika teks diset kosong (`text: ''`), menjamin posisi ikon murni berada tepat di tengah-tengah tombol.

---

## [1.0.0] — 2026-05-15

Rilis stabil pertama aplikasi McdWallet dengan seluruh modul inti manajemen transaksi bulanan, sistem pemantauan limit anggaran reaktif, multi-dompet, analitik grafik interaktif, ekspor laporan, biaya admin transfer, kalkulasi saldo historis, dan otentikasi PIN biometrik.

### Ditambahkan
*   **Manajemen Transaksi Mutasi (CRUD)**: Pencatatan mutasi pengeluaran, pemasukan, dan transfer dalam satu form terpadu dengan reload balance reaktif.
*   **Biaya Admin Transfer**: Fasilitas penambahan biaya administrasi ketika melakukan transfer saldo antar-dompet lengkap dengan trigger database update saldo di Supabase PostgreSQL.
*   **Visualisasi Saldo Awal & Saldo Akhir**: Monthly Summary Card pada daftar riwayat transaksi yang secara matematis menghitung saldo awal dan saldo akhir historis bulanan menggunakan sistem rollback transaksi.
*   **True Lazy Scroll Virtualization**: Struktur list riwayat transaksi datar (*flattening*) dengan viewport virtualization memanfaatkan single `ListView.builder` untuk menjamin performa gulir super mulus (60/120 FPS).
*   **Sistem Limit Anggaran (Budgeting)**: Progress bar limit anggaran bulanan reaktif yang berubah warna secara dinamis (Emerald/Amber/Rose) dilengkapi pemicuan local notification status bar saat batas pengeluaran terlampaui.
*   **Dasbor Analitik Keuangan**: Grafik tren garis arus kas melengkung ganda (*Cashflow Line Chart*) dan diagram lingkaran distribusi pengeluaran (*Pie Chart*) interaktif berbasis `fl_chart`.
*   **Keamanan PIN & Biometrik**: Proteksi kode keamanan PIN lokal yang diintegrasikan secara native dengan pemindaian biometrik (`local_auth`).
*   **Ekspor Data Laporan**: Bottom sheet pengeksporan mutasi transaksi ke berkas standard CSV dan ringkasan teks indah yang siap disalin untuk dibagikan ke WhatsApp.
