// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Washly';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDone => 'Done';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonClose => 'Close';

  @override
  String get commonApply => 'Apply';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonLoading => 'Loading';

  @override
  String get commonError => 'Something went wrong.';

  @override
  String get navHome => 'Home';

  @override
  String get navDiscovery => 'Discovery';

  @override
  String get navOrders => 'Orders';

  @override
  String get navAccount => 'Account';

  @override
  String get navActive => 'Active';

  @override
  String get navHistory => 'History';

  @override
  String get navProfile => 'Profile';

  @override
  String get navOffers => 'Offers';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navServices => 'Services';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageIndonesian => 'Indonesian';

  @override
  String get changeLanguageTitle => 'Language';

  @override
  String get changeLanguageSaved => 'Language updated.';

  @override
  String get orderStatusPendingAcceptance => 'Waiting for partner';

  @override
  String get orderStatusAccepted => 'Accepted';

  @override
  String get orderStatusDriverAssigned => 'Driver assigned';

  @override
  String get orderStatusPickedUp => 'Picked up from you';

  @override
  String get orderStatusAtLaundromat => 'At the laundromat';

  @override
  String get orderStatusWeighedAwaitingConfirm => 'Awaiting your confirmation';

  @override
  String get orderStatusAwaitingPayment => 'Awaiting payment';

  @override
  String get orderStatusWashing => 'Washing';

  @override
  String get orderStatusReadyForDelivery => 'Ready for delivery';

  @override
  String get orderStatusOutForDelivery => 'Out for delivery';

  @override
  String get orderStatusCompleted => 'Completed';

  @override
  String get orderStatusCancelled => 'Cancelled';

  @override
  String get orderStatusUnknown => 'Unknown';

  @override
  String get timelinePlaced => 'Placed';

  @override
  String get timelineAccepted => 'Accepted';

  @override
  String get timelinePickup => 'Pickup';

  @override
  String get timelineWashing => 'Washing';

  @override
  String get timelineOnTheWay => 'On the way';

  @override
  String get timelineCompleted => 'Completed';

  @override
  String get timelineOrderCancelled => 'Order cancelled';

  @override
  String get commonEmailLabel => 'Email';

  @override
  String get commonPasswordLabel => 'Password';

  @override
  String get commonPhoneLabel => 'Phone';

  @override
  String get commonFullNameLabel => 'Full name';

  @override
  String get commonConfirmPasswordLabel => 'Confirm password';

  @override
  String get commonCreateAccount => 'Create account';

  @override
  String get commonEmailRequired => 'Email is required';

  @override
  String get commonEmailInvalid => 'Enter a valid email';

  @override
  String get commonPasswordRequired => 'Password is required';

  @override
  String get commonPasswordTooShort => 'At least 6 characters';

  @override
  String get commonConfirmPasswordRequired => 'Please confirm your password';

  @override
  String get commonPasswordsDoNotMatch => 'Passwords do not match';

  @override
  String commonFieldRequired(String label) {
    return '$label is required';
  }

  @override
  String get commonShowPassword => 'Show password';

  @override
  String get commonHidePassword => 'Hide password';

  @override
  String get loginTitle => 'Welcome back';

  @override
  String get loginSubtitle => 'Log in to continue.';

  @override
  String get loginSubmit => 'Log in';

  @override
  String get loginNoAccountQuestion => 'Don\'t have an account?';

  @override
  String get loginRegisterAction => 'Register';

  @override
  String get roleSelectTitle => 'Welcome to Washly';

  @override
  String get roleSelectSubtitle => 'Choose how you want to join.';

  @override
  String get roleSelectCustomerTitle => 'Customer';

  @override
  String get roleSelectCustomerSubtitle => 'Order laundry pickup & delivery';

  @override
  String get roleSelectPartnerTitle => 'Laundromat Partner';

  @override
  String get roleSelectPartnerSubtitle => 'Manage your shop and orders';

  @override
  String get roleSelectDriverTitle => 'Driver';

  @override
  String get roleSelectDriverSubtitle => 'Pick up and deliver orders';

  @override
  String get roleSelectHaveAccountQuestion => 'Already have an account?';

  @override
  String get roleSelectLoginAction => 'Log in';

  @override
  String get registerCustomerTitle => 'Customer sign up';

  @override
  String get registerDriverTitle => 'Driver sign up';

  @override
  String get registerDriverVehicleTypeLabel => 'Vehicle type (e.g. motorcycle)';

  @override
  String get registerDriverPlateNumberLabel => 'Plate number';

  @override
  String get registerPartnerTitle => 'Partner sign up';

  @override
  String get registerPartnerSelectSpecialty => 'Select at least one specialty.';

  @override
  String get registerPartnerSectionAccount => 'Account';

  @override
  String get registerPartnerSectionBusiness => 'Business';

  @override
  String get registerPartnerSectionSpecialties => 'Specialties';

  @override
  String get registerPartnerOwnerNameLabel => 'Owner name';

  @override
  String get registerPartnerBusinessNameLabel => 'Business name';

  @override
  String get registerPartnerBusinessAddressLabel => 'Business address';

  @override
  String get registerPartnerLatitudeLabel => 'Latitude';

  @override
  String get registerPartnerLongitudeLabel => 'Longitude';

  @override
  String get registerPartnerCoordinateInvalid => 'Enter a valid number';

  @override
  String get registerPartnerPricingModelLabel => 'Pricing model';

  @override
  String get registerPartnerPricingPerKg => 'Per kilogram';

  @override
  String get registerPartnerPricingPerItem => 'Per item';

  @override
  String get registerPartnerSpecialtyShoes => 'shoes';

  @override
  String get registerPartnerSpecialtyBags => 'bags';

  @override
  String get registerPartnerSpecialtyDolls => 'dolls';

  @override
  String get registerPartnerSpecialtyCostumes => 'costumes';

  @override
  String get registerPartnerSpecialtyExpress => 'express';

  @override
  String get registerPartnerSpecialtyIroning => 'ironing';

  @override
  String get registerPartnerSpecialtyKiloan => 'kiloan';

  @override
  String get registerPartnerSpecialtyDryClean => 'dry clean';

  @override
  String get accountSettingsTitle => 'Account settings';

  @override
  String get accountLogoutTitle => 'Log out';

  @override
  String get accountLogoutConfirm => 'Are you sure you want to log out?';

  @override
  String get accountShopProfile => 'Shop profile';

  @override
  String get accountEditProfile => 'Edit Profile';

  @override
  String get accountChangePassword => 'Change Password';

  @override
  String get accountChangeLanguage => 'Change Language';

  @override
  String get editProfileTitle => 'Edit Profile';

  @override
  String get editProfileChangePhoto => 'Change photo';

  @override
  String get editProfilePhotoUpdated => 'Photo updated.';

  @override
  String editProfilePickerError(String error) {
    return 'Could not open the picker: $error';
  }

  @override
  String get editProfileUpdated => 'Profile updated.';

  @override
  String get editProfileNameLabel => 'Name';

  @override
  String get editProfileNameRequired => 'Name is required';

  @override
  String get editProfilePhoneRequired => 'Phone is required';

  @override
  String get editProfileSave => 'Save profile';

  @override
  String get navVouchers => 'Vouchers';

  @override
  String get commonSeeAll => 'See all';

  @override
  String get commonRedeem => 'Redeem';

  @override
  String get commonSubmit => 'Submit';

  @override
  String get commonPost => 'Post';

  @override
  String get commonNotNow => 'Not now';

  @override
  String orderN(int id) {
    return 'Order #$id';
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
    return 'Rp $amount off';
  }

  @override
  String moneyRpNegative(String amount) {
    return '- Rp $amount';
  }

  @override
  String get serviceTagShoes => 'Shoes';

  @override
  String get serviceTagBags => 'Bags';

  @override
  String get serviceTagDolls => 'Dolls';

  @override
  String get serviceTagCostumes => 'Costumes';

  @override
  String get serviceTagExpress => 'Express';

  @override
  String get serviceTagIroning => 'Ironing';

  @override
  String get serviceTagKiloan => 'Kiloan';

  @override
  String get serviceTagDryClean => 'Dry Clean';

  @override
  String get sortTopRated => 'Top Rated';

  @override
  String get sortNearest => 'Nearest';

  @override
  String get filterServices => 'Filter Services';

  @override
  String filterServicesCount(int count) {
    return 'Services ($count)';
  }

  @override
  String get filterReset => 'Reset';

  @override
  String filterApplyCount(int count) {
    return 'Apply Filters ($count)';
  }

  @override
  String get homeSpecialties => 'Specialties';

  @override
  String get homeSearchHint => 'Find a laundromat';

  @override
  String get homeWelcomeBack => 'Welcome back!';

  @override
  String get homeGreetingFallback => 'there';

  @override
  String get homeLoyaltyWallet => 'Loyalty wallet';

  @override
  String homePoints(int count) {
    return '$count points';
  }

  @override
  String get homeRedeemPrompt => 'Redeem your points for vouchers.';

  @override
  String homeVouchersReady(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vouchers ready at checkout.',
      one: '$count voucher ready at checkout.',
    );
    return '$_temp0';
  }

  @override
  String get homeActiveOrders => 'Active Orders';

  @override
  String get homeNoActiveOrders => 'No active orders right now.';

  @override
  String get homeYourOrder => 'Your order';

  @override
  String homeTapToTrack(int id) {
    return 'Order #$id · tap to track';
  }

  @override
  String get homeActionConfirmWeighedPrice =>
      'Action needed: confirm your weighed price';

  @override
  String get homeNearbyLaundromats => 'Nearby Laundromats';

  @override
  String get homeNoLaundromatsYet => 'No laundromats available yet.';

  @override
  String get ordersTitle => 'My Orders';

  @override
  String get ordersEmptyActive => 'No active orders. Place one from Discovery.';

  @override
  String get ordersEmptyHistory => 'No past orders yet.';

  @override
  String get ordersLaundromatFallback => 'Laundromat';

  @override
  String ordersItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '$count item',
    );
    return '$_temp0';
  }

  @override
  String get ordersPerKgSuffix => 'per kg';

  @override
  String get ordersActionConfirmPrice => 'Action needed: confirm price';

  @override
  String get ordersWeighedAtPickup => 'Weighed at pickup';

  @override
  String get vouchersTitle => 'Vouchers';

  @override
  String vouchersRedeemedToast(String amount) {
    return 'Redeemed a Rp $amount voucher!';
  }

  @override
  String get vouchersRedeemPoints => 'Redeem Points';

  @override
  String get vouchersRedeemSubtitle =>
      'Pick a reward to redeem with your points.';

  @override
  String get vouchersNoRewards => 'No rewards available right now.';

  @override
  String get vouchersYourVouchers => 'Your Vouchers';

  @override
  String get vouchersEmpty => 'No vouchers yet. Redeem points to get one.';

  @override
  String get vouchersEarnRate => 'Earn 5 points per Rp 10.000 spent.';

  @override
  String vouchersTierPoints(int count) {
    return '$count points';
  }

  @override
  String vouchersNeedMorePoints(int count) {
    return 'Need $count more points';
  }

  @override
  String get vouchersUsed => 'Used';

  @override
  String get vouchersAvailableAtCheckout => 'Available at checkout';

  @override
  String get voucherSelectTitle => 'Apply a voucher';

  @override
  String voucherSelectCountAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vouchers available',
      one: '$count voucher available',
    );
    return '$_temp0';
  }

  @override
  String get voucherSelectRemoveApplied => 'Remove applied voucher';

  @override
  String get voucherSelectDiscountVoucher => 'Discount voucher';

  @override
  String get voucherSelectEmptyTitle => 'There are no vouchers';

  @override
  String get voucherSelectEmptyBody =>
      'Redeem your loyalty points for vouchers, then apply them here.';

  @override
  String get searchHint => 'Search name, service, or area';

  @override
  String get searchPrompt => 'Type a name, service, or area, then hit search.';

  @override
  String get searchNoMatches => 'No laundromats match your search.';

  @override
  String discoveryError(String error) {
    return 'Error: $error';
  }

  @override
  String get discoveryNoLaundromats => 'No laundromats found.';

  @override
  String discoveryReviewCount(int count) {
    return '($count)';
  }

  @override
  String discoveryDistanceKm(String distance) {
    return '$distance km';
  }

  @override
  String get discoveryAreaHidden => 'Area shown after order';

  @override
  String detailReviewsCount(int count) {
    return 'Reviews ($count)';
  }

  @override
  String detailReviewCountSuffix(int count) {
    return ' ($count reviews)';
  }

  @override
  String get detailAreaHidden => 'Area hidden until pickup';

  @override
  String get detailServicesMenu => 'Services Menu';

  @override
  String get detailNoServices => 'No services listed yet.';

  @override
  String detailCustomerReviews(int count) {
    return '$count Customer Reviews';
  }

  @override
  String get detailAddReview => 'Add Review';

  @override
  String get detailNoReviews => 'No reviews yet. Be the first to leave one!';

  @override
  String get detailWriteReview => 'Write a Review';

  @override
  String get detailYourReview => 'Your review';

  @override
  String get detailSignInToReview => 'Please sign in to review.';

  @override
  String detailReviewFailed(String error) {
    return 'Failed: $error';
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
  String get detailQuantityOfItems => 'Quantity of Items';

  @override
  String detailPieces(int count) {
    return '$count pcs';
  }

  @override
  String detailPerKgNote(String price) {
    return 'Priced by weight at Rp $price/kg. The laundromat weighs your laundry after pickup and sends the price — you approve it before paying.';
  }

  @override
  String get detailWashingInstructions => 'Washing Instructions (Optional)';

  @override
  String get detailItemDetailsHint =>
      'Item Details (e.g. 2 Nike Dunks, 1 Coach bag)';

  @override
  String get detailAddToBasket => 'Add to Basket';

  @override
  String detailAddToBasketPrice(String price) {
    return 'Add to Basket • Rp $price';
  }

  @override
  String get detailNewBasketTitle => 'Start a new basket?';

  @override
  String detailNewBasketBody(String name, String store) {
    return 'Your basket has items from $name. Adding this will clear it and start a new basket at $store.';
  }

  @override
  String get detailAnotherLaundromat => 'another laundromat';

  @override
  String get detailClearAndAdd => 'Clear & add';

  @override
  String get detailInBasket => 'In basket';

  @override
  String detailItemsInBasket(int count) {
    return '$count items in basket';
  }

  @override
  String get detailWeighedAtPickupArrow => 'Weighed at pickup  ➔';

  @override
  String detailBasketTotalArrow(String amount) {
    return 'Rp $amount  ➔';
  }

  @override
  String get orderDetailTitle => 'Order Details';

  @override
  String get orderDetailPriceApprovedToast =>
      'Price approved. Proceed to payment.';

  @override
  String get orderDetailPaymentReceived => 'Payment received.';

  @override
  String get orderDetailPaymentPending => 'Payment pending confirmation.';

  @override
  String get orderDetailPaymentFailed => 'Payment failed. You can try again.';

  @override
  String get orderDetailPaymentClosed => 'Payment window closed.';

  @override
  String get orderDetailPaymentLaunched =>
      'Payment opened. This order updates once confirmed.';

  @override
  String get orderDetailDriverPickingUp => 'Driver picking up your laundry';

  @override
  String get orderDetailDriverDelivering => 'Driver delivering your laundry';

  @override
  String get orderDetailLookingForPickup =>
      'Looking for a driver to pick up your laundry';

  @override
  String get orderDetailLookingForDelivery =>
      'Looking for a driver to deliver your laundry';

  @override
  String get orderDetailVehicleFallback => 'Vehicle';

  @override
  String get orderDetailLaundromatFallback => 'Laundromat';

  @override
  String get orderDetailConfirmWeighedPrice => 'Confirm your weighed price';

  @override
  String get orderDetailWeighedExplainer =>
      'The laundromat weighed your laundry. Review the price and your items below, then approve to continue to payment.';

  @override
  String get orderDetailMeasuredWeight => 'Measured weight';

  @override
  String orderDetailKg(String value) {
    return '$value kg';
  }

  @override
  String get orderDetailWashSubtotal => 'Wash subtotal';

  @override
  String get orderDetailDeliveryFee => 'Delivery fee';

  @override
  String get orderDetailDeclaredProtection => 'Declared items protection';

  @override
  String get orderDetailVoucher => 'Voucher';

  @override
  String get orderDetailFinalPrice => 'Final price';

  @override
  String get orderDetailApproveContinue => 'Approve & continue to payment';

  @override
  String orderDetailDeclaredReceived(int received, int total) {
    return 'Declared items  ($received/$total received)';
  }

  @override
  String get orderDetailNotReceived => 'Not received';

  @override
  String get orderDetailPaymentRequired => 'Payment required';

  @override
  String get orderDetailAmountDue => 'Amount due';

  @override
  String get orderDetailPayNow => 'Pay now';

  @override
  String get orderDetailProgress => 'Progress';

  @override
  String get orderDetailReceipt => 'Receipt';

  @override
  String get orderDetailSubtotal => 'Subtotal';

  @override
  String get orderDetailWeighed => 'Weighed';

  @override
  String get orderDetailGrandTotal => 'Grand total';

  @override
  String get orderDetailAfterWeighing => 'After weighing';

  @override
  String get orderDetailPayment => 'Payment';

  @override
  String get orderDetailPaymentNotStarted => 'Not started';

  @override
  String get orderDetailUnitKg => 'kg';

  @override
  String get orderDetailUnitPcs => 'pcs';

  @override
  String get orderDetailDeclaredItems => 'Declared items';

  @override
  String get orderDetailReceived => 'Received';

  @override
  String get orderDetailAwaitingIntake => 'Awaiting intake';

  @override
  String get orderDetailHowDidItGo => 'How did it go?';

  @override
  String get orderDetailRateLaundromat => 'Rate laundromat';

  @override
  String get orderDetailWarranty => 'Warranty';

  @override
  String get orderDetailWarrantyOnlyDeclared =>
      'Warranty is available only for declared items the laundromat confirmed at intake.';

  @override
  String get orderDetailWarrantyClaims => 'Warranty claims';

  @override
  String get orderDetailNoClaims =>
      'No claims filed. Tap \"Warranty\" above if something went wrong with a declared item.';

  @override
  String get orderDetailRateThisLaundromat => 'Rate this laundromat';

  @override
  String get orderDetailAddCommentOptional => 'Add a comment (optional)';

  @override
  String get orderDetailSignInToRate => 'Please sign in to rate.';

  @override
  String get orderDetailRatingThanks => 'Thanks for your rating!';

  @override
  String get orderDetailUseWarrantyTitle => 'Use your warranty?';

  @override
  String get orderDetailWarrantyExplainer =>
      'Your declared items are covered by Washly warranty. If one was lost or damaged, you can file a claim with photos and the laundromat will review it.';

  @override
  String get orderDetailCoveredItems => 'Covered items';

  @override
  String get orderDetailFileClaim => 'File a claim';

  @override
  String orderDetailItemFallback(int id) {
    return 'Item #$id';
  }

  @override
  String orderDetailResolution(String note) {
    return 'Resolution: $note';
  }

  @override
  String orderDetailPayout(String amount) {
    return 'Payout: Rp $amount (Washly)';
  }

  @override
  String get orderDetailFileClaimTitle => 'File a warranty claim';

  @override
  String get orderDetailItem => 'Item';

  @override
  String get orderDetailWhatWentWrong => 'What went wrong?';

  @override
  String get orderDetailPickItemDescribe =>
      'Pick an item and describe the issue.';

  @override
  String get orderDetailAddPhoto => 'Add photo';

  @override
  String orderDetailPhotosAttached(int count) {
    return '$count attached';
  }

  @override
  String get orderDetailSubmitClaim => 'Submit claim';

  @override
  String get orderDetailClaimSubmitted => 'Claim submitted.';

  @override
  String get checkoutTitle => 'Checkout Order';

  @override
  String checkoutPickerError(String error) {
    return 'Could not open the picker: $error';
  }

  @override
  String get checkoutLabelItemTitle => 'Label this item';

  @override
  String get checkoutLabelItemHint => 'e.g. White Nike Air Force 1';

  @override
  String get checkoutEnterPickupAddress => 'Please enter your pickup address.';

  @override
  String get checkoutSignInToOrder => 'Please sign in again to place an order.';

  @override
  String get checkoutPaymentReceivedTitle => 'Payment received';

  @override
  String get checkoutPaymentReceivedBody =>
      'Thanks! Your payment is confirmed. Track this order in the Orders tab.';

  @override
  String get checkoutPaymentPendingTitle => 'Payment pending';

  @override
  String get checkoutPaymentPendingBody =>
      'Your payment is being processed. This order updates automatically once it is confirmed.';

  @override
  String get checkoutPaymentNotCompletedTitle => 'Payment not completed';

  @override
  String get checkoutPaymentNotCompletedBody =>
      'You closed the payment window. Your order is saved — you can pay from the Orders tab anytime.';

  @override
  String get checkoutPaymentFailedTitle => 'Payment failed';

  @override
  String get checkoutPaymentFailedBody =>
      'The payment did not go through. Your order is saved — try again from the Orders tab.';

  @override
  String get checkoutCompletePaymentTitle => 'Complete your payment';

  @override
  String get checkoutCompletePaymentBody =>
      'We opened the payment page. This order updates automatically once payment is confirmed.';

  @override
  String get checkoutOrderPlacedTitle => 'Order placed';

  @override
  String checkoutOrderPlacedPaymentError(String error) {
    return 'Your order was created, but we could not open payment: $error. You can pay from the Orders tab.';
  }

  @override
  String get checkoutPerKgPlacedTitle => 'Order Placed';

  @override
  String get checkoutPerKgPlacedBody =>
      'Your order is waiting for the laundromat to accept it. The final price is set after your laundry is weighed — you will pay then.';

  @override
  String get checkoutDeliveryPickupDetails => 'Delivery & Pickup Details';

  @override
  String get checkoutPickupAddressLabel => 'Pickup & Return Address';

  @override
  String get checkoutNotesLabel => 'Notes for driver / laundromat (optional)';

  @override
  String get checkoutNotesHint =>
      'e.g. Leave with security, house with black gate';

  @override
  String get checkoutOrderSummary => 'Order Summary';

  @override
  String get checkoutDeclaredItemsOptional => 'Declared items (optional)';

  @override
  String get checkoutDeclaredExplainer =>
      'Declared items are valuables you photograph before pickup — like a jacket, branded sneakers, or a bedcover.';

  @override
  String get checkoutDeclaredBenefit =>
      'The photo is proof of condition at drop-off, so you can file a warranty claim if an item is lost or damaged.';

  @override
  String checkoutDeclaredFeeNote(String fee) {
    return 'Adding declared items applies a one-time Rp $fee protection fee to this order.';
  }

  @override
  String get checkoutVoucherApplied => 'Voucher applied';

  @override
  String get checkoutApplyVoucher => 'Apply a voucher';

  @override
  String get checkoutPlaceOrder => 'Place Order';

  @override
  String checkoutPricePerKg(String price) {
    return 'Rp $price/kg';
  }

  @override
  String checkoutPiecesPrefix(int count) {
    return '${count}pcs x ';
  }

  @override
  String get checkoutEstimatedWashPerKg => 'Estimated wash (per kg)';

  @override
  String get checkoutWashSubtotal => 'Wash Subtotal';

  @override
  String get checkoutWeighedAtPickup => 'Weighed at pickup';

  @override
  String get checkoutDeclaredProtection => 'Declared items protection';

  @override
  String get checkoutVoucher => 'Voucher';

  @override
  String get checkoutPickupDeliveryFee => 'Pickup & Delivery Fee';

  @override
  String get checkoutCalculatedAtPickup => 'Calculated at pickup';

  @override
  String get checkoutFinalPrice => 'Final price';

  @override
  String get checkoutTotalBeforeFee => 'Total (before fee)';

  @override
  String get checkoutAfterWeighing => 'After weighing';

  @override
  String get checkoutPerKgFooter =>
      'Your laundry is priced by weight. You approve the final price after it is weighed, then pay.';

  @override
  String get checkoutPerItemFooter =>
      'The delivery fee is calculated from the pickup distance when you place the order.';

  @override
  String get partnerDashboardTitle => 'Dashboard';

  @override
  String get partnerDashboardReport => 'Report';

  @override
  String partnerDashboardReportSaved(String where) {
    return 'Report saved to $where.';
  }

  @override
  String get partnerDashboardRangeDay => 'This day';

  @override
  String get partnerDashboardRangeMonth => 'This month';

  @override
  String get partnerDashboardRangeYear => 'This year';

  @override
  String get partnerDashboardRevenue => 'Revenue (paid orders)';

  @override
  String get partnerDashboardInProcess => 'In process';

  @override
  String get partnerDashboardCompleted => 'Completed';

  @override
  String get partnerDashboardTotalOrders => 'Total orders';

  @override
  String partnerDashboardAvgReview(int count) {
    return 'Avg review · $count';
  }

  @override
  String get partnerDashboardNoReviewsYet => 'No reviews yet';

  @override
  String get partnerDashboardSalesByProduct => 'Sales by product';

  @override
  String get partnerDashboardNoSales => 'No sales in this period yet.';

  @override
  String get partnerDashboardRevenueAxis => 'Revenue';

  @override
  String get partnerOrdersTitle => 'Orders';

  @override
  String partnerOrdersActiveTab(int count) {
    return 'Active ($count)';
  }

  @override
  String partnerOrdersDoneTab(int count) {
    return 'Done ($count)';
  }

  @override
  String get partnerOrdersEmptyActive => 'No active orders.';

  @override
  String get partnerOrdersEmptyDone => 'No completed or cancelled orders yet.';

  @override
  String get partnerOrdersOpenForOrders => 'Open for orders';

  @override
  String get partnerOrdersClosed => 'Closed';

  @override
  String get partnerOrdersOpenHint =>
      'Customers can place orders with your shop.';

  @override
  String get partnerOrdersClosedHint => 'Your shop is hidden from new orders.';

  @override
  String get partnerOrdersPerKg => 'Per kg';

  @override
  String get partnerOrdersPerItem => 'Per item';

  @override
  String partnerOrdersItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '$count item',
    );
    return '$_temp0';
  }

  @override
  String get partnerOrdersNeedsWarranty => 'Needs warranty approval';

  @override
  String get partnerOrdersWeighedAtPickup => 'Weighed at pickup';

  @override
  String get partnerOrderDetailNotFound => 'Order not found.';

  @override
  String get partnerOrderDetailPerKgOrder => 'Per kg order';

  @override
  String get partnerOrderDetailPerItemOrder => 'Per item order';

  @override
  String get partnerOrderDetailItems => 'Items';

  @override
  String get partnerOrderDetailDeclaredItems => 'Declared items';

  @override
  String get partnerOrderDetailProgress => 'Progress';

  @override
  String get partnerOrderDetailWarrantyClaims => 'Warranty claims';

  @override
  String get partnerOrderDetailNeedsWarranty => 'Needs warranty approval';

  @override
  String get partnerOrderDetailReceived => 'Received';

  @override
  String get partnerOrderDetailAwaitingAcceptance => 'Awaiting acceptance';

  @override
  String get partnerOrderDetailNotReceived => 'Not received';

  @override
  String get partnerOrderDetailVehicleFallback => 'Vehicle';

  @override
  String get partnerOrderDetailClaimPhoto => 'Claim photo';

  @override
  String get partnerOrderDetailWaitWashAfterPayment =>
      'Waiting for the wash to begin after payment.';

  @override
  String get partnerOrderDetailWaitCustomerApprove =>
      'Waiting for the customer to approve the weighed price.';

  @override
  String get partnerOrderDetailWaitCustomerPay =>
      'Waiting for the customer to pay.';

  @override
  String get partnerOrderDetailWaitDriverPickup =>
      'Waiting for the driver to pick up.';

  @override
  String get partnerOrderDetailOutForDelivery => 'Out for delivery.';

  @override
  String get partnerOrderDetailDriverBringingIn =>
      'Driver bringing the laundry in';

  @override
  String get partnerOrderDetailDriverTakingOut =>
      'Driver taking the laundry out for delivery';

  @override
  String get partnerOrderDetailLookingForDriver =>
      'Looking for a driver to deliver the laundry';

  @override
  String get partnerOrderDetailReject => 'Reject';

  @override
  String get partnerOrderDetailAccept => 'Accept';

  @override
  String get partnerOrderDetailOrderRejected => 'Order rejected.';

  @override
  String get partnerOrderDetailOrderAccepted => 'Order accepted.';

  @override
  String get partnerOrderDetailReceiveAndWeigh => 'Receive & weigh';

  @override
  String get partnerOrderDetailConfirmReceived => 'Confirm received';

  @override
  String get partnerOrderDetailMarkReady => 'Mark ready for delivery';

  @override
  String get partnerOrderDetailMarkedReady => 'Marked ready for delivery.';

  @override
  String get partnerOrderDetailConfirmArrived =>
      'Confirm the laundry arrived to continue.';

  @override
  String get partnerOrderDetailConfirmEachItem =>
      'Confirm each declared item you received. Unchecking one lets you flag a discrepancy.';

  @override
  String get partnerOrderDetailDiscrepancyHint => 'What was wrong? (optional)';

  @override
  String get partnerOrderDetailMeasuredWeight => 'Measured weight';

  @override
  String get partnerOrderDetailWeightLabel => 'Weight (kg)';

  @override
  String get partnerOrderDetailEnterValidWeight => 'Enter a valid weight.';

  @override
  String get partnerOrderDetailSubmitWeight => 'Submit weight & send price';

  @override
  String get partnerOrderDetailConfirmStartWashing => 'Confirm & start washing';

  @override
  String get partnerOrderDetailWeightRecorded =>
      'Weight recorded. Price sent to the customer.';

  @override
  String get partnerOrderDetailOrderReceived => 'Order received.';

  @override
  String partnerOrderDetailResolutionNote(String note) {
    return 'Resolution: $note';
  }

  @override
  String partnerOrderDetailResolveTitle(String status) {
    return '$status claim';
  }

  @override
  String get partnerOrderDetailResolutionNoteLabel => 'Resolution note';

  @override
  String get partnerOrderDetailPayoutLabel => 'Payout amount (optional)';

  @override
  String get partnerOrderDetailApprove => 'Approve';

  @override
  String get partnerOrderDetailClaimApproved => 'Claim approved.';

  @override
  String get partnerOrderDetailClaimRejected => 'Claim rejected.';

  @override
  String get partnerOrderDetailDeliveredCompleted => 'Delivered & completed';

  @override
  String get partnerServicesTitle => 'Services';

  @override
  String get partnerServicesAdd => 'Add service';

  @override
  String get partnerServicesEdit => 'Edit service';

  @override
  String get partnerServicesEmpty => 'No services yet. Add your first one.';

  @override
  String get partnerServicesDeleteTitle => 'Delete service?';

  @override
  String partnerServicesDeleteBody(String name) {
    return 'Remove \"$name\"? This cannot be undone.';
  }

  @override
  String get partnerServicesDeleted => 'Service deleted.';

  @override
  String get partnerServicesEditTooltip => 'Edit';

  @override
  String get partnerServicesDeleteTooltip => 'Delete';

  @override
  String partnerServicesPricePerUnit(String price, String unit) {
    return 'Rp $price / $unit';
  }

  @override
  String get partnerServicesUnitKg => 'kg';

  @override
  String get partnerServicesUnitItem => 'item';

  @override
  String get partnerServicesNameLabel => 'Service name';

  @override
  String get partnerServicesDescriptionLabel => 'Description (optional)';

  @override
  String get partnerServicesPriceLabel => 'Price';

  @override
  String get partnerServicesPerItem => 'Per item';

  @override
  String get partnerServicesPerKg => 'Per kg';

  @override
  String get partnerServicesEnterNameAndPrice =>
      'Enter a name and a valid price.';

  @override
  String get partnerServicesAddPhoto => 'Add photo';

  @override
  String get partnerServicesProductImage => 'Product image';

  @override
  String get partnerServicesProductImageHint =>
      'This is the photo customers see for this service.';

  @override
  String get partnerServicesChange => 'Change';

  @override
  String get partnerServicesUpload => 'Upload';

  @override
  String get partnerReviewsTitle => 'Customer Reviews';

  @override
  String get partnerReviewsEmpty => 'No reviews yet.';

  @override
  String partnerReviewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '$count review',
    );
    return '  ·  $_temp0';
  }

  @override
  String get partnerReviewsNoComment => 'No written comment.';

  @override
  String get partnerShopEditTitle => 'Shop Profile';

  @override
  String get partnerShopEditUpdated => 'Shop profile updated.';

  @override
  String get partnerShopEditNameLabel => 'Shop name';

  @override
  String get partnerShopEditDescriptionLabel => 'Description';

  @override
  String get partnerShopEditAreaLabel => 'Area label (shown to customers)';

  @override
  String get partnerShopEditAreaHint => 'e.g. Kemang, South Jakarta';

  @override
  String get partnerShopEditAddressLabel =>
      'Exact address (private, not shown to customers)';

  @override
  String get partnerShopEditSpecialtiesLabel => 'Specialties (comma separated)';

  @override
  String get partnerShopEditSpecialtiesHint => 'shoes, bags, express';

  @override
  String get partnerShopEditSave => 'Save shop profile';

  @override
  String get driverStatusBarAccepted => 'Accepted';

  @override
  String get driverStatusBarPickedUp => 'Picked up';

  @override
  String get driverStatusBarOnTheWay => 'On the way';

  @override
  String get driverStatusBarDelivered => 'Delivered';

  @override
  String get driverNavHome => 'Home';

  @override
  String get driverNavActive => 'Active';

  @override
  String get driverNavHistory => 'History';

  @override
  String get driverNavProfile => 'Profile';

  @override
  String get driverHomeErrorTitle => 'Something went wrong';

  @override
  String get driverHomeErrorOk => 'OK';

  @override
  String get driverHomeDeliveryOffers => 'Delivery offers';

  @override
  String get driverHomeNoOffers => 'No offers right now.';

  @override
  String get driverHomeTurnOnActive => 'Turn on Active to receive offers.';

  @override
  String get driverHomeStatusOnDelivery => 'On a delivery';

  @override
  String get driverHomeStatusActive => 'Active';

  @override
  String get driverHomeStatusNotActive => 'Not Active';

  @override
  String driverHomeVehicleLine(String vehicleType, String plateNumber) {
    return '$vehicleType · $plateNumber';
  }

  @override
  String get driverHomeTagPickup => 'PICKUP';

  @override
  String get driverHomeTagDelivery => 'DELIVERY';

  @override
  String driverHomeOrderNumber(int id) {
    return 'Order #$id';
  }

  @override
  String get driverHomeLaundromatFallback => 'Laundromat';

  @override
  String driverHomeDeliverTo(String address) {
    return 'Deliver to: $address';
  }

  @override
  String get driverHomeReject => 'Reject';

  @override
  String get driverHomeAccept => 'Accept';

  @override
  String get driverActiveErrorTitle => 'Could not update order';

  @override
  String get driverActiveErrorOk => 'OK';

  @override
  String get driverActiveTitle => 'Active Delivery';

  @override
  String get driverActiveNoActiveDelivery => 'No active delivery.';

  @override
  String driverActiveCurrentDelivery(int id) {
    return 'Current delivery · #$id';
  }

  @override
  String get driverActiveLaundromatFallback => 'Laundromat';

  @override
  String driverActiveCollectFrom(String address) {
    return 'Collect from: $address';
  }

  @override
  String driverActiveDropAt(String name) {
    return 'Drop at: $name';
  }

  @override
  String driverActiveDeliverTo(String address) {
    return 'Deliver to: $address';
  }

  @override
  String get driverActiveMarkPickedUp => 'Mark picked up from customer';

  @override
  String get driverActivePickedUpSuccess => 'Picked up from the customer.';

  @override
  String get driverActiveMarkArrived => 'Mark arrived at laundromat';

  @override
  String get driverActiveArrivedSuccess => 'Dropped off at the laundromat.';

  @override
  String get driverActiveMarkDelivered => 'Mark delivered';

  @override
  String get driverActiveDeliveredSuccess => 'Delivery completed!';

  @override
  String driverActiveWaitingOn(String status) {
    return 'Waiting on the laundromat / customer: $status.';
  }

  @override
  String get driverHistoryTitle => 'Delivery History';

  @override
  String get driverHistoryEmpty => 'No completed deliveries yet.';

  @override
  String driverHistoryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count completed deliveries',
      one: '$count completed delivery',
    );
    return '$_temp0';
  }

  @override
  String get driverHistoryLaundromatFallback => 'Laundromat';

  @override
  String driverHistoryOrderCompleted(int id) {
    return 'Order #$id · Completed';
  }

  @override
  String get driverHistoryOrderTotal => 'Order total';

  @override
  String driverHistoryMoneyRp(String amount) {
    return 'Rp $amount';
  }
}
