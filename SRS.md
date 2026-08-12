# Software Requirements Specification (SRS)

## NyatetPesse
**Aplikasi Manajemen Keuangan Pribadi Berbasis Flutter dengan Local AI**

---

**Versi:** 2.0.0 (Merged)
**Tanggal:** 12 Agustus 2026
**Status:** Draft Baseline
**Platform:** Android
**Framework:** Flutter
**Bahasa:** Dart + Kotlin (Android Native)
**Database:** SQLite/Drift
**AI:** Machine Learning lokal/offline
**OCR:** On-device OCR

---

## Daftar Isi

1. [Pendahuluan](#1-pendahuluan)
2. [Deskripsi Umum](#2-deskripsi-umum)
3. [Aktor Sistem](#3-aktor-sistem)
4. [Kebutuhan Fungsional](#4-kebutuhan-fungsional)
5. [Kebutuhan Non-Fungsional](#5-kebutuhan-non-fungsional)
6. [Arsitektur Sistem](#6-arsitektur-sistem)
7. [Model Data](#7-model-data)
8. [Use Case Utama](#8-use-case-utama)
9. [Kebutuhan Antarmuka](#9-kebutuhan-antarmuka)
10. [Error Handling](#10-error-handling)
11. [Permission Requirements](#11-permission-requirements)
12. [Security Threats dan Mitigasi](#12-security-threats-dan-mitigasi)
13. [Machine Learning Specification](#13-machine-learning-specification)
14. [Testing Requirements](#14-testing-requirements)
15. [Acceptance Criteria MVP](#15-acceptance-criteria-mvp)
16. [Batasan & Asumsi](#16-batasan--asumsi)
17. [Risiko dan Mitigasi](#17-risiko-dan-mitigasi)
18. [Prinsip Desain Final](#18-prinsip-desain-final)
19. [Prioritas Pengembangan](#19-prioritas-pengembangan)
20. [Rekomendasi Teknologi](#20-rekomendasi-teknologi)
21. [Ringkasan Produk](#21-ringkasan-produk)

---

## 1. Pendahuluan

### 1.1 Tujuan Dokumen

Dokumen ini mendeskripsikan kebutuhan perangkat lunak untuk aplikasi **NyatetPesse** secara lengkap dan terstruktur, mencakup fitur, arsitektur sistem, model data, kebutuhan antarmuka, penanganan error, keamanan, pengujian, hingga prioritas pengembangan. Dokumen ini berfungsi sebagai acuan utama dalam proses perancangan, implementasi, dan pengujian.

### 1.2 Latar Belakang

Pengguna yang memiliki beberapa rekening bank, e-wallet, QRIS, dan uang tunai sering mengalami kesulitan menjaga pencatatan keuangan tetap lengkap. Pencatatan manual membutuhkan waktu dan berpotensi menyebabkan transaksi terlewat atau tercatat dua kali.

NyatetPesse dirancang untuk mengurangi pekerjaan tersebut dengan menggabungkan beberapa sumber transaksi dalam satu ledger keuangan. Notification Listener digunakan sebagai sumber transaksi digital, OCR digunakan untuk membaca struk dan bukti pembayaran, sedangkan Local AI digunakan untuk membantu klasifikasi transaksi.

### 1.3 Tujuan Sistem

1. Menyatukan transaksi dari berbagai sumber keuangan dalam satu aplikasi.
2. Mengotomatisasi pencatatan transaksi dan mengurangi input manual.
3. Mengklasifikasikan transaksi secara otomatis menggunakan Local AI.
4. Memungkinkan pemindaian struk dan bukti pembayaran (OCR).
5. Menjaga privasi data keuangan dengan pemrosesan 100% on-device.
6. Mendeteksi transaksi duplikat lintas sumber.
7. Memberikan mekanisme konfirmasi (human-in-the-loop) terhadap hasil otomatis.
8. Menyediakan dashboard, statistik, dan budgeting.
9. Mendukung rekonsiliasi antara catatan aplikasi dan saldo aktual.

### 1.4 Ruang Lingkup

**NyatetPesse** adalah aplikasi manajemen keuangan pribadi berbasis **Flutter** untuk platform **Android**, yang mengotomatiskan pencatatan transaksi keuangan dari berbagai sumber menggunakan:

- **Notification Listener** — menangkap notifikasi push dari aplikasi m-banking dan e-wallet secara real-time.
- **OCR (Optical Character Recognition)** — membaca teks dari foto struk fisik dan screenshot bukti pembayaran.
- **Local AI Model** — mengklasifikasikan dan mengekstrak informasi transaksi secara offline menggunakan model TFLite/LiteRT.
- **Input Manual** — sebagai fallback ketika sumber otomatis tidak tersedia.
- **Import data/mutasi** — sebagai mekanisme rekonsiliasi tambahan.

Seluruh pemrosesan AI utama berjalan **on-device** tanpa mengirim data finansial ke layanan pihak ketiga secara default, menjamin privasi pengguna.

#### Termasuk dalam Lingkup

- Manajemen akun/sumber dana & kategori.
- Input transaksi manual.
- Deteksi transaksi melalui notifikasi.
- OCR struk & OCR screenshot/bukti pembayaran.
- Rule engine + Local ML classifier + confidence score.
- Transaction inbox & duplicate detection.
- Transfer & top up antar akun.
- Dashboard, statistik, budget, search & filter.
- Rekonsiliasi saldo.
- Backup/export/import.
- Keamanan aplikasi (PIN, biometrik, enkripsi).
- Feedback pengguna untuk pengembangan/retraining model.
- Recurring transaction.

#### Tidak Termasuk pada MVP

- Mengakses database internal bank/e-wallet secara langsung.
- Login otomatis ke internet banking.
- Transfer uang atau pembayaran dari dalam aplikasi.
- Cloud AI sebagai komponen wajib.
- Integrasi open banking tanpa API resmi.
- Dukungan platform iOS.

### 1.5 Target Pengguna

| Karakteristik | Deskripsi |
|---|---|
| **Target Utama** | Pengguna Android usia 18–35 tahun |
| **Profil** | Aktif menggunakan lebih dari satu m-banking atau e-wallet |
| **Kebutuhan** | Ingin mencatat keuangan tanpa input manual yang repetitif |
| **Keahlian Teknis** | Pengguna umum (tidak perlu keahlian teknis) |
| **Kepedulian Privasi** | Tidak ingin data finansial dikirim ke server eksternal |

Versi awal ditujukan untuk **satu pengguna individu**. Arsitektur dapat dikembangkan untuk multi-user pada versi berikutnya.

### 1.6 Definisi dan Istilah

| Istilah | Definisi |
|---|---|
| **Transaksi** | Aktivitas keuangan berupa pemasukan, pengeluaran, transfer, atau top up |
| **Akun** | Sumber/tujuan dana (Bank, E-Wallet, Cash, Lainnya) |
| **Source** | Sumber data transaksi (manual, notification, ocr_receipt, ocr_screenshot, import) |
| **Notification Listener** | Layanan Android (`NotificationListenerService`) yang menangkap notifikasi yang diizinkan pengguna |
| **OCR** | Optical Character Recognition — pengenalan teks dari gambar |
| **Parser** | Komponen yang mengubah teks mentah menjadi data terstruktur |
| **Rule Engine** | Komponen berbasis aturan/regex untuk data deterministik (nominal, tanggal, dsb) |
| **Local AI / Local ML** | Model machine learning yang berjalan di perangkat tanpa koneksi internet |
| **TFLite / LiteRT** | TensorFlow Lite — format model ML yang dioptimalkan untuk mobile |
| **Confidence Score** | Nilai keyakinan model AI terhadap hasil prediksi (0.0–1.0) |
| **Transaction Inbox** | Antrian transaksi otomatis yang menunggu konfirmasi pengguna |
| **Duplicate Detection** | Proses mendeteksi transaksi yang kemungkinan tercatat lebih dari satu kali |
| **Rekonsiliasi** | Proses membandingkan saldo tercatat aplikasi dengan saldo aktual |
| **Merchant** | Toko/pihak penerima pembayaran |
| **Offline** | Fitur dapat digunakan tanpa koneksi internet |
| **SRS** | Software Requirements Specification |
| **MVP** | Minimum Viable Product |

### 1.7 Referensi

- Percakapan perancangan sistem NyatetPesse (Agustus 2026)
- Android NotificationListenerService Documentation
- TensorFlow Lite / LiteRT Documentation
- Flutter Documentation

---

## 2. Deskripsi Umum

### 2.1 Perspektif Produk

NyatetPesse adalah aplikasi **standalone** yang berjalan sepenuhnya di perangkat Android. Tidak ada ketergantungan pada server backend eksternal atau layanan cloud AI untuk fungsi inti. Semua data disimpan secara lokal menggunakan SQLite/Drift, dan semua inferensi AI dilakukan menggunakan model TFLite yang tertanam dalam aplikasi.

```
┌─────────────────────────────────────────────┐
│                  ANDROID                     │
│                                               │
│  ┌──────────────────────────────────────┐    │
│  │            Flutter UI                 │    │
│  └──────────────┬─────────────────────────┘   │
│                 │ MethodChannel               │
│  ┌──────────────▼─────────────────────────┐   │
│  │         Kotlin Native Layer            │   │
│  │   NotificationListenerService          │   │
│  └──────────────┬─────────────────────────┘   │
│                 │                             │
│  ┌──────────────▼─────────────────────────┐   │
│  │        Processing Engine               │   │
│  │   OCR + Parser + Rule Engine           │   │
│  └──────────────┬─────────────────────────┘   │
│                 │                             │
│  ┌──────────────▼─────────────────────────┐   │
│  │          Local AI Model                │   │
│  │           TFLite/LiteRT                │   │
│  └──────────────┬─────────────────────────┘   │
│                 │                             │
│  ┌──────────────▼─────────────────────────┐   │
│  │       SQLite / Drift Database          │   │
│  └──────────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

### 2.2 Fungsi Utama Produk

1. Mendeteksi dan mengekstrak transaksi otomatis dari notifikasi m-banking/e-wallet.
2. Mengekstrak transaksi dari foto struk fisik dan screenshot bukti pembayaran menggunakan OCR.
3. Mengklasifikasikan transaksi menggunakan Local AI Model secara offline.
4. Mengelola multiple akun/sumber dana dalam satu aplikasi.
5. Mendeteksi transaksi duplikat lintas sumber.
6. Menyediakan dashboard, statistik, dan laporan keuangan.
7. Mendukung perencanaan budget per kategori.
8. Mendukung rekonsiliasi saldo aplikasi vs saldo aktual.
9. Menjaga privasi data finansial pengguna sepenuhnya on-device.

### 2.3 Asumsi Umum

- Pengguna menggunakan perangkat Android minimal versi 8.0 (API Level 26).
- Pengguna memberikan izin Notification Listener kepada aplikasi.
- Pengguna memiliki setidaknya satu akun e-wallet atau m-banking.
- Aplikasi tidak memerlukan koneksi internet untuk fungsi inti.
- Penggunaan utama adalah transaksi dalam mata uang IDR.

---

## 3. Aktor Sistem

| Aktor | Peran |
|---|---|
| **Pengguna** | Mengatur akun, kategori, sumber notifikasi, transaksi, budget, keamanan, backup, serta mengoreksi hasil OCR/ML |
| **Android OS** | Menyediakan `NotificationListenerService`, camera/gallery, biometric authentication, secure storage, dan mekanisme permission |
| **OCR Engine** | Mengubah gambar (struk/screenshot) menjadi teks |
| **Local ML Model** | Membantu klasifikasi jenis transaksi, kategori, dan ekstraksi informasi tertentu |
| **Local Database** | Menyimpan data transaksi, akun, kategori, budget, konfigurasi, feedback, dan metadata |

---

## 4. Kebutuhan Fungsional

### 4.1 Manajemen Akun Dana

#### FR-01: Tambah Akun Dana
- Pengguna dapat menambahkan akun sumber dana baru.
- Tipe akun yang didukung: Bank, E-Wallet, Cash, Lainnya.
- Setiap akun memiliki: nama, tipe, warna identifikasi, ikon, dan saldo awal.
- Sistem menyediakan preset akun populer: BCA, BNI, BRI, Mandiri, DANA, OVO, GoPay, ShopeePay, LinkAja.

#### FR-02: Kelola Akun Dana
- Pengguna dapat mengedit nama, warna, dan saldo akun.
- Pengguna dapat menonaktifkan akun tanpa menghapus riwayat transaksi.
- Pengguna dapat menghapus akun (dengan konfirmasi dan peringatan dampak).
- Sistem menampilkan saldo terkini setiap akun secara real-time.

#### FR-03: Perhitungan Saldo
Saldo dihitung dengan formula:

```text
Saldo = saldo awal + pemasukan - pengeluaran + transfer masuk - transfer keluar
```

Transfer antar akun milik pengguna **tidak boleh** mengubah total aset secara keseluruhan.

#### FR-04: Rekonsiliasi Saldo
- Pengguna dapat memasukkan saldo aktual dari m-banking/e-wallet.
- Sistem membandingkan saldo tercatat dengan saldo aktual dan menampilkan selisih.
- Sistem mencatat selisih rekonsiliasi sebagai penyesuaian.

---

### 4.2 Manajemen Transaksi

#### FR-05: Tipe Transaksi

| Tipe | Deskripsi |
|---|---|
| `INCOME` | Pemasukan ke akun (gaji, transfer masuk, top-up) |
| `EXPENSE` | Pengeluaran dari akun (pembelian, tagihan, dll) |
| `TRANSFER` | Perpindahan dana antar akun milik pengguna |
| `TOP_UP` | Pengisian saldo e-wallet dari rekening bank |

> **Catatan:** Transaksi bertipe `TRANSFER`/`TOP_UP` harus mencatat akun asal dan akun tujuan, dan tidak dihitung sebagai pengeluaran biasa maupun pengeluaran ganda.

#### FR-06: Input Transaksi Manual
- Pengguna dapat menambahkan transaksi manual melalui form.
- Field yang tersedia: tipe, nominal, akun, kategori, merchant/keterangan, tanggal, waktu, catatan, lampiran.
- Sistem melakukan validasi input sebelum menyimpan.

#### FR-07: Kategori Transaksi
Sistem menyediakan kategori default (Pengeluaran: Makanan & Minuman, Transportasi, Belanja, Tagihan & Utilitas, Hiburan, Kesehatan, Pendidikan, Tempat Tinggal, Pakaian, Transfer Keluar, Lainnya; Pemasukan: Gaji, Transfer Masuk, Investasi, Hadiah, Lainnya). Pengguna dapat menambahkan kategori kustom.

#### FR-08: Edit & Hapus Transaksi
- Pengguna dapat mengedit semua field transaksi yang sudah tersimpan.
- Pengguna dapat menghapus transaksi dengan konfirmasi.
- Sistem mencatat log perubahan transaksi.

#### FR-09: Pencarian & Filter Transaksi
- Pencarian berdasarkan kata kunci (merchant, keterangan, nominal, kategori).
- Filter berdasarkan: tipe, kategori, akun, rentang tanggal, rentang nominal, source, status.
- Hasil ditampilkan secara real-time.

---

### 4.3 Notification Listener

#### FR-10: Konfigurasi Notification Listener
- Sistem meminta izin `NotificationListenerService` kepada pengguna.
- Pengguna dapat memilih aplikasi mana yang dipantau, kapan saja diaktifkan/dinonaktifkan.
- Aplikasi yang didukung secara default: DANA, OVO, GoPay, ShopeePay, LinkAja, BCA mobile, BNI mobile, BRImo, Mandiri Online, Jenius, SeaBank, Blu, Bank Jago.

#### FR-11: Identifikasi Sumber
Sistem mengidentifikasi aplikasi pengirim berdasarkan package name/metadata Android.

#### FR-12: Penyimpanan Raw Notification
Raw notification dapat disimpan secara terbatas untuk kebutuhan parsing/debugging. Data sensitif harus dapat dihapus otomatis sesuai kebijakan data minimization.

#### FR-13: Parsing Notifikasi
- Sistem mengekstrak informasi menggunakan kombinasi Regex + Rule Engine: nominal, tipe transaksi, merchant, penerima/pengirim, tanggal, waktu, source, reference ID.
- Notifikasi promosi, OTP, dan informasi non-transaksi diabaikan menggunakan pola teks.
- Hasil ekstraksi diteruskan ke Local AI Model untuk klasifikasi kategori.

#### FR-14: Failure Handling
Jika notifikasi tidak diterima (masalah jaringan, notifikasi dimatikan, pembatasan Android, perubahan format), aplikasi harus tetap menyediakan alternatif: input manual, foto struk, screenshot bukti pembayaran, import, rekonsiliasi. **Notification Listener tidak dianggap sebagai sumber kebenaran absolut.**

---

### 4.4 OCR & Pemrosesan Gambar

#### FR-15: Sumber Gambar
- Kamera perangkat, galeri, atau share intent dari aplikasi lain.
- Format yang didukung: JPG, PNG, WEBP.

#### FR-16: Preprocessing Gambar
Crop, rotate, resize, grayscale, peningkatan kontras, dan koreksi perspektif/rotasi sebelum OCR. Sistem memberikan panduan framing untuk foto struk yang baik.

#### FR-17: OCR Struk
- Sistem mengekstrak teks menggunakan engine on-device (mis. Google ML Kit).
- Field yang diekstrak: merchant, item, kuantitas, harga item, subtotal, pajak, diskon, total, tanggal, waktu, nomor transaksi.

#### FR-18: Total Validation
Jika item dapat diekstrak, sistem membandingkan total item dengan total struk dan memberi peringatan bila terdapat perbedaan.

#### FR-19: OCR Bukti Pembayaran/Screenshot
- Pengguna dapat memilih screenshot atau gambar bukti pembayaran.
- Sistem mengekstraksi: status pembayaran, nominal, tanggal, waktu, sumber, penerima/merchant, reference ID.
- Sistem mengenali format screenshot dari aplikasi populer (DANA, OVO, GoPay, dll) menggunakan template matching.

#### FR-20: Status Validation
Sistem membedakan minimal status: Berhasil, Pending, Gagal, Dibatalkan. **Transaksi gagal/dibatalkan tidak boleh otomatis menjadi transaksi final.**

---

### 4.5 Transaction Processing Engine

#### FR-21: Normalisasi Nominal
Variasi format (`Rp35.000`, `Rp 35.000`, `35.000`, dsb) dinormalisasi menjadi nilai numerik konsisten.

#### FR-22: Normalisasi Merchant
Variasi nama merchant dipetakan ke nama kanonik (mis. `TOKOPEDIA.COM`, `TOKOPEDIA`, `Tokopedia` → `Tokopedia`).

#### FR-23: Rule Engine
Digunakan untuk informasi deterministik: nominal, tanggal, waktu, package name, keyword, reference ID.

#### FR-24: Hybrid Processing (Rule + AI)
- Informasi deterministik diproses dengan Regex/Rule Engine.
- Informasi semantik (kategori, tipe transaksi, merchant intent) diproses dengan Local AI Model.
- Sistem tidak memaksakan AI memproses data yang sudah bisa ditentukan secara rule-based.

#### FR-25: Klasifikasi & Confidence Score
- Model menghasilkan output structured transaction (lihat Lampiran A) beserta confidence score (0.0–1.0).
- Threshold konfigurasi awal:

```text
Confidence ≥ 0.85        -> Inbox, kategori terisi, siap dikonfirmasi
Confidence 0.60 – 0.84    -> Inbox, tampilkan pilihan kategori alternatif
Confidence < 0.60         -> Inbox, wajib pilih kategori manual
```

Threshold harus dapat dievaluasi ulang berdasarkan hasil pengujian model.

#### FR-26: Learning dari Koreksi Pengguna
- Setiap koreksi kategori/field oleh pengguna disimpan sebagai data feedback (`correction_logs`).
- Data koreksi digunakan sebagai kandidat retraining di lingkungan pengembangan.
- **Feedback tidak boleh otomatis mengubah model production** tanpa proses training dan evaluasi ulang.

---

### 4.6 Transaction Inbox

#### FR-27: Antrian Transaksi
- Semua transaksi terdeteksi otomatis masuk ke **Transaction Inbox** sebelum disimpan final, khususnya jika confidence rendah atau data belum lengkap.
- Inbox menampilkan jumlah transaksi menunggu konfirmasi; notifikasi lokal dikirim saat ada item baru.

#### FR-28: Konfirmasi Transaksi
- Pengguna dapat mengonfirmasi (dengan/tanpa edit), mengedit, atau menolak/menghapus dari Inbox.
- Sistem mendukung konfirmasi massal ("Simpan Semua").

#### FR-29: Tampilan Inbox
Setiap item menampilkan: nama akun & ikon aplikasi sumber, nominal, merchant/keterangan, kategori hasil AI + confidence score, timestamp deteksi, sumber deteksi (Notifikasi/Foto Struk/Screenshot).

---

### 4.7 Duplicate Detection

#### FR-30: Deteksi Otomatis
Sistem membandingkan transaksi baru dengan transaksi sebelumnya berdasarkan kombinasi: akun, nominal, tanggal/waktu (toleransi ±5 menit), merchant, reference ID, source, tipe — dan menghitung similarity score.

#### FR-31: Penanganan Duplikat

```text
Similarity >= 90%   -> otomatis diblokir, tampilkan peringatan duplikat
Similarity 70-89%   -> tampilkan peringatan, minta konfirmasi pengguna
```

Pengguna dapat memilih **Abaikan (simpan keduanya)** atau **Tolak (hapus yang baru)**.

---

### 4.8 Transfer dan Top Up

#### FR-32: Transfer Antar Akun
Sistem mendukung perpindahan dana antar akun pengguna, misal:

```text
BCA -> DANA, Rp100.000
Saldo: BCA -100.000 | DANA +100.000
```

#### FR-33: Top Up
Top up e-wallet dari rekening bank dicatat sebagai transfer/top up, **bukan** expense biasa.

---

### 4.9 Dashboard

#### FR-34: Ringkasan Keuangan
Dashboard menampilkan: total aset, pemasukan periode berjalan, pengeluaran periode berjalan, saldo bersih, jumlah transaksi, ringkasan kategori, transaksi terbaru, budget, dan jumlah transaksi menunggu konfirmasi.

#### FR-35: Ringkasan Per Akun & Periode
- Daftar semua akun aktif beserta saldo dan indikator visual.
- Periode minimal: Hari ini, Minggu ini, Bulan ini, Custom range.

---

### 4.10 Statistik & Laporan

#### FR-36: Statistik Pengeluaran & Pemasukan
- Breakdown per kategori, akun, periode, dan merchant (pie/bar chart).
- Perbandingan antar periode (mis. bulan ini vs bulan lalu).
- Top merchant berdasarkan frekuensi dan nominal.

#### FR-37: Filter Periode
Minggu ini, Bulan ini, Bulan lalu, 3 bulan terakhir, Custom range.

#### FR-38: Grafik
Line chart, bar chart, dan pie/donut chart.

---

### 4.11 Budget

#### FR-39: Pengaturan Budget
- Budget per kategori per bulan, bersifat opsional, dapat diubah setiap bulan.

#### FR-40: Monitoring & Alert Budget
- Progress bar penggunaan budget per kategori.
- Notifikasi saat penggunaan mencapai threshold (mis. 75%, 90%, 100%).

```text
Makanan & Minuman
Rp 850.000 / Rp 1.000.000
[████████████████░░░░] 85%
Sisa: Rp 150.000
```

---

### 4.12 Recurring Transaction

#### FR-41: Deteksi & Manajemen Recurring
- Sistem dapat menganalisis riwayat untuk mendeteksi pola berulang (merchant, nominal, interval konsisten).
- Pengguna dapat mendaftarkan transaksi berulang manual: merchant, nominal, kategori, akun, interval (harian/mingguan/bulanan), tanggal mulai.
- Sistem memberikan pengingat saat tanggal recurring tiba.

---

### 4.13 Rekonsiliasi & Import

#### FR-42: Import Mutasi
Versi lanjutan dapat menyediakan import CSV/format data transaksi sebagai mekanisme rekonsiliasi. Data import harus melalui normalisasi dan duplicate detection.

---

### 4.14 Keamanan & Privasi

#### FR-43: Autentikasi Aplikasi
- Aplikasi dilindungi PIN 6 digit dan/atau biometrik (fingerprint/face unlock).
- Timeout auto-lock dapat diatur (1, 5, 15 menit, atau tidak pernah).

#### FR-44: Enkripsi & Penyimpanan
- Database dienkripsi (mis. SQLCipher) dengan kunci dikelola Android Keystore.
- Foto struk/screenshot disimpan di private app storage.
- Raw notification dan gambar dapat dihapus otomatis setelah ekstraksi (data minimization), sesuai pilihan pengguna.
- Data finansial, raw notification, struk, dan screenshot **tidak dikirim ke AI cloud secara default**.

#### FR-45: Manajemen Izin
- Aplikasi hanya meminta izin yang diperlukan, dijelaskan tujuannya kepada pengguna.
- Pengguna dapat mencabut izin Notification Listener kapan saja dari dalam aplikasi.

---

### 4.15 Backup & Export/Import

#### FR-46: Export Data
Ekspor transaksi ke CSV dan JSON, dapat difilter berdasarkan rentang tanggal dan akun.

#### FR-47: Backup Terenkripsi
- File backup terenkripsi, dapat disimpan ke Google Drive (opsional) atau penyimpanan lokal, dilindungi password.
- Pengguna dapat memulihkan (restore) data dari backup, dengan pencegahan restore tidak sengaja.

#### FR-48: Import Data
Mendukung import dari file backup NyatetPesse maupun file CSV dengan format yang ditentukan.

---

### 4.16 Pengaturan Aplikasi

#### FR-49: Pengaturan Umum
Mata uang (default IDR), bahasa (default Bahasa Indonesia), format tanggal, tema (Light/Dark/Sistem).

#### FR-50: Pengaturan Notifikasi & Sumber
- Toggle notifikasi budget, recurring transaction, dan Transaction Inbox.
- Daftar aplikasi yang dipantau Notification Listener, dapat diaktifkan/dinonaktifkan per aplikasi, dan menambahkan aplikasi kustom (package name).

---

## 5. Kebutuhan Non-Fungsional

### 5.1 Performa

| ID | Kebutuhan |
|---|---|
| NFR-01 | Inferensi Local AI Model selesai dalam < 500ms per transaksi |
| NFR-02 | OCR dan ekstraksi teks selesai dalam < 3 detik per gambar |
| NFR-03 | Parsing notifikasi selesai dalam < 200ms |
| NFR-04 | Cold start aplikasi < 3 detik |
| NFR-05 | Perpindahan antar halaman < 300ms |
| NFR-06 | Query database untuk daftar transaksi selesai < 500ms |
| NFR-07 | UI harus tetap responsif selama parsing, OCR, dan inference; proses berat tidak boleh memblokir UI thread |

### 5.2 Keandalan

| ID | Kebutuhan |
|---|---|
| NFR-08 | Notification Listener tidak menyebabkan crash saat aplikasi di-update/restart |
| NFR-09 | Semua operasi database menggunakan transaksi atomik untuk mencegah data corrupt |
| NFR-10 | Aplikasi menangani kondisi storage penuh dengan graceful error message |
| NFR-11 | Semua operasi berpotensi gagal memiliki fallback dan pesan error informatif |
| NFR-12 | Kegagalan Notification Listener bukan single point of failure — pencatatan manual/OCR tetap berfungsi |

### 5.3 Keamanan & Privasi

| ID | Kebutuhan |
|---|---|
| NFR-13 | Data finansial tidak pernah dikirim ke server eksternal manapun |
| NFR-14 | Foto struk tidak dapat diakses oleh aplikasi lain |
| NFR-15 | Database terenkripsi dan tidak dapat dibaca tanpa kunci |
| NFR-16 | Aplikasi terkunci otomatis sesuai setting auto-lock |
| NFR-17 | File backup terenkripsi sebelum dikirim ke penyimpanan eksternal |
| NFR-18 | Data keuangan tidak boleh dikirim ke pihak ketiga tanpa persetujuan eksplisit pengguna |

### 5.4 Usability & Accessibility

| ID | Kebutuhan |
|---|---|
| NFR-19 | Pengguna dapat menambahkan transaksi manual dalam ≤ 5 langkah |
| NFR-20 | Pengguna dapat mengonfirmasi transaksi dari Inbox dalam ≤ 2 ketukan |
| NFR-21 | Antarmuka menggunakan Bahasa Indonesia sebagai bahasa default |
| NFR-22 | Aplikasi mendukung dark mode dan light mode |
| NFR-23 | Ukuran font dan elemen UI dapat dibaca tanpa zoom di layar 5–6.5 inci |
| NFR-24 | UI memiliki kontras yang baik, label jelas, dan touch target yang memadai |

### 5.5 Kompatibilitas

| ID | Kebutuhan |
|---|---|
| NFR-25 | Mendukung Android 8.0 (API Level 26) ke atas |
| NFR-26 | Dioptimalkan untuk perangkat dengan RAM 2 GB ke atas |
| NFR-27 | Ukuran APK tidak melebihi 80 MB (termasuk model AI) |
| NFR-28 | Model TFLite kompatibel dengan CPU inference (tanpa GPU khusus) |

### 5.6 Maintainability & Extensibility

| ID | Kebutuhan |
|---|---|
| NFR-29 | Kode mengikuti arsitektur Clean Architecture / MVVM |
| NFR-30 | Setiap modul (Notification, OCR, AI, Database, Security) terpisah dan dapat diuji independen |
| NFR-31 | Model AI dapat diperbarui tanpa merilis ulang seluruh aplikasi |
| NFR-32 | Parser untuk sumber/aplikasi baru dapat ditambahkan tanpa mengubah seluruh sistem (source agnostic) |

---

## 6. Arsitektur Sistem

### 6.1 Arsitektur Konseptual

```text
                    SUMBER TRANSAKSI
                           |
        +------------------+------------------+
        |                  |                  |
        v                  v                  v
 Notification          Foto Struk       Bukti Pembayaran
   Listener                              / Screenshot
        |                  |                  |
        |                  v                  v
        |                 OCR                OCR
        |                  |                  |
        +------------------+------------------+
                           |
                           v
                 Transaction Processing
                           |
                 +---------+---------+
                 |                   |
                 v                   v
             Rule Engine        Local ML Model
                 |                   |
                 +---------+---------+
                           v
                 Structured Transaction
                           |
                    Duplicate Detection
                           |
                    Validation Layer
                           |
                 +---------+---------+
                 |                   |
              High Score          Low Score
                 |                   |
             Auto Save         User Confirmation
                 |                   |
                 +---------+---------+
                           v
                      Local Database
                           |
          +----------------+----------------+
          |                |                |
          v                v                v
      Dashboard        Statistics      Reconciliation
```

### 6.2 Prinsip Arsitektur

1. **Local-first:** data utama berada di perangkat.
2. **Privacy-first:** transaksi dan gambar tidak dikirim ke AI cloud secara default.
3. **Hybrid processing:** rule-based dan ML digunakan bersama.
4. **Human-in-the-loop:** pengguna dapat mengoreksi hasil otomatis.
5. **Offline capable:** fungsi utama tetap dapat berjalan tanpa internet.
6. **Source agnostic:** sumber transaksi dapat ditambah tanpa mengubah keseluruhan sistem.
7. **Fail-safe:** kegagalan Notification Listener tidak menghilangkan kemampuan pencatatan manual/bukti transaksi.

### 6.3 Stack Teknologi

| Layer | Teknologi |
|---|---|
| **UI** | Flutter, Dart |
| **State Management** | Riverpod / BLoC |
| **Native Android** | Kotlin, `NotificationListenerService` |
| **Bridge Flutter-Native** | MethodChannel / EventChannel |
| **OCR** | Google ML Kit Text Recognition (on-device) |
| **Local AI** | TensorFlow Lite / LiteRT |
| **Training** | Python, scikit-learn (baseline) |
| **Database** | SQLite via Drift (Dart ORM) |
| **Enkripsi DB** | SQLCipher |
| **Keamanan** | Android Keystore, BiometricPrompt API |
| **Gambar** | camera, image_picker (Flutter packages) |
| **Grafik** | fl_chart / syncfusion_flutter_charts |
| **Backup** | Google Drive API (opsional) |
| **Backend** | Tidak wajib untuk MVP |
| **Cloud AI** | Tidak wajib |

### 6.4 Arsitektur Layer Aplikasi

```
┌─────────────────────────────────────────┐
│          Presentation Layer              │
│   Flutter Widgets, Screens, ViewModels   │
├─────────────────────────────────────────┤
│           Domain Layer                   │
│   Use Cases, Entities, Repositories      │
├─────────────────────────────────────────┤
│            Data Layer                    │
│   Local DB, ML Model, OCR, Parser        │
├─────────────────────────────────────────┤
│          Infrastructure Layer            │
│   Android Native, Keystore, FileSystem   │
└─────────────────────────────────────────┘
```

### 6.5 Arsitektur Local AI Model (Hybrid)

```
INPUT TEXT
(Teks notifikasi / hasil OCR)
         │
         ↓
┌─────────────────┐     ┌───────────────────┐
│   Rule Engine    │     │   AI Classifier   │
│   (Regex)        │     │   (TFLite)        │
│                   │     │                   │
│ - Nominal         │     │ - Kategori        │
│ - Tanggal         │     │ - Tipe Transaksi  │
│ - Waktu           │     │ - Merchant Intent │
│ - Nama Akun       │     │ - Confidence      │
└────────┬──────────┘     └────────┬──────────┘
         │                         │
         └───────────┬─────────────┘
                     ↓
           Structured Transaction
```

### 6.6 Struktur Proyek

```text
lib/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── security/
│   └── utils/
├── features/
│   ├── dashboard/
│   ├── transactions/
│   ├── accounts/
│   ├── categories/
│   ├── budget/
│   ├── statistics/
│   ├── scanner/
│   ├── inbox/
│   ├── reconciliation/
│   └── settings/
├── data/
│   ├── database/
│   ├── repositories/
│   └── models/
├── domain/
│   ├── entities/
│   └── usecases/
├── ml/
│   ├── model/
│   ├── preprocessing/
│   └── inference/
├── ocr/
│   ├── services/
│   └── parsers/
└── notification/
    └── services/

android/
└── app/src/main/kotlin/notification/
    └── TransactionNotificationListener.kt
```

Komunikasi Android native ke Flutter menggunakan MethodChannel/EventChannel.

---

## 7. Model Data

### 7.1 Entity Relationship (Deskriptif)

```
USERS
ACCOUNTS ──< TRANSACTIONS >── CATEGORIES
    │                │
    │           INBOX_ITEMS (dari NOTIFICATIONS)
    │
BUDGET_SETTINGS ──< CATEGORIES
RECURRING_TRANSACTIONS
RECONCILIATIONS ──< ACCOUNTS
TRANSACTIONS >── TRANSACTION_IMAGES / TRANSACTION_ITEMS
TRANSACTIONS >── CORRECTION_LOGS (feedback ML)
```

### 7.2 Tabel Database

#### `users`

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | INTEGER PK | ID pengguna |
| `name` | TEXT | Nama pengguna |
| `currency` | TEXT | Mata uang utama (default IDR) |
| `created_at` | DATETIME | Waktu dibuat |

#### `accounts`

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | INTEGER PK | ID unik akun |
| `name` | TEXT NOT NULL | Nama akun (mis. BCA, DANA) |
| `type` | TEXT NOT NULL | `bank`, `ewallet`, `cash`, `other` |
| `color` | TEXT | Warna hex identifikasi UI |
| `icon` | TEXT | Nama ikon/asset |
| `initial_balance` | REAL | Saldo awal |
| `current_balance` | REAL | Saldo terkini (dihitung dari transaksi) |
| `is_active` | INTEGER | 1 = aktif |
| `created_at` / `updated_at` | TEXT | Timestamp |

#### `categories`

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | INTEGER PK | ID kategori |
| `name` | TEXT NOT NULL | Nama kategori |
| `type` | TEXT NOT NULL | `income` / `expense` |
| `icon` | TEXT | Emoji/ikon |
| `color` | TEXT | Warna hex |
| `is_custom` | INTEGER | 1 = buatan pengguna |
| `is_active` | INTEGER | 1 = aktif |
| `created_at` | TEXT | Timestamp |

#### `transactions`

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | INTEGER PK | ID transaksi |
| `type` | TEXT NOT NULL | `income`, `expense`, `transfer`, `top_up` |
| `amount` | REAL/INTEGER NOT NULL | Nominal (unit terkecil mata uang) |
| `account_id` | INTEGER FK | Akun sumber → `accounts.id` |
| `destination_account_id` | INTEGER FK NULL | Untuk `transfer`: akun tujuan |
| `category_id` | INTEGER FK | → `categories.id` |
| `merchant` | TEXT | Nama merchant/pihak terkait |
| `description` / `note` | TEXT | Deskripsi/catatan |
| `transaction_date` | TEXT/DATETIME NOT NULL | Tanggal (ISO 8601) |
| `transaction_time` | TEXT | Waktu |
| `source` | TEXT | `manual`, `notification`, `ocr_receipt`, `ocr_screenshot`, `import` |
| `source_app` | TEXT NULL | Nama aplikasi sumber (jika notifikasi) |
| `status` | TEXT | `pending`, `confirmed`, `rejected` |
| `confidence_score` | REAL NULL | Confidence AI (0.0–1.0) |
| `reference_id` | TEXT NULL | ID transaksi dari sumber |
| `is_confirmed` | INTEGER | 1 = sudah dikonfirmasi |
| `is_recurring` | INTEGER | 1 = bagian recurring |
| `recurring_id` | INTEGER FK NULL | → `recurring_transactions.id` |
| `created_at` / `updated_at` | TEXT | Timestamp |

#### `transaction_items`

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | INTEGER PK | ID item |
| `transaction_id` | INTEGER FK | → `transactions.id` |
| `name` | TEXT | Nama item |
| `quantity` | REAL | Kuantitas |
| `price` | REAL/INTEGER | Harga satuan |
| `subtotal` | REAL/INTEGER | Subtotal |

#### `inbox_items`

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | INTEGER PK | ID item inbox |
| `raw_text` | TEXT | Teks mentah notifikasi/OCR |
| `source` | TEXT | `notification`, `ocr_receipt`, `ocr_screenshot` |
| `source_app` | TEXT NULL | Aplikasi sumber |
| `extracted_data` | TEXT | JSON hasil ekstraksi AI |
| `confidence_score` | REAL | Confidence AI |
| `status` | TEXT | `pending`, `confirmed`, `rejected`, `duplicate` |
| `duplicate_of` | INTEGER FK NULL | → `transactions.id` jika duplikat |
| `detected_at` / `processed_at` | TEXT | Timestamp |

#### `notifications` (raw log, retensi terbatas)

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | INTEGER PK | ID |
| `package_name` | TEXT | Package pengirim |
| `title` / `body` | TEXT | Konten notifikasi |
| `received_at` | DATETIME | Waktu diterima |
| `parsed` | BOOLEAN | Status parsing |
| `transaction_id` | INTEGER NULL | Referensi jika berhasil diproses |

#### `transaction_images` / `attachments`

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | INTEGER PK | ID gambar |
| `transaction_id` | INTEGER FK | → `transactions.id` |
| `file_path` | TEXT NOT NULL | Path di private storage |
| `image_type` | TEXT | `receipt`, `screenshot` |
| `created_at` | TEXT | Timestamp |

#### `budget_settings`

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | INTEGER PK | ID budget |
| `category_id` | INTEGER FK | → `categories.id` |
| `amount` | REAL NOT NULL | Nominal budget |
| `period` | TEXT | `monthly` |
| `month` / `year` | INTEGER | Periode |
| `created_at` / `updated_at` | TEXT | Timestamp |

#### `recurring_transactions`

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | INTEGER PK | ID |
| `type` | TEXT NOT NULL | `income` / `expense` |
| `amount` | REAL NOT NULL | Nominal |
| `account_id` / `category_id` | INTEGER FK | Referensi |
| `merchant` / `note` | TEXT | Detail |
| `interval` | TEXT | `daily`, `weekly`, `monthly` |
| `next_date` | TEXT | Jatuh tempo berikutnya |
| `is_active` | INTEGER | Status |
| `created_at` | TEXT | Timestamp |

#### `notification_sources`

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | INTEGER PK | ID |
| `app_name` / `package_name` | TEXT NOT NULL | Identitas aplikasi |
| `is_enabled` | INTEGER | 1 = dipantau |
| `is_preset` | INTEGER | 1 = preset bawaan |
| `added_at` | TEXT | Timestamp |

#### `reconciliations`

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | INTEGER PK | ID |
| `account_id` | INTEGER FK | Akun direkonsiliasi |
| `recorded_balance` / `actual_balance` | REAL | Saldo aplikasi vs aktual |
| `difference` | REAL | Selisih |
| `note` | TEXT NULL | Catatan |
| `reconciled_at` | TEXT | Timestamp |

#### `correction_logs` / `ml_feedback`

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | INTEGER PK | ID |
| `transaction_id` / `input_text` | TEXT/INTEGER | Referensi transaksi/teks input |
| `field_corrected` | TEXT | Field yang dikoreksi |
| `predicted_label` / `original_value` | TEXT | Nilai asli dari AI |
| `corrected_label` / `corrected_value` | TEXT | Nilai koreksi pengguna |
| `original_confidence` | REAL | Confidence asli |
| `model_version` | TEXT | Versi model saat prediksi |
| `corrected_at` / `created_at` | TEXT | Timestamp |

### 7.3 Contoh Transaction Object (Structured Output)

```json
{
  "source": "DANA",
  "type": "expense",
  "amount": 35000,
  "currency": "IDR",
  "account": "DANA",
  "merchant": "KOPI SENJA",
  "category": "food_drink",
  "date": "2026-08-12",
  "time": "09:30",
  "confidence": 0.96,
  "raw_text": "Pembayaran ke KOPI SENJA berhasil Rp35.000",
  "detection_source": "notification"
}
```

Data hasil OCR/parser/notifikasi harus dinormalisasi ke struktur yang konsisten sebelum disimpan.

---

## 8. Use Case Utama

### UC-001 Otomatis Mencatat Transaksi
**Precondition:** Notification Access telah diberikan dan sumber dipilih.

1. Transaksi terjadi pada bank/e-wallet.
2. Aplikasi sumber mengirim notifikasi.
3. Notification Listener menerima notifikasi.
4. Sistem mengidentifikasi sumber (package name).
5. Parser mengekstrak informasi.
6. Rule engine menormalisasi data.
7. ML melakukan klasifikasi kategori & tipe.
8. Confidence score dihitung.
9. Duplicate detection dijalankan.
10. Transaksi disimpan otomatis atau masuk Inbox sesuai threshold confidence.
11. Pengguna dapat mengonfirmasi/mengedit dari Inbox.

**Postcondition:** Transaksi tercatat di database atau menunggu di Inbox.

### UC-002 Scan Struk
1. Pengguna memilih **Scan Struk**.
2. Kamera/gallery dibuka, gambar dipilih.
3. Image preprocessing dilakukan.
4. OCR dijalankan.
5. Parser mengekstrak merchant, item, total, dan tanggal.
6. ML menentukan kategori.
7. Hasil ditampilkan untuk direview.
8. Pengguna mengedit bila perlu, lalu menyimpan.

### UC-003 Scan Bukti Pembayaran
1. Pengguna memilih **Scan Bukti**.
2. Gambar dipilih, OCR dijalankan.
3. Status, nominal, penerima, tanggal, dan reference ID diekstrak.
4. Duplicate detection dijalankan.
5. Hasil ditampilkan, pengguna mengonfirmasi, transaksi disimpan.

### UC-004 Input Manual
1. Pengguna memilih **Tambah Transaksi**.
2. Memilih tipe transaksi, memasukkan nominal.
3. Memilih akun & kategori.
4. Mengisi detail opsional (merchant, catatan, lampiran).
5. Menyimpan.

### UC-005 Rekonsiliasi
1. Pengguna memilih akun.
2. Sistem menampilkan saldo aplikasi.
3. Pengguna memasukkan saldo aktual.
4. Sistem menghitung selisih.
5. Pengguna mencari transaksi yang hilang/salah dan melakukan koreksi.

---

## 9. Kebutuhan Antarmuka

### 9.1 Navigasi Utama

```text
Dashboard
Transactions
Scan
Budget
Statistics
Settings
```

Tombol Quick Add menyediakan: Tambah manual, Scan struk, Scan bukti pembayaran.

### 9.2 Halaman-Halaman Utama

**Dashboard** — total aset, pemasukan/pengeluaran bulan berjalan, daftar akun & saldo, shortcut ke Tambah Transaksi & Inbox, transaksi terbaru.

**Transaction Inbox** — badge jumlah pending, kartu transaksi (sumber, nominal, kategori AI, confidence), aksi ✓ Konfirmasi / ✏️ Edit / 🗑 Tolak, konfirmasi massal.

**Transactions** — daftar transaksi dengan filter & search, dikelompokkan per tanggal.

**Tambah/Edit Transaksi** — form dengan validasi real-time, pilihan akun (saldo terkini), pilihan kategori berikon, date/time picker, opsi lampirkan gambar struk.

**Statistics** — selector periode, pie chart per kategori, bar chart harian, perbandingan bulan lalu vs bulan ini.

**Budget** — daftar kategori berbudget, progress bar, tombol tambah budget.

**Accounts** — daftar akun & saldo, total aset keseluruhan, shortcut rekonsiliasi per akun.

**Settings** — umum (tema, bahasa, mata uang), keamanan (PIN, biometrik), pengaturan Notification Listener, backup & export, tentang aplikasi.

### 9.3 Detail Transaksi

Menampilkan: nominal, tipe, akun, kategori, merchant, tanggal/waktu, source, confidence (jika ada), attachment, reference ID, catatan.

### 9.4 Antarmuka Hardware

| Komponen | Kegunaan |
|---|---|
| Kamera | Mengambil foto struk fisik |
| Sensor Biometrik | Autentikasi fingerprint/face |
| Notifikasi Sistem Android | Menerima notifikasi dari m-banking/e-wallet |
| Penyimpanan Internal | Menyimpan database dan foto struk |

### 9.5 Antarmuka Software

| Komponen | Deskripsi |
|---|---|
| Android NotificationListenerService | API Android untuk menangkap notifikasi |
| Google ML Kit Text Recognition | Library OCR on-device |
| TensorFlow Lite / LiteRT | Runtime inferensi model AI |
| Android Keystore | Penyimpanan kunci enkripsi |
| BiometricPrompt API | Autentikasi biometrik |
| Google Drive API (opsional) | Backup terenkripsi ke cloud |

---

## 10. Error Handling

| ID | Kondisi | Penanganan |
|---|---|---|
| EH-001 | OCR gagal | Tampilkan pesan agar pengguna mengambil ulang gambar dengan pencahayaan/fokus/sudut lebih baik |
| EH-002 | Nominal tidak ditemukan | Pengguna diminta memasukkan nominal manual |
| EH-003 | Kategori tidak yakin (confidence rendah) | Pengguna diminta memilih kategori |
| EH-004 | Format notifikasi berubah | Parser gagal secara aman (fail-safe), fallback ke review/manual |
| EH-005 | Kemungkinan duplikat | Sistem memberi peringatan sebelum penyimpanan final |
| EH-006 | Model ML gagal dimuat | Aplikasi tetap menyediakan input manual dan rule-based parsing |
| EH-007 | Database error | Tangani tanpa merusak data tersimpan; tampilkan pesan yang dapat dipahami pengguna |

---

## 11. Permission Requirements

Aplikasi hanya meminta permission saat benar-benar diperlukan:

- **Notification Access** — dijelaskan transparan karena service dapat membaca notifikasi perangkat.
- **Camera** — untuk memindai struk/bukti pembayaran.
- **Photos/Media** — sesuai versi Android, untuk memilih gambar dari galeri.
- **Biometric** — untuk app lock.
- **Storage/Backup** — jika dibutuhkan oleh mekanisme implementasi backup.

---

## 12. Security Threats dan Mitigasi

| Ancaman | Mitigasi |
|---|---|
| Akses database tidak sah | Enkripsi database + app lock |
| Kebocoran foto struk/bukti | Private storage + enkripsi |
| Raw notification tersimpan terlalu lama | Data minimization / auto-delete |
| Backup bocor | Backup terenkripsi dengan password |
| Aplikasi diakses orang lain | PIN / biometrik + auto-lock |
| Cloud AI menerima data sensitif | Local AI sebagai default, tanpa pengiriman data ke cloud |
| Model ML gagal/salah | Fallback ke rule-based/manual, model bukan single point of failure |
| Notification Listener gagal | Fallback: screenshot, manual, import, rekonsiliasi |

---

## 13. Machine Learning Specification

### 13.1 Tujuan Model
Model awal difokuskan pada **klasifikasi ringan** (bukan LLM), dengan target utama: transaction type dan transaction category.

### 13.2 Dataset
Dataset terdiri dari teks transaksi berlabel, contoh:

```text
bayar nasi goreng       -> food
pembayaran kopi         -> food
isi bensin              -> transport
belanja tokopedia       -> shopping
bayar listrik           -> bills
menerima transfer       -> income
```

### 13.3 Baseline Model
Model baseline yang direkomendasikan: TF-IDF + Logistic Regression, TF-IDF + Naive Bayes, atau Linear SVM. Model neural network kecil dapat dipertimbangkan jika baseline tidak mencukupi.

### 13.4 Dataset Split

```text
Training   : 70-80%
Validation : 10-15%
Testing    : 10-15%
```

Pembagian final disesuaikan dengan jumlah dan kualitas dataset nyata.

### 13.5 Evaluasi
Metrik: Accuracy, Precision, Recall, F1-score, Confusion matrix. Accuracy tidak boleh menjadi satu-satunya metrik, terutama jika kelas tidak seimbang. Target awal pengembangan: F1/accuracy sekitar 90% untuk kelas utama; target final ditentukan setelah dataset nyata tersedia.

### 13.6 Deployment & Inference
Model dikonversi ke format TFLite/LiteRT dan harus dapat melakukan inference on-device, tanpa internet, tanpa API AI eksternal.

### 13.7 Model Versioning
Setiap model diberi versi dan metadata (tanggal training, dataset version, metrik evaluasi), contoh: `transaction_model_1.0.0`.

### 13.8 Feedback Loop
Koreksi pengguna disimpan sebagai data feedback (`correction_logs`/`ml_feedback`) dan dapat digunakan untuk retraining berkala di lingkungan pengembangan — bukan retraining otomatis di perangkat.

### 13.9 Confidence Score Decision Tree

```
Hasil Klasifikasi AI
        │
   Confidence?
        │
   ┌────┴─────┐
  ≥85%       <85%
   │           │
  Inbox    60%–84%
  (siap     │
  konfirmasi) Inbox
             (tampilkan
             pilihan kategori)
                 │
               <60%
                 │
             Inbox
             (wajib pilih
             kategori manual)
```

### 13.10 Contoh Skenario Duplicate Detection

```
Transaksi 1 (dari Notifikasi):
  source: notification | amount: 35000 | account: DANA
  date: 2026-08-12 | time: 09:30 | merchant: KOPI SENJA

Transaksi 2 (dari Screenshot):
  source: ocr_screenshot | amount: 35000 | account: DANA
  date: 2026-08-12 | time: 09:31 | merchant: KOPI SENJA

Similarity Score: 95%
-> BLOKIR: Kemungkinan duplikat terdeteksi
-> Tampilkan peringatan ke pengguna
```

---

## 14. Testing Requirements

### 14.1 Unit Test
Parser nominal, parser tanggal, parser merchant, balance calculation, duplicate detection, budget calculation, model wrapper.

### 14.2 Integration Test
Notification → parser → database; Image → OCR → parser → ML → database; Manual → database; Transfer → dua akun; Backup → restore.

### 14.3 ML Test
Accuracy, precision, recall, F1, confusion matrix, inference latency, model size.

### 14.4 UI Test
Dashboard, tambah transaksi, scan, inbox, edit transaksi, budget, dan settings.

### 14.5 Security Test
App lock, database access, attachment exposure, backup encryption, permission handling.

---

## 15. Acceptance Criteria MVP

MVP dianggap berhasil apabila:

1. Pengguna dapat membuat akun (FR-01).
2. Pengguna dapat membuat kategori (FR-07).
3. Pengguna dapat memasukkan transaksi manual (FR-06).
4. Notification Listener dapat menerima notifikasi dari sumber yang diizinkan (FR-10).
5. Parser dapat mengekstrak nominal dari format yang didukung (FR-21).
6. Foto struk dapat diproses OCR (FR-17).
7. Screenshot bukti pembayaran dapat diproses OCR (FR-19).
8. Local ML model dapat melakukan klasifikasi dasar (FR-25).
9. Sistem menghasilkan confidence score/status keyakinan (FR-25).
10. Pengguna dapat mengoreksi hasil otomatis (FR-26, FR-28).
11. Sistem dapat mendeteksi kemungkinan duplikasi (FR-30, FR-31).
12. Transfer antar akun tidak dihitung sebagai pengeluaran ganda (FR-32).
13. Dashboard menampilkan saldo dan ringkasan transaksi (FR-34).
14. Fitur utama tetap dapat digunakan tanpa internet (NFR-03, NFR-25).
15. Aplikasi memiliki mekanisme app lock (FR-43).
16. Data transaksi tidak dikirim ke AI cloud secara default (FR-44, NFR-13).
17. Aplikasi tetap dapat mencatat transaksi jika Notification Listener gagal (FR-14, NFR-12).
18. Data dapat diekspor/backup pada versi yang menyediakan fitur tersebut (FR-46, FR-47).

---

## 16. Batasan & Asumsi

### 16.1 Batasan Sistem

| ID | Batasan |
|---|---|
| CON-01 | Aplikasi hanya tersedia untuk platform Android (iOS tidak didukung) |
| CON-02 | Tidak semua bank/e-wallet menyediakan notifikasi dengan format yang sama |
| CON-03 | Format notifikasi dapat berubah setelah update aplikasi sumber |
| CON-04 | Notification Listener hanya dapat memproses notifikasi yang benar-benar diterima Android, bukan mengakses data internal aplikasi m-banking |
| CON-05 | Akurasi OCR bergantung pada kualitas gambar (pencahayaan, kejelasan, sudut) |
| CON-06 | Model ML tidak selalu menghasilkan prediksi benar dan tidak diperbarui otomatis; pembaruan model memerlukan update aplikasi |
| CON-07 | Akses mutasi bank otomatis membutuhkan API/integrasi resmi apabila ingin benar-benar otomatis |
| CON-08 | Saldo aktual bank tidak dapat dianggap tersedia tanpa sumber data resmi; rekonsiliasi bersifat manual |
| CON-09 | Deteksi duplikat tidak 100% sempurna, terutama untuk transaksi bernominal sama di waktu berdekatan |
| CON-10 | Model tidak boleh menjadi satu-satunya sumber keputusan untuk data kritis |
| CON-11 | Fitur backup ke Google Drive memerlukan koneksi internet dan akun Google |

### 16.2 Asumsi

| ID | Asumsi |
|---|---|
| ASS-01 | Pengguna memberikan izin Notification Listener kepada aplikasi |
| ASS-02 | Format notifikasi dari m-banking/e-wallet populer tidak berubah secara signifikan |
| ASS-03 | Perangkat memiliki cukup storage untuk database dan foto struk |
| ASS-04 | Pengguna memahami bahwa akurasi AI tidak selalu 100% dan perlu dikonfirmasi |
| ASS-05 | Penggunaan utama adalah transaksi dalam mata uang IDR |

---

## 17. Risiko dan Mitigasi

| Risiko | Dampak | Mitigasi |
|---|---|---|
| Notifikasi tidak masuk | Tinggi | Manual, screenshot, import, rekonsiliasi |
| Format notifikasi berubah | Tinggi | Parser modular + fallback |
| OCR salah | Sedang | Preview + edit + validation |
| Model salah kategori | Sedang | Confidence + user confirmation |
| Transaksi duplikat | Sedang | Duplicate detection |
| Database rusak | Tinggi | Backup |
| HP hilang/rusak | Tinggi | Encrypted backup/export |
| Data sensitif bocor | Sangat tinggi | Local-first + encryption |
| Model terlalu besar | Sedang | Model ringan |
| Inference lambat | Sedang | Optimasi model |
| Parser terlalu spesifik | Sedang | Normalization + generic fallback |

---

## 18. Prinsip Desain Final

1. Automation first, but not automation only.
2. Local first.
3. Privacy first.
4. AI assists, user controls.
5. Rule-based untuk data deterministik.
6. ML untuk klasifikasi dan pola.
7. Tidak bergantung pada satu sumber transaksi.
8. Semua transaksi otomatis dapat dikoreksi.
9. Notification Listener bukan sumber kebenaran absolut.
10. Model ML bukan single point of failure.

---

## 19. Prioritas Pengembangan

### Phase 1 — Database & UI Dasar (MVP Foundation)
> Target: Aplikasi dapat digunakan untuk input manual dan melihat ringkasan keuangan.

| ID | Fitur |
|---|---|
| P1-01 | Setup project Flutter + Kotlin |
| P1-02 | Skema database (Drift/SQLite) |
| P1-03 | Manajemen akun dana (FR-01, FR-02) |
| P1-04 | Manajemen kategori (FR-07) |
| P1-05 | Input transaksi manual (FR-06) |
| P1-06 | Riwayat transaksi + filter (FR-09) |
| P1-07 | Dashboard ringkasan (FR-34, FR-35) |
| P1-08 | Autentikasi PIN (FR-43) |

### Phase 2 — Otomatisasi Notifikasi
> Target: Transaksi dari m-banking/e-wallet terdeteksi otomatis.

| ID | Fitur |
|---|---|
| P2-01 | NotificationListenerService (FR-10, FR-11, FR-13) |
| P2-02 | Parser regex untuk notifikasi populer |
| P2-03 | Duplicate detection (FR-30, FR-31) |
| P2-04 | Transaction Inbox (FR-27, FR-28, FR-29) |
| P2-05 | Pengaturan sumber notifikasi (FR-50) |
| P2-06 | Failure handling & fallback (FR-14) |

### Phase 3 — OCR & Pemrosesan Gambar
> Target: Transaksi dari foto struk dan screenshot dapat diekstrak otomatis.

| ID | Fitur |
|---|---|
| P3-01 | Integrasi Google ML Kit OCR |
| P3-02 | Parser struk fisik (FR-17, FR-18) |
| P3-03 | Parser screenshot bukti pembayaran (FR-19, FR-20) |
| P3-04 | Lampiran gambar pada transaksi (FR-15, FR-16) |

### Phase 4 — Local AI Model
> Target: Transaksi diklasifikasikan otomatis menggunakan model lokal.

| ID | Fitur |
|---|---|
| P4-01 | Pengumpulan dan labeling dataset |
| P4-02 | Training dan evaluasi model klasifikasi baseline |
| P4-03 | Export model ke format TFLite |
| P4-04 | Integrasi TFLite ke Flutter |
| P4-05 | Confidence score & threshold (FR-25) |
| P4-06 | Offline inference end-to-end |

### Phase 5 — Privacy & Security
> Target: Data pengguna terlindungi sesuai prinsip privacy-first.

| ID | Fitur |
|---|---|
| P5-01 | App lock (PIN + biometrik) (FR-43) |
| P5-02 | Android Keystore integration |
| P5-03 | Database encryption (FR-44) |
| P5-04 | Private image storage (FR-44) |
| P5-05 | Encrypted backup (FR-47) |

### Phase 6 — Financial Management & Intelligence
> Target: Aplikasi menjadi alat manajemen keuangan lengkap.

| ID | Fitur |
|---|---|
| P6-01 | Budget per kategori (FR-39, FR-40) |
| P6-02 | Statistik & laporan lengkap (FR-36, FR-37, FR-38) |
| P6-03 | Rekonsiliasi saldo (FR-04) |
| P6-04 | Recurring transaction (FR-41) |
| P6-05 | Export/Import CSV & JSON (FR-46, FR-48) |
| P6-06 | Learning dari koreksi pengguna (FR-26) |
| P6-07 | Dark mode & personalisasi (FR-49) |

---

## 20. Rekomendasi Teknologi

| Komponen | Teknologi |
|---|---|
| Mobile UI | Flutter |
| Bahasa | Dart |
| Android Native | Kotlin |
| Notification | Android NotificationListenerService |
| Flutter-Native Bridge | MethodChannel/EventChannel |
| Database | SQLite / Drift |
| OCR | Google ML Kit (on-device) |
| Training | Python |
| ML Baseline | scikit-learn |
| Mobile ML | TFLite / LiteRT |
| Security | Android Keystore + Biometric |
| Attachment | Private app storage |
| Chart | fl_chart / syncfusion_flutter_charts |
| Backend | Tidak wajib untuk MVP |
| Cloud AI | Tidak wajib |

---

## 21. Ringkasan Produk

**NyatetPesse** adalah sistem manajemen keuangan pribadi berbasis Android menggunakan Flutter yang menggabungkan transaksi dari notification listener m-banking/e-wallet, foto struk, screenshot bukti pembayaran, import data, dan input manual.

Sistem menggunakan kombinasi OCR, rule-based parser, dan Local Machine Learning untuk mengubah berbagai bentuk data menjadi transaksi terstruktur. Model ML membantu klasifikasi jenis transaksi dan kategori serta menghasilkan confidence score.

Data utama disimpan secara lokal dan pemrosesan AI dirancang berjalan offline, sehingga informasi finansial dan dokumen transaksi tidak perlu dikirim ke layanan AI pihak ketiga.

Fitur tambahan seperti transaction inbox, duplicate detection, transfer antar akun, dashboard, statistik, budget, rekonsiliasi, backup, dan keamanan membuat aplikasi berfungsi sebagai *personal finance management system* yang lengkap — bukan sekadar aplikasi pencatat pengeluaran.

---

*Dokumen ini merupakan living document dan dapat diperbarui seiring perkembangan proyek NyatetPesse.*
