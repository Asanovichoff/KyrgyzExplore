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

  @override
  String get cancel => 'Cancel';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get confirm => 'Confirm';

  @override
  String get reject => 'Reject';

  @override
  String get continueLabel => 'Continue';

  @override
  String get setUp => 'Set up';

  @override
  String get language => 'Language';

  @override
  String get filterAll => 'All';

  @override
  String get filterHouses => 'Houses';

  @override
  String get filterCars => 'Cars';

  @override
  String get filterActivities => 'Activities';

  @override
  String get couldNotLoadListings => 'Could not load listings';

  @override
  String get checkConnectionAndRetry => 'Check your connection and try again';

  @override
  String get noListingsFound => 'No listings found';

  @override
  String get tryDifferentFilter => 'Try a different filter or area';

  @override
  String get about => 'About';

  @override
  String get availabilityTitle => 'Availability';

  @override
  String get reviewsTitle => 'Reviews';

  @override
  String get reviewsLabel => 'reviews';

  @override
  String get bookNow => 'Book Now';

  @override
  String get perNight => '/ night';

  @override
  String get perDay => '/ day';

  @override
  String get couldNotLoadListing => 'Could not load listing';

  @override
  String get couldNotLoadReviews => 'Could not load reviews';

  @override
  String get noReviewsYet => 'No reviews yet';

  @override
  String get myBookings => 'My Bookings';

  @override
  String get manageBookings => 'Manage Bookings';

  @override
  String get couldNotLoadBookings => 'Could not load bookings';

  @override
  String get noBookingsYet => 'No bookings yet';

  @override
  String get chatWithHost => 'Chat with host';

  @override
  String get chatWithGuest => 'Chat with guest';

  @override
  String get cancelBookingTitle => 'Cancel booking?';

  @override
  String get cancelBookingContent => 'This action cannot be undone.';

  @override
  String get keepIt => 'Keep it';

  @override
  String get cancelBookingAction => 'Cancel booking';

  @override
  String get paymentSuccessful => 'Payment successful!';

  @override
  String get paymentFailed => 'Payment failed';

  @override
  String get payNow => 'Pay now';

  @override
  String get leaveReview => 'Leave review';

  @override
  String get reviewSubmitted => 'Review submitted! Thank you.';

  @override
  String get couldNotCancel => 'Could not cancel booking';

  @override
  String get rejectBookingTitle => 'Reject booking';

  @override
  String get giveReasonRequired => 'Give a reason (required)';

  @override
  String nightCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nights',
      one: '1 night',
    );
    return '$_temp0';
  }

  @override
  String guestCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count guests',
      one: '1 guest',
    );
    return '$_temp0';
  }

  @override
  String get statusPending => 'Pending';

  @override
  String get statusConfirmed => 'Confirmed';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusPaid => 'Paid';

  @override
  String get myListings => 'My Listings';

  @override
  String get noListingsYet => 'No listings yet';

  @override
  String get tapToCreateFirstListing => 'Tap + to create your first listing';

  @override
  String get createListing => 'Create listing';

  @override
  String get deleteListingTitle => 'Delete listing?';

  @override
  String get deleteListingContent =>
      'This will remove the listing and cancel any pending bookings.';

  @override
  String get couldNotDelete => 'Could not delete listing';

  @override
  String get manageDates => 'Manage dates';

  @override
  String get typeHouse => 'House';

  @override
  String get typeCar => 'Car';

  @override
  String get typeActivity => 'Activity';

  @override
  String get notifications => 'Notifications';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get couldNotLoadNotifications => 'Could not load notifications';

  @override
  String get noNotificationsYet => 'No notifications yet';

  @override
  String get phoneOptional => 'Phone (optional)';

  @override
  String get couldNotUploadPhoto => 'Could not upload photo';

  @override
  String get couldNotSave => 'Could not save';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get payoutSettings => 'Payout Settings';

  @override
  String get payoutsEnabled => 'Payouts enabled';

  @override
  String get verificationInProgress => 'Verification in progress';

  @override
  String get notConnected => 'Not connected';

  @override
  String get youWillReceivePayouts => 'You will receive payouts from bookings';

  @override
  String get stripeReviewing => 'Stripe is reviewing your information';

  @override
  String get connectStripe => 'Connect Stripe to receive payments';

  @override
  String get viewEarnings => 'View earnings';

  @override
  String get couldNotOpenBrowser => 'Could not open browser';

  @override
  String get couldNotStartOnboarding => 'Could not start onboarding';

  @override
  String get earningsTitle => 'Earnings';

  @override
  String get totalEarned => 'Total earned';

  @override
  String get noEarningsYet => 'No earnings yet';

  @override
  String get completedBookingsWillAppear =>
      'Completed bookings will appear here';

  @override
  String get couldNotLoadEarnings => 'Could not load earnings';

  @override
  String bookingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bookings',
      one: '1 booking',
    );
    return '$_temp0';
  }
}
