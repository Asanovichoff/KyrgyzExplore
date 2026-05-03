// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kirghiz Kyrgyz (`ky`).
class AppLocalizationsKy extends AppLocalizations {
  AppLocalizationsKy([String locale = 'ky']) : super(locale);

  @override
  String get appName => 'KyrgyzExplore';

  @override
  String get login => 'Кирүү';

  @override
  String get register => 'Каттоо жасоо';

  @override
  String get email => 'Электрондук почта';

  @override
  String get password => 'Сырсөз';

  @override
  String get firstName => 'Аты';

  @override
  String get lastName => 'Фамилиясы';

  @override
  String get role => 'Мен';

  @override
  String get traveler => 'Саякатчы';

  @override
  String get host => 'Ээси';

  @override
  String get loginError => 'Туура эмес email же сырсөз.';

  @override
  String get registerError => 'Каттоо жасалган жок. Кайра аракет кылыңыз.';

  @override
  String get alreadyHaveAccount => 'Аккаунтуңуз барбы? Кириңиз';

  @override
  String get noAccount => 'Аккаунтуңуз жокпу? Жасаңыз';

  @override
  String get loading => 'Жүктөлүүдө...';

  @override
  String get retry => 'Кайталоо';

  @override
  String get logOut => 'Чыгуу';

  @override
  String get home => 'Изилдөө';

  @override
  String get trips => 'Саякаттар';

  @override
  String get messages => 'Билдирүүлөр';

  @override
  String get profile => 'Профиль';

  @override
  String get cancel => 'Жокко чыгаруу';

  @override
  String get edit => 'Өзгөртүү';

  @override
  String get delete => 'Жок кылуу';

  @override
  String get save => 'Сактоо';

  @override
  String get saveChanges => 'Өзгөртүүлөрдү сактоо';

  @override
  String get confirm => 'Тастыктоо';

  @override
  String get reject => 'Баш тартуу';

  @override
  String get continueLabel => 'Улантуу';

  @override
  String get setUp => 'Орнотуу';

  @override
  String get language => 'Тил';

  @override
  String get filterAll => 'Баары';

  @override
  String get filterHouses => 'Үйлөр';

  @override
  String get filterCars => 'Машиналар';

  @override
  String get filterActivities => 'Иш-чаралар';

  @override
  String get couldNotLoadListings => 'Жарнамаларды жүктөй алмак эмес';

  @override
  String get checkConnectionAndRetry =>
      'Байланышыңызды текшерип, кайра аракет кылыңыз';

  @override
  String get noListingsFound => 'Жарнамалар табылган жок';

  @override
  String get tryDifferentFilter => 'Башка чыпка же аймакты колдонуп көрүңүз';

  @override
  String get about => 'Жөнүндө';

  @override
  String get availabilityTitle => 'Жеткиликтүүлүк';

  @override
  String get reviewsTitle => 'Пикирлер';

  @override
  String get reviewsLabel => 'пикир';

  @override
  String get bookNow => 'Азыр броньдоо';

  @override
  String get perNight => '/ түн';

  @override
  String get perDay => '/ күн';

  @override
  String get couldNotLoadListing => 'Жарнаманы жүктөй алмак эмес';

  @override
  String get couldNotLoadReviews => 'Пикирлерди жүктөй алмак эмес';

  @override
  String get noReviewsYet => 'Азырынча пикир жок';

  @override
  String get myBookings => 'Менин броньдорум';

  @override
  String get manageBookings => 'Броньдорду башкаруу';

  @override
  String get couldNotLoadBookings => 'Броньдорду жүктөй алмак эмес';

  @override
  String get noBookingsYet => 'Азырынча бронь жок';

  @override
  String get chatWithHost => 'Ээси менен сүйлөшүү';

  @override
  String get chatWithGuest => 'Конок менен сүйлөшүү';

  @override
  String get cancelBookingTitle => 'Броньду жокко чыгарасызбы?';

  @override
  String get cancelBookingContent => 'Бул аракетти кайтарып алуу мүмкүн эмес.';

  @override
  String get keepIt => 'Калтыруу';

  @override
  String get cancelBookingAction => 'Броньду жокко чыгаруу';

  @override
  String get paymentSuccessful => 'Төлөм ийгиликтүү болду!';

  @override
  String get paymentFailed => 'Төлөм ийгиликсиз болду';

  @override
  String get payNow => 'Азыр төлөө';

  @override
  String get leaveReview => 'Пикир калтыруу';

  @override
  String get reviewSubmitted => 'Пикириңиз кабыл алынды! Рахмат.';

  @override
  String get couldNotCancel => 'Броньду жокко чыгара алган жок';

  @override
  String get rejectBookingTitle => 'Броньду баш тартуу';

  @override
  String get giveReasonRequired => 'Себебин жазыңыз (милдеттүү)';

  @override
  String nightCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count түн',
      one: '1 түн',
    );
    return '$_temp0';
  }

  @override
  String guestCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count конок',
      one: '1 конок',
    );
    return '$_temp0';
  }

  @override
  String get statusPending => 'Күтүүдө';

  @override
  String get statusConfirmed => 'Тастыкталды';

  @override
  String get statusRejected => 'Баш тартылды';

  @override
  String get statusCancelled => 'Жокко чыгарылды';

  @override
  String get statusPaid => 'Төлөндү';

  @override
  String get myListings => 'Менин жарнамаларым';

  @override
  String get noListingsYet => 'Азырынча жарнама жок';

  @override
  String get tapToCreateFirstListing =>
      'Биринчи жарнамаңызды жасоо үчүн + баскычын басыңыз';

  @override
  String get createListing => 'Жарнама жасоо';

  @override
  String get deleteListingTitle => 'Жарнаманы жок кылуу?';

  @override
  String get deleteListingContent =>
      'Бул жарнаманы жана бардык күтүүдөгү броньдорду жок кылат.';

  @override
  String get couldNotDelete => 'Жарнаманы жок кыла алган жок';

  @override
  String get manageDates => 'Күндөрдү башкаруу';

  @override
  String get typeHouse => 'Үй';

  @override
  String get typeCar => 'Машина';

  @override
  String get typeActivity => 'Иш-чара';

  @override
  String get notifications => 'Билдирүүлөр';

  @override
  String get markAllRead => 'Баарын окулган деп белгилөө';

  @override
  String get couldNotLoadNotifications => 'Билдирүүлөрдү жүктөй алмак эмес';

  @override
  String get noNotificationsYet => 'Азырынча билдирүүлөр жок';

  @override
  String get phoneOptional => 'Телефон (кошумча)';

  @override
  String get couldNotUploadPhoto => 'Сүрөттү жүктөй алган жок';

  @override
  String get couldNotSave => 'Сактай алган жок';

  @override
  String get profileUpdated => 'Профиль жаңыланды';

  @override
  String get payoutSettings => 'Төлөм жөндөөлөрү';

  @override
  String get payoutsEnabled => 'Төлөмдөр иштетилди';

  @override
  String get verificationInProgress => 'Текшерүү жүрүп жатат';

  @override
  String get notConnected => 'Туташтырылган жок';

  @override
  String get youWillReceivePayouts => 'Броньдордон төлөм аласыз';

  @override
  String get stripeReviewing => 'Stripe маалыматыңызды текшерүүдө';

  @override
  String get connectStripe => 'Төлөм алуу үчүн Stripe туташтырыңыз';

  @override
  String get viewEarnings => 'Кирешени көрүү';

  @override
  String get couldNotOpenBrowser => 'Браузерди ача алган жок';

  @override
  String get couldNotStartOnboarding => 'Орнотууну баштай алган жок';

  @override
  String get earningsTitle => 'Киреше';

  @override
  String get totalEarned => 'Жалпы киреше';

  @override
  String get noEarningsYet => 'Азырынча киреше жок';

  @override
  String get completedBookingsWillAppear =>
      'Аяктаган броньдор бул жерде көрүнөт';

  @override
  String get couldNotLoadEarnings => 'Кирешени жүктөө мүмкүн болгон жок';

  @override
  String bookingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count бронь',
      one: '1 бронь',
    );
    return '$_temp0';
  }

  @override
  String get logInToContinue => 'Улантуу үчүн кириңиз';

  @override
  String get enterValidEmail => 'Туура email киргизиңиз';

  @override
  String get passwordMinLength => 'Сырсөз кеминде 8 белгиден турушу керек';

  @override
  String get or => 'же';

  @override
  String get continueWithGoogle => 'Google аркылуу улантуу';

  @override
  String get continueWithApple => 'Apple аркылуу улантуу';

  @override
  String get googleSignInFailed => 'Google аркылуу кирүү мүмкүн болгон жок';

  @override
  String get appleSignInFailed => 'Apple аркылуу кирүү мүмкүн болгон жок';

  @override
  String get loginFailed => 'Кирүү катасы. Кайра аракет кылыңыз.';

  @override
  String get registrationFailed => 'Катталуу катасы. Кайра аракет кылыңыз.';

  @override
  String get required => 'Милдеттүү талаа';

  @override
  String get mustBeNumber => 'Сан болушу керек';

  @override
  String get filtersTooltip => 'Чыпкалар';

  @override
  String get requestToBook => 'Бронь сурамжылоо';

  @override
  String get dates => 'Күндөр';

  @override
  String get checkInLabel => 'Кирүү';

  @override
  String get checkOutLabel => 'Чыгуу';

  @override
  String get guestsLabel => 'Конокчулар';

  @override
  String get messageToHostOptional => 'Ээсине билдирүү (милдеттүү эмес)';

  @override
  String get messageToHostHint => 'Планыңыз жөнүндө ээге айтыңыз...';

  @override
  String get selectDate => 'Тандоо';

  @override
  String dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count күн',
      one: '1 күн',
    );
    return '$_temp0';
  }

  @override
  String get bookingRequestSent =>
      'Бронь сурамжылоосу жөнөтүлдү! Ээ жакында ырастайт.';

  @override
  String get pleaseSelectDates => 'Кирүү жана чыгуу күндөрүн тандаңыз.';

  @override
  String get checkoutAfterCheckin =>
      'Чыгуу кирүүдөн кийин кеминде 1 күн болушу керек.';

  @override
  String get couldNotReachServer =>
      'Серверге туташуу мүмкүн болгон жок. Байланышыңызды текшериңиз.';

  @override
  String get somethingWentWrong =>
      'Бир нерсе ката кетти. Кайра аракет кылыңыз.';

  @override
  String get editListing => 'Жарнаманы өзгөртүү';

  @override
  String get newListing => 'Жаңы жарнама';

  @override
  String get typeSectionLabel => 'Түрү';

  @override
  String get basicInfo => 'Негизги маалымат';

  @override
  String get titleFieldLabel => 'Аты';

  @override
  String get descriptionFieldLabel => 'Сүрөттөмө';

  @override
  String get pricingSection => 'Баасы';

  @override
  String get pricePerNightDay => 'Бир түн/күн баасы';

  @override
  String get currencyLabel => 'Валюта';

  @override
  String get maxGuestsOptional => 'Мак. конок (кошумча)';

  @override
  String get locationSection => 'Жайгашуу';

  @override
  String get streetAddress => 'Дарек';

  @override
  String get cityLabel => 'Шаар';

  @override
  String get latitudeLabel => 'Кеңдик';

  @override
  String get longitudeLabel => 'Узундук';

  @override
  String get useMyLocation => 'Менин жайгашуумду колдонуу';

  @override
  String get locationPermissionDenied => 'Жайгашуу уруксаты берилген жок';

  @override
  String get couldNotGetLocation => 'Жайгашууну аныктоо мүмкүн болгон жок';

  @override
  String get photosSection => 'Сүрөттөр';

  @override
  String get listingUpdated => 'Жарнама жаңыланды!';

  @override
  String get listingCreated => 'Жарнама түзүлдү!';

  @override
  String get couldNotDeleteImage => 'Сүрөттү жок кылуу мүмкүн болгон жок';

  @override
  String get available => 'Жеткиликтүү';

  @override
  String get blockedLabel => 'Блокталган';

  @override
  String get pendingChangeLabel => 'Күтүп жаткан өзгөртүү';

  @override
  String get availabilityUpdated => 'Жеткиликтүүлүк жаңыланды';

  @override
  String availabilityUnsavedHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count сакталбаган өзгөртүү — Сактоо баскычын басыңыз',
      one: '1 сакталбаган өзгөртүү — Сактоо баскычын басыңыз',
    );
    return '$_temp0';
  }

  @override
  String get couldNotLoadAvailability =>
      'Жеткиликтүүлүктү жүктөө мүмкүн болгон жок';

  @override
  String get couldNotSaveAvailability =>
      'Жеткиликтүүлүктү сактоо мүмкүн болгон жок';

  @override
  String get chatNoMessages => 'Азырынча кабарлар жок.\nСалам айтыңыз!';

  @override
  String get typeAMessage => 'Кабар жазыңыз…';

  @override
  String get navListings => 'Жарнамалар';

  @override
  String get navBookings => 'Броньдор';

  @override
  String get logOutConfirm => 'Чыгуу жөнүндө ишениңизби?';

  @override
  String get timeJustNow => 'Азыр эле';

  @override
  String timeMinutesAgo(int count) {
    return '$count мүн. мурун';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count саат мурун';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count күн мурун';
  }
}
