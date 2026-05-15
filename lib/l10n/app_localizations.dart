import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/event.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  // Keep only English as the static fallback. Dynamic translations
  // are handled by the translation provider / TranslatableText.
  static const supportedLocales = [Locale('en')];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  String get appName => _text('EventBridge');
  String get home => _text('Home');
  String get search => _text('Search');
  String get wishlist => _text('Wishlist');
  String get profile => _text('Profile');
  String get login => _text('Login');
  String get logout => _text('Logout');
  String get wallet => _text('Wallet');
  String get notifications => _text('Notifications');
  String get categories => _text('Categories');
  String get all => _text('All');
  String get trendingEvents => _text('Trending Events');
  String get recommendedForYou => _text('Recommended For You');
  String get allEvents => _text('All Events');
  String get settings => _text('Settings');
  String get darkMode => _text('Dark Mode');
  String get language => _text('Language');
  String get accessibility => _text('Accessibility');
  String get accessibilitySettings => _text('Accessibility Settings');
  String get accessibilitySettingsSubtitle =>
      _text('Adjust text size to improve readability across the app.');
  String get openAccessibilitySettings => _text('Open accessibility settings');
  String get textSize => _text('Text Size');
  String get textScalePreview => _text('This is a text size preview.');
  String get accessibilityTip => _text(
    'Tip: You can also use your device accessibility options for bold text and screen readers.',
  );
  String get organizerDashboard => _text('Organizer Dashboard');
  String get organizerTools =>
      _text('Create/manage events, analytics and organizer tools.');
  String get editProfile => _text('Edit Profile');
  String get editName => _text('Edit Name');
  String get editPhone => _text('Edit Phone');
  String get editPhotoUrl => _text('Edit Profile Photo URL');
  String get cancel => _text('Cancel');
  String get save => _text('Save');
  String get name => _text('Name');
  String get phone => _text('Phone');
  String get photoUrl => _text('Profile Photo URL (optional)');
  String get chooseFromGallery => _text('Choose from gallery');
  String get removePhoto => _text('Remove photo');
  String get selectedPhotoReady =>
      _text('Selected photo will be uploaded on save.');
  String get noPhotoSelected => _text('No photo selected');
  String get galleryAccessFailed =>
      _text('Could not open gallery. Please try again.');
  String get galleryNeedsFullRestart => _text(
    'Gallery plugin is initializing. Please stop the app and run it again once.',
  );
  String get nameRequired => _text('Name is required.');
  String get phoneRequired => _text('Phone must be exactly 10 digits.');
  String get validUrl => _text('Enter a valid URL.');
  String get profileUpdatedSuccessfully =>
      _text('Profile updated successfully.');
  String get guestUser => _text('Guest User');
  String get setYourDisplayName => _text('Set your display name');
  String get signInToManageProfile =>
      _text('Sign in to manage your profile and wishlist.');
  String get logoutFromYourAccount => _text('Logout from your account');
  String get loggedOutSuccessfully => _text('Logged out successfully.');
  String get addMobileNumber => _text('Add mobile number');
  String get profileImageIsSet => _text('Profile image is set');
  String get addProfilePhotoLink => _text('Add a profile photo link');
  String get userStats => _text('User Stats');
  String get eventsAttended => _text('Events Attended');
  String get spent => _text('Spent');
  String get favorite => _text('Favorite');
  String get myTickets => _text('My Tickets');
  String get noTicketsYet => _text('No tickets yet.');
  String get notificationsSubtitle =>
      _text('Reminders, confirmations, organizer updates');
  String get aboutUs => _text('About Us');
  String get contactUs => _text('Contact Us');
  String get couldNotLoadEventsFromFirestore =>
      _text('Could not load events from Firestore:');
  String get noEventsFoundInFirestore =>
      _text('No events found in Firestore collection "events".');
  String get linkPhoneNumber => _text('Link Phone Number');
  String get linkPhoneNumberForOtp => _text('Link Phone Number for OTP Login');
  String get linkPhoneNumberForOtpSubtitle =>
      _text('Add or change phone number for OTP authentication');
  String get enterPhoneToLink =>
      _text('Enter a phone number to link with OTP login.');
  String get enterOtpSent => _text('Enter the OTP code sent to your phone.');
  String get phoneLinkSuccessful =>
      _text('Phone number linked successfully. You can now login with OTP.');
  String get phonePlaceholder => _text('10-digit number');
  String get otp => _text('OTP Code');
  String get sendOtp => _text('Send OTP');
  String get verify => _text('Verify');
  String get enterValidOtp => _text('Enter a valid 6-digit OTP code.');

  String otpSentTo(String phone) {
    return _text('OTP sent to $phone');
  }

  String categoryLabel(EventCategory category) {
    switch (category) {
      case EventCategory.conference:
        return _text('Conference');
      case EventCategory.wedding:
        return _text('Wedding');
      case EventCategory.concert:
        return _text('Concert');
      case EventCategory.festival:
        return _text('Festival');
      case EventCategory.workshop:
        return _text('Workshop');
    }
  }

  // Return the English text as static fallback. Dynamic translation
  // should be performed via the TranslationProvider and
  // `TranslatableText` widget. We accept optional hi/gu params
  // for compatibility but ignore them here.
  String _text(String en) {
    return en;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (supported) => supported.languageCode == locale.languageCode,
  );

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
