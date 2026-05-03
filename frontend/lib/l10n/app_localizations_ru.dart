// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'KyrgyzExplore';

  @override
  String get login => 'Войти';

  @override
  String get register => 'Создать аккаунт';

  @override
  String get email => 'Электронная почта';

  @override
  String get password => 'Пароль';

  @override
  String get firstName => 'Имя';

  @override
  String get lastName => 'Фамилия';

  @override
  String get role => 'Я';

  @override
  String get traveler => 'Путешественник';

  @override
  String get host => 'Хозяин';

  @override
  String get loginError => 'Неверный email или пароль.';

  @override
  String get registerError => 'Не удалось создать аккаунт. Попробуйте ещё раз.';

  @override
  String get alreadyHaveAccount => 'Уже есть аккаунт? Войти';

  @override
  String get noAccount => 'Нет аккаунта? Создать';

  @override
  String get loading => 'Загрузка...';

  @override
  String get retry => 'Повторить';

  @override
  String get logOut => 'Выйти';

  @override
  String get home => 'Исследовать';

  @override
  String get trips => 'Поездки';

  @override
  String get messages => 'Сообщения';

  @override
  String get profile => 'Профиль';

  @override
  String get cancel => 'Отмена';

  @override
  String get edit => 'Редактировать';

  @override
  String get delete => 'Удалить';

  @override
  String get save => 'Сохранить';

  @override
  String get saveChanges => 'Сохранить изменения';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get reject => 'Отклонить';

  @override
  String get continueLabel => 'Продолжить';

  @override
  String get setUp => 'Настроить';

  @override
  String get language => 'Язык';

  @override
  String get filterAll => 'Все';

  @override
  String get filterHouses => 'Дома';

  @override
  String get filterCars => 'Автомобили';

  @override
  String get filterActivities => 'Активности';

  @override
  String get couldNotLoadListings => 'Не удалось загрузить объявления';

  @override
  String get checkConnectionAndRetry =>
      'Проверьте подключение и попробуйте снова';

  @override
  String get noListingsFound => 'Объявления не найдены';

  @override
  String get tryDifferentFilter => 'Попробуйте другой фильтр или область';

  @override
  String get about => 'О месте';

  @override
  String get availabilityTitle => 'Доступность';

  @override
  String get reviewsTitle => 'Отзывы';

  @override
  String get reviewsLabel => 'отзывов';

  @override
  String get bookNow => 'Забронировать';

  @override
  String get perNight => '/ ночь';

  @override
  String get perDay => '/ день';

  @override
  String get couldNotLoadListing => 'Не удалось загрузить объявление';

  @override
  String get couldNotLoadReviews => 'Не удалось загрузить отзывы';

  @override
  String get noReviewsYet => 'Отзывов пока нет';

  @override
  String get myBookings => 'Мои бронирования';

  @override
  String get manageBookings => 'Управление бронированиями';

  @override
  String get couldNotLoadBookings => 'Не удалось загрузить бронирования';

  @override
  String get noBookingsYet => 'Бронирований пока нет';

  @override
  String get chatWithHost => 'Написать хозяину';

  @override
  String get chatWithGuest => 'Написать гостю';

  @override
  String get cancelBookingTitle => 'Отменить бронирование?';

  @override
  String get cancelBookingContent => 'Это действие нельзя отменить.';

  @override
  String get keepIt => 'Оставить';

  @override
  String get cancelBookingAction => 'Отменить бронирование';

  @override
  String get paymentSuccessful => 'Оплата прошла успешно!';

  @override
  String get paymentFailed => 'Ошибка оплаты';

  @override
  String get payNow => 'Оплатить';

  @override
  String get leaveReview => 'Оставить отзыв';

  @override
  String get reviewSubmitted => 'Отзыв отправлен! Спасибо.';

  @override
  String get couldNotCancel => 'Не удалось отменить бронирование';

  @override
  String get rejectBookingTitle => 'Отклонить бронирование';

  @override
  String get giveReasonRequired => 'Укажите причину (обязательно)';

  @override
  String nightCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ночи',
      many: '$count ночей',
      few: '$count ночи',
      one: '1 ночь',
    );
    return '$_temp0';
  }

  @override
  String guestCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count гостя',
      many: '$count гостей',
      few: '$count гостя',
      one: '1 гость',
    );
    return '$_temp0';
  }

  @override
  String get statusPending => 'Ожидает';

  @override
  String get statusConfirmed => 'Подтверждено';

  @override
  String get statusRejected => 'Отклонено';

  @override
  String get statusCancelled => 'Отменено';

  @override
  String get statusPaid => 'Оплачено';

  @override
  String get myListings => 'Мои объявления';

  @override
  String get noListingsYet => 'Объявлений пока нет';

  @override
  String get tapToCreateFirstListing =>
      'Нажмите + чтобы создать первое объявление';

  @override
  String get createListing => 'Создать объявление';

  @override
  String get deleteListingTitle => 'Удалить объявление?';

  @override
  String get deleteListingContent =>
      'Это удалит объявление и отменит все ожидающие бронирования.';

  @override
  String get couldNotDelete => 'Не удалось удалить объявление';

  @override
  String get manageDates => 'Управление датами';

  @override
  String get typeHouse => 'Дом';

  @override
  String get typeCar => 'Автомобиль';

  @override
  String get typeActivity => 'Активность';

  @override
  String get notifications => 'Уведомления';

  @override
  String get markAllRead => 'Отметить все как прочитанные';

  @override
  String get couldNotLoadNotifications => 'Не удалось загрузить уведомления';

  @override
  String get noNotificationsYet => 'Уведомлений пока нет';

  @override
  String get phoneOptional => 'Телефон (необязательно)';

  @override
  String get couldNotUploadPhoto => 'Не удалось загрузить фото';

  @override
  String get couldNotSave => 'Не удалось сохранить';

  @override
  String get profileUpdated => 'Профиль обновлён';

  @override
  String get payoutSettings => 'Настройки выплат';

  @override
  String get payoutsEnabled => 'Выплаты включены';

  @override
  String get verificationInProgress => 'Верификация в процессе';

  @override
  String get notConnected => 'Не подключено';

  @override
  String get youWillReceivePayouts =>
      'Вы будете получать выплаты от бронирований';

  @override
  String get stripeReviewing => 'Stripe проверяет вашу информацию';

  @override
  String get connectStripe => 'Подключите Stripe для получения платежей';

  @override
  String get viewEarnings => 'Просмотр доходов';

  @override
  String get couldNotOpenBrowser => 'Не удалось открыть браузер';

  @override
  String get couldNotStartOnboarding => 'Не удалось начать настройку';

  @override
  String get earningsTitle => 'Доходы';

  @override
  String get totalEarned => 'Всего заработано';

  @override
  String get noEarningsYet => 'Доходов ещё нет';

  @override
  String get completedBookingsWillAppear =>
      'Завершённые бронирования появятся здесь';

  @override
  String get couldNotLoadEarnings => 'Не удалось загрузить доходы';

  @override
  String bookingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count бронирования',
      many: '$count бронирований',
      few: '$count бронирования',
      one: '1 бронирование',
    );
    return '$_temp0';
  }

  @override
  String get logInToContinue => 'Войдите, чтобы продолжить';

  @override
  String get enterValidEmail => 'Введите корректный email';

  @override
  String get passwordMinLength => 'Пароль должен содержать не менее 8 символов';

  @override
  String get or => 'или';

  @override
  String get continueWithGoogle => 'Продолжить через Google';

  @override
  String get continueWithApple => 'Продолжить через Apple';

  @override
  String get googleSignInFailed => 'Не удалось войти через Google';

  @override
  String get appleSignInFailed => 'Не удалось войти через Apple';

  @override
  String get loginFailed => 'Ошибка входа. Попробуйте снова.';

  @override
  String get registrationFailed => 'Ошибка регистрации. Попробуйте снова.';

  @override
  String get required => 'Обязательное поле';

  @override
  String get mustBeNumber => 'Должно быть числом';

  @override
  String get filtersTooltip => 'Фильтры';

  @override
  String get requestToBook => 'Отправить заявку';

  @override
  String get dates => 'Даты';

  @override
  String get checkInLabel => 'Заезд';

  @override
  String get checkOutLabel => 'Выезд';

  @override
  String get guestsLabel => 'Гости';

  @override
  String get messageToHostOptional => 'Сообщение хозяину (необязательно)';

  @override
  String get messageToHostHint => 'Расскажите хозяину о своих планах...';

  @override
  String get selectDate => 'Выбрать';

  @override
  String dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня',
      many: '$count дней',
      few: '$count дня',
      one: '1 день',
    );
    return '$_temp0';
  }

  @override
  String get bookingRequestSent =>
      'Заявка отправлена! Хозяин скоро подтвердит.';

  @override
  String get pleaseSelectDates => 'Выберите даты заезда и выезда.';

  @override
  String get checkoutAfterCheckin =>
      'Дата выезда должна быть не раньше следующего дня после заезда.';

  @override
  String get couldNotReachServer =>
      'Не удалось подключиться к серверу. Проверьте соединение.';

  @override
  String get somethingWentWrong => 'Что-то пошло не так. Попробуйте снова.';

  @override
  String get editListing => 'Редактировать объявление';

  @override
  String get newListing => 'Новое объявление';

  @override
  String get typeSectionLabel => 'Тип';

  @override
  String get basicInfo => 'Основная информация';

  @override
  String get titleFieldLabel => 'Название';

  @override
  String get descriptionFieldLabel => 'Описание';

  @override
  String get pricingSection => 'Цена';

  @override
  String get pricePerNightDay => 'Цена за ночь/день';

  @override
  String get currencyLabel => 'Валюта';

  @override
  String get maxGuestsOptional => 'Макс. гостей (необязательно)';

  @override
  String get locationSection => 'Местоположение';

  @override
  String get streetAddress => 'Адрес';

  @override
  String get cityLabel => 'Город';

  @override
  String get latitudeLabel => 'Широта';

  @override
  String get longitudeLabel => 'Долгота';

  @override
  String get useMyLocation => 'Использовать мою геопозицию';

  @override
  String get locationPermissionDenied => 'Доступ к геопозиции запрещён';

  @override
  String get couldNotGetLocation => 'Не удалось определить местоположение';

  @override
  String get photosSection => 'Фотографии';

  @override
  String get listingUpdated => 'Объявление обновлено!';

  @override
  String get listingCreated => 'Объявление создано!';

  @override
  String get couldNotDeleteImage => 'Не удалось удалить фото';

  @override
  String get available => 'Доступно';

  @override
  String get blockedLabel => 'Занято';

  @override
  String get pendingChangeLabel => 'Ожидает изменения';

  @override
  String get availabilityUpdated => 'Доступность обновлена';

  @override
  String availabilityUnsavedHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count несохранённых изменения — нажмите Сохранить',
      many: '$count несохранённых изменений — нажмите Сохранить',
      few: '$count несохранённых изменения — нажмите Сохранить',
      one: '1 несохранённое изменение — нажмите Сохранить',
    );
    return '$_temp0';
  }

  @override
  String get couldNotLoadAvailability => 'Не удалось загрузить доступность';

  @override
  String get couldNotSaveAvailability => 'Не удалось сохранить доступность';

  @override
  String get chatNoMessages => 'Сообщений пока нет.\nПоздоровайтесь!';

  @override
  String get typeAMessage => 'Введите сообщение…';

  @override
  String get navListings => 'Объявления';

  @override
  String get navBookings => 'Брони';

  @override
  String get logOutConfirm => 'Вы уверены, что хотите выйти?';

  @override
  String get timeJustNow => 'Только что';

  @override
  String timeMinutesAgo(int count) {
    return '$count мин. назад';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count ч. назад';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count дн. назад';
  }
}
