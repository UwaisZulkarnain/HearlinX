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
  String get contactCoordinator =>
      isMs ? 'Hubungi Penyelaras' : 'Contact Coordinator';
  String get forgotPinContactName => 'Siti Aminah Kamaludin (Mak Uda)';
  String get forgotPinContactPhone =>
      isMs ? 'Telefon: +6012-345-6789' : 'Phone: +6012-345-6789';
  String get forgotPinContactEmail => isMs
      ? 'Emel: p153232@siswa.ukm.edu.my'
      : 'Email: p153232@siswa.ukm.edu.my';
  String get forgotPinContactOffice =>
      'Pejabat: iCaRehab, Fakulti Sains Kesihatan, UKM';
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
  String get today => isMs ? 'Hari Ini' : 'Today';
  String get allHistory => isMs ? 'Semua Sejarah' : 'All History';
  String get allScreenings => isMs ? 'Semua Saringan' : 'All Screenings';
  String get noAllScreenings =>
      isMs ? 'Tiada saringan direkodkan' : 'No screenings recorded';
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
  String get ltfu => 'LTFU';
  String get ltfuRate => isMs ? 'Kadar LTFU' : 'LTFU Rate';
  String get overdue => isMs ? 'Lewat' : 'Overdue';
  String get newFollowup => isMs ? 'Baharu' : 'New';
  String get redRisk => isMs ? 'Risiko Tinggi' : 'High Risk';
  String get markContacted => isMs ? 'Tandakan Dihubungi' : 'Mark Contacted';
  String get bookAppointment => isMs ? 'Buat Temujanji' : 'Book Appointment';
  String get escalate => isMs ? 'Eskalasi' : 'Escalate';
  String get complete => isMs ? 'Selesai' : 'Complete';
  String get markLtfu => isMs ? 'Tanda LTFU' : 'Mark LTFU';
  String get followupDetails => isMs ? 'Butiran Susulan' : 'Follow-up Details';
  String get timeline => isMs ? 'Garis Masa' : 'Timeline';
  String get status => 'Status';
  String get appointmentDate => isMs ? 'Tarikh Temujanji' : 'Appointment Date';
  String get ltfuReason => isMs ? 'Sebab LTFU' : 'LTFU Reason';
  String get contactAttempts => isMs ? 'Cubaan Hubungan' : 'Contact Attempts';
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
  String get coordinator =>
      isMs ? 'Audiologis Hospital' : 'Hospital Audiologist';
  String get unhsCoordinator =>
      isMs ? 'Penyelaras UNHS Nasional' : 'National UNHS Coordinator';
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
  String get activeScreeners => isMs ? 'Penyaring Aktif' : 'Active Screeners';
  String get screeningType => isMs ? 'Jenis Saringan' : 'Screening Type';
  String get coverageRateTitle =>
      isMs ? 'Kadar Liputan Saringan' : 'Screening Coverage Rate';
  String get benchmarkTitle =>
      isMs ? 'Penanda Aras 1-3-6 KKM' : '1-3-6 KKM Benchmark';
  String get screenedBy1Month =>
      isMs ? 'Disaring dalam 1 bulan' : 'Screened within 1 month';
  String get diagnosedBy3Months =>
      isMs ? 'Diagnosis dalam 3 bulan' : 'Diagnosed within 3 months';
  String get kkmTarget => isMs ? 'Sasaran KKM: ≥90%' : 'KKM Target: ≥90%';
  String get wardBreakdown => isMs ? 'Pecahan Mengikut Wad' : 'Ward Breakdown';
  String get noWardData => isMs ? 'Tiada data wad' : 'No ward data';
  String get screenedToday => isMs ? 'Disaring Hari Ini' : 'Screened Today';
  String get restMessage =>
      isMs ? 'Beristirahat dan nikmati hari anda!' : 'Rest and enjoy your day!';
  String get coverageRate => isMs ? 'Kadar Liputan' : 'Coverage Rate';
  String get totalBabiesRegistered =>
      isMs ? 'Jumlah Bayi Terdaftar' : 'Total Babies Registered';
  String get lastUpdated => isMs ? 'Dikemas kini terakhir' : 'Last updated';
}
