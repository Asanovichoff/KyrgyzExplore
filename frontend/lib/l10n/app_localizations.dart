import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ky.dart';
import 'app_localizations_ru.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('ky'),
    Locale('ru')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'KyrgyzExplore'**
  String get appName;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'I am a'**
  String get role;

  /// No description provided for @traveler.
  ///
  /// In en, this message translates to:
  /// **'Traveler'**
  String get traveler;

  /// No description provided for @host.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get host;

  /// No description provided for @loginError.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get loginError;

  /// No description provided for @registerError.
  ///
  /// In en, this message translates to:
  /// **'Could not create account. Please try again.'**
  String get registerError;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in'**
  String get alreadyHaveAccount;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Create one'**
  String get noAccount;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get home;

  /// No description provided for @trips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get trips;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @setUp.
  ///
  /// In en, this message translates to:
  /// **'Set up'**
  String get setUp;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterHouses.
  ///
  /// In en, this message translates to:
  /// **'Houses'**
  String get filterHouses;

  /// No description provided for @filterCars.
  ///
  /// In en, this message translates to:
  /// **'Cars'**
  String get filterCars;

  /// No description provided for @filterActivities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get filterActivities;

  /// No description provided for @couldNotLoadListings.
  ///
  /// In en, this message translates to:
  /// **'Could not load listings'**
  String get couldNotLoadListings;

  /// No description provided for @checkConnectionAndRetry.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again'**
  String get checkConnectionAndRetry;

  /// No description provided for @noListingsFound.
  ///
  /// In en, this message translates to:
  /// **'No listings found'**
  String get noListingsFound;

  /// No description provided for @tryDifferentFilter.
  ///
  /// In en, this message translates to:
  /// **'Try a different filter or area'**
  String get tryDifferentFilter;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @availabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availabilityTitle;

  /// No description provided for @reviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviewsTitle;

  /// No description provided for @reviewsLabel.
  ///
  /// In en, this message translates to:
  /// **'reviews'**
  String get reviewsLabel;

  /// No description provided for @bookNow.
  ///
  /// In en, this message translates to:
  /// **'Book Now'**
  String get bookNow;

  /// No description provided for @perNight.
  ///
  /// In en, this message translates to:
  /// **'/ night'**
  String get perNight;

  /// No description provided for @perDay.
  ///
  /// In en, this message translates to:
  /// **'/ day'**
  String get perDay;

  /// No description provided for @couldNotLoadListing.
  ///
  /// In en, this message translates to:
  /// **'Could not load listing'**
  String get couldNotLoadListing;

  /// No description provided for @couldNotLoadReviews.
  ///
  /// In en, this message translates to:
  /// **'Could not load reviews'**
  String get couldNotLoadReviews;

  /// No description provided for @noReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get noReviewsYet;

  /// No description provided for @myBookings.
  ///
  /// In en, this message translates to:
  /// **'My Bookings'**
  String get myBookings;

  /// No description provided for @manageBookings.
  ///
  /// In en, this message translates to:
  /// **'Manage Bookings'**
  String get manageBookings;

  /// No description provided for @couldNotLoadBookings.
  ///
  /// In en, this message translates to:
  /// **'Could not load bookings'**
  String get couldNotLoadBookings;

  /// No description provided for @noBookingsYet.
  ///
  /// In en, this message translates to:
  /// **'No bookings yet'**
  String get noBookingsYet;

  /// No description provided for @chatWithHost.
  ///
  /// In en, this message translates to:
  /// **'Chat with host'**
  String get chatWithHost;

  /// No description provided for @chatWithGuest.
  ///
  /// In en, this message translates to:
  /// **'Chat with guest'**
  String get chatWithGuest;

  /// No description provided for @cancelBookingTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking?'**
  String get cancelBookingTitle;

  /// No description provided for @cancelBookingContent.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get cancelBookingContent;

  /// No description provided for @keepIt.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get keepIt;

  /// No description provided for @cancelBookingAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get cancelBookingAction;

  /// No description provided for @paymentSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Payment successful!'**
  String get paymentSuccessful;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed'**
  String get paymentFailed;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay now'**
  String get payNow;

  /// No description provided for @leaveReview.
  ///
  /// In en, this message translates to:
  /// **'Leave review'**
  String get leaveReview;

  /// No description provided for @reviewSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Review submitted! Thank you.'**
  String get reviewSubmitted;

  /// No description provided for @couldNotCancel.
  ///
  /// In en, this message translates to:
  /// **'Could not cancel booking'**
  String get couldNotCancel;

  /// No description provided for @rejectBookingTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject booking'**
  String get rejectBookingTitle;

  /// No description provided for @giveReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Give a reason (required)'**
  String get giveReasonRequired;

  /// No description provided for @nightCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 night} other{{count} nights}}'**
  String nightCount(int count);

  /// No description provided for @guestCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 guest} other{{count} guests}}'**
  String guestCount(int count);

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get statusConfirmed;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get statusPaid;

  /// No description provided for @myListings.
  ///
  /// In en, this message translates to:
  /// **'My Listings'**
  String get myListings;

  /// No description provided for @noListingsYet.
  ///
  /// In en, this message translates to:
  /// **'No listings yet'**
  String get noListingsYet;

  /// No description provided for @tapToCreateFirstListing.
  ///
  /// In en, this message translates to:
  /// **'Tap + to create your first listing'**
  String get tapToCreateFirstListing;

  /// No description provided for @createListing.
  ///
  /// In en, this message translates to:
  /// **'Create listing'**
  String get createListing;

  /// No description provided for @deleteListingTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete listing?'**
  String get deleteListingTitle;

  /// No description provided for @deleteListingContent.
  ///
  /// In en, this message translates to:
  /// **'This will remove the listing and cancel any pending bookings.'**
  String get deleteListingContent;

  /// No description provided for @couldNotDelete.
  ///
  /// In en, this message translates to:
  /// **'Could not delete listing'**
  String get couldNotDelete;

  /// No description provided for @manageDates.
  ///
  /// In en, this message translates to:
  /// **'Manage dates'**
  String get manageDates;

  /// No description provided for @typeHouse.
  ///
  /// In en, this message translates to:
  /// **'House'**
  String get typeHouse;

  /// No description provided for @typeCar.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get typeCar;

  /// No description provided for @typeActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get typeActivity;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @couldNotLoadNotifications.
  ///
  /// In en, this message translates to:
  /// **'Could not load notifications'**
  String get couldNotLoadNotifications;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @phoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get phoneOptional;

  /// No description provided for @couldNotUploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Could not upload photo'**
  String get couldNotUploadPhoto;

  /// No description provided for @couldNotSave.
  ///
  /// In en, this message translates to:
  /// **'Could not save'**
  String get couldNotSave;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @payoutSettings.
  ///
  /// In en, this message translates to:
  /// **'Payout Settings'**
  String get payoutSettings;

  /// No description provided for @payoutsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Payouts enabled'**
  String get payoutsEnabled;

  /// No description provided for @verificationInProgress.
  ///
  /// In en, this message translates to:
  /// **'Verification in progress'**
  String get verificationInProgress;

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get notConnected;

  /// No description provided for @youWillReceivePayouts.
  ///
  /// In en, this message translates to:
  /// **'You will receive payouts from bookings'**
  String get youWillReceivePayouts;

  /// No description provided for @stripeReviewing.
  ///
  /// In en, this message translates to:
  /// **'Stripe is reviewing your information'**
  String get stripeReviewing;

  /// No description provided for @connectStripe.
  ///
  /// In en, this message translates to:
  /// **'Connect Stripe to receive payments'**
  String get connectStripe;

  /// No description provided for @viewEarnings.
  ///
  /// In en, this message translates to:
  /// **'View earnings'**
  String get viewEarnings;

  /// No description provided for @couldNotOpenBrowser.
  ///
  /// In en, this message translates to:
  /// **'Could not open browser'**
  String get couldNotOpenBrowser;

  /// No description provided for @couldNotStartOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Could not start onboarding'**
  String get couldNotStartOnboarding;

  /// No description provided for @earningsTitle.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earningsTitle;

  /// No description provided for @totalEarned.
  ///
  /// In en, this message translates to:
  /// **'Total earned'**
  String get totalEarned;

  /// No description provided for @noEarningsYet.
  ///
  /// In en, this message translates to:
  /// **'No earnings yet'**
  String get noEarningsYet;

  /// No description provided for @completedBookingsWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Completed bookings will appear here'**
  String get completedBookingsWillAppear;

  /// No description provided for @couldNotLoadEarnings.
  ///
  /// In en, this message translates to:
  /// **'Could not load earnings'**
  String get couldNotLoadEarnings;

  /// No description provided for @bookingCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 booking} other{{count} bookings}}'**
  String bookingCount(int count);

  /// No description provided for @logInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Log in to continue'**
  String get logInToContinue;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get enterValidEmail;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 chars'**
  String get passwordMinLength;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @googleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed'**
  String get googleSignInFailed;

  /// No description provided for @appleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in failed'**
  String get appleSignInFailed;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Try again.'**
  String get loginFailed;

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed. Try again.'**
  String get registrationFailed;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @mustBeNumber.
  ///
  /// In en, this message translates to:
  /// **'Must be a number'**
  String get mustBeNumber;

  /// No description provided for @filtersTooltip.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filtersTooltip;

  /// No description provided for @requestToBook.
  ///
  /// In en, this message translates to:
  /// **'Request to Book'**
  String get requestToBook;

  /// No description provided for @dates.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get dates;

  /// No description provided for @checkInLabel.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get checkInLabel;

  /// No description provided for @checkOutLabel.
  ///
  /// In en, this message translates to:
  /// **'Check-out'**
  String get checkOutLabel;

  /// No description provided for @guestsLabel.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get guestsLabel;

  /// No description provided for @messageToHostOptional.
  ///
  /// In en, this message translates to:
  /// **'Message to host (optional)'**
  String get messageToHostOptional;

  /// No description provided for @messageToHostHint.
  ///
  /// In en, this message translates to:
  /// **'Tell the host about your plans...'**
  String get messageToHostHint;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectDate;

  /// No description provided for @dayCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String dayCount(int count);

  /// No description provided for @bookingRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Booking request sent! The host will confirm shortly.'**
  String get bookingRequestSent;

  /// No description provided for @pleaseSelectDates.
  ///
  /// In en, this message translates to:
  /// **'Please select check-in and check-out dates.'**
  String get pleaseSelectDates;

  /// No description provided for @checkoutAfterCheckin.
  ///
  /// In en, this message translates to:
  /// **'Check-out must be at least 1 day after check-in.'**
  String get checkoutAfterCheckin;

  /// No description provided for @couldNotReachServer.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Check your connection.'**
  String get couldNotReachServer;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get somethingWentWrong;

  /// No description provided for @editListing.
  ///
  /// In en, this message translates to:
  /// **'Edit Listing'**
  String get editListing;

  /// No description provided for @newListing.
  ///
  /// In en, this message translates to:
  /// **'New Listing'**
  String get newListing;

  /// No description provided for @typeSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get typeSectionLabel;

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic info'**
  String get basicInfo;

  /// No description provided for @titleFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleFieldLabel;

  /// No description provided for @descriptionFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionFieldLabel;

  /// No description provided for @pricingSection.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get pricingSection;

  /// No description provided for @pricePerNightDay.
  ///
  /// In en, this message translates to:
  /// **'Price per night/day'**
  String get pricePerNightDay;

  /// No description provided for @currencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currencyLabel;

  /// No description provided for @maxGuestsOptional.
  ///
  /// In en, this message translates to:
  /// **'Max guests (optional)'**
  String get maxGuestsOptional;

  /// No description provided for @locationSection.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationSection;

  /// No description provided for @streetAddress.
  ///
  /// In en, this message translates to:
  /// **'Street address'**
  String get streetAddress;

  /// No description provided for @cityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get cityLabel;

  /// No description provided for @latitudeLabel.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitudeLabel;

  /// No description provided for @longitudeLabel.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitudeLabel;

  /// No description provided for @useMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get useMyLocation;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get locationPermissionDenied;

  /// No description provided for @couldNotGetLocation.
  ///
  /// In en, this message translates to:
  /// **'Could not get location'**
  String get couldNotGetLocation;

  /// No description provided for @photosSection.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photosSection;

  /// No description provided for @listingUpdated.
  ///
  /// In en, this message translates to:
  /// **'Listing updated!'**
  String get listingUpdated;

  /// No description provided for @listingCreated.
  ///
  /// In en, this message translates to:
  /// **'Listing created!'**
  String get listingCreated;

  /// No description provided for @couldNotDeleteImage.
  ///
  /// In en, this message translates to:
  /// **'Could not delete image'**
  String get couldNotDeleteImage;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @blockedLabel.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get blockedLabel;

  /// No description provided for @pendingChangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending change'**
  String get pendingChangeLabel;

  /// No description provided for @availabilityUpdated.
  ///
  /// In en, this message translates to:
  /// **'Availability updated'**
  String get availabilityUpdated;

  /// No description provided for @availabilityUnsavedHint.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unsaved change — tap Save} other{{count} unsaved changes — tap Save}}'**
  String availabilityUnsavedHint(int count);

  /// No description provided for @couldNotLoadAvailability.
  ///
  /// In en, this message translates to:
  /// **'Could not load availability'**
  String get couldNotLoadAvailability;

  /// No description provided for @couldNotSaveAvailability.
  ///
  /// In en, this message translates to:
  /// **'Could not save availability'**
  String get couldNotSaveAvailability;

  /// No description provided for @chatNoMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages yet.\nSay hello!'**
  String get chatNoMessages;

  /// No description provided for @typeAMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message…'**
  String get typeAMessage;

  /// No description provided for @navListings.
  ///
  /// In en, this message translates to:
  /// **'Listings'**
  String get navListings;

  /// No description provided for @navBookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get navBookings;

  /// No description provided for @logOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logOutConfirm;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String timeHoursAgo(int count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String timeDaysAgo(int count);
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
      <String>['en', 'ky', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ky':
      return AppLocalizationsKy();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
