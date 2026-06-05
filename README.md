# EduLink - Peer Tutoring Marketplace & Quiz Manager

Platform kolaborasi belajar dengan sistem Knowledge Points (KP)
sebagai pengganti uang.

### Fitur 2: Teach (Hardcoded / Local State)

Marketplace peer tutoring tempat siswa dapat membuat permintaan bantuan, mencari
tutor, memesan sesi, dan mengelola booking menggunakan KP.

### Fitur 3: Test (Quiz Material)

Dashboard quiz khusus tutor untuk membuat materi test berdasarkan sesi tutor
yang sudah dibooking siswa. Untuk saat ini, quiz belum menghasilkan soal AI;
materi yang dibuat tutor ditampilkan ke siswa sebagai plain text.

Catatan sementara: fitur Test saat ini membaca `DummyData.myBookings` agar bisa
langsung dites. 

Alur utama:

- Tutor membuka tab `Test`, memilih booking siswa aktif, lalu membuat materi quiz.
- Materi quiz disimpan sementara di memori dummy dengan status `assigned`.
- Siswa membuka tab `Materi`, melihat daftar sesi tutor yang dibooking, lalu membuka materi quiz aktif dari tiap sesi.

---

## Struktur Project

```txt
lib/
|-- main.dart                          # Entry point
|-- theme.dart                         # Warna, badge, helper UI
|-- models/
|   |-- user_model.dart                # AppUser, UserRole
|   |-- help_request_model.dart        # HelpRequest, RequestStatus
|   |-- tutor_session_model.dart       # TutorSession
|   |-- booking_model.dart             # Booking, BookingStatus
|   `-- quiz_model.dart                # Quiz + mapping Firestore
|-- data/
|   `-- dummy_data.dart                # Data hardcoded untuk Teach
|-- services/
|   |-- auth_service.dart              # Firebase Auth + profile helper
|   `-- quiz_service.dart              # Dummy mode + kode Firestore untuk fitur Test
|-- screens/
|   |-- auth_gate.dart                 # Gate login/register
|   |-- auth_screen.dart               # UI autentikasi
|   |-- marketplace_screen.dart        # Dashboard student untuk Teach
|   |-- tutor_home_screen.dart         # Dashboard tutor + tab Test
|   |-- materials_quiz_screen.dart     # Student: sesi tutor + materi quiz aktif
|   |-- help_requests_tab.dart         # Tab permintaan bantuan
|   |-- tutors_tab.dart                # Tab tutor tersedia
|   |-- my_bookings_tab.dart           # Tab pemesananku
|   |-- tutor_activity_tab.dart        # Aktivitas tutor
|   `-- quiz_dashboard_tab.dart        # Tutor: daftar/edit/hapus materi quiz
`-- widgets/
    |-- common_widgets.dart            # AvatarWidget, KpBadge, TagChip, dll
    |-- create_request_sheet.dart      # Bottom sheet buat permintaan
    |-- create_tutor_session_sheet.dart# Bottom sheet daftar sesi tutor
    |-- book_session_sheet.dart        # Bottom sheet pesan sesi
    `-- create_quiz_sheet.dart         # Bottom sheet buat/edit materi quiz
```

---

## CRUD Operations

### CREATE

- **Buat Permintaan Bantuan** -> FAB di tab "Permintaan" -> `CreateRequestSheet`
- **Daftar Sesi Tutor** -> FAB di tab "Sesi tutor" -> `CreateTutorSessionSheet`
- **Pesan Sesi Tutor** -> Tombol "Pesan Sesi" di tab "Tutor" -> `BookSessionSheet`
- **Buat Materi Quiz** -> FAB di tab "Test" tutor -> `CreateQuizSheet` -> dummy quiz memory

### READ

- **Tab Permintaan** -> Daftar `HelpRequest` dengan fitur search
- **Tab Tutor** -> Daftar `TutorSession` dengan status online/offline
- **Tab Pemesananku** -> Daftar `Booking` milik user
- **Tab Test Tutor** -> Daftar `Quiz` dari dummy service berdasarkan `tutorId`
- **Tab Materi Student** -> Daftar booking tutor dari `DummyData.myBookings`, lalu quiz aktif berdasarkan `bookingId`

### UPDATE

- **Edit Pemesanan** -> Tombol "Ubah" di kartu booking -> `_EditBookingSheet`
- **Update Status Permintaan** -> Tutor menawarkan bantuan dan status berubah menjadi `pending`
- **Edit Materi Quiz** -> Tombol "Edit Materi" di kartu quiz -> `CreateQuizSheet` -> update dummy quiz memory
- **Auto KP Balance** -> KP balance berubah saat pesan atau membatalkan booking

### DELETE

- **Hapus Permintaan** -> Tombol hapus di kartu permintaan dengan konfirmasi dialog
- **Batalkan Pemesanan** -> Tombol "Batalkan" + refund KP otomatis
- **Hapus Materi Quiz** -> Tombol hapus di kartu quiz tutor -> delete dari dummy quiz memory

---

## Cara Jalankan

```bash
flutter pub get
flutter run
```

## Langkah Selanjutnya

- [ ] Integrasikan flow booking Teach ke Firestore agar otomatis membuat dokumen `bookings`
- [ ] Integrasikan dengan API LLM untuk generate soal quiz dari `materialText`
- [ ] Tambahkan pengerjaan quiz, jawaban siswa, skor, dan analisis performa
- [ ] Real-time booking dengan WebSocket atau Firestore stream yang lebih lengkap
- [ ] Sistem rating dan ulasan tutor
- [ ] Notifikasi push untuk status booking dan materi quiz baru
