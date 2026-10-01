// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Washly';

  @override
  String get commonCancel => 'Batal';

  @override
  String get commonSave => 'Simpan';

  @override
  String get commonDone => 'Selesai';

  @override
  String get commonAdd => 'Tambah';

  @override
  String get commonRemove => 'Hapus';

  @override
  String get commonDelete => 'Hapus';

  @override
  String get commonRetry => 'Coba lagi';

  @override
  String get commonClose => 'Tutup';

  @override
  String get commonApply => 'Terapkan';

  @override
  String get commonConfirm => 'Konfirmasi';

  @override
  String get commonLoading => 'Memuat';

  @override
  String get commonError => 'Terjadi kesalahan.';

  @override
  String get navHome => 'Beranda';

  @override
  String get navDiscovery => 'Jelajah';

  @override
  String get navOrders => 'Pesanan';

  @override
  String get navAccount => 'Akun';

  @override
  String get navActive => 'Aktif';

  @override
  String get navHistory => 'Riwayat';

  @override
  String get navProfile => 'Profil';

  @override
  String get navOffers => 'Tawaran';

  @override
  String get navDashboard => 'Dasbor';

  @override
  String get navServices => 'Layanan';

  @override
  String get languageEnglish => 'Inggris';

  @override
  String get languageIndonesian => 'Indonesia';

  @override
  String get changeLanguageTitle => 'Bahasa';

  @override
  String get changeLanguageSaved => 'Bahasa diperbarui.';

  @override
  String get orderStatusPendingAcceptance => 'Menunggu mitra';

  @override
  String get orderStatusAccepted => 'Diterima';

  @override
  String get orderStatusDriverAssigned => 'Driver ditugaskan';

  @override
  String get orderStatusPickedUp => 'Diambil dari Anda';

  @override
  String get orderStatusAtLaundromat => 'Di laundry';

  @override
  String get orderStatusWeighedAwaitingConfirm => 'Menunggu konfirmasi Anda';

  @override
  String get orderStatusAwaitingPayment => 'Menunggu pembayaran';

  @override
  String get orderStatusWashing => 'Dicuci';

  @override
  String get orderStatusReadyForDelivery => 'Siap diantar';

  @override
  String get orderStatusOutForDelivery => 'Dalam pengantaran';

  @override
  String get orderStatusCompleted => 'Selesai';

  @override
  String get orderStatusCancelled => 'Dibatalkan';

  @override
  String get orderStatusUnknown => 'Tidak diketahui';

  @override
  String get timelinePlaced => 'Dibuat';

  @override
  String get timelineAccepted => 'Diterima';

  @override
  String get timelinePickup => 'Penjemputan';

  @override
  String get timelineWashing => 'Dicuci';

  @override
  String get timelineOnTheWay => 'Dalam perjalanan';

  @override
  String get timelineCompleted => 'Selesai';

  @override
  String get timelineOrderCancelled => 'Pesanan dibatalkan';

  @override
  String get commonEmailLabel => 'Email';

  @override
  String get commonPasswordLabel => 'Kata sandi';

  @override
  String get commonPhoneLabel => 'Nomor telepon';

  @override
  String get commonFullNameLabel => 'Nama lengkap';

  @override
  String get commonConfirmPasswordLabel => 'Konfirmasi kata sandi';

  @override
  String get commonCreateAccount => 'Buat akun';

  @override
  String get commonEmailRequired => 'Email wajib diisi';

  @override
  String get commonEmailInvalid => 'Masukkan email yang valid';

  @override
  String get commonPasswordRequired => 'Kata sandi wajib diisi';

  @override
  String get commonPasswordTooShort => 'Minimal 6 karakter';

  @override
  String get commonConfirmPasswordRequired =>
      'Harap konfirmasi kata sandi Anda';

  @override
  String get commonPasswordsDoNotMatch => 'Kata sandi tidak cocok';

  @override
  String commonFieldRequired(String label) {
    return '$label wajib diisi';
  }

  @override
  String get commonShowPassword => 'Tampilkan kata sandi';

  @override
  String get commonHidePassword => 'Sembunyikan kata sandi';

  @override
  String get loginTitle => 'Selamat datang kembali';

  @override
  String get loginSubtitle => 'Masuk untuk melanjutkan.';

  @override
  String get loginSubmit => 'Masuk';

  @override
  String get loginNoAccountQuestion => 'Belum punya akun?';

  @override
  String get loginRegisterAction => 'Daftar';

  @override
  String get roleSelectTitle => 'Selamat datang di Washly';

  @override
  String get roleSelectSubtitle => 'Pilih cara Anda bergabung.';

  @override
  String get roleSelectCustomerTitle => 'Pelanggan';

  @override
  String get roleSelectCustomerSubtitle => 'Pesan antar-jemput cucian';

  @override
  String get roleSelectPartnerTitle => 'Mitra Laundry';

  @override
  String get roleSelectPartnerSubtitle => 'Kelola toko dan pesanan Anda';

  @override
  String get roleSelectDriverTitle => 'Driver';

  @override
  String get roleSelectDriverSubtitle => 'Ambil dan antar pesanan';

  @override
  String get roleSelectHaveAccountQuestion => 'Sudah punya akun?';

  @override
  String get roleSelectLoginAction => 'Masuk';

  @override
  String get registerCustomerTitle => 'Daftar pelanggan';

  @override
  String get registerDriverTitle => 'Daftar driver';

  @override
  String get registerDriverVehicleTypeLabel => 'Jenis kendaraan (mis. motor)';

  @override
  String get registerDriverPlateNumberLabel => 'Nomor pelat';

  @override
  String get registerPartnerTitle => 'Daftar mitra';

  @override
  String get registerPartnerSelectSpecialty =>
      'Pilih setidaknya satu spesialisasi.';

  @override
  String get registerPartnerSectionAccount => 'Akun';

  @override
  String get registerPartnerSectionBusiness => 'Bisnis';

  @override
  String get registerPartnerSectionSpecialties => 'Spesialisasi';

  @override
  String get registerPartnerOwnerNameLabel => 'Nama pemilik';

  @override
  String get registerPartnerBusinessNameLabel => 'Nama bisnis';

  @override
  String get registerPartnerBusinessAddressLabel => 'Alamat bisnis';

  @override
  String get registerPartnerLatitudeLabel => 'Lintang';

  @override
  String get registerPartnerLongitudeLabel => 'Bujur';

  @override
  String get registerPartnerCoordinateInvalid => 'Masukkan angka yang valid';

  @override
  String get registerPartnerPricingModelLabel => 'Model harga';

  @override
  String get registerPartnerPricingPerKg => 'Per kilogram';

  @override
  String get registerPartnerPricingPerItem => 'Per item';

  @override
  String get registerPartnerSpecialtyShoes => 'sepatu';

  @override
  String get registerPartnerSpecialtyBags => 'tas';

  @override
  String get registerPartnerSpecialtyDolls => 'boneka';

  @override
  String get registerPartnerSpecialtyCostumes => 'kostum';

  @override
  String get registerPartnerSpecialtyExpress => 'ekspres';

  @override
  String get registerPartnerSpecialtyIroning => 'setrika';

  @override
  String get registerPartnerSpecialtyKiloan => 'kiloan';

  @override
  String get registerPartnerSpecialtyDryClean => 'cuci kering';

  @override
  String get accountSettingsTitle => 'Pengaturan akun';

  @override
  String get accountLogoutTitle => 'Keluar';

  @override
  String get accountLogoutConfirm => 'Apakah Anda yakin ingin keluar?';

  @override
  String get accountShopProfile => 'Profil toko';

  @override
  String get accountEditProfile => 'Edit Profil';

  @override
  String get accountChangePassword => 'Ubah Kata Sandi';

  @override
  String get accountChangeLanguage => 'Ubah Bahasa';

  @override
  String get editProfileTitle => 'Edit Profil';

  @override
  String get editProfileChangePhoto => 'Ubah foto';

  @override
  String get editProfilePhotoUpdated => 'Foto diperbarui.';

  @override
  String editProfilePickerError(String error) {
    return 'Tidak dapat membuka pemilih: $error';
  }

  @override
  String get editProfileUpdated => 'Profil diperbarui.';

  @override
  String get editProfileNameLabel => 'Nama';

  @override
  String get editProfileNameRequired => 'Nama wajib diisi';

  @override
  String get editProfilePhoneRequired => 'Nomor telepon wajib diisi';

  @override
  String get editProfileSave => 'Simpan profil';

  @override
  String get navVouchers => 'Voucher';

  @override
  String get commonSeeAll => 'Lihat semua';

  @override
  String get commonRedeem => 'Tukar';

  @override
  String get commonSubmit => 'Kirim';

  @override
  String get commonPost => 'Kirim';

  @override
  String get commonNotNow => 'Nanti saja';

  @override
  String orderN(int id) {
    return 'Pesanan #$id';
  }

  @override
  String orderNumber(int id) {
    return '#$id';
  }

  @override
  String moneyRp(String amount) {
    return 'Rp $amount';
  }

  @override
  String moneyRpOff(String amount) {
    return 'Potongan Rp $amount';
  }

  @override
  String moneyRpNegative(String amount) {
    return '- Rp $amount';
  }

  @override
  String get serviceTagShoes => 'Sepatu';

  @override
  String get serviceTagBags => 'Tas';

  @override
  String get serviceTagDolls => 'Boneka';

  @override
  String get serviceTagCostumes => 'Kostum';

  @override
  String get serviceTagExpress => 'Ekspres';

  @override
  String get serviceTagIroning => 'Setrika';

  @override
  String get serviceTagKiloan => 'Kiloan';

  @override
  String get serviceTagDryClean => 'Cuci Kering';

  @override
  String get sortTopRated => 'Rating Teratas';

  @override
  String get sortNearest => 'Terdekat';

  @override
  String get filterServices => 'Filter Layanan';

  @override
  String filterServicesCount(int count) {
    return 'Layanan ($count)';
  }

  @override
  String get filterReset => 'Atur ulang';

  @override
  String filterApplyCount(int count) {
    return 'Terapkan Filter ($count)';
  }

  @override
  String get homeSpecialties => 'Spesialisasi';

  @override
  String get homeSearchHint => 'Cari laundry';

  @override
  String get homeWelcomeBack => 'Selamat datang kembali!';

  @override
  String get homeGreetingFallback => 'di sana';

  @override
  String get homeLoyaltyWallet => 'Dompet loyalitas';

  @override
  String homePoints(int count) {
    return '$count poin';
  }

  @override
  String get homeRedeemPrompt => 'Tukarkan poin Anda dengan voucher.';

  @override
  String homeVouchersReady(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count voucher siap dipakai saat checkout.',
      one: '$count voucher siap dipakai saat checkout.',
    );
    return '$_temp0';
  }

  @override
  String get homeActiveOrders => 'Pesanan Aktif';

  @override
  String get homeNoActiveOrders => 'Belum ada pesanan aktif saat ini.';

  @override
  String get homeYourOrder => 'Pesanan Anda';

  @override
  String homeTapToTrack(int id) {
    return 'Pesanan #$id · ketuk untuk melacak';
  }

  @override
  String get homeActionConfirmWeighedPrice =>
      'Perlu tindakan: konfirmasi harga timbangan Anda';

  @override
  String get homeNearbyLaundromats => 'Laundry Terdekat';

  @override
  String get homeNoLaundromatsYet => 'Belum ada laundry yang tersedia.';

  @override
  String get ordersTitle => 'Pesanan Saya';

  @override
  String get ordersEmptyActive =>
      'Belum ada pesanan aktif. Buat satu dari Jelajah.';

  @override
  String get ordersEmptyHistory => 'Belum ada pesanan sebelumnya.';

  @override
  String get ordersLaundromatFallback => 'Laundry';

  @override
  String ordersItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count item',
      one: '$count item',
    );
    return '$_temp0';
  }

  @override
  String get ordersPerKgSuffix => 'per kg';

  @override
  String get ordersActionConfirmPrice => 'Perlu tindakan: konfirmasi harga';

  @override
  String get ordersWeighedAtPickup => 'Ditimbang saat penjemputan';

  @override
  String get vouchersTitle => 'Voucher';

  @override
  String vouchersRedeemedToast(String amount) {
    return 'Berhasil menukar voucher Rp $amount!';
  }

  @override
  String get vouchersRedeemPoints => 'Tukar Poin';

  @override
  String get vouchersRedeemSubtitle =>
      'Pilih hadiah untuk ditukar dengan poin Anda.';

  @override
  String get vouchersNoRewards => 'Belum ada hadiah yang tersedia saat ini.';

  @override
  String get vouchersYourVouchers => 'Voucher Anda';

  @override
  String get vouchersEmpty =>
      'Belum ada voucher. Tukarkan poin untuk mendapatkannya.';

  @override
  String get vouchersEarnRate =>
      'Dapatkan 5 poin per Rp 10.000 yang dibelanjakan.';

  @override
  String vouchersTierPoints(int count) {
    return '$count poin';
  }

  @override
  String vouchersNeedMorePoints(int count) {
    return 'Butuh $count poin lagi';
  }

  @override
  String get vouchersUsed => 'Terpakai';

  @override
  String get vouchersAvailableAtCheckout => 'Tersedia saat checkout';

  @override
  String get voucherSelectTitle => 'Terapkan voucher';

  @override
  String voucherSelectCountAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count voucher tersedia',
      one: '$count voucher tersedia',
    );
    return '$_temp0';
  }

  @override
  String get voucherSelectRemoveApplied => 'Hapus voucher yang diterapkan';

  @override
  String get voucherSelectDiscountVoucher => 'Voucher diskon';

  @override
  String get voucherSelectEmptyTitle => 'Tidak ada voucher';

  @override
  String get voucherSelectEmptyBody =>
      'Tukarkan poin loyalitas Anda dengan voucher, lalu terapkan di sini.';

  @override
  String get searchHint => 'Cari nama, layanan, atau area';

  @override
  String get searchPrompt => 'Ketik nama, layanan, atau area, lalu tekan cari.';

  @override
  String get searchNoMatches =>
      'Tidak ada laundry yang cocok dengan pencarian Anda.';

  @override
  String discoveryError(String error) {
    return 'Kesalahan: $error';
  }

  @override
  String get discoveryNoLaundromats => 'Tidak ada laundry ditemukan.';

  @override
  String discoveryReviewCount(int count) {
    return '($count)';
  }

  @override
  String discoveryDistanceKm(String distance) {
    return '$distance km';
  }

  @override
  String get discoveryAreaHidden => 'Area ditampilkan setelah pemesanan';

  @override
  String detailReviewsCount(int count) {
    return 'Ulasan ($count)';
  }

  @override
  String detailReviewCountSuffix(int count) {
    return ' ($count ulasan)';
  }

  @override
  String get detailAreaHidden => 'Area disembunyikan hingga penjemputan';

  @override
  String get detailServicesMenu => 'Menu Layanan';

  @override
  String get detailNoServices => 'Belum ada layanan yang terdaftar.';

  @override
  String detailCustomerReviews(int count) {
    return '$count Ulasan Pelanggan';
  }

  @override
  String get detailAddReview => 'Tambah Ulasan';

  @override
  String get detailNoReviews => 'Belum ada ulasan. Jadilah yang pertama!';

  @override
  String get detailWriteReview => 'Tulis Ulasan';

  @override
  String get detailYourReview => 'Ulasan Anda';

  @override
  String get detailSignInToReview => 'Silakan masuk untuk memberi ulasan.';

  @override
  String detailReviewFailed(String error) {
    return 'Gagal: $error';
  }

  @override
  String detailPricePerUnit(String price, String unit) {
    return 'Rp $price / $unit';
  }

  @override
  String get detailUnitKg => 'kg';

  @override
  String get detailUnitItem => 'item';

  @override
  String get detailQuantityOfItems => 'Jumlah Item';

  @override
  String detailPieces(int count) {
    return '$count pcs';
  }

  @override
  String detailPerKgNote(String price) {
    return 'Dihargai per berat Rp $price/kg. Laundry menimbang cucian Anda setelah penjemputan dan mengirim harganya — Anda menyetujuinya sebelum membayar.';
  }

  @override
  String get detailWashingInstructions => 'Instruksi Pencucian (Opsional)';

  @override
  String get detailItemDetailsHint =>
      'Detail Item (mis. 2 Nike Dunks, 1 tas Coach)';

  @override
  String get detailAddToBasket => 'Tambah ke Keranjang';

  @override
  String detailAddToBasketPrice(String price) {
    return 'Tambah ke Keranjang • Rp $price';
  }

  @override
  String get detailNewBasketTitle => 'Mulai keranjang baru?';

  @override
  String detailNewBasketBody(String name, String store) {
    return 'Keranjang Anda berisi item dari $name. Menambahkan ini akan mengosongkannya dan memulai keranjang baru di $store.';
  }

  @override
  String get detailAnotherLaundromat => 'laundry lain';

  @override
  String get detailClearAndAdd => 'Kosongkan & tambah';

  @override
  String get detailInBasket => 'Di keranjang';

  @override
  String detailItemsInBasket(int count) {
    return '$count item di keranjang';
  }

  @override
  String get detailWeighedAtPickupArrow => 'Ditimbang saat penjemputan  ➔';

  @override
  String detailBasketTotalArrow(String amount) {
    return 'Rp $amount  ➔';
  }

  @override
  String get orderDetailTitle => 'Detail Pesanan';

  @override
  String get orderDetailPriceApprovedToast =>
      'Harga disetujui. Lanjut ke pembayaran.';

  @override
  String get orderDetailPaymentReceived => 'Pembayaran diterima.';

  @override
  String get orderDetailPaymentPending => 'Pembayaran menunggu konfirmasi.';

  @override
  String get orderDetailPaymentFailed =>
      'Pembayaran gagal. Anda dapat mencoba lagi.';

  @override
  String get orderDetailPaymentClosed => 'Jendela pembayaran ditutup.';

  @override
  String get orderDetailPaymentLaunched =>
      'Pembayaran dibuka. Pesanan ini diperbarui setelah dikonfirmasi.';

  @override
  String get orderDetailDriverPickingUp => 'Driver menjemput cucian Anda';

  @override
  String get orderDetailDriverDelivering => 'Driver mengantar cucian Anda';

  @override
  String get orderDetailLookingForPickup =>
      'Mencari driver untuk menjemput cucian Anda';

  @override
  String get orderDetailLookingForDelivery =>
      'Mencari driver untuk mengantar cucian Anda';

  @override
  String get orderDetailVehicleFallback => 'Kendaraan';

  @override
  String get orderDetailLaundromatFallback => 'Laundry';

  @override
  String get orderDetailConfirmWeighedPrice =>
      'Konfirmasi harga timbangan Anda';

  @override
  String get orderDetailWeighedExplainer =>
      'Laundry telah menimbang cucian Anda. Tinjau harga dan item Anda di bawah, lalu setujui untuk lanjut ke pembayaran.';

  @override
  String get orderDetailMeasuredWeight => 'Berat terukur';

  @override
  String orderDetailKg(String value) {
    return '$value kg';
  }

  @override
  String get orderDetailWashSubtotal => 'Subtotal cuci';

  @override
  String get orderDetailDeliveryFee => 'Biaya pengantaran';

  @override
  String get orderDetailDeclaredProtection =>
      'Perlindungan item dideklarasikan';

  @override
  String get orderDetailVoucher => 'Voucher';

  @override
  String get orderDetailFinalPrice => 'Harga akhir';

  @override
  String get orderDetailApproveContinue => 'Setujui & lanjut ke pembayaran';

  @override
  String orderDetailDeclaredReceived(int received, int total) {
    return 'Item dideklarasikan  ($received/$total diterima)';
  }

  @override
  String get orderDetailNotReceived => 'Tidak diterima';

  @override
  String get orderDetailPaymentRequired => 'Pembayaran diperlukan';

  @override
  String get orderDetailAmountDue => 'Jumlah tagihan';

  @override
  String get orderDetailPayNow => 'Bayar sekarang';

  @override
  String get orderDetailProgress => 'Progres';

  @override
  String get orderDetailReceipt => 'Struk';

  @override
  String get orderDetailSubtotal => 'Subtotal';

  @override
  String get orderDetailWeighed => 'Ditimbang';

  @override
  String get orderDetailGrandTotal => 'Total keseluruhan';

  @override
  String get orderDetailAfterWeighing => 'Setelah ditimbang';

  @override
  String get orderDetailPayment => 'Pembayaran';

  @override
  String get orderDetailPaymentNotStarted => 'Belum dimulai';

  @override
  String get orderDetailUnitKg => 'kg';

  @override
  String get orderDetailUnitPcs => 'pcs';

  @override
  String get orderDetailDeclaredItems => 'Item dideklarasikan';

  @override
  String get orderDetailReceived => 'Diterima';

  @override
  String get orderDetailAwaitingIntake => 'Menunggu penerimaan';

  @override
  String get orderDetailHowDidItGo => 'Bagaimana hasilnya?';

  @override
  String get orderDetailRateLaundromat => 'Beri rating laundry';

  @override
  String get orderDetailWarranty => 'Garansi';

  @override
  String get orderDetailWarrantyOnlyDeclared =>
      'Garansi hanya tersedia untuk item dideklarasikan yang dikonfirmasi laundry saat penerimaan.';

  @override
  String get orderDetailWarrantyClaims => 'Klaim garansi';

  @override
  String get orderDetailNoClaims =>
      'Belum ada klaim diajukan. Ketuk \"Garansi\" di atas jika ada masalah dengan item dideklarasikan.';

  @override
  String get orderDetailRateThisLaundromat => 'Beri rating laundry ini';

  @override
  String get orderDetailAddCommentOptional => 'Tambahkan komentar (opsional)';

  @override
  String get orderDetailSignInToRate => 'Silakan masuk untuk memberi rating.';

  @override
  String get orderDetailRatingThanks => 'Terima kasih atas rating Anda!';

  @override
  String get orderDetailUseWarrantyTitle => 'Gunakan garansi Anda?';

  @override
  String get orderDetailWarrantyExplainer =>
      'Item yang Anda deklarasikan dilindungi garansi Washly. Jika salah satu hilang atau rusak, Anda dapat mengajukan klaim dengan foto dan laundry akan meninjaunya.';

  @override
  String get orderDetailCoveredItems => 'Item yang dilindungi';

  @override
  String get orderDetailFileClaim => 'Ajukan klaim';

  @override
  String orderDetailItemFallback(int id) {
    return 'Item #$id';
  }

  @override
  String orderDetailResolution(String note) {
    return 'Penyelesaian: $note';
  }

  @override
  String orderDetailPayout(String amount) {
    return 'Pembayaran: Rp $amount (Washly)';
  }

  @override
  String get orderDetailFileClaimTitle => 'Ajukan klaim garansi';

  @override
  String get orderDetailItem => 'Item';

  @override
  String get orderDetailWhatWentWrong => 'Apa yang terjadi?';

  @override
  String get orderDetailPickItemDescribe =>
      'Pilih item dan jelaskan masalahnya.';

  @override
  String get orderDetailAddPhoto => 'Tambah foto';

  @override
  String orderDetailPhotosAttached(int count) {
    return '$count terlampir';
  }

  @override
  String get orderDetailSubmitClaim => 'Kirim klaim';

  @override
  String get orderDetailClaimSubmitted => 'Klaim terkirim.';

  @override
  String get checkoutTitle => 'Checkout Pesanan';

  @override
  String checkoutPickerError(String error) {
    return 'Tidak dapat membuka pemilih: $error';
  }

  @override
  String get checkoutLabelItemTitle => 'Beri label item ini';

  @override
  String get checkoutLabelItemHint => 'mis. Nike Air Force 1 Putih';

  @override
  String get checkoutEnterPickupAddress =>
      'Silakan masukkan alamat penjemputan Anda.';

  @override
  String get checkoutSignInToOrder =>
      'Silakan masuk lagi untuk membuat pesanan.';

  @override
  String get checkoutPaymentReceivedTitle => 'Pembayaran diterima';

  @override
  String get checkoutPaymentReceivedBody =>
      'Terima kasih! Pembayaran Anda telah dikonfirmasi. Lacak pesanan ini di tab Pesanan.';

  @override
  String get checkoutPaymentPendingTitle => 'Pembayaran menunggu';

  @override
  String get checkoutPaymentPendingBody =>
      'Pembayaran Anda sedang diproses. Pesanan ini diperbarui otomatis setelah dikonfirmasi.';

  @override
  String get checkoutPaymentNotCompletedTitle => 'Pembayaran belum selesai';

  @override
  String get checkoutPaymentNotCompletedBody =>
      'Anda menutup jendela pembayaran. Pesanan Anda tersimpan — Anda dapat membayar dari tab Pesanan kapan saja.';

  @override
  String get checkoutPaymentFailedTitle => 'Pembayaran gagal';

  @override
  String get checkoutPaymentFailedBody =>
      'Pembayaran tidak berhasil. Pesanan Anda tersimpan — coba lagi dari tab Pesanan.';

  @override
  String get checkoutCompletePaymentTitle => 'Selesaikan pembayaran Anda';

  @override
  String get checkoutCompletePaymentBody =>
      'Kami membuka halaman pembayaran. Pesanan ini diperbarui otomatis setelah pembayaran dikonfirmasi.';

  @override
  String get checkoutOrderPlacedTitle => 'Pesanan dibuat';

  @override
  String checkoutOrderPlacedPaymentError(String error) {
    return 'Pesanan Anda dibuat, tetapi kami tidak dapat membuka pembayaran: $error. Anda dapat membayar dari tab Pesanan.';
  }

  @override
  String get checkoutPerKgPlacedTitle => 'Pesanan Dibuat';

  @override
  String get checkoutPerKgPlacedBody =>
      'Pesanan Anda menunggu laundry untuk menerimanya. Harga akhir ditetapkan setelah cucian Anda ditimbang — Anda membayar kemudian.';

  @override
  String get checkoutDeliveryPickupDetails =>
      'Detail Pengantaran & Penjemputan';

  @override
  String get checkoutPickupAddressLabel => 'Alamat Penjemputan & Pengembalian';

  @override
  String get checkoutNotesLabel => 'Catatan untuk driver / laundry (opsional)';

  @override
  String get checkoutNotesHint =>
      'mis. Titipkan ke satpam, rumah berpagar hitam';

  @override
  String get checkoutOrderSummary => 'Ringkasan Pesanan';

  @override
  String get checkoutDeclaredItemsOptional => 'Item dideklarasikan (opsional)';

  @override
  String get checkoutDeclaredExplainer =>
      'Item dideklarasikan adalah barang berharga yang Anda foto sebelum penjemputan — seperti jaket, sepatu bermerek, atau seprai.';

  @override
  String get checkoutDeclaredBenefit =>
      'Foto tersebut adalah bukti kondisi saat penyerahan, sehingga Anda dapat mengajukan klaim garansi jika suatu item hilang atau rusak.';

  @override
  String checkoutDeclaredFeeNote(String fee) {
    return 'Menambahkan item dideklarasikan menerapkan biaya perlindungan satu kali Rp $fee pada pesanan ini.';
  }

  @override
  String get checkoutVoucherApplied => 'Voucher diterapkan';

  @override
  String get checkoutApplyVoucher => 'Terapkan voucher';

  @override
  String get checkoutPlaceOrder => 'Buat Pesanan';

  @override
  String checkoutPricePerKg(String price) {
    return 'Rp $price/kg';
  }

  @override
  String checkoutPiecesPrefix(int count) {
    return '${count}pcs x ';
  }

  @override
  String get checkoutEstimatedWashPerKg => 'Estimasi cuci (per kg)';

  @override
  String get checkoutWashSubtotal => 'Subtotal Cuci';

  @override
  String get checkoutWeighedAtPickup => 'Ditimbang saat penjemputan';

  @override
  String get checkoutDeclaredProtection => 'Perlindungan item dideklarasikan';

  @override
  String get checkoutVoucher => 'Voucher';

  @override
  String get checkoutPickupDeliveryFee => 'Biaya Penjemputan & Pengantaran';

  @override
  String get checkoutCalculatedAtPickup => 'Dihitung saat penjemputan';

  @override
  String get checkoutFinalPrice => 'Harga akhir';

  @override
  String get checkoutTotalBeforeFee => 'Total (sebelum biaya)';

  @override
  String get checkoutAfterWeighing => 'Setelah ditimbang';

  @override
  String get checkoutPerKgFooter =>
      'Cucian Anda dihargai per berat. Anda menyetujui harga akhir setelah ditimbang, lalu membayar.';

  @override
  String get checkoutPerItemFooter =>
      'Biaya pengantaran dihitung dari jarak penjemputan saat Anda membuat pesanan.';

  @override
  String get partnerDashboardTitle => 'Dasbor';

  @override
  String get partnerDashboardReport => 'Laporan';

  @override
  String partnerDashboardReportSaved(String where) {
    return 'Laporan disimpan ke $where.';
  }

  @override
  String get partnerDashboardRangeDay => 'Hari ini';

  @override
  String get partnerDashboardRangeMonth => 'Bulan ini';

  @override
  String get partnerDashboardRangeYear => 'Tahun ini';

  @override
  String get partnerDashboardRevenue => 'Pendapatan (pesanan dibayar)';

  @override
  String get partnerDashboardInProcess => 'Diproses';

  @override
  String get partnerDashboardCompleted => 'Selesai';

  @override
  String get partnerDashboardTotalOrders => 'Total pesanan';

  @override
  String partnerDashboardAvgReview(int count) {
    return 'Rata-rata ulasan · $count';
  }

  @override
  String get partnerDashboardNoReviewsYet => 'Belum ada ulasan';

  @override
  String get partnerDashboardSalesByProduct => 'Penjualan per produk';

  @override
  String get partnerDashboardNoSales => 'Belum ada penjualan pada periode ini.';

  @override
  String get partnerDashboardRevenueAxis => 'Pendapatan';

  @override
  String get partnerOrdersTitle => 'Pesanan';

  @override
  String partnerOrdersActiveTab(int count) {
    return 'Aktif ($count)';
  }

  @override
  String partnerOrdersDoneTab(int count) {
    return 'Selesai ($count)';
  }

  @override
  String get partnerOrdersEmptyActive => 'Belum ada pesanan aktif.';

  @override
  String get partnerOrdersEmptyDone =>
      'Belum ada pesanan selesai atau dibatalkan.';

  @override
  String get partnerOrdersOpenForOrders => 'Menerima pesanan';

  @override
  String get partnerOrdersClosed => 'Tutup';

  @override
  String get partnerOrdersOpenHint =>
      'Pelanggan dapat membuat pesanan di toko Anda.';

  @override
  String get partnerOrdersClosedHint =>
      'Toko Anda disembunyikan dari pesanan baru.';

  @override
  String get partnerOrdersPerKg => 'Per kg';

  @override
  String get partnerOrdersPerItem => 'Per item';

  @override
  String partnerOrdersItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count item',
      one: '$count item',
    );
    return '$_temp0';
  }

  @override
  String get partnerOrdersNeedsWarranty => 'Perlu persetujuan garansi';

  @override
  String get partnerOrdersWeighedAtPickup => 'Ditimbang saat penjemputan';

  @override
  String get partnerOrderDetailNotFound => 'Pesanan tidak ditemukan.';

  @override
  String get partnerOrderDetailPerKgOrder => 'Pesanan per kg';

  @override
  String get partnerOrderDetailPerItemOrder => 'Pesanan per item';

  @override
  String get partnerOrderDetailItems => 'Item';

  @override
  String get partnerOrderDetailDeclaredItems => 'Item dideklarasikan';

  @override
  String get partnerOrderDetailProgress => 'Progres';

  @override
  String get partnerOrderDetailWarrantyClaims => 'Klaim garansi';

  @override
  String get partnerOrderDetailNeedsWarranty => 'Perlu persetujuan garansi';

  @override
  String get partnerOrderDetailReceived => 'Diterima';

  @override
  String get partnerOrderDetailAwaitingAcceptance => 'Menunggu penerimaan';

  @override
  String get partnerOrderDetailNotReceived => 'Tidak diterima';

  @override
  String get partnerOrderDetailVehicleFallback => 'Kendaraan';

  @override
  String get partnerOrderDetailClaimPhoto => 'Foto klaim';

  @override
  String get partnerOrderDetailWaitWashAfterPayment =>
      'Menunggu pencucian dimulai setelah pembayaran.';

  @override
  String get partnerOrderDetailWaitCustomerApprove =>
      'Menunggu pelanggan menyetujui harga timbangan.';

  @override
  String get partnerOrderDetailWaitCustomerPay =>
      'Menunggu pelanggan membayar.';

  @override
  String get partnerOrderDetailWaitDriverPickup => 'Menunggu driver menjemput.';

  @override
  String get partnerOrderDetailOutForDelivery => 'Dalam pengantaran.';

  @override
  String get partnerOrderDetailDriverBringingIn =>
      'Driver membawa cucian masuk';

  @override
  String get partnerOrderDetailDriverTakingOut =>
      'Driver membawa cucian keluar untuk diantar';

  @override
  String get partnerOrderDetailLookingForDriver =>
      'Mencari driver untuk mengantar cucian';

  @override
  String get partnerOrderDetailReject => 'Tolak';

  @override
  String get partnerOrderDetailAccept => 'Terima';

  @override
  String get partnerOrderDetailOrderRejected => 'Pesanan ditolak.';

  @override
  String get partnerOrderDetailOrderAccepted => 'Pesanan diterima.';

  @override
  String get partnerOrderDetailReceiveAndWeigh => 'Terima & timbang';

  @override
  String get partnerOrderDetailConfirmReceived => 'Konfirmasi diterima';

  @override
  String get partnerOrderDetailMarkReady => 'Tandai siap diantar';

  @override
  String get partnerOrderDetailMarkedReady => 'Ditandai siap diantar.';

  @override
  String get partnerOrderDetailConfirmArrived =>
      'Konfirmasi cucian telah tiba untuk melanjutkan.';

  @override
  String get partnerOrderDetailConfirmEachItem =>
      'Konfirmasi setiap item dideklarasikan yang Anda terima. Hilangkan centang untuk menandai ketidaksesuaian.';

  @override
  String get partnerOrderDetailDiscrepancyHint => 'Apa yang salah? (opsional)';

  @override
  String get partnerOrderDetailMeasuredWeight => 'Berat terukur';

  @override
  String get partnerOrderDetailWeightLabel => 'Berat (kg)';

  @override
  String get partnerOrderDetailEnterValidWeight => 'Masukkan berat yang valid.';

  @override
  String get partnerOrderDetailSubmitWeight => 'Kirim berat & kirim harga';

  @override
  String get partnerOrderDetailConfirmStartWashing =>
      'Konfirmasi & mulai mencuci';

  @override
  String get partnerOrderDetailWeightRecorded =>
      'Berat tercatat. Harga dikirim ke pelanggan.';

  @override
  String get partnerOrderDetailOrderReceived => 'Pesanan diterima.';

  @override
  String partnerOrderDetailResolutionNote(String note) {
    return 'Penyelesaian: $note';
  }

  @override
  String partnerOrderDetailResolveTitle(String status) {
    return 'Klaim $status';
  }

  @override
  String get partnerOrderDetailResolutionNoteLabel => 'Catatan penyelesaian';

  @override
  String get partnerOrderDetailPayoutLabel => 'Jumlah pembayaran (opsional)';

  @override
  String get partnerOrderDetailApprove => 'Setujui';

  @override
  String get partnerOrderDetailClaimApproved => 'Klaim disetujui.';

  @override
  String get partnerOrderDetailClaimRejected => 'Klaim ditolak.';

  @override
  String get partnerOrderDetailDeliveredCompleted => 'Diantar & selesai';

  @override
  String get partnerServicesTitle => 'Layanan';

  @override
  String get partnerServicesAdd => 'Tambah layanan';

  @override
  String get partnerServicesEdit => 'Edit layanan';

  @override
  String get partnerServicesEmpty =>
      'Belum ada layanan. Tambahkan yang pertama.';

  @override
  String get partnerServicesDeleteTitle => 'Hapus layanan?';

  @override
  String partnerServicesDeleteBody(String name) {
    return 'Hapus \"$name\"? Tindakan ini tidak dapat dibatalkan.';
  }

  @override
  String get partnerServicesDeleted => 'Layanan dihapus.';

  @override
  String get partnerServicesEditTooltip => 'Edit';

  @override
  String get partnerServicesDeleteTooltip => 'Hapus';

  @override
  String partnerServicesPricePerUnit(String price, String unit) {
    return 'Rp $price / $unit';
  }

  @override
  String get partnerServicesUnitKg => 'kg';

  @override
  String get partnerServicesUnitItem => 'item';

  @override
  String get partnerServicesNameLabel => 'Nama layanan';

  @override
  String get partnerServicesDescriptionLabel => 'Deskripsi (opsional)';

  @override
  String get partnerServicesPriceLabel => 'Harga';

  @override
  String get partnerServicesPerItem => 'Per item';

  @override
  String get partnerServicesPerKg => 'Per kg';

  @override
  String get partnerServicesEnterNameAndPrice =>
      'Masukkan nama dan harga yang valid.';

  @override
  String get partnerServicesAddPhoto => 'Tambah foto';

  @override
  String get partnerServicesProductImage => 'Gambar produk';

  @override
  String get partnerServicesProductImageHint =>
      'Ini foto yang dilihat pelanggan untuk layanan ini.';

  @override
  String get partnerServicesChange => 'Ubah';

  @override
  String get partnerServicesUpload => 'Unggah';

  @override
  String get partnerReviewsTitle => 'Ulasan Pelanggan';

  @override
  String get partnerReviewsEmpty => 'Belum ada ulasan.';

  @override
  String partnerReviewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ulasan',
      one: '$count ulasan',
    );
    return '  ·  $_temp0';
  }

  @override
  String get partnerReviewsNoComment => 'Tidak ada komentar tertulis.';

  @override
  String get partnerShopEditTitle => 'Profil Toko';

  @override
  String get partnerShopEditUpdated => 'Profil toko diperbarui.';

  @override
  String get partnerShopEditNameLabel => 'Nama toko';

  @override
  String get partnerShopEditDescriptionLabel => 'Deskripsi';

  @override
  String get partnerShopEditAreaLabel =>
      'Label area (ditampilkan ke pelanggan)';

  @override
  String get partnerShopEditAreaHint => 'mis. Kemang, Jakarta Selatan';

  @override
  String get partnerShopEditAddressLabel =>
      'Alamat lengkap (pribadi, tidak ditampilkan ke pelanggan)';

  @override
  String get partnerShopEditSpecialtiesLabel =>
      'Spesialisasi (dipisahkan koma)';

  @override
  String get partnerShopEditSpecialtiesHint => 'sepatu, tas, ekspres';

  @override
  String get partnerShopEditSave => 'Simpan profil toko';

  @override
  String get driverStatusBarAccepted => 'Diterima';

  @override
  String get driverStatusBarPickedUp => 'Dijemput';

  @override
  String get driverStatusBarOnTheWay => 'Dalam perjalanan';

  @override
  String get driverStatusBarDelivered => 'Diantar';

  @override
  String get driverNavHome => 'Beranda';

  @override
  String get driverNavActive => 'Aktif';

  @override
  String get driverNavHistory => 'Riwayat';

  @override
  String get driverNavProfile => 'Profil';

  @override
  String get driverHomeErrorTitle => 'Terjadi kesalahan';

  @override
  String get driverHomeErrorOk => 'OK';

  @override
  String get driverHomeDeliveryOffers => 'Tawaran pengantaran';

  @override
  String get driverHomeNoOffers => 'Belum ada tawaran saat ini.';

  @override
  String get driverHomeTurnOnActive =>
      'Aktifkan status Aktif untuk menerima tawaran.';

  @override
  String get driverHomeStatusOnDelivery => 'Sedang mengantar';

  @override
  String get driverHomeStatusActive => 'Aktif';

  @override
  String get driverHomeStatusNotActive => 'Tidak Aktif';

  @override
  String driverHomeVehicleLine(String vehicleType, String plateNumber) {
    return '$vehicleType · $plateNumber';
  }

  @override
  String get driverHomeTagPickup => 'JEMPUT';

  @override
  String get driverHomeTagDelivery => 'ANTAR';

  @override
  String driverHomeOrderNumber(int id) {
    return 'Pesanan #$id';
  }

  @override
  String get driverHomeLaundromatFallback => 'Laundry';

  @override
  String driverHomeDeliverTo(String address) {
    return 'Antar ke: $address';
  }

  @override
  String get driverHomeReject => 'Tolak';

  @override
  String get driverHomeAccept => 'Terima';

  @override
  String get driverActiveErrorTitle => 'Tidak dapat memperbarui pesanan';

  @override
  String get driverActiveErrorOk => 'OK';

  @override
  String get driverActiveTitle => 'Pengantaran Aktif';

  @override
  String get driverActiveNoActiveDelivery => 'Tidak ada pengantaran aktif.';

  @override
  String driverActiveCurrentDelivery(int id) {
    return 'Pengantaran saat ini · #$id';
  }

  @override
  String get driverActiveLaundromatFallback => 'Laundry';

  @override
  String driverActiveCollectFrom(String address) {
    return 'Ambil dari: $address';
  }

  @override
  String driverActiveDropAt(String name) {
    return 'Antar ke: $name';
  }

  @override
  String driverActiveDeliverTo(String address) {
    return 'Antar ke: $address';
  }

  @override
  String get driverActiveMarkPickedUp => 'Tandai sudah dijemput dari pelanggan';

  @override
  String get driverActivePickedUpSuccess => 'Sudah dijemput dari pelanggan.';

  @override
  String get driverActiveMarkArrived => 'Tandai tiba di laundry';

  @override
  String get driverActiveArrivedSuccess => 'Sudah diantar ke laundry.';

  @override
  String get driverActiveMarkDelivered => 'Tandai sudah diantar';

  @override
  String get driverActiveDeliveredSuccess => 'Pengantaran selesai!';

  @override
  String driverActiveWaitingOn(String status) {
    return 'Menunggu laundry / pelanggan: $status.';
  }

  @override
  String get driverHistoryTitle => 'Riwayat Pengantaran';

  @override
  String get driverHistoryEmpty => 'Belum ada pengantaran selesai.';

  @override
  String driverHistoryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pengantaran selesai',
      one: '$count pengantaran selesai',
    );
    return '$_temp0';
  }

  @override
  String get driverHistoryLaundromatFallback => 'Laundry';

  @override
  String driverHistoryOrderCompleted(int id) {
    return 'Pesanan #$id · Selesai';
  }

  @override
  String get driverHistoryOrderTotal => 'Total pesanan';

  @override
  String driverHistoryMoneyRp(String amount) {
    return 'Rp $amount';
  }
}
