class AppText {
  const AppText(this.lang);

  final String lang;

  bool get isMs => lang == 'ms';

  String get welcome => isMs ? 'Selamat kembali' : 'Welcome back';
  String get subtitle =>
      isMs ? 'Log masuk ke akaun anda' : 'Sign in to your account';
  String get staffId => isMs ? 'ID Staf' : 'Staff ID';
  String get pin => 'PIN';
  String get signIn => isMs ? 'Log Masuk' : 'Sign In';
  String get invalidCreds =>
      isMs ? 'ID Staf atau PIN tidak sah' : 'Invalid Staff ID or PIN';
  String get hospital => 'Hospital';
  String get selectHospital => isMs ? 'Pilih Hospital' : 'Select Hospital';
  String get enterStaffId => isMs ? 'Masukkan ID Staf' : 'Enter Staff ID';
  String get enterPin => isMs ? 'Masukkan PIN' : 'Enter PIN';
  String get forgotPin => isMs
      ? 'Lupa PIN?\nHubungi Penyelaras'
      : 'Forgot PIN?\nContact Coordinator';
  String get appSubtitle => isMs
      ? 'Sistem Pengurusan Saringan Pendengaran Bayi'
      : 'Newborn Hearing Screening Management System';

  String get newScreening => isMs ? 'Saringan Baharu' : 'New Screening';
  String get scanQR => isMs ? 'Imbas Kod QR' : 'Scan QR Code';
  String get manualEntry => isMs ? 'Masukkan secara manual' : 'Enter manually';
  String get babyId => isMs ? 'ID Bayi' : 'Baby ID';
  String get ward => isMs ? 'Wad' : 'Ward';
  String get device => isMs ? 'Peranti Digunakan' : 'Device Used';
  String get leftEar => isMs ? 'Telinga Kiri' : 'Left Ear';
  String get rightEar => isMs ? 'Telinga Kanan' : 'Right Ear';
  String get pass => isMs ? 'LULUS' : 'PASS';
  String get refer => isMs ? 'RUJUK' : 'REFER';
  String get notes => isMs ? 'Nota (pilihan)' : 'Notes (optional)';
  String get submit => isMs ? 'Hantar' : 'Submit';
  String get shiftSummary => isMs ? 'Ringkasan Syif' : 'Shift Summary';
  String get myShiftSummary => isMs ? 'Ringkasan Syif' : 'Shift Summary';
  String get allSaved => isMs ? 'Semua Tersimpan' : 'All Saved';
  String get pendingSync =>
      isMs ? 'rekod belum disinkron' : 'records pending sync';
  String get continueText => isMs ? 'Teruskan' : 'Continue';
  String get typeBabyId => isMs ? 'Taip ID Bayi' : 'Enter Baby ID';
  String get enterBabyToContinue => isMs
      ? 'Masukkan ID bayi untuk meneruskan saringan'
      : 'Enter baby ID to continue screening';
  String get babyInfo => isMs ? 'Maklumat Bayi' : 'Baby Information';
  String get pointCameraQr =>
      isMs ? 'Arahkan kamera ke kod QR' : 'Point camera at QR code';
  String get todayScreenings =>
      isMs ? 'Saringan Hari Ini' : 'Today\'s Screenings';
  String get noTodayScreenings =>
      isMs ? 'Tiada saringan hari ini' : 'No screenings today';
  String get totalScreenedToday =>
      isMs ? 'Jumlah disaring hari ini' : 'Total screened today';
  String get totalPass => isMs ? 'Jumlah LULUS' : 'Total PASS';
  String get totalRefer => isMs ? 'Jumlah RUJUK' : 'Total REFER';

  String get dashboard => isMs ? 'Papan Pemuka' : 'Dashboard';
  String get hospitalDashboard =>
      isMs ? 'Papan Pemuka Hospital' : 'Hospital Dashboard';
  String get nationalDashboard =>
      isMs ? 'Dashboard Nasional' : 'National Dashboard';
  String get unhsDashboard => isMs ? 'Dashboard UNHS' : 'UNHS Dashboard';
  String get followupQueue => isMs ? 'Antrian Susulan' : 'Follow-up Queue';
  String get markContacted => isMs ? 'Tandakan Dihubungi' : 'Mark Contacted';
  String get bookAppointment => isMs ? 'Buat Temujanji' : 'Book Appointment';
  String get escalate => isMs ? 'Eskalasi' : 'Escalate';
  String get close => isMs ? 'Tutup' : 'Close';
  String get monthlyReport => isMs ? 'Laporan Bulanan' : 'Monthly Report';
  String get export => isMs ? 'Eksport' : 'Export';
  String get monthlySummary => isMs ? 'Ringkasan Bulanan' : 'Monthly Summary';
  String get noPendingFollowups =>
      isMs ? 'Tiada susulan tertunda.' : 'No pending follow-ups.';
  String get todayScreeningRecorded => isMs
      ? 'Tiada saringan direkodkan hari ini.'
      : 'No screenings recorded today.';

  String get logout => isMs ? 'Log Keluar' : 'Logout';
  String get loading => isMs ? 'Memuatkan...' : 'Loading...';
  String get error => isMs ? 'Sesuatu telah berlaku' : 'Something went wrong';
  String get retry => isMs ? 'Cuba semula' : 'Retry';
  String get cancel => isMs ? 'Batal' : 'Cancel';
  String get confirm => isMs ? 'Sahkan' : 'Confirm';
  String get save => isMs ? 'Simpan' : 'Save';
  String get back => isMs ? 'Kembali' : 'Back';
  String get welcomeHome => isMs ? 'Selamat datang' : 'Welcome';
  String get userLoadError => isMs
      ? 'Tidak dapat memuatkan profil pengguna.'
      : 'Unable to load user profile.';
  String get screener => isMs ? 'Penyaring' : 'Screener';
  String get coordinator => isMs ? 'Penyelaras' : 'Coordinator';
  String get unhsCoordinator => isMs ? 'Penyelaras UNHS' : 'UNHS Coordinator';
  String get user => isMs ? 'Pengguna' : 'User';
  String get totalScreenings => isMs ? 'Total Saringan' : 'Total Screenings';
  String get notTested => isMs ? 'Tidak diuji' : 'Not tested';
  String get recentAudit =>
      isMs ? 'Aktiviti Audit Terkini' : 'Recent Audit Activity';
  String get noAudit =>
      isMs ? 'Tiada aktiviti audit direkodkan.' : 'No audit activity recorded.';
  String get hospitalPerformance =>
      isMs ? 'Prestasi Mengikut Hospital' : 'Performance by Hospital';
  String get noNationalData =>
      isMs ? 'Tiada data kebangsaan tersedia.' : 'No national data available.';
  String get screening => isMs ? 'Saringan' : 'Screenings';

  // Coordinator Dashboard
  String welcomeGreeting(String name) => isMs
      ? 'Selamat datang, $name! Semoga hari anda produktif. 🌟'
      : 'Welcome, $name! Have a productive day. 🌟';
  String get lastScreening => isMs ? 'Saringan Terakhir' : 'Last Screening';
  String get coverageRate => isMs ? 'Kadar Liputan' : 'Coverage Rate';
  String get activeScreeners =>
      isMs ? 'Penyaring Aktif Hari Ini' : 'Active Screeners Today';
  String get totalBabiesRegistered =>
      isMs ? 'Jumlah Bayi Terdaftar' : 'Total Babies Registered';
  String get lastUpdated => isMs ? 'Dikemas kini terakhir' : 'Last updated';
}
