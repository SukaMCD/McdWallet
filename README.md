# <div align="center"> McdWallet</div>

McdWallet adalah aplikasi manajemen keuangan pribadi (*personal finance manager*) berbasis mobile yang dirancang untuk membantu pengguna mengelola transaksi keuangan, memantau batas anggaran, menganalisis arus kas melalui grafik interaktif, serta menyimpan data secara aman.

Aplikasi ini dibangun menggunakan framework Flutter dengan manajemen status (state management) Riverpod, dan memanfaatkan Supabase sebagai infrastruktur basis data backend secara real-time.

---

## Fitur Utama

Aplikasi McdWallet menyediakan berbagai fungsionalitas utama untuk mendukung pencatatan keuangan yang disiplin dan aman:

### 1. Manajemen Transaksi Mutasi
*   **Pencatatan Terpadu**: Mendukung pencatatan jenis transaksi Pemasukan, Pengeluaran, dan Transfer antar-dompet dalam satu form terintegrasi.
*   **Biaya Admin Transfer**: Fasilitas penambahan biaya administrasi khusus saat melakukan transfer antar-dompet.
*   **Upload Lampiran Struk**: Penyimpanan berkas digital atau foto nota transaksi secara asinkron ke layanan Supabase Storage.
*   **Swipe-to-Delete**: Penghapusan transaksi secara cepat melalui gestur geser (*swipe*) yang disertai dengan pemulihan (*rollback*) otomatis terhadap saldo dompet terkait.

### 2. Dasbor Analitik Keuangan
*   **Grafik Arus Kas (Cashflow Line Chart)**: Visualisasi tren pemasukan dan pengeluaran berkala menggunakan diagram garis ganda interaktif.
*   **Distribusi Pengeluaran (Expense Pie Chart)**: Diagram lingkaran reaktif yang menyajikan komposisi pengeluaran berdasarkan kategori transaksi beserta persentase kontribusinya.
*   **Filter Periode**: Pengelompokan data mutasi berdasarkan 7 hari terakhir, bulan berjalan, atau keseluruhan data transaksi.

### 3. Sistem Pemantauan Anggaran (Budgeting)
*   **Batas Anggaran Reaktif**: Pembuatan limit anggaran bulanan untuk kategori pengeluaran tertentu.
*   **Indikator Visual Dinamis**: Progress bar linear yang berubah warna secara otomatis dari hijau (aman), kuning (mendekati batas), hingga merah (anggaran terlampaui).
*   **Notifikasi Alarm Batas**: Pemicuan notifikasi lokal secara instan pada sistem status bar handphone apabila transaksi pengeluaran melampaui sisa anggaran yang ditentukan.

### 4. Manajemen Multi-Dompet & Saldo Historis
*   **Saldo Awal & Saldo Akhir**: Penghitungan dinamis saldo awal (opening balance) dan saldo akhir (closing balance) bulanan menggunakan skema matematika *rollback* historis.
*   **Penyederhanaan Warna Visual**: Skema warna ikon transaksi yang disederhanakan berdasarkan tipe (Hijau untuk Pemasukan, Merah untuk Pengeluaran, Abu-abu untuk Transfer) guna mengurangi beban visual bagi pengguna.

### 5. Keamanan Akses Berlapis
*   **PIN & Setup Akses**: Kewajiban pengisian kode keamanan PIN saat pertama kali melakukan pendaftaran dan setiap kali membuka aplikasi.
*   **Autentikasi Biometrik**: Integrasi pemindaian sidik jari (*fingerprint*) atau pengenalan wajah (*face recognition*) menggunakan pustaka *local_auth* native.

### 6. Ekspor Laporan Finansial
*   **File CSV**: Pengeksporan laporan berkala langsung ke format CSV yang kompatibel dengan Microsoft Excel atau Google Sheets.
*   **Ringkasan Teks Indah**: Ringkasan deskriptif laporan arus kas bersih yang diformat rapi dan siap disalin untuk dibagikan ke platform pesan eksternal.

### 7. Pemindai Struk Otomatis (OCR Receipt Scanner)
*   **Hibrida Cerdas Multi-LLM**: Mengintegrasikan API super cepat **Groq (LLaMA 3.3 70B)** sebagai pemroses utama online (~100ms), didukung fallback **Gemini API (gemini-1.5-flash)**, serta parser offline lokal **Google ML Kit Text Recognition** untuk menjamin fungsionalitas pemindaian tanpa jaringan internet!
*   **Pembersihan Noise Otomatis**: Secara cerdas menyaring elemen screenshot/UI media sosial (seperti LinkedIn, Buka, Bagikan, Simpan) dan status bar ponsel (kecepatan internet `53,1 K/s`, baterai, jam, dll.) agar data nominal belanja tetap bersih dari kesalahan baca.
*   **Koreksi Pintar Angka Ribuan**: Algoritma reaktif yang otomatis merekonstruksi angka ribuan yang terpotong oleh OCR (misal `25.000` terbaca `25.00`), menjamin ekstraksi nominal belanja tetap akurat secara presisi.
*   **Antarmuka Scrollable & Keyboard-Safe**: Form modal verifikasi glassmorphic premium yang dilindungi oleh `SingleChildScrollView` dan `AnimatedPadding` (durasi 150ms) untuk menjamin 0% bug keyboard layout overflow.
*   **Tombol Ikon Minimalis**: Tombol "Foto Ulang" berbasis ikon kamera murni (*icon-only*) untuk tampilan estetika visual yang seimbang dan modern.

### 8. Pemantau Kurs Asing (Forex Monitoring)
*   **Wise/Revolut-Style Horizontal Carousel**: Desain baris kartu minimalis premium bergulir horizontal (horizontal list) pada dasbor untuk memantau kurs mata uang asing pilihan secara real-time.
*   **Integrasi API Publik Bebas Kunci (Keyless)**: Mengakses data nilai tukar mata uang global terupdate secara real-time menggunakan `open.er-api.com` (ExchangeRate-API terdistribusi via Cloudflare CDN) tanpa memerlukan API Key, menjamin stabilitas 100% dan bebas dari kehabisan limit kunci.
*   **Sistem Background Auto-Refresh & Caching**: Cache pintar berbasis penyimpanan lokal (`SharedPreferences`) dengan masa berlaku (TTL) 1 jam untuk memperbarui data secara berkala tanpa membebani performa perangkat atau kuota data.
*   **Proteksi Cooldown Refresh Manual**: Dilindungi oleh batas waktu tunggu (*cooldown*) 5 menit setiap kali pengguna melakukan gestur *pull-to-refresh* pada dasbor utama untuk menjaga efisiensi lalu lintas data dan mencegah overload server.
*   **Seleksi Favorit & Pencarian Dinamis**: Lembar modal (bottom sheet) reaktif dengan kolom pencarian cepat untuk mencari, memilih, dan mengelola hingga 5 mata uang asing favorit secara fleksibel.
*   **Visualisasi Trend & Konversi Cerdas**: Setiap kartu dilengkapi panah indikator trend kenaikan/penurunan harga kurs reaktif dan modul formatting pintar (pembulatan otomatis ke bilangan bulat untuk nominal di atas Rp100 agar menghemat ruang visual).