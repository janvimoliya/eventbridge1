import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/event.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('hi'), Locale('gu')];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  String get appName => _text('EventBridge', 'इवेंटब्रिज', 'ઇવેન્ટબ્રિજ');
  String get home => _text('Home', 'होम', 'હોમ');
  String get search => _text('Search', 'खोजें', 'શોધો');
  String get wishlist => _text('Wishlist', 'विशलिस्ट', 'વિશલિસ્ટ');
  String get profile => _text('Profile', 'प्रोफ़ाइल', 'પ્રોફાઇલ');
  String get login => _text('Login', 'लॉगिन', 'લૉગિન');
  String get logout => _text('Logout', 'लॉगआउट', 'લૉગઆઉટ');
  String get wallet => _text('Wallet', 'वॉलेट', 'વૉલેટ');
  String get notifications => _text('Notifications', 'सूचनाएँ', 'સૂચનાઓ');
  String get categories => _text('Categories', 'श्रेणियाँ', 'શ્રેણીઓ');
  String get all => _text('All', 'सभी', 'બધા');
  String get trendingEvents =>
      _text('Trending Events', 'ट्रेंडिंग इवेंट', 'ટ્રેન્ડિંગ ઇવેન્ટ્સ');
  String get recommendedForYou =>
      _text('Recommended For You', 'आपके लिए सुझाव', 'તમારા માટે સૂચનો');
  String get allEvents => _text('All Events', 'सभी इवेंट', 'બધા ઇવેન્ટ્સ');
  String get settings => _text('Settings', 'सेटिंग्स', 'સેટિંગ્સ');
  String get darkMode => _text('Dark Mode', 'डार्क मोड', 'ડાર્ક મોડ');
  String get language => _text('Language', 'भाषा', 'ભાષા');
  String get accessibility =>
      _text('Accessibility', 'पहुँच-योग्यता', 'ઍક્સેસિબિલિટી');
  String get accessibilitySettings => _text(
    'Accessibility Settings',
    'एक्सेसिबिलिटी सेटिंग्स',
    'ઍક્સેસિબિલિટી સેટિંગ્સ',
  );
  String get accessibilitySettingsSubtitle => _text(
    'Adjust text size to improve readability across the app.',
    'ऐप में पढ़ने की सुविधा बेहतर करने के लिए टेक्स्ट साइज बदलें।',
    'એપમાં વાંચવાની સરળતા માટે ટેક્સ્ટ સાઇઝ બદલો.',
  );
  String get openAccessibilitySettings => _text(
    'Open accessibility settings',
    'एक्सेसिबिलिटी सेटिंग्स खोलें',
    'ઍક્સેસિબિલિટી સેટિંગ્સ ખોલો',
  );
  String get textSize => _text('Text Size', 'टेक्स्ट साइज़', 'ટેક્સ્ટ સાઇઝ');
  String get textScalePreview => _text(
    'This is a text size preview.',
    'यह टेक्स्ट साइज़ का प्रीव्यू है।',
    'આ ટેક્સ્ટ સાઇઝનું પ્રિવ્યુ છે.',
  );
  String get accessibilityTip => _text(
    'Tip: You can also use your device accessibility options for bold text and screen readers.',
    'टिप: बोल्ड टेक्स्ट और स्क्रीन रीडर के लिए आप डिवाइस की एक्सेसिबिलिटी सेटिंग्स भी इस्तेमाल कर सकते हैं।',
    'ટિપ: બોલ્ડ ટેક્સ્ટ અને સ્ક્રીન રીડર માટે ડિવાઇસની ઍક્સેસિબિલિટી સેટિંગ્સ પણ વાપરી શકો છો.',
  );
  String get organizerDashboard =>
      _text('Organizer Dashboard', 'ऑर्गेनाइज़र डैशबोर्ड', 'આયોજક ડેશબોર્ડ');
  String get organizerTools => _text(
    'Create/manage events, analytics and organizer tools.',
    'इवेंट बनाएं/मैनेज करें, एनालिटिक्स और ऑर्गेनाइज़र टूल्स।',
    'ઇવેન્ટ બનાવો/મેનેજ કરો, ઍનલિટિક્સ અને આયોજક ટૂલ્સ.',
  );
  String get editProfile =>
      _text('Edit Profile', 'प्रोफ़ाइल संपादित करें', 'પ્રોફાઇલ સંપાદિત કરો');
  String get editName => _text('Edit Name', 'नाम बदलें', 'નામ સંપાદિત કરો');
  String get editPhone => _text('Edit Phone', 'फोन बदलें', 'ફોન સંપાદિત કરો');
  String get editPhotoUrl => _text(
    'Edit Profile Photo URL',
    'प्रोफ़ाइल फोटो URL बदलें',
    'પ્રોફાઇલ ફોટો URL સંપાદિત કરો',
  );
  String get cancel => _text('Cancel', 'रद्द करें', 'રદ કરો');
  String get save => _text('Save', 'सहेजें', 'સેવ કરો');
  String get name => _text('Name', 'नाम', 'નામ');
  String get phone => _text('Phone', 'फोन', 'ફોન');
  String get photoUrl => _text(
    'Profile Photo URL (optional)',
    'प्रोफ़ाइल फोटो URL (वैकल्पिक)',
    'પ્રોફાઇલ ફોટો URL (વૈકલ્પિક)',
  );
  String get chooseFromGallery =>
      _text('Choose from gallery', 'गैलरी से चुनें', 'ગેલેરીમાંથી પસંદ કરો');
  String get removePhoto => _text('Remove photo', 'फोटो हटाएं', 'ફોટો દૂર કરો');
  String get selectedPhotoReady => _text(
    'Selected photo will be uploaded on save.',
    'चुनी हुई फोटो सेव पर अपलोड होगी।',
    'પસંદ કરેલી ફોટો સેવ કરતાં અપલોડ થશે.',
  );
  String get noPhotoSelected => _text(
    'No photo selected',
    'कोई फोटो चयनित नहीं',
    'કોઈ ફોટો પસંદ કરાયો નથી',
  );
  String get galleryAccessFailed => _text(
    'Could not open gallery. Please try again.',
    'गैलरी नहीं खुल सकी। कृपया फिर से प्रयास करें।',
    'ગેલેરી ખુલતી નથી. કૃપા કરીને ફરી પ્રયાસ કરો.',
  );
  String get galleryNeedsFullRestart => _text(
    'Gallery plugin is initializing. Please stop the app and run it again once.',
    'गैलरी प्लगइन शुरू हो रहा है। ऐप बंद करके एक बार फिर चलाएं।',
    'ગેલેરી પ્લગિન શરૂ થઈ રહ્યો છે. એપ બંધ કરીને એકવાર ફરી ચલાવો.',
  );
  String get nameRequired =>
      _text('Name is required.', 'नाम आवश्यक है.', 'નામ જરૂરી છે.');
  String get phoneRequired => _text(
    'Phone must be exactly 10 digits.',
    'फोन ठीक 10 अंक का होना चाहिए.',
    'ફોન ચોક્કસ 10 અંકનો હોવો જોઈએ.',
  );
  String get validUrl => _text(
    'Enter a valid URL.',
    'मान्य URL दर्ज करें.',
    'માન્ય URL દાખલ કરો.',
  );
  String get profileUpdatedSuccessfully => _text(
    'Profile updated successfully.',
    'प्रोफ़ाइल सफलतापूर्वक अपडेट हुई.',
    'પ્રોફાઇલ સફળતાપૂર્વક અપડેટ થઈ.',
  );
  String get guestUser =>
      _text('Guest User', 'अतिथि उपयोगकर्ता', 'અતિથિ વપરાશકર્તા');
  String get setYourDisplayName => _text(
    'Set your display name',
    'अपना दिखने वाला नाम सेट करें',
    'તમારું ડિસ્પ્લે નામ સેટ કરો',
  );
  String get signInToManageProfile => _text(
    'Sign in to manage your profile and wishlist.',
    'प्रोफ़ाइल और विशलिस्ट मैनेज करने के लिए साइन इन करें।',
    'પ્રોફાઇલ અને વિશલિસ્ટ મેનેજ કરવા સાઇન ઇન કરો.',
  );
  String get logoutFromYourAccount => _text(
    'Logout from your account',
    'अपने खाते से लॉगआउट करें',
    'તમારા એકાઉન્ટમાંથી લૉગઆઉટ કરો',
  );
  String get loggedOutSuccessfully => _text(
    'Logged out successfully.',
    'सफलतापूर्वक लॉगआउट हो गया।',
    'સફળતાપૂર્વક લૉગઆઉટ થયું.',
  );
  String get addMobileNumber =>
      _text('Add mobile number', 'मोबाइल नंबर जोड़ें', 'મોબાઇલ નંબર ઉમેરો');
  String get profileImageIsSet => _text(
    'Profile image is set',
    'प्रोफ़ाइल छवि सेट है',
    'પ્રોફાઇલ છબી સેટ છે',
  );
  String get addProfilePhotoLink => _text(
    'Add a profile photo link',
    'प्रोफ़ाइल फोटो लिंक जोड़ें',
    'પ્રોફાઇલ ફોટો લિંક ઉમેરો',
  );
  String get userStats =>
      _text('User Stats', 'उपयोगकर्ता आँकड़े', 'વપરાશકર્તા આંકડા');
  String get eventsAttended =>
      _text('Events Attended', 'भाग लिए इवेंट', 'હાજર રહેલા ઇવેન્ટ્સ');
  String get spent => _text('Spent', 'खर्च', 'ખર્ચ');
  String get favorite => _text('Favorite', 'पसंदीदा', 'મનપસંદ');
  String get myTickets => _text('My Tickets', 'मेरे टिकट', 'મારા ટિકિટ');
  String get noTicketsYet =>
      _text('No tickets yet.', 'अभी कोई टिकट नहीं.', 'હજી કોઈ ટિકિટ નથી.');
  String get notificationsSubtitle => _text(
    'Reminders, confirmations, organizer updates',
    'रिमाइंडर, पुष्टि, ऑर्गेनाइज़र अपडेट',
    'રિમાઇન્ડર, પુષ્ટિ, આયોજક અપડેટ્સ',
  );
  String get aboutUs => _text('About Us', 'हमारे बारे में', 'અમારા વિશે');
  String get contactUs => _text('Contact Us', 'संपर्क करें', 'સંપર્ક કરો');
  String get couldNotLoadEventsFromFirestore => _text(
    'Could not load events from Firestore:',
    'Firestore से इवेंट लोड नहीं हो पाए:',
    'Firestoreમાંથી ઇવેન્ટ્સ લોડ થઈ શક્યા નથી:',
  );
  String get noEventsFoundInFirestore => _text(
    'No events found in Firestore collection "events".',
    'Firestore कलेक्शन "events" में कोई इवेंट नहीं मिला.',
    'Firestore કલેક્શન "events" માં કોઈ ઇવેન્ટ મળ્યો નથી.',
  );

  String categoryLabel(EventCategory category) {
    switch (category) {
      case EventCategory.conference:
        return _text('Conference', 'कॉन्फ़्रेंस', 'કોન્ફરન્સ');
      case EventCategory.wedding:
        return _text('Wedding', 'शादी', 'લગ્ન');
      case EventCategory.concert:
        return _text('Concert', 'कंसर्ट', 'કોન્સર્ટ');
      case EventCategory.festival:
        return _text('Festival', 'त्योहार', 'ફેસ્ટિવલ');
      case EventCategory.workshop:
        return _text('Workshop', 'वर्कशॉप', 'વર્કશોપ');
    }
  }

  String _text(String en, String hi, String gu) {
    switch (locale.languageCode) {
      case 'hi':
        return hi;
      case 'gu':
        return gu;
      default:
        return en;
    }
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
