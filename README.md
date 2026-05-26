# EduLink — Peer Tutoring Marketplace
## Fitur 2: Teach (Hardcoded / Local State)

Platform kolaborasi belajar dengan sistem Knowledge Points (KP) menggantikan uang.

---

## Struktur Project

```
lib/
├── main.dart                          # Entry point
├── theme.dart                         # Warna, badge, helper UI
├── models/
│   └── models.dart                    # HelpRequest, TutorSession, Booking
├── data/
│   └── dummy_data.dart                # Data hardcoded (8 item)
├── screens/
│   ├── marketplace_screen.dart        # Main screen + state management
│   ├── help_requests_tab.dart         # Tab permintaan bantuan
│   ├── tutors_tab.dart                # Tab tutor tersedia
│   └── my_bookings_tab.dart           # Tab pemesananku
└── widgets/
    ├── common_widgets.dart            # AvatarWidget, KpBadge, TagChip, dll
    ├── create_request_sheet.dart      # Bottom sheet buat permintaan (CREATE)
    └── book_session_sheet.dart        # Bottom sheet pesan sesi (CREATE booking)
```

---

## CRUD Operations

### CREATE
- **Buat Permintaan Bantuan** → FAB di tab "Permintaan" → `CreateRequestSheet`
- **Pesan Sesi Tutor** → Tombol "Pesan Sesi" di tab "Tutor" → `BookSessionSheet`
- **Tawarkan Bantuan** → Tombol di kartu permintaan → `BookSessionSheet`

### READ
- **Tab Permintaan** → Daftar semua `HelpRequest` dengan fitur search
- **Tab Tutor** → Daftar `TutorSession` dengan status online/offline
- **Tab Pemesananku** → Daftar `Booking` milik user

### UPDATE
- **Edit Pemesanan** → Tombol "Ubah" di kartu booking → `_EditBookingSheet`
- **Auto status update** → KP balance otomatis berubah saat pesan/batalkan

### DELETE
- **Hapus Permintaan** → Tombol hapus di kartu permintaan (dengan konfirmasi dialog)
- **Batalkan Pemesanan** → Tombol "Batalkan" + refund KP otomatis

---

## Cara Jalankan

```bash
cd edulink
flutter pub get
flutter run
```

## Langkah Selanjutnya

- [ ] Integrasikan dengan backend/API (Supabase / Firebase)
- [ ] Tambahkan autentikasi pengguna
- [ ] Real-time booking dengan WebSocket
- [ ] Sistem rating dan ulasan tutor
- [ ] Notifikasi push untuk status booking
