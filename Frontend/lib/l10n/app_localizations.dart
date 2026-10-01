import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Washly'**
  String get appTitle;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get commonApply;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get commonLoading;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get commonError;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navDiscovery.
  ///
  /// In en, this message translates to:
  /// **'Discovery'**
  String get navDiscovery;

  /// No description provided for @navOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get navOrders;

  /// No description provided for @navAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get navAccount;

  /// No description provided for @navActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get navActive;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navOffers.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get navOffers;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get navServices;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageIndonesian.
  ///
  /// In en, this message translates to:
  /// **'Indonesian'**
  String get languageIndonesian;

  /// No description provided for @changeLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get changeLanguageTitle;

  /// No description provided for @changeLanguageSaved.
  ///
  /// In en, this message translates to:
  /// **'Language updated.'**
  String get changeLanguageSaved;

  /// No description provided for @orderStatusPendingAcceptance.
  ///
  /// In en, this message translates to:
  /// **'Waiting for partner'**
  String get orderStatusPendingAcceptance;

  /// No description provided for @orderStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get orderStatusAccepted;

  /// No description provided for @orderStatusDriverAssigned.
  ///
  /// In en, this message translates to:
  /// **'Driver assigned'**
  String get orderStatusDriverAssigned;

  /// No description provided for @orderStatusPickedUp.
  ///
  /// In en, this message translates to:
  /// **'Picked up from you'**
  String get orderStatusPickedUp;

  /// No description provided for @orderStatusAtLaundromat.
  ///
  /// In en, this message translates to:
  /// **'At the laundromat'**
  String get orderStatusAtLaundromat;

  /// No description provided for @orderStatusWeighedAwaitingConfirm.
  ///
  /// In en, this message translates to:
  /// **'Awaiting your confirmation'**
  String get orderStatusWeighedAwaitingConfirm;

  /// No description provided for @orderStatusAwaitingPayment.
  ///
  /// In en, this message translates to:
  /// **'Awaiting payment'**
  String get orderStatusAwaitingPayment;

  /// No description provided for @orderStatusWashing.
  ///
  /// In en, this message translates to:
  /// **'Washing'**
  String get orderStatusWashing;

  /// No description provided for @orderStatusReadyForDelivery.
  ///
  /// In en, this message translates to:
  /// **'Ready for delivery'**
  String get orderStatusReadyForDelivery;

  /// No description provided for @orderStatusOutForDelivery.
  ///
  /// In en, this message translates to:
  /// **'Out for delivery'**
  String get orderStatusOutForDelivery;

  /// No description provided for @orderStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get orderStatusCompleted;

  /// No description provided for @orderStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get orderStatusCancelled;

  /// No description provided for @orderStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get orderStatusUnknown;

  /// No description provided for @timelinePlaced.
  ///
  /// In en, this message translates to:
  /// **'Placed'**
  String get timelinePlaced;

  /// No description provided for @timelineAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get timelineAccepted;

  /// No description provided for @timelinePickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get timelinePickup;

  /// No description provided for @timelineWashing.
  ///
  /// In en, this message translates to:
  /// **'Washing'**
  String get timelineWashing;

  /// No description provided for @timelineOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get timelineOnTheWay;

  /// No description provided for @timelineCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get timelineCompleted;

  /// No description provided for @timelineOrderCancelled.
  ///
  /// In en, this message translates to:
  /// **'Order cancelled'**
  String get timelineOrderCancelled;

  /// No description provided for @commonEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get commonEmailLabel;

  /// No description provided for @commonPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get commonPasswordLabel;

  /// No description provided for @commonPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get commonPhoneLabel;

  /// No description provided for @commonFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get commonFullNameLabel;

  /// No description provided for @commonConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get commonConfirmPasswordLabel;

  /// No description provided for @commonCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get commonCreateAccount;

  /// No description provided for @commonEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get commonEmailRequired;

  /// No description provided for @commonEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get commonEmailInvalid;

  /// No description provided for @commonPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get commonPasswordRequired;

  /// No description provided for @commonPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get commonPasswordTooShort;

  /// No description provided for @commonConfirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get commonConfirmPasswordRequired;

  /// No description provided for @commonPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get commonPasswordsDoNotMatch;

  /// No description provided for @commonFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'{label} is required'**
  String commonFieldRequired(String label);

  /// No description provided for @commonShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get commonShowPassword;

  /// No description provided for @commonHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get commonHidePassword;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to continue.'**
  String get loginSubtitle;

  /// No description provided for @loginSubmit.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get loginSubmit;

  /// No description provided for @loginNoAccountQuestion.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get loginNoAccountQuestion;

  /// No description provided for @loginRegisterAction.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get loginRegisterAction;

  /// No description provided for @roleSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Washly'**
  String get roleSelectTitle;

  /// No description provided for @roleSelectSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to join.'**
  String get roleSelectSubtitle;

  /// No description provided for @roleSelectCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get roleSelectCustomerTitle;

  /// No description provided for @roleSelectCustomerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Order laundry pickup & delivery'**
  String get roleSelectCustomerSubtitle;

  /// No description provided for @roleSelectPartnerTitle.
  ///
  /// In en, this message translates to:
  /// **'Laundromat Partner'**
  String get roleSelectPartnerTitle;

  /// No description provided for @roleSelectPartnerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your shop and orders'**
  String get roleSelectPartnerSubtitle;

  /// No description provided for @roleSelectDriverTitle.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get roleSelectDriverTitle;

  /// No description provided for @roleSelectDriverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick up and deliver orders'**
  String get roleSelectDriverSubtitle;

  /// No description provided for @roleSelectHaveAccountQuestion.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get roleSelectHaveAccountQuestion;

  /// No description provided for @roleSelectLoginAction.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get roleSelectLoginAction;

  /// No description provided for @registerCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer sign up'**
  String get registerCustomerTitle;

  /// No description provided for @registerDriverTitle.
  ///
  /// In en, this message translates to:
  /// **'Driver sign up'**
  String get registerDriverTitle;

  /// No description provided for @registerDriverVehicleTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Vehicle type (e.g. motorcycle)'**
  String get registerDriverVehicleTypeLabel;

  /// No description provided for @registerDriverPlateNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Plate number'**
  String get registerDriverPlateNumberLabel;

  /// No description provided for @registerPartnerTitle.
  ///
  /// In en, this message translates to:
  /// **'Partner sign up'**
  String get registerPartnerTitle;

  /// No description provided for @registerPartnerSelectSpecialty.
  ///
  /// In en, this message translates to:
  /// **'Select at least one specialty.'**
  String get registerPartnerSelectSpecialty;

  /// No description provided for @registerPartnerSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get registerPartnerSectionAccount;

  /// No description provided for @registerPartnerSectionBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get registerPartnerSectionBusiness;

  /// No description provided for @registerPartnerSectionSpecialties.
  ///
  /// In en, this message translates to:
  /// **'Specialties'**
  String get registerPartnerSectionSpecialties;

  /// No description provided for @registerPartnerOwnerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Owner name'**
  String get registerPartnerOwnerNameLabel;

  /// No description provided for @registerPartnerBusinessNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Business name'**
  String get registerPartnerBusinessNameLabel;

  /// No description provided for @registerPartnerBusinessAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Business address'**
  String get registerPartnerBusinessAddressLabel;

  /// No description provided for @registerPartnerLatitudeLabel.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get registerPartnerLatitudeLabel;

  /// No description provided for @registerPartnerLongitudeLabel.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get registerPartnerLongitudeLabel;

  /// No description provided for @registerPartnerCoordinateInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get registerPartnerCoordinateInvalid;

  /// No description provided for @registerPartnerPricingModelLabel.
  ///
  /// In en, this message translates to:
  /// **'Pricing model'**
  String get registerPartnerPricingModelLabel;

  /// No description provided for @registerPartnerPricingPerKg.
  ///
  /// In en, this message translates to:
  /// **'Per kilogram'**
  String get registerPartnerPricingPerKg;

  /// No description provided for @registerPartnerPricingPerItem.
  ///
  /// In en, this message translates to:
  /// **'Per item'**
  String get registerPartnerPricingPerItem;

  /// No description provided for @registerPartnerSpecialtyShoes.
  ///
  /// In en, this message translates to:
  /// **'shoes'**
  String get registerPartnerSpecialtyShoes;

  /// No description provided for @registerPartnerSpecialtyBags.
  ///
  /// In en, this message translates to:
  /// **'bags'**
  String get registerPartnerSpecialtyBags;

  /// No description provided for @registerPartnerSpecialtyDolls.
  ///
  /// In en, this message translates to:
  /// **'dolls'**
  String get registerPartnerSpecialtyDolls;

  /// No description provided for @registerPartnerSpecialtyCostumes.
  ///
  /// In en, this message translates to:
  /// **'costumes'**
  String get registerPartnerSpecialtyCostumes;

  /// No description provided for @registerPartnerSpecialtyExpress.
  ///
  /// In en, this message translates to:
  /// **'express'**
  String get registerPartnerSpecialtyExpress;

  /// No description provided for @registerPartnerSpecialtyIroning.
  ///
  /// In en, this message translates to:
  /// **'ironing'**
  String get registerPartnerSpecialtyIroning;

  /// No description provided for @registerPartnerSpecialtyKiloan.
  ///
  /// In en, this message translates to:
  /// **'kiloan'**
  String get registerPartnerSpecialtyKiloan;

  /// No description provided for @registerPartnerSpecialtyDryClean.
  ///
  /// In en, this message translates to:
  /// **'dry clean'**
  String get registerPartnerSpecialtyDryClean;

  /// No description provided for @accountSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Account settings'**
  String get accountSettingsTitle;

  /// No description provided for @accountLogoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get accountLogoutTitle;

  /// No description provided for @accountLogoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get accountLogoutConfirm;

  /// No description provided for @accountShopProfile.
  ///
  /// In en, this message translates to:
  /// **'Shop profile'**
  String get accountShopProfile;

  /// No description provided for @accountEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get accountEditProfile;

  /// No description provided for @accountChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get accountChangePassword;

  /// No description provided for @accountChangeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get accountChangeLanguage;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileTitle;

  /// No description provided for @editProfileChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get editProfileChangePhoto;

  /// No description provided for @editProfilePhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Photo updated.'**
  String get editProfilePhotoUpdated;

  /// No description provided for @editProfilePickerError.
  ///
  /// In en, this message translates to:
  /// **'Could not open the picker: {error}'**
  String editProfilePickerError(String error);

  /// No description provided for @editProfileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated.'**
  String get editProfileUpdated;

  /// No description provided for @editProfileNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get editProfileNameLabel;

  /// No description provided for @editProfileNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get editProfileNameRequired;

  /// No description provided for @editProfilePhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone is required'**
  String get editProfilePhoneRequired;

  /// No description provided for @editProfileSave.
  ///
  /// In en, this message translates to:
  /// **'Save profile'**
  String get editProfileSave;

  /// No description provided for @navVouchers.
  ///
  /// In en, this message translates to:
  /// **'Vouchers'**
  String get navVouchers;

  /// No description provided for @commonSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get commonSeeAll;

  /// No description provided for @commonRedeem.
  ///
  /// In en, this message translates to:
  /// **'Redeem'**
  String get commonRedeem;

  /// No description provided for @commonSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get commonSubmit;

  /// No description provided for @commonPost.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get commonPost;

  /// No description provided for @commonNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get commonNotNow;

  /// No description provided for @orderN.
  ///
  /// In en, this message translates to:
  /// **'Order #{id}'**
  String orderN(int id);

  /// No description provided for @orderNumber.
  ///
  /// In en, this message translates to:
  /// **'#{id}'**
  String orderNumber(int id);

  /// No description provided for @moneyRp.
  ///
  /// In en, this message translates to:
  /// **'Rp {amount}'**
  String moneyRp(String amount);

  /// No description provided for @moneyRpOff.
  ///
  /// In en, this message translates to:
  /// **'Rp {amount} off'**
  String moneyRpOff(String amount);

  /// No description provided for @moneyRpNegative.
  ///
  /// In en, this message translates to:
  /// **'- Rp {amount}'**
  String moneyRpNegative(String amount);

  /// No description provided for @serviceTagShoes.
  ///
  /// In en, this message translates to:
  /// **'Shoes'**
  String get serviceTagShoes;

  /// No description provided for @serviceTagBags.
  ///
  /// In en, this message translates to:
  /// **'Bags'**
  String get serviceTagBags;

  /// No description provided for @serviceTagDolls.
  ///
  /// In en, this message translates to:
  /// **'Dolls'**
  String get serviceTagDolls;

  /// No description provided for @serviceTagCostumes.
  ///
  /// In en, this message translates to:
  /// **'Costumes'**
  String get serviceTagCostumes;

  /// No description provided for @serviceTagExpress.
  ///
  /// In en, this message translates to:
  /// **'Express'**
  String get serviceTagExpress;

  /// No description provided for @serviceTagIroning.
  ///
  /// In en, this message translates to:
  /// **'Ironing'**
  String get serviceTagIroning;

  /// No description provided for @serviceTagKiloan.
  ///
  /// In en, this message translates to:
  /// **'Kiloan'**
  String get serviceTagKiloan;

  /// No description provided for @serviceTagDryClean.
  ///
  /// In en, this message translates to:
  /// **'Dry Clean'**
  String get serviceTagDryClean;

  /// No description provided for @sortTopRated.
  ///
  /// In en, this message translates to:
  /// **'Top Rated'**
  String get sortTopRated;

  /// No description provided for @sortNearest.
  ///
  /// In en, this message translates to:
  /// **'Nearest'**
  String get sortNearest;

  /// No description provided for @filterServices.
  ///
  /// In en, this message translates to:
  /// **'Filter Services'**
  String get filterServices;

  /// No description provided for @filterServicesCount.
  ///
  /// In en, this message translates to:
  /// **'Services ({count})'**
  String filterServicesCount(int count);

  /// No description provided for @filterReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get filterReset;

  /// No description provided for @filterApplyCount.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters ({count})'**
  String filterApplyCount(int count);

  /// No description provided for @homeSpecialties.
  ///
  /// In en, this message translates to:
  /// **'Specialties'**
  String get homeSpecialties;

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Find a laundromat'**
  String get homeSearchHint;

  /// No description provided for @homeWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get homeWelcomeBack;

  /// No description provided for @homeGreetingFallback.
  ///
  /// In en, this message translates to:
  /// **'there'**
  String get homeGreetingFallback;

  /// No description provided for @homeLoyaltyWallet.
  ///
  /// In en, this message translates to:
  /// **'Loyalty wallet'**
  String get homeLoyaltyWallet;

  /// No description provided for @homePoints.
  ///
  /// In en, this message translates to:
  /// **'{count} points'**
  String homePoints(int count);

  /// No description provided for @homeRedeemPrompt.
  ///
  /// In en, this message translates to:
  /// **'Redeem your points for vouchers.'**
  String get homeRedeemPrompt;

  /// No description provided for @homeVouchersReady.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} voucher ready at checkout.} other{{count} vouchers ready at checkout.}}'**
  String homeVouchersReady(int count);

  /// No description provided for @homeActiveOrders.
  ///
  /// In en, this message translates to:
  /// **'Active Orders'**
  String get homeActiveOrders;

  /// No description provided for @homeNoActiveOrders.
  ///
  /// In en, this message translates to:
  /// **'No active orders right now.'**
  String get homeNoActiveOrders;

  /// No description provided for @homeYourOrder.
  ///
  /// In en, this message translates to:
  /// **'Your order'**
  String get homeYourOrder;

  /// No description provided for @homeTapToTrack.
  ///
  /// In en, this message translates to:
  /// **'Order #{id} · tap to track'**
  String homeTapToTrack(int id);

  /// No description provided for @homeActionConfirmWeighedPrice.
  ///
  /// In en, this message translates to:
  /// **'Action needed: confirm your weighed price'**
  String get homeActionConfirmWeighedPrice;

  /// No description provided for @homeNearbyLaundromats.
  ///
  /// In en, this message translates to:
  /// **'Nearby Laundromats'**
  String get homeNearbyLaundromats;

  /// No description provided for @homeNoLaundromatsYet.
  ///
  /// In en, this message translates to:
  /// **'No laundromats available yet.'**
  String get homeNoLaundromatsYet;

  /// No description provided for @ordersTitle.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get ordersTitle;

  /// No description provided for @ordersEmptyActive.
  ///
  /// In en, this message translates to:
  /// **'No active orders. Place one from Discovery.'**
  String get ordersEmptyActive;

  /// No description provided for @ordersEmptyHistory.
  ///
  /// In en, this message translates to:
  /// **'No past orders yet.'**
  String get ordersEmptyHistory;

  /// No description provided for @ordersLaundromatFallback.
  ///
  /// In en, this message translates to:
  /// **'Laundromat'**
  String get ordersLaundromatFallback;

  /// No description provided for @ordersItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} item} other{{count} items}}'**
  String ordersItemCount(int count);

  /// No description provided for @ordersPerKgSuffix.
  ///
  /// In en, this message translates to:
  /// **'per kg'**
  String get ordersPerKgSuffix;

  /// No description provided for @ordersActionConfirmPrice.
  ///
  /// In en, this message translates to:
  /// **'Action needed: confirm price'**
  String get ordersActionConfirmPrice;

  /// No description provided for @ordersWeighedAtPickup.
  ///
  /// In en, this message translates to:
  /// **'Weighed at pickup'**
  String get ordersWeighedAtPickup;

  /// No description provided for @vouchersTitle.
  ///
  /// In en, this message translates to:
  /// **'Vouchers'**
  String get vouchersTitle;

  /// No description provided for @vouchersRedeemedToast.
  ///
  /// In en, this message translates to:
  /// **'Redeemed a Rp {amount} voucher!'**
  String vouchersRedeemedToast(String amount);

  /// No description provided for @vouchersRedeemPoints.
  ///
  /// In en, this message translates to:
  /// **'Redeem Points'**
  String get vouchersRedeemPoints;

  /// No description provided for @vouchersRedeemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a reward to redeem with your points.'**
  String get vouchersRedeemSubtitle;

  /// No description provided for @vouchersNoRewards.
  ///
  /// In en, this message translates to:
  /// **'No rewards available right now.'**
  String get vouchersNoRewards;

  /// No description provided for @vouchersYourVouchers.
  ///
  /// In en, this message translates to:
  /// **'Your Vouchers'**
  String get vouchersYourVouchers;

  /// No description provided for @vouchersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No vouchers yet. Redeem points to get one.'**
  String get vouchersEmpty;

  /// No description provided for @vouchersEarnRate.
  ///
  /// In en, this message translates to:
  /// **'Earn 5 points per Rp 10.000 spent.'**
  String get vouchersEarnRate;

  /// No description provided for @vouchersTierPoints.
  ///
  /// In en, this message translates to:
  /// **'{count} points'**
  String vouchersTierPoints(int count);

  /// No description provided for @vouchersNeedMorePoints.
  ///
  /// In en, this message translates to:
  /// **'Need {count} more points'**
  String vouchersNeedMorePoints(int count);

  /// No description provided for @vouchersUsed.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get vouchersUsed;

  /// No description provided for @vouchersAvailableAtCheckout.
  ///
  /// In en, this message translates to:
  /// **'Available at checkout'**
  String get vouchersAvailableAtCheckout;

  /// No description provided for @voucherSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Apply a voucher'**
  String get voucherSelectTitle;

  /// No description provided for @voucherSelectCountAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} voucher available} other{{count} vouchers available}}'**
  String voucherSelectCountAvailable(int count);

  /// No description provided for @voucherSelectRemoveApplied.
  ///
  /// In en, this message translates to:
  /// **'Remove applied voucher'**
  String get voucherSelectRemoveApplied;

  /// No description provided for @voucherSelectDiscountVoucher.
  ///
  /// In en, this message translates to:
  /// **'Discount voucher'**
  String get voucherSelectDiscountVoucher;

  /// No description provided for @voucherSelectEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'There are no vouchers'**
  String get voucherSelectEmptyTitle;

  /// No description provided for @voucherSelectEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Redeem your loyalty points for vouchers, then apply them here.'**
  String get voucherSelectEmptyBody;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search name, service, or area'**
  String get searchHint;

  /// No description provided for @searchPrompt.
  ///
  /// In en, this message translates to:
  /// **'Type a name, service, or area, then hit search.'**
  String get searchPrompt;

  /// No description provided for @searchNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No laundromats match your search.'**
  String get searchNoMatches;

  /// No description provided for @discoveryError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String discoveryError(String error);

  /// No description provided for @discoveryNoLaundromats.
  ///
  /// In en, this message translates to:
  /// **'No laundromats found.'**
  String get discoveryNoLaundromats;

  /// No description provided for @discoveryReviewCount.
  ///
  /// In en, this message translates to:
  /// **'({count})'**
  String discoveryReviewCount(int count);

  /// No description provided for @discoveryDistanceKm.
  ///
  /// In en, this message translates to:
  /// **'{distance} km'**
  String discoveryDistanceKm(String distance);

  /// No description provided for @discoveryAreaHidden.
  ///
  /// In en, this message translates to:
  /// **'Area shown after order'**
  String get discoveryAreaHidden;

  /// No description provided for @detailReviewsCount.
  ///
  /// In en, this message translates to:
  /// **'Reviews ({count})'**
  String detailReviewsCount(int count);

  /// No description provided for @detailReviewCountSuffix.
  ///
  /// In en, this message translates to:
  /// **' ({count} reviews)'**
  String detailReviewCountSuffix(int count);

  /// No description provided for @detailAreaHidden.
  ///
  /// In en, this message translates to:
  /// **'Area hidden until pickup'**
  String get detailAreaHidden;

  /// No description provided for @detailServicesMenu.
  ///
  /// In en, this message translates to:
  /// **'Services Menu'**
  String get detailServicesMenu;

  /// No description provided for @detailNoServices.
  ///
  /// In en, this message translates to:
  /// **'No services listed yet.'**
  String get detailNoServices;

  /// No description provided for @detailCustomerReviews.
  ///
  /// In en, this message translates to:
  /// **'{count} Customer Reviews'**
  String detailCustomerReviews(int count);

  /// No description provided for @detailAddReview.
  ///
  /// In en, this message translates to:
  /// **'Add Review'**
  String get detailAddReview;

  /// No description provided for @detailNoReviews.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet. Be the first to leave one!'**
  String get detailNoReviews;

  /// No description provided for @detailWriteReview.
  ///
  /// In en, this message translates to:
  /// **'Write a Review'**
  String get detailWriteReview;

  /// No description provided for @detailYourReview.
  ///
  /// In en, this message translates to:
  /// **'Your review'**
  String get detailYourReview;

  /// No description provided for @detailSignInToReview.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to review.'**
  String get detailSignInToReview;

  /// No description provided for @detailReviewFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String detailReviewFailed(String error);

  /// No description provided for @detailPricePerUnit.
  ///
  /// In en, this message translates to:
  /// **'Rp {price} / {unit}'**
  String detailPricePerUnit(String price, String unit);

  /// No description provided for @detailUnitKg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get detailUnitKg;

  /// No description provided for @detailUnitItem.
  ///
  /// In en, this message translates to:
  /// **'item'**
  String get detailUnitItem;

  /// No description provided for @detailQuantityOfItems.
  ///
  /// In en, this message translates to:
  /// **'Quantity of Items'**
  String get detailQuantityOfItems;

  /// No description provided for @detailPieces.
  ///
  /// In en, this message translates to:
  /// **'{count} pcs'**
  String detailPieces(int count);

  /// No description provided for @detailPerKgNote.
  ///
  /// In en, this message translates to:
  /// **'Priced by weight at Rp {price}/kg. The laundromat weighs your laundry after pickup and sends the price — you approve it before paying.'**
  String detailPerKgNote(String price);

  /// No description provided for @detailWashingInstructions.
  ///
  /// In en, this message translates to:
  /// **'Washing Instructions (Optional)'**
  String get detailWashingInstructions;

  /// No description provided for @detailItemDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Item Details (e.g. 2 Nike Dunks, 1 Coach bag)'**
  String get detailItemDetailsHint;

  /// No description provided for @detailAddToBasket.
  ///
  /// In en, this message translates to:
  /// **'Add to Basket'**
  String get detailAddToBasket;

  /// No description provided for @detailAddToBasketPrice.
  ///
  /// In en, this message translates to:
  /// **'Add to Basket • Rp {price}'**
  String detailAddToBasketPrice(String price);

  /// No description provided for @detailNewBasketTitle.
  ///
  /// In en, this message translates to:
  /// **'Start a new basket?'**
  String get detailNewBasketTitle;

  /// No description provided for @detailNewBasketBody.
  ///
  /// In en, this message translates to:
  /// **'Your basket has items from {name}. Adding this will clear it and start a new basket at {store}.'**
  String detailNewBasketBody(String name, String store);

  /// No description provided for @detailAnotherLaundromat.
  ///
  /// In en, this message translates to:
  /// **'another laundromat'**
  String get detailAnotherLaundromat;

  /// No description provided for @detailClearAndAdd.
  ///
  /// In en, this message translates to:
  /// **'Clear & add'**
  String get detailClearAndAdd;

  /// No description provided for @detailInBasket.
  ///
  /// In en, this message translates to:
  /// **'In basket'**
  String get detailInBasket;

  /// No description provided for @detailItemsInBasket.
  ///
  /// In en, this message translates to:
  /// **'{count} items in basket'**
  String detailItemsInBasket(int count);

  /// No description provided for @detailWeighedAtPickupArrow.
  ///
  /// In en, this message translates to:
  /// **'Weighed at pickup  ➔'**
  String get detailWeighedAtPickupArrow;

  /// No description provided for @detailBasketTotalArrow.
  ///
  /// In en, this message translates to:
  /// **'Rp {amount}  ➔'**
  String detailBasketTotalArrow(String amount);

  /// No description provided for @orderDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orderDetailTitle;

  /// No description provided for @orderDetailPriceApprovedToast.
  ///
  /// In en, this message translates to:
  /// **'Price approved. Proceed to payment.'**
  String get orderDetailPriceApprovedToast;

  /// No description provided for @orderDetailPaymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Payment received.'**
  String get orderDetailPaymentReceived;

  /// No description provided for @orderDetailPaymentPending.
  ///
  /// In en, this message translates to:
  /// **'Payment pending confirmation.'**
  String get orderDetailPaymentPending;

  /// No description provided for @orderDetailPaymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed. You can try again.'**
  String get orderDetailPaymentFailed;

  /// No description provided for @orderDetailPaymentClosed.
  ///
  /// In en, this message translates to:
  /// **'Payment window closed.'**
  String get orderDetailPaymentClosed;

  /// No description provided for @orderDetailPaymentLaunched.
  ///
  /// In en, this message translates to:
  /// **'Payment opened. This order updates once confirmed.'**
  String get orderDetailPaymentLaunched;

  /// No description provided for @orderDetailDriverPickingUp.
  ///
  /// In en, this message translates to:
  /// **'Driver picking up your laundry'**
  String get orderDetailDriverPickingUp;

  /// No description provided for @orderDetailDriverDelivering.
  ///
  /// In en, this message translates to:
  /// **'Driver delivering your laundry'**
  String get orderDetailDriverDelivering;

  /// No description provided for @orderDetailLookingForPickup.
  ///
  /// In en, this message translates to:
  /// **'Looking for a driver to pick up your laundry'**
  String get orderDetailLookingForPickup;

  /// No description provided for @orderDetailLookingForDelivery.
  ///
  /// In en, this message translates to:
  /// **'Looking for a driver to deliver your laundry'**
  String get orderDetailLookingForDelivery;

  /// No description provided for @orderDetailVehicleFallback.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get orderDetailVehicleFallback;

  /// No description provided for @orderDetailLaundromatFallback.
  ///
  /// In en, this message translates to:
  /// **'Laundromat'**
  String get orderDetailLaundromatFallback;

  /// No description provided for @orderDetailConfirmWeighedPrice.
  ///
  /// In en, this message translates to:
  /// **'Confirm your weighed price'**
  String get orderDetailConfirmWeighedPrice;

  /// No description provided for @orderDetailWeighedExplainer.
  ///
  /// In en, this message translates to:
  /// **'The laundromat weighed your laundry. Review the price and your items below, then approve to continue to payment.'**
  String get orderDetailWeighedExplainer;

  /// No description provided for @orderDetailMeasuredWeight.
  ///
  /// In en, this message translates to:
  /// **'Measured weight'**
  String get orderDetailMeasuredWeight;

  /// No description provided for @orderDetailKg.
  ///
  /// In en, this message translates to:
  /// **'{value} kg'**
  String orderDetailKg(String value);

  /// No description provided for @orderDetailWashSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Wash subtotal'**
  String get orderDetailWashSubtotal;

  /// No description provided for @orderDetailDeliveryFee.
  ///
  /// In en, this message translates to:
  /// **'Delivery fee'**
  String get orderDetailDeliveryFee;

  /// No description provided for @orderDetailDeclaredProtection.
  ///
  /// In en, this message translates to:
  /// **'Declared items protection'**
  String get orderDetailDeclaredProtection;

  /// No description provided for @orderDetailVoucher.
  ///
  /// In en, this message translates to:
  /// **'Voucher'**
  String get orderDetailVoucher;

  /// No description provided for @orderDetailFinalPrice.
  ///
  /// In en, this message translates to:
  /// **'Final price'**
  String get orderDetailFinalPrice;

  /// No description provided for @orderDetailApproveContinue.
  ///
  /// In en, this message translates to:
  /// **'Approve & continue to payment'**
  String get orderDetailApproveContinue;

  /// No description provided for @orderDetailDeclaredReceived.
  ///
  /// In en, this message translates to:
  /// **'Declared items  ({received}/{total} received)'**
  String orderDetailDeclaredReceived(int received, int total);

  /// No description provided for @orderDetailNotReceived.
  ///
  /// In en, this message translates to:
  /// **'Not received'**
  String get orderDetailNotReceived;

  /// No description provided for @orderDetailPaymentRequired.
  ///
  /// In en, this message translates to:
  /// **'Payment required'**
  String get orderDetailPaymentRequired;

  /// No description provided for @orderDetailAmountDue.
  ///
  /// In en, this message translates to:
  /// **'Amount due'**
  String get orderDetailAmountDue;

  /// No description provided for @orderDetailPayNow.
  ///
  /// In en, this message translates to:
  /// **'Pay now'**
  String get orderDetailPayNow;

  /// No description provided for @orderDetailProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get orderDetailProgress;

  /// No description provided for @orderDetailReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get orderDetailReceipt;

  /// No description provided for @orderDetailSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get orderDetailSubtotal;

  /// No description provided for @orderDetailWeighed.
  ///
  /// In en, this message translates to:
  /// **'Weighed'**
  String get orderDetailWeighed;

  /// No description provided for @orderDetailGrandTotal.
  ///
  /// In en, this message translates to:
  /// **'Grand total'**
  String get orderDetailGrandTotal;

  /// No description provided for @orderDetailAfterWeighing.
  ///
  /// In en, this message translates to:
  /// **'After weighing'**
  String get orderDetailAfterWeighing;

  /// No description provided for @orderDetailPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get orderDetailPayment;

  /// No description provided for @orderDetailPaymentNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get orderDetailPaymentNotStarted;

  /// No description provided for @orderDetailUnitKg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get orderDetailUnitKg;

  /// No description provided for @orderDetailUnitPcs.
  ///
  /// In en, this message translates to:
  /// **'pcs'**
  String get orderDetailUnitPcs;

  /// No description provided for @orderDetailDeclaredItems.
  ///
  /// In en, this message translates to:
  /// **'Declared items'**
  String get orderDetailDeclaredItems;

  /// No description provided for @orderDetailReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get orderDetailReceived;

  /// No description provided for @orderDetailAwaitingIntake.
  ///
  /// In en, this message translates to:
  /// **'Awaiting intake'**
  String get orderDetailAwaitingIntake;

  /// No description provided for @orderDetailHowDidItGo.
  ///
  /// In en, this message translates to:
  /// **'How did it go?'**
  String get orderDetailHowDidItGo;

  /// No description provided for @orderDetailRateLaundromat.
  ///
  /// In en, this message translates to:
  /// **'Rate laundromat'**
  String get orderDetailRateLaundromat;

  /// No description provided for @orderDetailWarranty.
  ///
  /// In en, this message translates to:
  /// **'Warranty'**
  String get orderDetailWarranty;

  /// No description provided for @orderDetailWarrantyOnlyDeclared.
  ///
  /// In en, this message translates to:
  /// **'Warranty is available only for declared items the laundromat confirmed at intake.'**
  String get orderDetailWarrantyOnlyDeclared;

  /// No description provided for @orderDetailWarrantyClaims.
  ///
  /// In en, this message translates to:
  /// **'Warranty claims'**
  String get orderDetailWarrantyClaims;

  /// No description provided for @orderDetailNoClaims.
  ///
  /// In en, this message translates to:
  /// **'No claims filed. Tap \"Warranty\" above if something went wrong with a declared item.'**
  String get orderDetailNoClaims;

  /// No description provided for @orderDetailRateThisLaundromat.
  ///
  /// In en, this message translates to:
  /// **'Rate this laundromat'**
  String get orderDetailRateThisLaundromat;

  /// No description provided for @orderDetailAddCommentOptional.
  ///
  /// In en, this message translates to:
  /// **'Add a comment (optional)'**
  String get orderDetailAddCommentOptional;

  /// No description provided for @orderDetailSignInToRate.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to rate.'**
  String get orderDetailSignInToRate;

  /// No description provided for @orderDetailRatingThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks for your rating!'**
  String get orderDetailRatingThanks;

  /// No description provided for @orderDetailUseWarrantyTitle.
  ///
  /// In en, this message translates to:
  /// **'Use your warranty?'**
  String get orderDetailUseWarrantyTitle;

  /// No description provided for @orderDetailWarrantyExplainer.
  ///
  /// In en, this message translates to:
  /// **'Your declared items are covered by Washly warranty. If one was lost or damaged, you can file a claim with photos and the laundromat will review it.'**
  String get orderDetailWarrantyExplainer;

  /// No description provided for @orderDetailCoveredItems.
  ///
  /// In en, this message translates to:
  /// **'Covered items'**
  String get orderDetailCoveredItems;

  /// No description provided for @orderDetailFileClaim.
  ///
  /// In en, this message translates to:
  /// **'File a claim'**
  String get orderDetailFileClaim;

  /// No description provided for @orderDetailItemFallback.
  ///
  /// In en, this message translates to:
  /// **'Item #{id}'**
  String orderDetailItemFallback(int id);

  /// No description provided for @orderDetailResolution.
  ///
  /// In en, this message translates to:
  /// **'Resolution: {note}'**
  String orderDetailResolution(String note);

  /// No description provided for @orderDetailPayout.
  ///
  /// In en, this message translates to:
  /// **'Payout: Rp {amount} (Washly)'**
  String orderDetailPayout(String amount);

  /// No description provided for @orderDetailFileClaimTitle.
  ///
  /// In en, this message translates to:
  /// **'File a warranty claim'**
  String get orderDetailFileClaimTitle;

  /// No description provided for @orderDetailItem.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get orderDetailItem;

  /// No description provided for @orderDetailWhatWentWrong.
  ///
  /// In en, this message translates to:
  /// **'What went wrong?'**
  String get orderDetailWhatWentWrong;

  /// No description provided for @orderDetailPickItemDescribe.
  ///
  /// In en, this message translates to:
  /// **'Pick an item and describe the issue.'**
  String get orderDetailPickItemDescribe;

  /// No description provided for @orderDetailAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get orderDetailAddPhoto;

  /// No description provided for @orderDetailPhotosAttached.
  ///
  /// In en, this message translates to:
  /// **'{count} attached'**
  String orderDetailPhotosAttached(int count);

  /// No description provided for @orderDetailSubmitClaim.
  ///
  /// In en, this message translates to:
  /// **'Submit claim'**
  String get orderDetailSubmitClaim;

  /// No description provided for @orderDetailClaimSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Claim submitted.'**
  String get orderDetailClaimSubmitted;

  /// No description provided for @checkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Checkout Order'**
  String get checkoutTitle;

  /// No description provided for @checkoutPickerError.
  ///
  /// In en, this message translates to:
  /// **'Could not open the picker: {error}'**
  String checkoutPickerError(String error);

  /// No description provided for @checkoutLabelItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Label this item'**
  String get checkoutLabelItemTitle;

  /// No description provided for @checkoutLabelItemHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. White Nike Air Force 1'**
  String get checkoutLabelItemHint;

  /// No description provided for @checkoutEnterPickupAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter your pickup address.'**
  String get checkoutEnterPickupAddress;

  /// No description provided for @checkoutSignInToOrder.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to place an order.'**
  String get checkoutSignInToOrder;

  /// No description provided for @checkoutPaymentReceivedTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment received'**
  String get checkoutPaymentReceivedTitle;

  /// No description provided for @checkoutPaymentReceivedBody.
  ///
  /// In en, this message translates to:
  /// **'Thanks! Your payment is confirmed. Track this order in the Orders tab.'**
  String get checkoutPaymentReceivedBody;

  /// No description provided for @checkoutPaymentPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment pending'**
  String get checkoutPaymentPendingTitle;

  /// No description provided for @checkoutPaymentPendingBody.
  ///
  /// In en, this message translates to:
  /// **'Your payment is being processed. This order updates automatically once it is confirmed.'**
  String get checkoutPaymentPendingBody;

  /// No description provided for @checkoutPaymentNotCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment not completed'**
  String get checkoutPaymentNotCompletedTitle;

  /// No description provided for @checkoutPaymentNotCompletedBody.
  ///
  /// In en, this message translates to:
  /// **'You closed the payment window. Your order is saved — you can pay from the Orders tab anytime.'**
  String get checkoutPaymentNotCompletedBody;

  /// No description provided for @checkoutPaymentFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment failed'**
  String get checkoutPaymentFailedTitle;

  /// No description provided for @checkoutPaymentFailedBody.
  ///
  /// In en, this message translates to:
  /// **'The payment did not go through. Your order is saved — try again from the Orders tab.'**
  String get checkoutPaymentFailedBody;

  /// No description provided for @checkoutCompletePaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your payment'**
  String get checkoutCompletePaymentTitle;

  /// No description provided for @checkoutCompletePaymentBody.
  ///
  /// In en, this message translates to:
  /// **'We opened the payment page. This order updates automatically once payment is confirmed.'**
  String get checkoutCompletePaymentBody;

  /// No description provided for @checkoutOrderPlacedTitle.
  ///
  /// In en, this message translates to:
  /// **'Order placed'**
  String get checkoutOrderPlacedTitle;

  /// No description provided for @checkoutOrderPlacedPaymentError.
  ///
  /// In en, this message translates to:
  /// **'Your order was created, but we could not open payment: {error}. You can pay from the Orders tab.'**
  String checkoutOrderPlacedPaymentError(String error);

  /// No description provided for @checkoutPerKgPlacedTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Placed'**
  String get checkoutPerKgPlacedTitle;

  /// No description provided for @checkoutPerKgPlacedBody.
  ///
  /// In en, this message translates to:
  /// **'Your order is waiting for the laundromat to accept it. The final price is set after your laundry is weighed — you will pay then.'**
  String get checkoutPerKgPlacedBody;

  /// No description provided for @checkoutDeliveryPickupDetails.
  ///
  /// In en, this message translates to:
  /// **'Delivery & Pickup Details'**
  String get checkoutDeliveryPickupDetails;

  /// No description provided for @checkoutPickupAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Pickup & Return Address'**
  String get checkoutPickupAddressLabel;

  /// No description provided for @checkoutNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes for driver / laundromat (optional)'**
  String get checkoutNotesLabel;

  /// No description provided for @checkoutNotesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Leave with security, house with black gate'**
  String get checkoutNotesHint;

  /// No description provided for @checkoutOrderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get checkoutOrderSummary;

  /// No description provided for @checkoutDeclaredItemsOptional.
  ///
  /// In en, this message translates to:
  /// **'Declared items (optional)'**
  String get checkoutDeclaredItemsOptional;

  /// No description provided for @checkoutDeclaredExplainer.
  ///
  /// In en, this message translates to:
  /// **'Declared items are valuables you photograph before pickup — like a jacket, branded sneakers, or a bedcover.'**
  String get checkoutDeclaredExplainer;

  /// No description provided for @checkoutDeclaredBenefit.
  ///
  /// In en, this message translates to:
  /// **'The photo is proof of condition at drop-off, so you can file a warranty claim if an item is lost or damaged.'**
  String get checkoutDeclaredBenefit;

  /// No description provided for @checkoutDeclaredFeeNote.
  ///
  /// In en, this message translates to:
  /// **'Adding declared items applies a one-time Rp {fee} protection fee to this order.'**
  String checkoutDeclaredFeeNote(String fee);

  /// No description provided for @checkoutVoucherApplied.
  ///
  /// In en, this message translates to:
  /// **'Voucher applied'**
  String get checkoutVoucherApplied;

  /// No description provided for @checkoutApplyVoucher.
  ///
  /// In en, this message translates to:
  /// **'Apply a voucher'**
  String get checkoutApplyVoucher;

  /// No description provided for @checkoutPlaceOrder.
  ///
  /// In en, this message translates to:
  /// **'Place Order'**
  String get checkoutPlaceOrder;

  /// No description provided for @checkoutPricePerKg.
  ///
  /// In en, this message translates to:
  /// **'Rp {price}/kg'**
  String checkoutPricePerKg(String price);

  /// No description provided for @checkoutPiecesPrefix.
  ///
  /// In en, this message translates to:
  /// **'{count}pcs x '**
  String checkoutPiecesPrefix(int count);

  /// No description provided for @checkoutEstimatedWashPerKg.
  ///
  /// In en, this message translates to:
  /// **'Estimated wash (per kg)'**
  String get checkoutEstimatedWashPerKg;

  /// No description provided for @checkoutWashSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Wash Subtotal'**
  String get checkoutWashSubtotal;

  /// No description provided for @checkoutWeighedAtPickup.
  ///
  /// In en, this message translates to:
  /// **'Weighed at pickup'**
  String get checkoutWeighedAtPickup;

  /// No description provided for @checkoutDeclaredProtection.
  ///
  /// In en, this message translates to:
  /// **'Declared items protection'**
  String get checkoutDeclaredProtection;

  /// No description provided for @checkoutVoucher.
  ///
  /// In en, this message translates to:
  /// **'Voucher'**
  String get checkoutVoucher;

  /// No description provided for @checkoutPickupDeliveryFee.
  ///
  /// In en, this message translates to:
  /// **'Pickup & Delivery Fee'**
  String get checkoutPickupDeliveryFee;

  /// No description provided for @checkoutCalculatedAtPickup.
  ///
  /// In en, this message translates to:
  /// **'Calculated at pickup'**
  String get checkoutCalculatedAtPickup;

  /// No description provided for @checkoutFinalPrice.
  ///
  /// In en, this message translates to:
  /// **'Final price'**
  String get checkoutFinalPrice;

  /// No description provided for @checkoutTotalBeforeFee.
  ///
  /// In en, this message translates to:
  /// **'Total (before fee)'**
  String get checkoutTotalBeforeFee;

  /// No description provided for @checkoutAfterWeighing.
  ///
  /// In en, this message translates to:
  /// **'After weighing'**
  String get checkoutAfterWeighing;

  /// No description provided for @checkoutPerKgFooter.
  ///
  /// In en, this message translates to:
  /// **'Your laundry is priced by weight. You approve the final price after it is weighed, then pay.'**
  String get checkoutPerKgFooter;

  /// No description provided for @checkoutPerItemFooter.
  ///
  /// In en, this message translates to:
  /// **'The delivery fee is calculated from the pickup distance when you place the order.'**
  String get checkoutPerItemFooter;

  /// No description provided for @partnerDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get partnerDashboardTitle;

  /// No description provided for @partnerDashboardReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get partnerDashboardReport;

  /// No description provided for @partnerDashboardReportSaved.
  ///
  /// In en, this message translates to:
  /// **'Report saved to {where}.'**
  String partnerDashboardReportSaved(String where);

  /// No description provided for @partnerDashboardRangeDay.
  ///
  /// In en, this message translates to:
  /// **'This day'**
  String get partnerDashboardRangeDay;

  /// No description provided for @partnerDashboardRangeMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get partnerDashboardRangeMonth;

  /// No description provided for @partnerDashboardRangeYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get partnerDashboardRangeYear;

  /// No description provided for @partnerDashboardRevenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue (paid orders)'**
  String get partnerDashboardRevenue;

  /// No description provided for @partnerDashboardInProcess.
  ///
  /// In en, this message translates to:
  /// **'In process'**
  String get partnerDashboardInProcess;

  /// No description provided for @partnerDashboardCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get partnerDashboardCompleted;

  /// No description provided for @partnerDashboardTotalOrders.
  ///
  /// In en, this message translates to:
  /// **'Total orders'**
  String get partnerDashboardTotalOrders;

  /// No description provided for @partnerDashboardAvgReview.
  ///
  /// In en, this message translates to:
  /// **'Avg review · {count}'**
  String partnerDashboardAvgReview(int count);

  /// No description provided for @partnerDashboardNoReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get partnerDashboardNoReviewsYet;

  /// No description provided for @partnerDashboardSalesByProduct.
  ///
  /// In en, this message translates to:
  /// **'Sales by product'**
  String get partnerDashboardSalesByProduct;

  /// No description provided for @partnerDashboardNoSales.
  ///
  /// In en, this message translates to:
  /// **'No sales in this period yet.'**
  String get partnerDashboardNoSales;

  /// No description provided for @partnerDashboardRevenueAxis.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get partnerDashboardRevenueAxis;

  /// No description provided for @partnerOrdersTitle.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get partnerOrdersTitle;

  /// No description provided for @partnerOrdersActiveTab.
  ///
  /// In en, this message translates to:
  /// **'Active ({count})'**
  String partnerOrdersActiveTab(int count);

  /// No description provided for @partnerOrdersDoneTab.
  ///
  /// In en, this message translates to:
  /// **'Done ({count})'**
  String partnerOrdersDoneTab(int count);

  /// No description provided for @partnerOrdersEmptyActive.
  ///
  /// In en, this message translates to:
  /// **'No active orders.'**
  String get partnerOrdersEmptyActive;

  /// No description provided for @partnerOrdersEmptyDone.
  ///
  /// In en, this message translates to:
  /// **'No completed or cancelled orders yet.'**
  String get partnerOrdersEmptyDone;

  /// No description provided for @partnerOrdersOpenForOrders.
  ///
  /// In en, this message translates to:
  /// **'Open for orders'**
  String get partnerOrdersOpenForOrders;

  /// No description provided for @partnerOrdersClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get partnerOrdersClosed;

  /// No description provided for @partnerOrdersOpenHint.
  ///
  /// In en, this message translates to:
  /// **'Customers can place orders with your shop.'**
  String get partnerOrdersOpenHint;

  /// No description provided for @partnerOrdersClosedHint.
  ///
  /// In en, this message translates to:
  /// **'Your shop is hidden from new orders.'**
  String get partnerOrdersClosedHint;

  /// No description provided for @partnerOrdersPerKg.
  ///
  /// In en, this message translates to:
  /// **'Per kg'**
  String get partnerOrdersPerKg;

  /// No description provided for @partnerOrdersPerItem.
  ///
  /// In en, this message translates to:
  /// **'Per item'**
  String get partnerOrdersPerItem;

  /// No description provided for @partnerOrdersItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} item} other{{count} items}}'**
  String partnerOrdersItemCount(int count);

  /// No description provided for @partnerOrdersNeedsWarranty.
  ///
  /// In en, this message translates to:
  /// **'Needs warranty approval'**
  String get partnerOrdersNeedsWarranty;

  /// No description provided for @partnerOrdersWeighedAtPickup.
  ///
  /// In en, this message translates to:
  /// **'Weighed at pickup'**
  String get partnerOrdersWeighedAtPickup;

  /// No description provided for @partnerOrderDetailNotFound.
  ///
  /// In en, this message translates to:
  /// **'Order not found.'**
  String get partnerOrderDetailNotFound;

  /// No description provided for @partnerOrderDetailPerKgOrder.
  ///
  /// In en, this message translates to:
  /// **'Per kg order'**
  String get partnerOrderDetailPerKgOrder;

  /// No description provided for @partnerOrderDetailPerItemOrder.
  ///
  /// In en, this message translates to:
  /// **'Per item order'**
  String get partnerOrderDetailPerItemOrder;

  /// No description provided for @partnerOrderDetailItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get partnerOrderDetailItems;

  /// No description provided for @partnerOrderDetailDeclaredItems.
  ///
  /// In en, this message translates to:
  /// **'Declared items'**
  String get partnerOrderDetailDeclaredItems;

  /// No description provided for @partnerOrderDetailProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get partnerOrderDetailProgress;

  /// No description provided for @partnerOrderDetailWarrantyClaims.
  ///
  /// In en, this message translates to:
  /// **'Warranty claims'**
  String get partnerOrderDetailWarrantyClaims;

  /// No description provided for @partnerOrderDetailNeedsWarranty.
  ///
  /// In en, this message translates to:
  /// **'Needs warranty approval'**
  String get partnerOrderDetailNeedsWarranty;

  /// No description provided for @partnerOrderDetailReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get partnerOrderDetailReceived;

  /// No description provided for @partnerOrderDetailAwaitingAcceptance.
  ///
  /// In en, this message translates to:
  /// **'Awaiting acceptance'**
  String get partnerOrderDetailAwaitingAcceptance;

  /// No description provided for @partnerOrderDetailNotReceived.
  ///
  /// In en, this message translates to:
  /// **'Not received'**
  String get partnerOrderDetailNotReceived;

  /// No description provided for @partnerOrderDetailVehicleFallback.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get partnerOrderDetailVehicleFallback;

  /// No description provided for @partnerOrderDetailClaimPhoto.
  ///
  /// In en, this message translates to:
  /// **'Claim photo'**
  String get partnerOrderDetailClaimPhoto;

  /// No description provided for @partnerOrderDetailWaitWashAfterPayment.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the wash to begin after payment.'**
  String get partnerOrderDetailWaitWashAfterPayment;

  /// No description provided for @partnerOrderDetailWaitCustomerApprove.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the customer to approve the weighed price.'**
  String get partnerOrderDetailWaitCustomerApprove;

  /// No description provided for @partnerOrderDetailWaitCustomerPay.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the customer to pay.'**
  String get partnerOrderDetailWaitCustomerPay;

  /// No description provided for @partnerOrderDetailWaitDriverPickup.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the driver to pick up.'**
  String get partnerOrderDetailWaitDriverPickup;

  /// No description provided for @partnerOrderDetailOutForDelivery.
  ///
  /// In en, this message translates to:
  /// **'Out for delivery.'**
  String get partnerOrderDetailOutForDelivery;

  /// No description provided for @partnerOrderDetailDriverBringingIn.
  ///
  /// In en, this message translates to:
  /// **'Driver bringing the laundry in'**
  String get partnerOrderDetailDriverBringingIn;

  /// No description provided for @partnerOrderDetailDriverTakingOut.
  ///
  /// In en, this message translates to:
  /// **'Driver taking the laundry out for delivery'**
  String get partnerOrderDetailDriverTakingOut;

  /// No description provided for @partnerOrderDetailLookingForDriver.
  ///
  /// In en, this message translates to:
  /// **'Looking for a driver to deliver the laundry'**
  String get partnerOrderDetailLookingForDriver;

  /// No description provided for @partnerOrderDetailReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get partnerOrderDetailReject;

  /// No description provided for @partnerOrderDetailAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get partnerOrderDetailAccept;

  /// No description provided for @partnerOrderDetailOrderRejected.
  ///
  /// In en, this message translates to:
  /// **'Order rejected.'**
  String get partnerOrderDetailOrderRejected;

  /// No description provided for @partnerOrderDetailOrderAccepted.
  ///
  /// In en, this message translates to:
  /// **'Order accepted.'**
  String get partnerOrderDetailOrderAccepted;

  /// No description provided for @partnerOrderDetailReceiveAndWeigh.
  ///
  /// In en, this message translates to:
  /// **'Receive & weigh'**
  String get partnerOrderDetailReceiveAndWeigh;

  /// No description provided for @partnerOrderDetailConfirmReceived.
  ///
  /// In en, this message translates to:
  /// **'Confirm received'**
  String get partnerOrderDetailConfirmReceived;

  /// No description provided for @partnerOrderDetailMarkReady.
  ///
  /// In en, this message translates to:
  /// **'Mark ready for delivery'**
  String get partnerOrderDetailMarkReady;

  /// No description provided for @partnerOrderDetailMarkedReady.
  ///
  /// In en, this message translates to:
  /// **'Marked ready for delivery.'**
  String get partnerOrderDetailMarkedReady;

  /// No description provided for @partnerOrderDetailConfirmArrived.
  ///
  /// In en, this message translates to:
  /// **'Confirm the laundry arrived to continue.'**
  String get partnerOrderDetailConfirmArrived;

  /// No description provided for @partnerOrderDetailConfirmEachItem.
  ///
  /// In en, this message translates to:
  /// **'Confirm each declared item you received. Unchecking one lets you flag a discrepancy.'**
  String get partnerOrderDetailConfirmEachItem;

  /// No description provided for @partnerOrderDetailDiscrepancyHint.
  ///
  /// In en, this message translates to:
  /// **'What was wrong? (optional)'**
  String get partnerOrderDetailDiscrepancyHint;

  /// No description provided for @partnerOrderDetailMeasuredWeight.
  ///
  /// In en, this message translates to:
  /// **'Measured weight'**
  String get partnerOrderDetailMeasuredWeight;

  /// No description provided for @partnerOrderDetailWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get partnerOrderDetailWeightLabel;

  /// No description provided for @partnerOrderDetailEnterValidWeight.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid weight.'**
  String get partnerOrderDetailEnterValidWeight;

  /// No description provided for @partnerOrderDetailSubmitWeight.
  ///
  /// In en, this message translates to:
  /// **'Submit weight & send price'**
  String get partnerOrderDetailSubmitWeight;

  /// No description provided for @partnerOrderDetailConfirmStartWashing.
  ///
  /// In en, this message translates to:
  /// **'Confirm & start washing'**
  String get partnerOrderDetailConfirmStartWashing;

  /// No description provided for @partnerOrderDetailWeightRecorded.
  ///
  /// In en, this message translates to:
  /// **'Weight recorded. Price sent to the customer.'**
  String get partnerOrderDetailWeightRecorded;

  /// No description provided for @partnerOrderDetailOrderReceived.
  ///
  /// In en, this message translates to:
  /// **'Order received.'**
  String get partnerOrderDetailOrderReceived;

  /// No description provided for @partnerOrderDetailResolutionNote.
  ///
  /// In en, this message translates to:
  /// **'Resolution: {note}'**
  String partnerOrderDetailResolutionNote(String note);

  /// No description provided for @partnerOrderDetailResolveTitle.
  ///
  /// In en, this message translates to:
  /// **'{status} claim'**
  String partnerOrderDetailResolveTitle(String status);

  /// No description provided for @partnerOrderDetailResolutionNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Resolution note'**
  String get partnerOrderDetailResolutionNoteLabel;

  /// No description provided for @partnerOrderDetailPayoutLabel.
  ///
  /// In en, this message translates to:
  /// **'Payout amount (optional)'**
  String get partnerOrderDetailPayoutLabel;

  /// No description provided for @partnerOrderDetailApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get partnerOrderDetailApprove;

  /// No description provided for @partnerOrderDetailClaimApproved.
  ///
  /// In en, this message translates to:
  /// **'Claim approved.'**
  String get partnerOrderDetailClaimApproved;

  /// No description provided for @partnerOrderDetailClaimRejected.
  ///
  /// In en, this message translates to:
  /// **'Claim rejected.'**
  String get partnerOrderDetailClaimRejected;

  /// No description provided for @partnerOrderDetailDeliveredCompleted.
  ///
  /// In en, this message translates to:
  /// **'Delivered & completed'**
  String get partnerOrderDetailDeliveredCompleted;

  /// No description provided for @partnerServicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get partnerServicesTitle;

  /// No description provided for @partnerServicesAdd.
  ///
  /// In en, this message translates to:
  /// **'Add service'**
  String get partnerServicesAdd;

  /// No description provided for @partnerServicesEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit service'**
  String get partnerServicesEdit;

  /// No description provided for @partnerServicesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No services yet. Add your first one.'**
  String get partnerServicesEmpty;

  /// No description provided for @partnerServicesDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete service?'**
  String get partnerServicesDeleteTitle;

  /// No description provided for @partnerServicesDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\"? This cannot be undone.'**
  String partnerServicesDeleteBody(String name);

  /// No description provided for @partnerServicesDeleted.
  ///
  /// In en, this message translates to:
  /// **'Service deleted.'**
  String get partnerServicesDeleted;

  /// No description provided for @partnerServicesEditTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get partnerServicesEditTooltip;

  /// No description provided for @partnerServicesDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get partnerServicesDeleteTooltip;

  /// No description provided for @partnerServicesPricePerUnit.
  ///
  /// In en, this message translates to:
  /// **'Rp {price} / {unit}'**
  String partnerServicesPricePerUnit(String price, String unit);

  /// No description provided for @partnerServicesUnitKg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get partnerServicesUnitKg;

  /// No description provided for @partnerServicesUnitItem.
  ///
  /// In en, this message translates to:
  /// **'item'**
  String get partnerServicesUnitItem;

  /// No description provided for @partnerServicesNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Service name'**
  String get partnerServicesNameLabel;

  /// No description provided for @partnerServicesDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get partnerServicesDescriptionLabel;

  /// No description provided for @partnerServicesPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get partnerServicesPriceLabel;

  /// No description provided for @partnerServicesPerItem.
  ///
  /// In en, this message translates to:
  /// **'Per item'**
  String get partnerServicesPerItem;

  /// No description provided for @partnerServicesPerKg.
  ///
  /// In en, this message translates to:
  /// **'Per kg'**
  String get partnerServicesPerKg;

  /// No description provided for @partnerServicesEnterNameAndPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter a name and a valid price.'**
  String get partnerServicesEnterNameAndPrice;

  /// No description provided for @partnerServicesAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get partnerServicesAddPhoto;

  /// No description provided for @partnerServicesProductImage.
  ///
  /// In en, this message translates to:
  /// **'Product image'**
  String get partnerServicesProductImage;

  /// No description provided for @partnerServicesProductImageHint.
  ///
  /// In en, this message translates to:
  /// **'This is the photo customers see for this service.'**
  String get partnerServicesProductImageHint;

  /// No description provided for @partnerServicesChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get partnerServicesChange;

  /// No description provided for @partnerServicesUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get partnerServicesUpload;

  /// No description provided for @partnerReviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer Reviews'**
  String get partnerReviewsTitle;

  /// No description provided for @partnerReviewsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet.'**
  String get partnerReviewsEmpty;

  /// No description provided for @partnerReviewsCount.
  ///
  /// In en, this message translates to:
  /// **'  ·  {count, plural, one{{count} review} other{{count} reviews}}'**
  String partnerReviewsCount(int count);

  /// No description provided for @partnerReviewsNoComment.
  ///
  /// In en, this message translates to:
  /// **'No written comment.'**
  String get partnerReviewsNoComment;

  /// No description provided for @partnerShopEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop Profile'**
  String get partnerShopEditTitle;

  /// No description provided for @partnerShopEditUpdated.
  ///
  /// In en, this message translates to:
  /// **'Shop profile updated.'**
  String get partnerShopEditUpdated;

  /// No description provided for @partnerShopEditNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Shop name'**
  String get partnerShopEditNameLabel;

  /// No description provided for @partnerShopEditDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get partnerShopEditDescriptionLabel;

  /// No description provided for @partnerShopEditAreaLabel.
  ///
  /// In en, this message translates to:
  /// **'Area label (shown to customers)'**
  String get partnerShopEditAreaLabel;

  /// No description provided for @partnerShopEditAreaHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Kemang, South Jakarta'**
  String get partnerShopEditAreaHint;

  /// No description provided for @partnerShopEditAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Exact address (private, not shown to customers)'**
  String get partnerShopEditAddressLabel;

  /// No description provided for @partnerShopEditSpecialtiesLabel.
  ///
  /// In en, this message translates to:
  /// **'Specialties (comma separated)'**
  String get partnerShopEditSpecialtiesLabel;

  /// No description provided for @partnerShopEditSpecialtiesHint.
  ///
  /// In en, this message translates to:
  /// **'shoes, bags, express'**
  String get partnerShopEditSpecialtiesHint;

  /// No description provided for @partnerShopEditSave.
  ///
  /// In en, this message translates to:
  /// **'Save shop profile'**
  String get partnerShopEditSave;

  /// No description provided for @driverStatusBarAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get driverStatusBarAccepted;

  /// No description provided for @driverStatusBarPickedUp.
  ///
  /// In en, this message translates to:
  /// **'Picked up'**
  String get driverStatusBarPickedUp;

  /// No description provided for @driverStatusBarOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get driverStatusBarOnTheWay;

  /// No description provided for @driverStatusBarDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get driverStatusBarDelivered;

  /// No description provided for @driverNavHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get driverNavHome;

  /// No description provided for @driverNavActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get driverNavActive;

  /// No description provided for @driverNavHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get driverNavHistory;

  /// No description provided for @driverNavProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get driverNavProfile;

  /// No description provided for @driverHomeErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get driverHomeErrorTitle;

  /// No description provided for @driverHomeErrorOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get driverHomeErrorOk;

  /// No description provided for @driverHomeDeliveryOffers.
  ///
  /// In en, this message translates to:
  /// **'Delivery offers'**
  String get driverHomeDeliveryOffers;

  /// No description provided for @driverHomeNoOffers.
  ///
  /// In en, this message translates to:
  /// **'No offers right now.'**
  String get driverHomeNoOffers;

  /// No description provided for @driverHomeTurnOnActive.
  ///
  /// In en, this message translates to:
  /// **'Turn on Active to receive offers.'**
  String get driverHomeTurnOnActive;

  /// No description provided for @driverHomeStatusOnDelivery.
  ///
  /// In en, this message translates to:
  /// **'On a delivery'**
  String get driverHomeStatusOnDelivery;

  /// No description provided for @driverHomeStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get driverHomeStatusActive;

  /// No description provided for @driverHomeStatusNotActive.
  ///
  /// In en, this message translates to:
  /// **'Not Active'**
  String get driverHomeStatusNotActive;

  /// No description provided for @driverHomeVehicleLine.
  ///
  /// In en, this message translates to:
  /// **'{vehicleType} · {plateNumber}'**
  String driverHomeVehicleLine(String vehicleType, String plateNumber);

  /// No description provided for @driverHomeTagPickup.
  ///
  /// In en, this message translates to:
  /// **'PICKUP'**
  String get driverHomeTagPickup;

  /// No description provided for @driverHomeTagDelivery.
  ///
  /// In en, this message translates to:
  /// **'DELIVERY'**
  String get driverHomeTagDelivery;

  /// No description provided for @driverHomeOrderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order #{id}'**
  String driverHomeOrderNumber(int id);

  /// No description provided for @driverHomeLaundromatFallback.
  ///
  /// In en, this message translates to:
  /// **'Laundromat'**
  String get driverHomeLaundromatFallback;

  /// No description provided for @driverHomeDeliverTo.
  ///
  /// In en, this message translates to:
  /// **'Deliver to: {address}'**
  String driverHomeDeliverTo(String address);

  /// No description provided for @driverHomeReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get driverHomeReject;

  /// No description provided for @driverHomeAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get driverHomeAccept;

  /// No description provided for @driverActiveErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not update order'**
  String get driverActiveErrorTitle;

  /// No description provided for @driverActiveErrorOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get driverActiveErrorOk;

  /// No description provided for @driverActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Active Delivery'**
  String get driverActiveTitle;

  /// No description provided for @driverActiveNoActiveDelivery.
  ///
  /// In en, this message translates to:
  /// **'No active delivery.'**
  String get driverActiveNoActiveDelivery;

  /// No description provided for @driverActiveCurrentDelivery.
  ///
  /// In en, this message translates to:
  /// **'Current delivery · #{id}'**
  String driverActiveCurrentDelivery(int id);

  /// No description provided for @driverActiveLaundromatFallback.
  ///
  /// In en, this message translates to:
  /// **'Laundromat'**
  String get driverActiveLaundromatFallback;

  /// No description provided for @driverActiveCollectFrom.
  ///
  /// In en, this message translates to:
  /// **'Collect from: {address}'**
  String driverActiveCollectFrom(String address);

  /// No description provided for @driverActiveDropAt.
  ///
  /// In en, this message translates to:
  /// **'Drop at: {name}'**
  String driverActiveDropAt(String name);

  /// No description provided for @driverActiveDeliverTo.
  ///
  /// In en, this message translates to:
  /// **'Deliver to: {address}'**
  String driverActiveDeliverTo(String address);

  /// No description provided for @driverActiveMarkPickedUp.
  ///
  /// In en, this message translates to:
  /// **'Mark picked up from customer'**
  String get driverActiveMarkPickedUp;

  /// No description provided for @driverActivePickedUpSuccess.
  ///
  /// In en, this message translates to:
  /// **'Picked up from the customer.'**
  String get driverActivePickedUpSuccess;

  /// No description provided for @driverActiveMarkArrived.
  ///
  /// In en, this message translates to:
  /// **'Mark arrived at laundromat'**
  String get driverActiveMarkArrived;

  /// No description provided for @driverActiveArrivedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Dropped off at the laundromat.'**
  String get driverActiveArrivedSuccess;

  /// No description provided for @driverActiveMarkDelivered.
  ///
  /// In en, this message translates to:
  /// **'Mark delivered'**
  String get driverActiveMarkDelivered;

  /// No description provided for @driverActiveDeliveredSuccess.
  ///
  /// In en, this message translates to:
  /// **'Delivery completed!'**
  String get driverActiveDeliveredSuccess;

  /// No description provided for @driverActiveWaitingOn.
  ///
  /// In en, this message translates to:
  /// **'Waiting on the laundromat / customer: {status}.'**
  String driverActiveWaitingOn(String status);

  /// No description provided for @driverHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delivery History'**
  String get driverHistoryTitle;

  /// No description provided for @driverHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No completed deliveries yet.'**
  String get driverHistoryEmpty;

  /// No description provided for @driverHistoryCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} completed delivery} other{{count} completed deliveries}}'**
  String driverHistoryCount(int count);

  /// No description provided for @driverHistoryLaundromatFallback.
  ///
  /// In en, this message translates to:
  /// **'Laundromat'**
  String get driverHistoryLaundromatFallback;

  /// No description provided for @driverHistoryOrderCompleted.
  ///
  /// In en, this message translates to:
  /// **'Order #{id} · Completed'**
  String driverHistoryOrderCompleted(int id);

  /// No description provided for @driverHistoryOrderTotal.
  ///
  /// In en, this message translates to:
  /// **'Order total'**
  String get driverHistoryOrderTotal;

  /// No description provided for @driverHistoryMoneyRp.
  ///
  /// In en, this message translates to:
  /// **'Rp {amount}'**
  String driverHistoryMoneyRp(String amount);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
