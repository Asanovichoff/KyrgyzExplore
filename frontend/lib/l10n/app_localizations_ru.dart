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
}
