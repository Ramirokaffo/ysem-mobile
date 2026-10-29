import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/charte/charte.dart';
import '../../../core/auth/espace.dart';
import '../../../core/format/formats.dart';
import '../../../core/models/notifications.dart';
import '../../../core/network/api_exception.dart';
import '../../../l10n/app_localizations.dart';
import '../langue.dart';
import 'centre_notifications.dart';
import 'menu.dart';

/// Section de l'application que désigne l'adresse web d'une notification.
typedef LecteurAdresse = String? Function(String adresse);

/// Ouvre une section de l'espace par son code de registre.
typedef OuvreurSection = void Function(BuildContext context, String code);

/// Centre de notifications d'un espace : le même que celui du portail web,
/// lu dans la langue du destinataire. Chaque espace dit comment une adresse
/// du portail se traduit en section, et comment l'ouvrir.
class CentreNotificationsPage extends ConsumerStatefulWidget {
  const CentreNotificationsPage({
    super.key,
    required this.espace,
    required this.sectionDeLAdresse,
    required this.ouvrirSection,
  });

  final Espace espace;
  final LecteurAdresse sectionDeLAdresse;
  final OuvreurSection ouvrirSection;

  @override
  ConsumerState<CentreNotificationsPage> createState() =>
      _CentreNotificationsPageState();
}

class _CentreNotificationsPageState
    extends ConsumerState<CentreNotificationsPage> {
  bool _nonLuesSeulement = false;
  final _defilement = ScrollController();

  @override
  void initState() {
    super.initState();
    _defilement.addListener(_auBas);
  }

  @override
  void dispose() {
    _defilement.dispose();
    super.dispose();
  }

  FiltreCentre get _filtre => (widget.espace, _nonLuesSeulement);

  NotificationsController get _controleur =>
      ref.read(centreNotificationsProvider(_filtre).notifier);

  void _auBas() {
    if (_defilement.position.extentAfter < 400) {
      _executer(_controleur.chargerSuite);
    }
  }

  /// Joue un geste et dit l'erreur du serveur s'il échoue.
  Future<bool> _executer(Future<void> Function() geste) async {
    try {
      await geste();
      return true;
    } catch (e) {
      if (mounted) {
        final t = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is ApiException ? e.message : t.erreurInattendue),
        ));
      }
      return false;
    }
  }

  Future<void> _ouvrir(NotificationPortail notification) async {
    final controleur = _controleur;
    final lecture = notification.lue
        ? null
        : _executer(() => controleur.marquer(notification, lue: true));
    final action = await showModalBottomSheet<_Action>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _Detail(
        notification: notification,
        ouvrable: widget.sectionDeLAdresse(notification.url) != null,
      ),
    );
    await lecture;
    if (!mounted) return;
    // Ouverte, elle est lue : les gestes suivants partent de cet état.
    final lue = notification.copieLue(true);
    switch (action) {
      case _Action.ouvrir:
        final section = widget.sectionDeLAdresse(notification.url);
        if (section != null) widget.ouvrirSection(context, section);
      case _Action.nonLue:
        _executer(() => controleur.marquer(lue, lue: false));
      case _Action.supprimer:
        _supprimer(lue);
      case null:
        break;
    }
  }

  Future<bool> _supprimer(NotificationPortail notification) async {
    final t = AppLocalizations.of(context);
    final fait = await _executer(() => _controleur.supprimer(notification));
    if (fait && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(t.notificationSupprimee)));
    }
    return fait;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final valeur = ref.watch(centreNotificationsProvider(_filtre));
    final nonLues = ref
            .watch(menuProvider(widget.espace))
            .valueOrNull
            ?.notificationsNonLues ??
        0;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.ongletNotifications),
        actions: [
          IconButton(
            tooltip: t.toutMarquerLu,
            onPressed: nonLues == 0
                ? null
                : () => _executer(_controleur.toutMarquerLu),
            icon: const Icon(Icons.done_all_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: false, label: Text(t.notificationsToutes)),
                  ButtonSegment(
                    value: true,
                    label: Text(nonLues > 0
                        ? '${t.notificationsFiltreNonLues} ($nonLues)'
                        : t.notificationsFiltreNonLues),
                  ),
                ],
                selected: {_nonLuesSeulement},
                onSelectionChanged: (choix) =>
                    setState(() => _nonLuesSeulement = choix.first),
              ),
            ),
          ),
          Expanded(
            child: VueAsynchrone<ListeNotifications>(
              valeur: valeur,
              surRafraichir: () async {
                await Future.wait([
                  ref.refresh(centreNotificationsProvider(_filtre).future),
                  ref.read(menuProvider(widget.espace).notifier).relireCompteur(),
                ]);
              },
              constructeur: (liste) => liste.notifications.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(top: 64),
                      children: [
                        EtatVide(
                          message: _nonLuesSeulement
                              ? t.aucuneNotificationNonLue
                              : t.aucuneNotification,
                          icone: _nonLuesSeulement
                              ? Icons.mark_email_read_outlined
                              : Icons.notifications_none_rounded,
                        ),
                      ],
                    )
                  : ListView.separated(
                      controller: _defilement,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: liste.notifications.length +
                          (liste.pagination.aUneSuite ? 1 : 0),
                      separatorBuilder: (_, _) =>
                          const Divider(indent: 72, endIndent: 16),
                      itemBuilder: (context, i) {
                        if (i >= liste.notifications.length) {
                          return const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final notification = liste.notifications[i];
                        return Dismissible(
                          key: ValueKey(notification.id),
                          direction: DismissDirection.endToStart,
                          background: const _FondSuppression(),
                          confirmDismiss: (_) => _supprimer(notification),
                          child: _TuileNotification(
                            notification: notification,
                            onTap: () => _ouvrir(notification),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _Action { ouvrir, nonLue, supprimer }

/// Icône d'une catégorie (`notifications.models.CATEGORY_ICONS`).
IconData _iconeDeCategorie(String categorie) => switch (categorie) {
      'scholar' => Icons.school_rounded,
      'payment' => Icons.payments_rounded,
      'document' => Icons.description_rounded,
      'planning' => Icons.calendar_month_rounded,
      'teaching' => Icons.co_present_rounded,
      'discipline' => Icons.verified_user_rounded,
      'notes' => Icons.fact_check_rounded,
      'admission' => Icons.how_to_reg_rounded,
      'account' => Icons.manage_accounts_rounded,
      'message' => Icons.chat_rounded,
      'system' => Icons.settings_rounded,
      _ => Icons.notifications_rounded,
    };

Color _couleurDuNiveau(BuildContext context, String niveau) {
  final jetons = YsemTokens.of(context);
  return switch (niveau) {
    'success' => jetons.succes,
    'warning' => jetons.alerte,
    'danger' => jetons.danger,
    _ => Theme.of(context).colorScheme.secondary,
  };
}

class _IconeNotification extends StatelessWidget {
  const _IconeNotification({required this.notification});

  final NotificationPortail notification;

  @override
  Widget build(BuildContext context) {
    final couleur = _couleurDuNiveau(context, notification.niveau);
    return CircleAvatar(
      radius: 22,
      backgroundColor: couleur.withValues(alpha: 0.14),
      child: Icon(_iconeDeCategorie(notification.categorie),
          color: couleur, size: 22),
    );
  }
}

class _TuileNotification extends StatelessWidget {
  const _TuileNotification({required this.notification, required this.onTap});

  final NotificationPortail notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final nonLue = !notification.lue;

    return Material(
      color: nonLue
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconeNotification(notification: notification),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.titre,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: nonLue ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                    if (notification.message.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        notification.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      [
                        Formats.horodatage(notification.creeLe, langue),
                        notification.categorieLibelle,
                      ].where((s) => s.isNotEmpty).join(' · '),
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (nonLue)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 6),
                  child: Icon(Icons.circle,
                      size: 10, color: theme.colorScheme.primary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FondSuppression extends StatelessWidget {
  const _FondSuppression();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.errorContainer,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      child: Icon(Icons.delete_outline_rounded,
          color: theme.colorScheme.onErrorContainer),
    );
  }
}

/// La notification en entier, et ce qu'on peut en faire.
class _Detail extends StatelessWidget {
  const _Detail({required this.notification, required this.ouvrable});

  final NotificationPortail notification;

  /// L'adresse désigne une section de l'application.
  final bool ouvrable;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _IconeNotification(notification: notification),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(notification.titre,
                        style: theme.textTheme.titleMedium),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                [
                  Formats.horodatage(notification.creeLe, langue),
                  notification.categorieLibelle,
                ].where((s) => s.isNotEmpty).join(' · '),
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              if (notification.message.isNotEmpty) ...[
                const SizedBox(height: 14),
                SelectableText(notification.message,
                    style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: 20),
              if (ouvrable) ...[
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context, _Action.ouvrir),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text(t.ouvrir),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => Navigator.pop(context, _Action.nonLue),
                      icon: const Icon(Icons.mark_email_unread_outlined),
                      label: Text(t.marquerNonLue),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.error),
                      onPressed: () =>
                          Navigator.pop(context, _Action.supprimer),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: Text(t.supprimer),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
