// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'KyrgyzExplore';

  @override
  String get login => 'Log In';

  @override
  String get register => 'Create Account';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get firstName => 'First Name';

  @override
  String get lastName => 'Last Name';

  @override
  String get role => 'I am a';

  @override
  String get traveler => 'Traveler';

  @override
  String get host => 'Host';

  @override
  String get loginError => 'Invalid email or password.';

  @override
  String get registerError => 'Could not create account. Please try again.';

  @override
  String get alreadyHaveAccount => 'Already have an account? Log in';

  @override
  String get noAccount => 'Don\'t have an account? Create one';

  @override
  String get loading => 'Loading...';

  @override
  String get retry => 'Retry';

  @override
  String get logOut => 'Log Out';

  @override
  String get home => 'Explore';

  @override
  String get trips => 'Trips';

  @override
  String get messages => 'Messages';

  @override
  String get profile => 'Profile';
}
