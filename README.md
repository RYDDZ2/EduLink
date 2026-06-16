# EduLink — Peer Tutoring Marketplace & Collaborative Learning Platform

> Platform kolaborasi belajar berbasis Flutter yang menghubungkan siswa dan tutor, dilengkapi sistem **Knowledge Points (KP)** sebagai mata uang internal, fitur Study Hub komunitas, quiz bertenaga AI, dan real-time chat.

---

## Daftar Isi

- [Gambaran Umum](#gambaran-umum)
- [Fitur Utama](#fitur-utama)
- [Arsitektur & Tech Stack](#arsitektur--tech-stack)
- [Struktur Project](#struktur-project)
- [Alur Pengguna](#alur-pengguna)
- [CRUD Operations](#crud-operations)
- [Konfigurasi & Setup](#konfigurasi--setup)
- [Variabel Environment (.env)](#variabel-environment-env)
- [Cara Menjalankan](#cara-menjalankan)
- [Langkah Selanjutnya](#langkah-selanjutnya)

---

## Gambaran Umum

EduLink adalah aplikasi Flutter multi-platform (Android & iOS) yang dirancang untuk mendukung **SDG 4 — Quality Education**. Platform ini mempertemukan siswa yang butuh bantuan belajar dengan tutor berpengalaman menggunakan sistem poin (KP) sebagai pengganti uang tunai.

### Peran Pengguna

| Peran | Deskripsi |
|-------|-----------|
| **Student** | Dapat memposting permintaan bantuan, memesan sesi tutor, mengakses materi quiz, bergabung ke Study Hub, dan melakukan chat dengan tutor |
| **Tutor** | Dapat membuka sesi tutoring, merespons permintaan bantuan, membuat materi quiz bertenaga AI, dan mengelola booking dari siswa |

---

## Fitur Utama

### 1. Study Hub (Komunitas Belajar)
- Siswa dapat membuat atau bergabung ke **Study Hub** — ruang diskusi tematik berbasis topik atau mata pelajaran.
- Setiap hub mendukung **threads** (utas diskusi) untuk tanya-jawab kolaboratif.
- Data tersimpan di Firestore (`studyHubs/{hubId}/threads/{threadId}`).
- Fitur pencarian hub berdasarkan judul dan tags.
- Upload gambar/lampiran di threads menggunakan Supabase Storage.

### 2. Teach (Marketplace Tutoring)
- Siswa memposting **permintaan bantuan** (`HelpRequest`) dengan topik, deskripsi, dan anggaran KP.
- Tutor membuka **sesi tutoring** (`TutorSession`) dengan jadwal, harga KP, dan kapasitas.
- Tutor dapat mengirim **penawaran bantuan** (`HelpOffer`) ke permintaan yang ada.
- Siswa menerima/menolak penawaran dari tab **Inbox**.
- Setelah deal, sesi tutoring berjalan melalui `TutoringSession` yang mendukung **real-time chat** antar kedua pihak.
- Siswa dapat melakukan **booking langsung** ke sesi tutor yang terbuka.
- Seluruh data dikelola via Firestore dengan stream real-time.

### 3. Test (Quiz Bertenaga AI)
- Tutor membuat **materi quiz** berdasarkan sesi tutoring yang sudah dibooking siswa.
- Integrasi dengan **OpenRouter API** untuk generate soal otomatis dari teks materi yang dimasukkan tutor.
- Quiz disimpan ke Firestore (`quizzes`) dan terhubung ke `bookingId` serta `tutorId`.
- Siswa membuka tab **Materi** untuk melihat daftar quiz aktif dari tutor mereka.
- Status quiz: `assigned` → dapat diakses siswa.

### 4. Real-Time Chat
- Chat satu-ke-satu antara tutor dan siswa dalam konteks `TutoringSession`.
- Mendukung pengiriman **teks**, **gambar** (via kamera/galeri), dan **file** (PDF, dokumen).
- Lampiran diupload ke **Supabase Storage** (`chat-attachments` bucket).
- Pesan tersimpan di Firestore dan dapat diunduh/dibuka langsung dari dalam chat.

### 5. Profil & Onboarding
- Setelah registrasi, pengguna diarahkan ke **BioOnboardingScreen** untuk mengisi bio lengkap sesuai perannya:
  - **Student**: tingkat pendidikan (SD/SMP/SMA/Mahasiswa), kelas/semester, jurusan.
  - **Tutor**: tipe (Guru/Dosen), mata pelajaran yang diajarkan.
- Upload **foto profil** menggunakan kamera atau galeri, disimpan di Supabase Storage (`profile-images` bucket).
- Edit profil lengkap tersedia di halaman **Edit Account**.

### 6. Notifikasi Lokal
- **NotificationService** memantau Firestore secara real-time untuk:
  - Penawaran baru dari tutor (notifikasi ke student).
  - Pesan chat baru.
- Notifikasi muncul selama app aktif di foreground maupun background (menggunakan `flutter_local_notifications`).

### 7. Knowledge Points (KP)
- Setiap pengguna memiliki saldo KP yang tercatat di Firestore.
- KP dikurangkan saat siswa melakukan booking sesi.
- KP di-refund otomatis saat booking dibatalkan.
- KP ditransfer ke tutor saat sesi selesai.

---

## Arsitektur & Tech Stack

### Flutter & Dart
- **Flutter SDK** `>=3.0.0` dengan Material 3.
- Target platform: **Android** & **iOS** (web/desktop tersedia sebagai bonus).

### Backend Services

| Layanan | Kegunaan |
|---------|---------|
| **Firebase Auth** | Autentikasi email/password + manajemen sesi |
| **Cloud Firestore** | Database utama: users, helpRequests, tutorSessions, bookings, quizzes, studyHubs, threads, messages, dsb |
| **Supabase Storage** | Penyimpanan file: foto profil, lampiran chat, gambar permintaan, materi Study Hub |
| **OpenRouter API** | Generate soal quiz secara otomatis menggunakan LLM (GPT/model lainnya) |
| **flutter_local_notifications** | Push notifikasi lokal saat app aktif |

### Pola Arsitektur
- **Service Layer** — semua akses ke Firebase/Supabase/API dikapsulasi di `lib/services/`.
- **Model Layer** — class data + serialisasi Firestore di `lib/models/`.
- **Screen/Widget Layer** — UI murni yang memanggil service.
- **Stream-based reactivity** — Firestore `snapshots()` digunakan di sebagian besar tampilan untuk update real-time.

---

## Struktur Project

```
edulink/
├── lib/
│   ├── main.dart                              # Entry point, init Firebase + Supabase + Notifikasi
│   ├── firebase_options.dart                  # Konfigurasi Firebase per platform
│   ├── theme.dart                             # Warna, badge, helper UI global
│   │
│   ├── models/
│   │   ├── user_model.dart                    # AppUser, UserRole, StudentBio, TutorBio
│   │   ├── help_request_model.dart            # HelpRequest, RequestStatus
│   │   ├── tutor_session_model.dart           # TutorSession
│   │   ├── booking_model.dart                 # Booking, BookingStatus
│   │   ├── marketplace_models.dart            # HelpOffer, SessionBookingRequest, TutoringSession, ChatMessage
│   │   ├── quiz_model.dart                    # Quiz + serialisasi Firestore
│   │   └── study_hub_model.dart               # StudyHub, StudyThread, StudyHubStatus
│   │
│   ├── data/
│   │   └── dummy_data.dart                    # Data fallback / demo lokal
│   │
│   ├── services/
│   │   ├── auth_service.dart                  # Firebase Auth: login, register, profil, logout
│   │   ├── marketplace_service.dart           # Firestore CRUD: helpRequests, tutorSessions, offers, bookings, chat
│   │   ├── quiz_service.dart                  # Firestore CRUD: quizzes (dengan fallback dummy mode)
│   │   ├── openrouter_quiz_service.dart       # Integrasi OpenRouter API untuk generate soal AI
│   │   ├── study_hub_service.dart             # Firestore CRUD: studyHubs + threads
│   │   ├── notification_service.dart          # Local push notifikasi via flutter_local_notifications
│   │   ├── supabase_profile_service.dart      # Upload/hapus foto profil ke Supabase Storage
│   │   ├── supabase_chat_attachment_service.dart  # Upload lampiran chat ke Supabase Storage
│   │   ├── supabase_request_image_service.dart    # Upload gambar permintaan bantuan ke Supabase Storage
│   │   └── supabase_study_hub_service.dart    # Upload lampiran thread Study Hub ke Supabase Storage
│   │
│   ├── screens/
│   │   ├── auth_gate.dart                     # Router: cek auth state → login atau home
│   │   ├── auth_screen.dart                   # UI login & register
│   │   ├── bio_onboarding_screen.dart         # Onboarding bio setelah registrasi
│   │   ├── student_home_screen.dart           # Shell navigasi utama Student (Study Hub, Tutor, Materi, Profile)
│   │   ├── tutor_home_screen.dart             # Shell navigasi utama Tutor (Teach, Test, Profile)
│   │   │
│   │   │   [--- STUDENT TABS ---]
│   │   ├── study_hub_screen.dart              # Tab Study Hub: daftar & cari hub komunitas
│   │   ├── study_hub_detail_screen.dart       # Halaman detail hub: daftar thread + buat thread
│   │   ├── thread_detail_screen.dart          # Halaman detail thread: balasan + lampiran
│   │   ├── marketplace_screen.dart            # Tab Tutor: help requests, sesi tutor, bookings, inbox
│   │   ├── help_requests_tab.dart             # Sub-tab: daftar & cari permintaan bantuan
│   │   ├── tutors_tab.dart                    # Sub-tab: daftar sesi tutor tersedia
│   │   ├── my_bookings_tab.dart               # Sub-tab: booking aktif milik user
│   │   ├── marketplace_inbox_tab.dart         # Sub-tab: penawaran masuk (student) / booking masuk (tutor)
│   │   ├── marketplace_activity_tab.dart      # Sub-tab: riwayat aktivitas
│   │   ├── materials_quiz_screen.dart         # Tab Materi: sesi aktif + quiz dari tutor
│   │   ├── request_detail_screen.dart         # Detail permintaan bantuan
│   │   ├── tutor_profile_screen.dart          # Profil publik tutor
│   │   ├── chat_screen.dart                   # Real-time chat dalam sesi tutoring
│   │   │
│   │   │   [--- TUTOR TABS ---]
│   │   ├── tutor_activity_tab.dart            # Aktivitas tutor (booking masuk, dll)
│   │   ├── quiz_dashboard_tab.dart            # Tab Test: daftar, edit, hapus materi quiz
│   │   │
│   │   │   [--- SHARED ---]
│   │   ├── profile_screen.dart                # Halaman profil diri sendiri
│   │   └── edit_account_page.dart / edit_account_sheet.dart  # Edit data akun & profil
│   │
│   └── widgets/
│       ├── common_widgets.dart                # AvatarWidget, KpBadge, TagChip, SectionHeader, dsb
│       ├── bio_fields_form.dart               # Form bio student/tutor (dipakai di onboarding & edit)
│       ├── create_request_sheet.dart          # Bottom sheet: buat permintaan bantuan (+ upload gambar)
│       ├── edit_request_sheet.dart            # Bottom sheet: edit permintaan bantuan
│       ├── create_tutor_session_sheet.dart    # Bottom sheet: buka sesi tutor baru
│       ├── edit_tutor_session_sheet.dart      # Bottom sheet: edit sesi tutor
│       ├── book_session_sheet.dart            # Bottom sheet: pesan sesi tutor
│       ├── create_quiz_sheet.dart             # Bottom sheet: buat/edit materi quiz (+ generate AI)
│       ├── create_study_hub_sheet.dart        # Bottom sheet: buat Study Hub baru
│       └── create_thread_sheet.dart           # Bottom sheet: buat thread di Study Hub
│
├── android/                                   # Konfigurasi Android
├── ios/                                       # Konfigurasi iOS
├── web/                                       # Konfigurasi Web (bonus)
├── pubspec.yaml                               # Dependencies Flutter
├── firebase.json                              # Konfigurasi Firebase CLI
└── .env                                       # Variabel environment (tidak di-commit)
```

---

## Alur Pengguna

### Alur Student

```
Buka App
  └─► AuthGate
        ├─ Belum login → AuthScreen (Login / Register)
        │     └─ Register → BioOnboardingScreen (isi bio + foto)
        │
        └─ Sudah login → StudentHomeScreen
              ├─ Tab Study Hub
              │     ├─ Lihat daftar hub komunitas
              │     ├─ Buat hub baru
              │     ├─ Masuk detail hub → lihat threads
              │     └─ Buat/balas thread + upload lampiran
              │
              ├─ Tab Tutor (MarketplaceScreen)
              │     ├─ Sub-tab Permintaan → Buat/lihat/hapus HelpRequest
              │     ├─ Sub-tab Tutor → Lihat TutorSession → Pesan sesi
              │     ├─ Sub-tab Bookingku → Lihat/ubah/batalkan booking
              │     ├─ Sub-tab Inbox → Terima/tolak penawaran dari tutor
              │     └─ Sesi aktif → Masuk ChatScreen (kirim pesan & file)
              │
              ├─ Tab Materi
              │     └─ Lihat daftar sesi tutoring aktif + materi quiz dari tutor
              │
              └─ Tab Profile → Lihat & edit profil, ganti foto, logout
```

### Alur Tutor

```
Buka App
  └─► AuthGate → TutorHomeScreen
        ├─ Tab Teach (MarketplaceScreen)
        │     ├─ Sub-tab Permintaan → Lihat HelpRequest siswa → Kirim penawaran
        │     ├─ Sub-tab Tutor → Buka sesi tutoring baru
        │     ├─ Sub-tab Bookingku → Lihat booking yang diterima
        │     ├─ Sub-tab Inbox → Kelola booking session dari siswa
        │     └─ Sesi aktif → Masuk ChatScreen
        │
        ├─ Tab Test (QuizDashboard)
        │     ├─ Lihat daftar quiz yang sudah dibuat
        │     ├─ Buat materi quiz baru → input teks → generate soal via OpenRouter AI
        │     ├─ Edit materi quiz
        │     └─ Hapus materi quiz
        │
        └─ Tab Profile → Lihat & edit profil, logout
```

---

## CRUD Operations

### Firestore Collections

| Collection | Model | Siapa yang bisa akses |
|---|---|---|
| `users` | `AppUser` | Semua (read), diri sendiri (write) |
| `helpRequests` | `HelpRequest` | Semua (read), pemilik (write/delete) |
| `tutorSessions` | `TutorSession` | Semua (read), tutor pemilik (write/delete) |
| `helpOffers` | `HelpOffer` | Tutor (create), student terkait (read/update) |
| `sessionBookings` | `SessionBookingRequest` | Student (create), tutor terkait (read/update) |
| `tutoringSessions` | `TutoringSession` | Tutor + student terkait |
| `tutoringSessions/{id}/messages` | `ChatMessage` | Tutor + student terkait |
| `quizzes` | `Quiz` | Tutor pemilik (write), student terkait (read) |
| `studyHubs` | `StudyHub` | Semua |
| `studyHubs/{id}/threads` | `StudyThread` | Semua |

### CREATE

| Aksi | Siapa | Entry Point |
|------|-------|------------|
| Buat permintaan bantuan | Student | FAB → `CreateRequestSheet` |
| Buka sesi tutoring | Tutor | FAB → `CreateTutorSessionSheet` |
| Kirim penawaran bantuan | Tutor | Tombol di `RequestDetailScreen` |
| Pesan sesi tutor | Student | Tombol di `TutorsTab` → `BookSessionSheet` |
| Buat materi quiz | Tutor | FAB → `CreateQuizSheet` → opsional generate AI via OpenRouter |
| Buat Study Hub | Siapapun | FAB → `CreateStudyHubSheet` |
| Buat thread | Siapapun | FAB di `StudyHubDetailScreen` → `CreateThreadSheet` |
| Kirim pesan chat | Siapapun | Input field di `ChatScreen` |

### READ

| Tampilan | Data yang dibaca |
|----------|-----------------|
| `HelpRequestsTab` | Stream `helpRequests` dengan pencarian |
| `TutorsTab` | Stream `tutorSessions` |
| `MyBookingsTab` | Stream booking milik user |
| `MarketplaceInboxTab` | Stream penawaran / booking masuk |
| `StudyHubScreen` | Stream `studyHubs` dengan pencarian |
| `StudyHubDetailScreen` | Stream threads dalam hub |
| `ChatScreen` | Stream `messages` dalam sesi tutoring |
| `QuizDashboardTab` | Stream quiz berdasarkan `tutorId` |
| `MaterialsQuizScreen` | Stream sesi aktif + quiz berdasarkan `bookingId` |
| `ProfileScreen` | Data `AppUser` dari Firestore |

### UPDATE

| Aksi | Entry Point |
|------|------------|
| Edit permintaan bantuan | Tombol Edit di kartu → `EditRequestSheet` |
| Edit sesi tutor | Tombol Edit → `EditTutorSessionSheet` |
| Ubah booking | Tombol "Ubah" di kartu booking |
| Terima/tolak penawaran | Tombol di `MarketplaceInboxTab` |
| Edit materi quiz | Tombol "Edit" di kartu quiz → `CreateQuizSheet` (mode edit) |
| Update KP balance | Otomatis saat booking/cancel/sesi selesai |
| Update foto profil | `ProfileScreen` → `SupabaseProfileService` |
| Update bio profil | `EditAccountPage` → `AuthService.updateProfile` |

### DELETE

| Aksi | Konfirmasi |
|------|-----------|
| Hapus permintaan bantuan | Dialog konfirmasi |
| Batalkan booking | Dialog konfirmasi + refund KP otomatis |
| Hapus materi quiz | Dialog konfirmasi |
| Hapus foto profil | Hapus dari Supabase Storage + update Firestore |

---

## Konfigurasi & Setup

### 1. Prasyarat

- Flutter SDK `>=3.0.0` (cek: `flutter doctor`)
- Akun Firebase (project sudah ada: `fp-ppb-7a2fe`)
- Akun Supabase (untuk storage)
- API key OpenRouter (untuk fitur generate quiz AI)

### 2. Clone & Install Dependencies

```bash
git clone https://github.com/RYDDZ2/EduLink.git
cd EduLink
flutter pub get
```

### 3. Konfigurasi Firebase

File `google-services.json` (Android) dan `GoogleService-Info.plist` (iOS) diperlukan. Unduh dari Firebase Console dan tempatkan di:

```
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
```

### 4. Konfigurasi Supabase

Buat project Supabase dan buat tiga Storage bucket berikut:

| Bucket | Kegunaan |
|--------|---------|
| `profile-images` | Foto profil pengguna |
| `chat-attachments` | Lampiran file/gambar di chat |
| `request-images` | Gambar di permintaan bantuan |
| `study-hub-attachments` | Lampiran thread Study Hub |

Atur **RLS policy** untuk tiap bucket sesuai kebutuhan (service role key untuk upload, anon key untuk read publik).

---

## Variabel Environment (.env)

Buat file `.env` di root project:

```env
# OpenRouter (untuk generate soal quiz AI)
OPENROUTER_API_KEY=sk-or-...
OPENROUTER_BASE_URL=https://openrouter.ai/api/v1
OPENROUTER_MODEL=openai/gpt-4o-mini

# Supabase
SUPABASE_URL=https://xxxx.supabase.co
SUPABASE_ANON_KEY=eyJ...
SUPABASE_SERVICE_ROLE_KEY=eyJ...
```

> **Penting:** Jangan commit file `.env` ke repository. File ini sudah ada di `.gitignore`.

---

## Cara Menjalankan

```bash
# Install dependencies
flutter pub get

# Jalankan di emulator/device
flutter run

# Jalankan di platform tertentu
flutter run -d android
flutter run -d ios

# Build APK
flutter build apk --release

# Build untuk iOS
flutter build ipa
```

---

## Langkah Selanjutnya

- [ ] **Firestore Security Rules** — Tambahkan rules yang ketat agar data hanya bisa diakses oleh pihak yang berwenang.
- [ ] **Quiz interaktif** — Tambahkan alur pengerjaan soal oleh siswa: tampilkan soal satu per satu, input jawaban, hitung skor, dan simpan hasil ke Firestore.
- [ ] **Analisis performa siswa** — Dashboard ringkasan skor dan progress per topik.
- [ ] **FCM Push Notification** — Notifikasi saat app tertutup (butuh Firebase Cloud Messaging + Cloud Functions).
- [ ] **Sistem rating & ulasan** — Siswa memberi rating kepada tutor setelah sesi selesai.
- [ ] **Transfer KP otomatis** — Logika transfer KP dari siswa ke tutor dijalankan via Cloud Function saat sesi selesai.
- [ ] **Pagination** — Lazy loading untuk daftar permintaan, sesi tutor, dan Study Hub yang makin banyak.
- [ ] **Pencarian global** — Full-text search across Study Hubs, tutor, dan permintaan bantuan.
- [ ] **Video call** — Integrasi WebRTC atau layanan pihak ketiga (Agora, Jitsi) untuk sesi tatap muka virtual.
