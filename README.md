# EduLink - Peer Tutoring Marketplace & Quiz Manager

Platform kolaborasi belajar dengan sistem Knowledge Points (KP)
sebagai pengganti uang.

### Fitur 2: Teach (Hardcoded / Local State)

Marketplace peer tutoring tempat siswa dapat membuat permintaan bantuan, mencari
tutor, memesan sesi, dan mengelola booking menggunakan KP.

### Fitur 3: Test (Local State)

Dashboard quiz khusus tutor untuk membuat quiz dari materi belajar.

---

## Struktur Project

```txt
lib/
├── main.dart                          # Entry point
├── theme.dart                         # Warna, badge, helper UI
├── models/
│   ├── user_model.dart                # AppUser, UserRole
│   ├── help_request_model.dart        # HelpRequest, RequestStatus
│   ├── tutor_session_model.dart       # TutorSession
│   ├── booking_model.dart             # Booking, BookingStatus
│   └── quiz_model.dart                # Quiz, QuizStatus, QuizDifficulty
├── data/
│   └── dummy_data.dart                # Data hardcoded untuk Teach dan Test
├── services/
│   └── auth_service.dart              # Firebase Auth + profile helper
├── screens/
│   ├── auth_gate.dart                 # Gate login/register
│   ├── auth_screen.dart               # UI autentikasi
│   ├── marketplace_screen.dart        # Dashboard student untuk Teach
│   ├── tutor_home_screen.dart         # Dashboard tutor + tab Test
│   ├── help_requests_tab.dart         # Tab permintaan bantuan
│   ├── tutors_tab.dart                # Tab tutor tersedia
│   ├── my_bookings_tab.dart           # Tab pemesananku
│   ├── tutor_activity_tab.dart        # Aktivitas tutor
│   └── quiz_dashboard_tab.dart        # Dashboard quiz lokal tutor
└── widgets/
    ├── common_widgets.dart            # AvatarWidget, KpBadge, TagChip, dll
    ├── create_request_sheet.dart      # Bottom sheet buat permintaan
    ├── create_tutor_session_sheet.dart# Bottom sheet daftar sesi tutor
    ├── book_session_sheet.dart        # Bottom sheet pesan sesi
    └── create_quiz_sheet.dart         # Bottom sheet buat/edit quiz draft
```

---

## CRUD Operations

### CREATE

- **Buat Permintaan Bantuan** -> FAB di tab "Permintaan" -> `CreateRequestSheet`
- **Daftar Sesi Tutor** -> FAB di tab "Sesi tutor" -> `CreateTutorSessionSheet`
- **Pesan Sesi Tutor** -> Tombol "Pesan Sesi" di tab "Tutor" -> `BookSessionSheet`
- **Buat Quiz Draft** -> FAB di tab "Test" tutor -> `CreateQuizSheet`

### READ

- **Tab Permintaan** -> Daftar `HelpRequest` dengan fitur search
- **Tab Tutor** -> Daftar `TutorSession` dengan status online/offline
- **Tab Pemesananku** -> Daftar `Booking` milik user
- **Tab Test** -> Daftar `Quiz` milik tutor dengan search berdasarkan judul, topik, atau siswa

### UPDATE

- **Edit Pemesanan** -> Tombol "Ubah" di kartu booking -> `_EditBookingSheet`
- **Update Status Permintaan** -> Tutor menawarkan bantuan dan status berubah menjadi `pending`
- **Edit Quiz Draft** -> Tombol "Edit Draft" di kartu quiz -> `CreateQuizSheet`
- **Auto KP Balance** -> KP balance berubah saat pesan atau membatalkan booking

### DELETE

- **Hapus Permintaan** -> Tombol hapus di kartu permintaan dengan konfirmasi dialog
- **Batalkan Pemesanan** -> Tombol "Batalkan" + refund KP otomatis
- **Hapus Quiz Draft** -> Tombol hapus di kartu quiz dengan konfirmasi dialog

---

## Cara Jalankan

```bash
flutter pub get
flutter run
```

## Langkah Selanjutnya

- [ ] Integrasikan dengan API LLM untuk generate quiz
- [ ] Integrasikan dengan backend/API (Firebase)
- [ ] Tambahkan autentikasi pengguna
- [ ] Real-time booking dengan WebSocket
- [ ] Sistem rating dan ulasan tutor
- [ ] Notifikasi push untuk status booking
