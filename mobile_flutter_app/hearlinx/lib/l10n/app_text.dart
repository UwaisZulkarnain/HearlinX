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
  String get forgotPinContactName =>
      isMs ? 'Dr. Siti Aminah Kamaludin' : 'Dr. Siti Aminah Kamaludin';
  String get forgotPinContactPhone =>
      isMs ? 'Tel: +60 12-204 8848' : 'Tel: +60 12-204 8848';
  String get forgotPinContactEmail =>
      isMs ? 'Emel: sitiaminah@email.com' : 'Email: sitiaminah@email.com';
  String get forgotPinContactOffice => isMs
      ? 'Pejabat: Unit Audiologi, Hospital Kuala Lumpur'
      : 'Office: Audiology Unit, Hospital Kuala Lumpur';
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
  String get screeningDate => isMs ? 'Tarikh Saringan' : 'Screening Date';
  String get selectDate => isMs ? 'Pilih Tarikh' : 'Select Date';
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
      isMs ? 'Tiada saringan direkodkan.' : 'No screenings recorded.';
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
  String get statusLabel => 'Status';
  String get wardLabel => isMs ? 'Wad' : 'Ward';
  String get totalCount => isMs ? 'Jumlah' : 'Total';
  String get referCount => isMs ? 'Rujukan' : 'Referrals';
  String get ratePercentage => isMs ? 'Kadar %' : 'Rate %';
  String get dateLabel => isMs ? 'Tarikh' : 'Date';
  String get appointmentDate => isMs ? 'Tarikh Temujanji' : 'Appointment Date';
  String get ltfuReason => isMs ? 'Sebab LTFU' : 'LTFU Reason';
  String get contactAttempts => isMs ? 'Cubaan Hubungan' : 'Contact Attempts';
  String get connectionError => isMs ? 'Ralat Sambungan' : 'Connection Error';
  String get checkInternet => isMs
      ? 'Sila pastikan anda mempunyai sambungan internet dan cuba semula.'
      : 'Please ensure you have an internet connection and try again.';
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
  String get sessionExpired => isMs
      ? 'Sesi telah tamat. Sila log masuk semula.'
      : 'Session expired. Please sign in again.';
  String get serverDataError =>
      isMs ? 'Ralat data dari pelayan.' : 'Server data error.';
  String get slowConnection => isMs
      ? 'Sambungan lambat. Sila cuba semula.'
      : 'Connection is slow. Please try again.';
  String get noInternet => isMs
      ? 'Sambungan internet tiada. Sila cuba semula.'
      : 'No internet connection. Please try again.';
  String get unknownError => isMs ? 'Ralat tidak diketahui' : 'Unknown error';
  String get retry => isMs ? 'Cuba Semula' : 'Retry';
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
  String noResponseFor(String label) =>
      isMs ? 'Tiada respons untuk $label.' : 'No response for $label.';
  String get monthlyReportLabel => isMs ? 'laporan bulanan' : 'monthly report';
  String get followupListLabel => isMs ? 'senarai susulan' : 'follow-up list';
  String get todayScreeningsLabel =>
      isMs ? 'saringan hari ini' : 'today screenings';
  String get benchmarkLabel => isMs ? 'benchmark' : 'benchmark';
  String get coverageRateLabel => isMs ? 'kadar liputan' : 'coverage rate';
  String get wardBreakdownLabel => isMs ? 'pecahan wad' : 'ward breakdown';
  String get dashboardNoDataMessage => isMs
      ? 'Tiada data dashboard tersedia selepas dimuatkan. Cuba semula atau semak sambungan pelayan.'
      : 'No dashboard data is available after loading. Try again or check the server connection.';
  String get followupStatusUpdated => isMs
      ? 'Status susulan berjaya dikemas kini'
      : 'Follow-up status updated successfully';
  String get noDueDate => isMs ? 'Tiada tarikh' : 'No date';
  String get noTimelineEvents =>
      isMs ? 'Tiada peristiwa garis masa lagi.' : 'No timeline events yet.';

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
  String get viewAll => isMs ? 'Lihat Semua' : 'View All';
  String get more => isMs ? 'lagi' : 'more';
  String get versionUpToDate => isMs ? 'Versi terkini' : 'Up to date';
  String get updateApplied =>
      isMs ? 'Aplikasi telah dikemaskini' : 'Update applied';
  String get patchLabel => isMs ? 'Kemaskini Perisian' : 'Software Update';
  String get appVersion => 'v1.0.1';

  // Follow-up status translations
  String get statusPending => isMs ? 'Belum Selesai' : 'Pending';
  String get statusContacted => isMs ? 'Dihubungi' : 'Contacted';
  String get statusAppointmentBooked =>
      isMs ? 'Temujanji Ditetapkan' : 'Appointment Booked';
  String get statusEscalated => isMs ? 'Dinaik Taraf' : 'Escalated';
  String get statusCompleted => isMs ? 'Selesai' : 'Completed';
  String get statusLostToFollowup =>
      isMs ? 'Hilang Susulan' : 'Lost to Follow-up';
  String get statusClosed => isMs ? 'Ditutup' : 'Closed';

  // Timeline action translations
  String get actionCreatedFromRujuk =>
      isMs ? 'Dicipta dari saringan RUJUK' : 'Created from RUJUK screening';
  String get actionStatusChanged => isMs ? 'Status ditukar' : 'Status changed';
  String get actionContactAttempt =>
      isMs ? 'Cubaan hubungan' : 'Contact attempt';
  String get actionNoteAdded => isMs ? 'Nota ditambah' : 'Note added';
  String get actionAppointmentBooked =>
      isMs ? 'Temujanji ditetapkan' : 'Appointment booked';
  String get actionEscalated => isMs ? 'Kes dinaik taraf' : 'Case escalated';
  String get actionMarkedLtfu => isMs ? 'Tanda hilang susulan' : 'Marked LTFU';
  String get actionCompleted => isMs ? 'Kes selesai' : 'Case completed';

  // Status transition helper
  String get statusTo => isMs ? 'kepada' : 'to';

  // Follow-up detail modal labels
  String get followUpDetailTitle =>
      isMs ? 'Butiran Susulan' : 'Follow-up Details';
  String get babyIdLabel => isMs ? 'ID Bayi' : 'Baby ID';
  String get appointmentDateHint =>
      isMs ? 'Pilih tarikh & masa' : 'Select date & time';
  String get ltfuReasonLabel => isMs ? 'Sebab Hilang Susulan' : 'LTFU Reason';
  String get ltfuReasonHint => isMs ? 'Nyatakan sebab...' : 'Enter reason...';
  String get notesOptionalLabel => isMs ? 'Nota (pilihan)' : 'Notes (optional)';
  String get notesHint => isMs ? 'Tambah nota...' : 'Add notes...';
  String get contactAttemptsLabel =>
      isMs ? 'Cubaan Hubungan' : 'Contact Attempts';
  String get timelineTitle => isMs ? 'Garis Masa' : 'Timeline';
  String get timelineCount => isMs ? 'aktiviti' : 'events';
  String get saveChanges => isMs ? 'Simpan Perubahan' : 'Save Changes';
  String get tapToViewDetails =>
      isMs ? 'Ketik untuk butiran' : 'Tap for details';

  // Follow-up list page
  String get allFollowUpsTitle => isMs ? 'Senarai Susulan' : 'Follow-up List';
  String get searchByBabyId => isMs ? 'Cari ID Bayi...' : 'Search baby ID...';
  String get filterAll => isMs ? 'Semua' : 'All';
  String get filterLtfu => 'LTFU';
  String get filterRed => isMs ? 'Merah' : 'Red';
  String get filterAmber => isMs ? 'Oren' : 'Amber';
  String get filterNew => isMs ? 'Baharu' : 'New';
  String get noFollowUpsFound =>
      isMs ? 'Tiada susulan dijumpai' : 'No follow-ups found';
  String get dueDateLabel => isMs ? 'Tarikh Akhir' : 'Due Date';
  String get daysOverdueText => isMs ? 'hari lewat' : 'days overdue';

  // Confirmation dialogs
  String get confirmAction => isMs ? 'Sahkan Tindakan' : 'Confirm Action';
  String get confirmMarkLtfu => isMs
      ? 'Tanda bayi ini sebagai Hilang Susulan (LTFU)?'
      : 'Mark this baby as Lost to Follow-up (LTFU)?';
  String get confirmComplete =>
      isMs ? 'Tanda kes ini sebagai Selesai?' : 'Mark this case as Completed?';
  String get confirmEscalate => isMs
      ? 'Naik taraf kes ini kepada penyelia?'
      : 'Escalate this case to supervisor?';
  String get yes => isMs ? 'Ya' : 'Yes';
  String get no => isMs ? 'Tidak' : 'No';

  // Quick action success messages
  String get markedAsContacted => isMs ? 'Dihubungi' : 'Marked as Contacted';
  String get appointmentBooked =>
      isMs ? 'Temujanji Ditetapkan' : 'Appointment Booked';
  String get caseEscalated => isMs ? 'Kes Dinaik Taraf' : 'Case Escalated';
  String get caseCompleted => isMs ? 'Kes Selesai' : 'Case Completed';
  String get caseMarkedLtfu => isMs ? 'Hilang Susulan' : 'Lost to Follow-up';

  // Timeline quick action names
  String get actionQuickContacted =>
      isMs ? 'Dihubungi secara pantas' : 'Quick contacted';
  String get actionQuickAppointment =>
      isMs ? 'Temujanji pantas' : 'Quick appointment';
  String get actionQuickEscalated =>
      isMs ? 'Naik taraf pantas' : 'Quick escalated';
  String get actionQuickCompleted =>
      isMs ? 'Selesai pantas' : 'Quick completed';
  String get actionQuickLtfu => isMs ? 'LTFU pantas' : 'Quick LTFU';

  // Appointment booking dialog
  String get bookAppointmentTitle =>
      isMs ? 'Tetapkan Temujanji' : 'Book Appointment';
  String get appointmentDateLabel =>
      isMs ? 'Tarikh & Masa Temujanji' : 'Appointment Date & Time';
  String get confirmAppointment =>
      isMs ? 'Sahkan Temujanji' : 'Confirm Appointment';
  String get invalidDateFormat =>
      isMs ? 'Format tarikh tidak sah' : 'Invalid date format';

  // Escalation dialog
  String get escalateTitle => isMs ? 'Naik Taraf Kes' : 'Escalate Case';
  String get escalationReasonLabel =>
      isMs ? 'Sebab Pennaikan Taraf' : 'Escalation Reason';
  String get escalationReasonHint =>
      isMs ? 'Nyatakan sebab...' : 'Enter reason...';
  String get confirmEscalation =>
      isMs ? 'Sahkan Eskalasi' : 'Confirm Escalation';
}
