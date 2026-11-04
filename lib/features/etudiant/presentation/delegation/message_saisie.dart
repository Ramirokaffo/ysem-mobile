import '../../../../l10n/app_localizations.dart';
import '../../hors_ligne/depot_delegation.dart';
import '../../hors_ligne/synchroniseur.dart';

/// Ce que le délégué lit une fois sa saisie enregistrée.
String messageDeSaisie(AppLocalizations t, IssueEnregistrement issue) {
  final message = issue.message;
  return switch (issue.genre) {
    GenreIssue.surLeTelephone => t.saisieGardeeSurLeTelephone,
    GenreIssue.aArbitrer => message == null || message.isEmpty
        ? t.saisieTransmiseAuService
        : '${t.saisieTransmiseAuService} $message',
    GenreIssue.transmise =>
      message == null || message.isEmpty ? t.saisieEnregistree : message,
  };
}
