<div align="center">

# 💰 NyatetPesse

**Aplikasi manajemen keuangan pribadi untuk Android — mencatat transaksi secara otomatis, 100% offline, dan privasi-first.**

[![Platform](https://img.shields.io/badge/platform-Android-3DDC84?logo=android&logoColor=white)](#)
[![Framework](https://img.shields.io/badge/framework-Flutter-02569B?logo=flutter&logoColor=white)](#)
[![Language](https://img.shields.io/badge/language-Dart%20%2B%20Kotlin-informational)](#)
[![License](https://img.shields.io/badge/license-TBD-lightgrey)](#)
[![Status](https://img.shields.io/badge/status-in%20development-yellow)](#)

</div>

---

## 📖 Tentang NyatetPesse

Punya banyak rekening bank, e-wallet, dan uang tunai bikin pencatatan keuangan manual jadi merepotkan dan gampang kelewat. **NyatetPesse** menyatukan semua transaksimu dalam satu ledger, dengan pencatatan yang **sebagian besar otomatis** — tanpa mengorbankan privasi data finansialmu.

NyatetPesse menangkap transaksi dari tiga sumber utama:

- 🔔 **Notification Listener** — membaca notifikasi m-banking/e-wallet secara real-time
- 📸 **OCR Struk & Bukti Pembayaran** — cukup foto struk atau screenshot, sistem yang mengekstrak datanya (ML Kit on-device)
- ✍️ **Input Manual** — sebagai fallback kapan pun otomatisasi tidak tersedia

Pemrosesan memakai **arsitektur hybrid**: rule engine regex berjalan **100% lokal dan offline** sebagai jalur utama. Opsional, pengguna dapat mengisi API key Gemini pribadi di Pengaturan agar notifikasi yang gagal dikenali rule engine diparsing oleh AI cloud (*opt-in* — tanpa API key, tidak ada data yang keluar dari perangkat).

---

## ✨ Fitur Utama

| Fitur | Deskripsi |
|---|---|
| 🔄 **Deteksi Transaksi Otomatis** | Menangkap & mengekstrak transaksi dari notifikasi m-banking/e-wallet |
| 🧾 **Scan Struk (OCR)** | Ekstraksi merchant, item, dan total dari foto struk fisik |
| 📲 **Scan Bukti Pembayaran** | Ekstraksi status, nominal, dan referensi dari screenshot pembayaran |
| 🧠 **Ekstraksi Hybrid** | Rule engine regex offline sebagai jalur utama + AI cloud opsional (opt-in) untuk kasus sulit |
| 📥 **Transaction Inbox** | Antrian human-in-the-loop untuk konfirmasi transaksi berconfidence rendah |
| 🧭 **Duplicate Detection** | Mendeteksi kemungkinan transaksi tercatat dua kali lintas sumber |
| 💸 **Transfer & Top Up** | Perpindahan dana antar akun tanpa dihitung sebagai pengeluaran ganda |
| 📊 **Dashboard & Statistik** | Ringkasan aset, grafik pengeluaran/pemasukan, top merchant |
| 🎯 **Budgeting** | Budget per kategori dengan alert saat mendekati limit |
| 🔁 **Recurring Transaction** | Deteksi & pengingat transaksi berulang |
| ⚖️ **Rekonsiliasi Saldo** | Bandingkan saldo tercatat vs saldo aktual |
| 🔐 **Keamanan** | App lock (PIN/biometrik), enkripsi database, backup terenkripsi |
| 🌐 **Offline-First** | Fungsi inti berjalan tanpa koneksi internet |

---

## 🖼️ Tampilan Aplikasi

> _Screenshot akan ditambahkan seiring progres pengembangan UI._

| Dashboard | Transaction Inbox | Scan Struk |
|---|---|---|
| _coming soon_ | _coming soon_ | _coming soon_ |

---

## 🏗️ Arsitektur

NyatetPesse berjalan **sepenuhnya on-device** — tanpa backend wajib, tanpa cloud AI wajib.

```
                    SUMBER TRANSAKSI
                           │
        ┌──────────────────┼──────────────────┐
        ▼                  ▼                  ▼
 Notification          Foto Struk       Bukti Pembayaran
   Listener               (OCR)          / Screenshot (OCR)
        │                  │                  │
        └──────────────────┼──────────────────┘
                           ▼
             Rule Engine (offline, default)
                           ▼
              AI Cloud opsional (opt-in)*
                           ▼
                 Structured Transaction
                           ▼
                    Duplicate Detection
                           ▼
              ┌────────────┴────────────┐
              ▼                         ▼
        Auto Save                User Confirmation
              │                         │
              └────────────┬────────────┘
                           ▼
                Local Database (terenkripsi)
                           ▼
          ┌────────────────┼────────────────┐
          ▼                ▼                ▼
      Dashboard        Statistics      Reconciliation

  * Gemini API hanya dipakai jika pengguna mengisi API key sendiri;
    tanpa itu seluruh alur tetap berjalan offline.
```

**Prinsip desain utama:**
- **Local-first** — data utama tersimpan di perangkat
- **Privacy-first** — tidak ada data finansial dikirim ke AI cloud secara default
- **Hybrid processing** — rule engine untuk data deterministik, ML untuk klasifikasi
- **Human-in-the-loop** — semua hasil otomatis dapat dikoreksi pengguna
- **Fail-safe** — kegagalan satu sumber (mis. Notification Listener) tidak menghentikan pencatatan

Detail arsitektur lengkap, skema database, dan spesifikasi model ML tersedia di [`SRS.md`](SRS.md).

---

## 🛠️ Tech Stack

| Layer | Teknologi |
|---|---|
| UI | Flutter (Dart) |
| State Management | Riverpod / BLoC |
| Android Native | Kotlin — `NotificationListenerService` |
| Bridge | MethodChannel / EventChannel |
| Database | SQLite via Drift, terenkripsi dengan SQLite3MultipleCiphers (kunci di secure storage) |
| OCR | Google ML Kit Text Recognition (on-device) |
| Machine Learning | TensorFlow Lite / LiteRT *(roadmap — belum aktif)*; fallback parsing Gemini API opsional |
| Training Pipeline | Python + scikit-learn *(roadmap)* |
| Keamanan | Android Keystore, BiometricPrompt API |
| Grafik | fl_chart / syncfusion_flutter_charts |
| Backup (opsional) | Google Drive API |

---

## 🚀 Getting Started

### Prasyarat

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (versi stabil terbaru)
- Android Studio / VS Code dengan plugin Flutter & Dart
- Android SDK — target minimum **Android 8.0 (API 26)**
- Perangkat/emulator Android untuk testing `NotificationListenerService`

### Instalasi

```bash
# Clone repository
git clone https://github.com/<username>/nyatetpesse.git
cd nyatetpesse

# Ambil dependencies
flutter pub get

# Jalankan aplikasi
flutter run
```

### Build APK

```bash
flutter build apk --release
```

> ⚠️ Fitur Notification Listener memerlukan izin manual dari pengguna di **Settings → Notification Access** pada perangkat Android, karena tidak dapat diminta lewat runtime permission dialog biasa.

---

## 📁 Struktur Proyek

```text
lib/
├── core/            # services (gemini, ocr, fingerprint), theme
├── features/        # dashboard, transactions, accounts, categories,
│                    # inbox, reports, security, settings
├── data/            # database (drift), repositories
└── notification/    # notification listener service (pipeline utama)

android/
└── app/src/main/kotlin/com/example/nyatet_pesse/
    ├── MainActivity.kt
    └── NyatetNotificationListener.kt

tool/                # skrip utilitas dev (mis. pad_image.dart)
test/                # unit tests (parser, enkripsi DB, filter notifikasi)
UI/                  # mockup desain HTML
```

---

## 🗺️ Roadmap

- [x] **Phase 1 — Foundation**: setup project, skema database, manajemen akun & kategori, input manual, dashboard dasar, biometrik lock ✅
- [x] **Phase 2 — Notification Automation**: `NotificationListenerService`, parser notifikasi (rule engine + fallback AI), Transaction Inbox ✅
- [x] **Phase 3 — OCR**: scan struk & bukti pembayaran via ML Kit + Gemini vision opsional ✅
- [x] **Phase 5 — Privacy & Security (parsial)**: enkripsi database via SQLite3MultipleCiphers, biometrik, secure storage ✅ *(encrypted backup belum)*
- [x] **Phase 6 — Financial Intelligence (parsial)**: budgeting, statistik, recurring transaction, export CSV ✅ *(rekonsiliasi UI belum)*
- [ ] **Phase 4 — Local AI**: dataset & training, konversi TFLite, confidence score, offline inference
- [ ] **Phase 6 — lanjutan**: rekonsiliasi saldo (UI), import, encrypted backup

Detail lengkap tiap fase & mapping ke functional requirement ada di [`SRS.md`](SRS.md#19-prioritas-pengembangan).

---

## 🔒 Privasi & Keamanan

NyatetPesse dirancang dengan prinsip **privacy by design**:

- Jalur pemrosesan utama (rule engine regex, OCR ML Kit) berjalan **on-device** — tanpa koneksi internet.
- Database dienkripsi menggunakan **SQLite3MultipleCiphers** (via build hooks) dengan kunci 256-bit acak yang disimpan di `flutter_secure_storage`; migrasi otomatis dari database plaintext lama.
- Aplikasi dilindungi autentikasi biometrik dengan auto-lock dan grace period.
- **AI cloud bersifat opt-in**: jika pengguna mengisi API key Gemini sendiri di Pengaturan, teks notifikasi/struk yang gagal dikenali rule engine akan dikirim ke Google API untuk diparsing. Tanpa API key, tidak ada data yang keluar dari perangkat.

Lihat bagian [Security Threats & Mitigasi](SRS.md#12-security-threats-dan-mitigasi) di SRS untuk detail ancaman dan mitigasinya.

---

## 📄 Dokumentasi

Spesifikasi kebutuhan lengkap (SRS) — mencakup functional & non-functional requirements, skema database, use case, error handling, ML spec, testing plan, hingga roadmap — tersedia di:

📘 [`SRS.md`](SRS.md)

---

## 🤝 Contributing

Kontribusi sangat terbuka! Untuk berkontribusi:

1. Fork repository ini
2. Buat branch fitur (`git checkout -b fitur/nama-fitur`)
3. Commit perubahan (`git commit -m 'Menambahkan fitur X'`)
4. Push ke branch (`git push origin fitur/nama-fitur`)
5. Buka Pull Request

Mohon pastikan perubahan sejalan dengan prinsip desain di [SRS](SRS.md#18-prinsip-desain-final) — khususnya **local-first** dan **privacy-first**.

---

## 📜 Lisensi

Lisensi proyek ini belum ditentukan (*TBD*). Tambahkan file `LICENSE` sesuai kebutuhan sebelum rilis publik.

---

<div align="center">

Dibuat dengan ❤️ untuk siapa pun yang capek mencatat keuangan manual.

</div>
