import 'package:flutter/widgets.dart';
import '../../l10n/app_localizations.dart';

// Shorthand so screens can write `context.l10n.retry` instead of
// `AppLocalizations.of(context)!.retry`.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
