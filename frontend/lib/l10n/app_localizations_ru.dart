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
}
