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
- 📸 **OCR Struk & Bukti Pembayaran** — cukup foto struk atau screenshot, sistem yang mengekstrak datanya
- ✍️ **Input Manual** — sebagai fallback kapan pun otomatisasi tidak tersedia

Semua diproses dan diklasifikasikan menggunakan **Local AI Model (on-device)** — **tidak ada data finansial yang dikirim ke server pihak ketiga**.

---

## ✨ Fitur Utama

| Fitur | Deskripsi |
|---|---|
| 🔄 **Deteksi Transaksi Otomatis** | Menangkap & mengekstrak transaksi dari notifikasi m-banking/e-wallet |
| 🧾 **Scan Struk (OCR)** | Ekstraksi merchant, item, dan total dari foto struk fisik |
| 📲 **Scan Bukti Pembayaran** | Ekstraksi status, nominal, dan referensi dari screenshot pembayaran |
| 🤖 **Klasifikasi Local AI** | Kategori transaksi otomatis via model TFLite/LiteRT, 100% offline |
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
                 Rule Engine + Local AI Model
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
                      Local Database
                           ▼
          ┌────────────────┼────────────────┐
          ▼                ▼                ▼
      Dashboard        Statistics      Reconciliation
```

**Prinsip desain utama:**
- **Local-first** — data utama tersimpan di perangkat
- **Privacy-first** — tidak ada data finansial dikirim ke AI cloud secara default
- **Hybrid processing** — rule engine untuk data deterministik, ML untuk klasifikasi
- **Human-in-the-loop** — semua hasil otomatis dapat dikoreksi pengguna
- **Fail-safe** — kegagalan satu sumber (mis. Notification Listener) tidak menghentikan pencatatan

Detail arsitektur lengkap, skema database, dan spesifikasi model ML tersedia di [`docs/SRS.md`](docs/SRS.md).

---

## 🛠️ Tech Stack

| Layer | Teknologi |
|---|---|
| UI | Flutter (Dart) |
| State Management | Riverpod / BLoC |
| Android Native | Kotlin — `NotificationListenerService` |
| Bridge | MethodChannel / EventChannel |
| Database | SQLite via Drift, dienkripsi dengan SQLCipher |
| OCR | Google ML Kit Text Recognition (on-device) |
| Machine Learning | TensorFlow Lite / LiteRT |
| Training Pipeline | Python + scikit-learn |
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
├── core/            # constants, errors, security, utils
├── features/        # dashboard, transactions, accounts, categories,
│                     # budget, statistics, scanner, inbox,
│                     # reconciliation, settings
├── data/            # database, repositories, models
├── domain/          # entities, usecases
├── ml/              # model, preprocessing, inference
├── ocr/             # services, parsers
└── notification/    # services

android/
└── app/src/main/kotlin/notification/
    └── TransactionNotificationListener.kt
```

---

## 🗺️ Roadmap

- [ ] **Phase 1 — Foundation**: setup project, skema database, manajemen akun & kategori, input manual, dashboard dasar, PIN lock
- [ ] **Phase 2 — Notification Automation**: `NotificationListenerService`, parser notifikasi, duplicate detection, Transaction Inbox
- [ ] **Phase 3 — OCR**: scan struk & bukti pembayaran, image preprocessing
- [ ] **Phase 4 — Local AI**: dataset & training, konversi TFLite, confidence score, offline inference
- [ ] **Phase 5 — Privacy & Security**: enkripsi database, private storage, encrypted backup
- [ ] **Phase 6 — Financial Intelligence**: budgeting, statistik lengkap, rekonsiliasi, recurring transaction, export/import

Detail lengkap tiap fase & mapping ke functional requirement ada di [`docs/SRS.md`](docs/SRS.md#19-prioritas-pengembangan).

---

## 🔒 Privasi & Keamanan

NyatetPesse dirancang dengan prinsip **privacy by design**:

- Seluruh inferensi AI berjalan **on-device** — tidak ada transaksi, foto struk, atau notifikasi yang dikirim ke server pihak ketiga secara default.
- Database dienkripsi (SQLCipher), foto struk disimpan di private app storage.
- Aplikasi dilindungi PIN/biometrik dengan auto-lock.
- Backup (opsional) dienkripsi sebelum disimpan ke penyimpanan eksternal/cloud.

Lihat bagian [Security Threats & Mitigasi](docs/SRS.md#12-security-threats-dan-mitigasi) di SRS untuk detail ancaman dan mitigasinya.

---

## 📄 Dokumentasi

Spesifikasi kebutuhan lengkap (SRS) — mencakup functional & non-functional requirements, skema database, use case, error handling, ML spec, testing plan, hingga roadmap — tersedia di:

📘 [`docs/SRS.md`](docs/SRS.md)

---

## 🤝 Contributing

Kontribusi sangat terbuka! Untuk berkontribusi:

1. Fork repository ini
2. Buat branch fitur (`git checkout -b fitur/nama-fitur`)
3. Commit perubahan (`git commit -m 'Menambahkan fitur X'`)
4. Push ke branch (`git push origin fitur/nama-fitur`)
5. Buka Pull Request

Mohon pastikan perubahan sejalan dengan prinsip desain di [SRS](docs/SRS.md#18-prinsip-desain-final) — khususnya **local-first** dan **privacy-first**.

---

## 📜 Lisensi

Lisensi proyek ini belum ditentukan (*TBD*). Tambahkan file `LICENSE` sesuai kebutuhan sebelum rilis publik.

---

<div align="center">

Dibuat dengan ❤️ untuk siapa pun yang capek mencatat keuangan manual.

</div>
