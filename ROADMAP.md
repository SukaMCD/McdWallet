# Rencana Pengembangan Sistem (Roadmap & Backlog) — McdWallet

Dokumen ini berisi rencana pengembangan jangka panjang, perbaikan sistem (*improvements*), serta gagasan fitur baru untuk aplikasi **McdWallet** guna meningkatkan kualitas rekayasa, performa, keamanan, dan kegunaan sistem (*user experience*).

---

## 1. Optimalisasi Sistem & Perbaikan Arsitektur (*System Improvements*)

Daftar perbaikan teknis pada modul yang sudah ada untuk menjamin skalabilitas aplikasi:

### [ ] Kompresi Gambar Lampiran Struk (*Image Compression*)
*   **Deskripsi**: Mengurangi ukuran resolusi dan kapasitas file foto struk/nota belanja yang diambil langsung dari kamera ponsel sebelum diunggah ke Supabase Storage.
*   **Strategi Implementasi**:
    *   Mengintegrasikan package `flutter_image_compress` atau `image`.
    *   Membatasi kapasitas file maksimal di kisaran 300 KB - 500 KB dan resolusi maksimal 1080p.
    *   Menerapkan optimasi format gambar ke `.jpg` atau `.webp` untuk kompresi terbaik.
*   **Kompleksitas**: Rendah (Low)

### [ ] Sistem Penyimpanan Lokal & Mode Offline (*Offline Caching*)
*   **Deskripsi**: Menjamin pencatatan keuangan tetap dapat dilakukan ketika pengguna berada di area tanpa koneksi internet.
*   **Strategi Implementasi**:
    *   Memasang local database yang ringan dan aman seperti `Hive` atau `Isar`.
    *   Menyimpan transaksi baru secara lokal dengan bendera status `is_synced: false`.
    *   Membuat modul sinkronisasi latar belakang yang mendeteksi jaringan menggunakan `connectivity_plus` dan mengunggah data tertunda ke Supabase secara otomatis saat koneksi pulih.
*   **Kompleksitas**: Tinggi (High)

### [ ] Otomatisasi Kunci Aplikasi (*Auto-Lock Timeout*)
*   **Deskripsi**: Mengamankan data finansial pengguna secara otomatis jika aplikasi ditinggalkan dalam kondisi terbuka.
*   **Strategi Implementasi**:
    *   Memantau status aplikasi melalui class `WidgetsBindingObserver` (*App Lifecycle States*).
    *   Mencatat timestamp saat aplikasi masuk ke status `paused` atau `inactive`.
    *   Memicu layar PIN secara otomatis saat aplikasi kembali ke status `resumed` apabila durasi jeda telah melebihi 3 menit.
*   **Kompleksitas**: Sedang (Medium)

---

## 2. Rencana Fitur Baru (*New Features Backlog*)

Daftar fungsionalitas baru untuk memperluas jangkauan penggunaan aplikasi McdWallet:

### [ ] Pengingat & Pencatatan Transaksi Berulang (*Recurring & Subscription Manager*)
*   **Deskripsi**: Fasilitas otomatisasi untuk mencatat tagihan periodik rutin bulanan atau tahunan seperti layanan berlangganan (Netflix, Spotify), tagihan listrik, BPJS, maupun kosan.
*   **Strategi Implementasi**:
    *   Membuat tabel `recurring_templates` di Supabase untuk menampung template transaksi rutin.
    *   Menggunakan local notification scheduler untuk memicu alarm pengingat pembayaran pada H-1 tanggal jatuh tempo.
    *   Menyediakan opsi otomatisasi persetujuan pencatatan saldo dompet saat tanggal jatuh tempo terlewati.
*   **Kompleksitas**: Sedang (Medium)

### [x] Pemindai Struk Otomatis (*OCR Receipt Scanner*)
*   **Status**: **SELESAI (v2.1.0)**
*   **Deskripsi**: Kemudahan mencatat transaksi pengeluaran secara cepat hanya dengan memfoto struk kasir fisik tanpa perlu mengetik nominal secara manual.
*   **Hasil Implementasi**:
    *   **Hibrida Cerdas**: Sukses mengintegrasikan API **Groq (LLaMA 3.3 70B)** super cepat (~100ms) sebagai pemroses utama, didukung fallback sekunder **Gemini API (gemini-1.5-flash)**, serta parser offline lokal **Google ML Kit Text Recognition** untuk pemindaian mandiri tanpa koneksi internet.
    *   **Filter Noise Status Bar**: Algoritma reaktif yang otomatis menyaring data screenshot seperti jam, baterai, status bar (`VoLTE`, `4G`), kecepatan internet (`53,1 K/s`), dan UI media sosial (seperti `LinkedIn`, `Bagikan`, `Simpan`).
    *   **Koreksi Cerdas Ribuan**: Algoritma reaktif yang otomatis merekonstruksi angka ribuan yang terpotong oleh OCR (misal `25.000` terbaca `25.00`), menjamin ekstraksi nominal belanja tetap akurat secara presisi.
    *   **Keyboard Overflow Fix**: Desain layout modal bottom sheet scrollable interaktif yang dilindungi oleh `SingleChildScrollView` dan `AnimatedPadding` (durasi 150ms) untuk menjamin 0% bug keyboard layout bottom overflow.
    *   **Tombol Ikon Minimalis**: Tombol "Foto Ulang" berbasis ikon kamera murni (*icon-only*) untuk tampilan estetika visual yang seimbang dan modern.
*   **Kompleksitas**: Tinggi (High)

### [ ] Alat Bantu Pembagian Tagihan (*Split Bill Manager*)
*   **Deskripsi**: Membantu pengguna membagi tagihan pembayaran pengeluaran kelompok secara adil saat melakukan aktivitas makan atau belanja bersama rekan-rekan.
*   **Strategi Implementasi**:
    *   Mendesain modul antarmuka kalkulator pembagi tagihan yang fleksibel (pembagian rata atau berdasarkan item pesanan masing-masing individu).
    *   Menyimpan status pembayaran piutang (*settled* / *unsettled*) per kontak nama teman.
    *   Mencatat porsi bayar pribadi secara otomatis sebagai pengeluaran transaksi di dalam dompet terpilih.
*   **Kompleksitas**: Sedang (Medium)

### [ ] Dashboard Analitik Perbandingan Bulanan (*Month-over-Month Analytics*)
*   **Deskripsi**: Laporan grafik komparatif mendalam untuk membantu pengguna mengevaluasi efisiensi penghematan finansial dari bulan ke bulan.
*   **Strategi Implementasi**:
    *   Merancang chart bar komparatif (`BarChart` dari library `fl_chart`) untuk menyandingkan pengeluaran total bulan ini dengan bulan lalu.
    *   Menampilkan metrik persentase kenaikan/penurunan mutasi bersih secara deskriptif (misal: "Pengeluaran Anda menurun 12% dibanding bulan April").
*   **Kompleksitas**: Sedang (Medium)

### [ ] Sinkronisasi Mutasi BNI Otomatis via Email Reader (`wondr@bni.co.id`)
*   **Deskripsi**: Fitur otomatisasi pencatatan transaksi BNI wondr sekecil apa pun nominalnya dengan cara membaca email bukti transaksi masuk secara aman dari alamat pengirim resmi BNI `wondr@bni.co.id`, memecahkan masalah notifikasi SMS/Push wondr BNI yang hanya muncul untuk nominal di atas Rp500.000.
*   **Strategi Implementasi**:
    *   Mengintegrasikan Google Sign-In (`OAuth2`) dengan cakupan (*scope*) `https://www.googleapis.com/auth/gmail.readonly` untuk meminta izin akses baca email transaksi secara aman.
    *   Membuat *background sync worker* (menggunakan `workmanager` atau alarm scheduler) yang berjalan berkala untuk memeriksa inbox email terbaru dari pengirim `wondr@bni.co.id`.
    *   Mendesain parser teks HTML e-notification BNI wondr menggunakan modul RegExp dinamis untuk mengekstrak data penting:
        *   **Nominal Mutasi** (Debit / Kredit)
        *   **Tanggal & Waktu Transaksi** secara presisi.
        *   **Jenis Transaksi** (Transfer, QRIS, Tarik Tunai, Biaya Admin).
        *   **Nama Merchant / Rekening Tujuan**.
    *   Memasukkan data transaksi secara otomatis ke dompet BNI di dalam McdWallet dan memicu sinkronisasi lokal.
*   **Kompleksitas**: Tinggi (High)

### [ ] Pemantau Notifikasi Transaksi GoPay & E-Wallet (`GoPay Push Notification Listener`)
*   **Deskripsi**: Pencatatan otomatis mutasi pengeluaran e-wallet harian (GoPay, ShopeePay, OVO) bernominal mikro melalui bilah status notifikasi ponsel Android secara gratis dan *real-time*.
*   **Strategi Implementasi**:
    *   Memanfaatkan layanan sistem Android resmi `NotificationListenerService` di Flutter melalui integrasi native platform channel.
    *   Menyaring notifikasi masuk khusus dari aplikasi Gojek (`com.gojek.app`), OVO (`id.ovo`), dan Shopee (`com.shopee.id`).
    *   Mengekstrak data transaksi (nominal, jenis transaksi masuk/keluar, nama merchant) menggunakan parser regex lokal yang cepat.
    *   Menampilkan *background banner / silent local notification* ketika transaksi berhasil diimpor otomatis ke e-wallet terkait di McdWallet.
*   **Kompleksitas**: Sedang (Medium)

---

## 3. Mesin Rekonsiliasi Transaksi Pintar (*Cross-Wallet Smart Reconciliation*)

Untuk menghindari **pencatatan ganda (*double-counting*)** ketika pengguna memindahkan uang antar-rekening milik sendiri (misalnya transfer dari BNI ke GoPay, atau sebaliknya), McdWallet akan dilengkapi dengan **Smart Reconciliation Engine** yang bekerja di latar belakang.

### [ ] Sistem Rekonsiliasi Aliran Transfer Antar-Dompet
*   **Mekanisme Kerja**:
    1. **Skenario A: Transfer BNI wondr ke GoPay (Top-Up)**
       * *Deteksi Debit BNI*: Sistem membaca email dari `wondr@bni.co.id` yang menyatakan ada *debit keluar* sebesar Rp100.000 untuk transfer ke VA GoPay.
       * *Deteksi Kredit GoPay*: Listener mendeteksi notifikasi masuk dari `com.gojek.app` berupa *saldo bertambah* sebesar Rp100.000 (atau Rp99.000 setelah dipotong biaya admin).
       * *Pencocokan Rekonsiliasi*: Sistem secara otomatis membandingkan timestamp kedua kejadian. Jika selisih waktu `< 3 menit` dan nominal dasar cocok, kedua mutasi tersebut **TIDAK** dicatat sebagai 1 Pengeluaran BNI + 1 Pemasukan GoPay secara terpisah.
       * *Penyatuan Data (Merge)*: Kedua entri disatukan menjadi **1 Transaksi Transfer** tunggal (Dari: Dompet BNI -> Ke: Dompet GoPay) dengan nominal bersih Rp100.000, serta otomatis mencatat selisih (misal Rp1.000) sebagai biaya admin pengeluaran terpisah.
    2. **Skenario B: Penarikan Saldo GoPay ke BNI wondr (Cashout)**
       * *Deteksi Debit GoPay*: Listener mendeteksi notifikasi pengeluaran GoPay sebesar Rp50.000 dengan tujuan BNI.
       * *Deteksi Kredit BNI*: Sistem mendeteksi email masuk dari `wondr@bni.co.id` berupa transfer masuk (kredit) sebesar Rp50.000.
       * *Penyatuan Data (Merge)*: Otomatis terkonversi menjadi **1 Transaksi Transfer** tunggal (Dari: Dompet GoPay -> Ke: Dompet BNI) bernominal Rp50.000.
*   **Keunggulan Sistem**:
    *   **Akurasi Saldo 100%**: Menjamin grafik total pengeluaran dan pemasukan bulanan tetap akurat tanpa tergelembung oleh aktivitas pemindahan saldo sendiri.
    *   **Otomatisasi Penuh**: Pengguna tidak perlu menghapus secara manual atau mengubah tipe transaksi secara berulang.
*   **Kompleksitas**: Tinggi (High)
