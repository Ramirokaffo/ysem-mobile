import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/charte/charte.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../application/connexion.dart';
import '../data/auth_repository.dart';
import 'entete_connexion.dart';

/// Double authentification : le code à six chiffres reçu par e-mail.
class CodeVerificationPage extends ConsumerStatefulWidget {
  const CodeVerificationPage({super.key, required this.defi});

  final CodeRequis defi;

  @override
  ConsumerState<CodeVerificationPage> createState() =>
      _CodeVerificationPageState();
}

class _CodeVerificationPageState extends ConsumerState<CodeVerificationPage> {
  final _code = TextEditingController();
  late CodeRequis _defi = widget.defi;
  Timer? _minuteur;
  Duration _restant = Duration.zero;
  bool _enCours = false;
  bool _renvoiEnCours = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _demarrerMinuteur();
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _demarrerMinuteur() {
    _minuteur?.cancel();
    void tic() {
      final fin = _defi.expireLe;
      final reste = fin == null ? Duration.zero : fin.difference(DateTime.now());
      setState(() => _restant = reste.isNegative ? Duration.zero : reste);
    }

    tic();
    _minuteur = Timer.periodic(const Duration(seconds: 1), (_) => tic());
  }

  bool get _expire => _defi.expireLe != null && _restant == Duration.zero;

  Future<void> _verifier() async {
    final code = _code.text.trim();
    if (code.length != 6 || _enCours) return;
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      final resultat = await ref
          .read(authRepositoryProvider(_defi.espace))
          .verifierCode(defi: _defi.defi, code: code);
      if (!mounted) return;
      poursuivreConnexion(context, ref, resultat);
    } on ApiException catch (e) {
      if (!mounted) return;
      final t = AppLocalizations.of(context);
      final restantes = e.donnees['tentatives_restantes'];
      setState(() {
        _erreur = restantes is int && restantes > 0
            ? '${e.message} ${t.tentativesRestantes(restantes)}'
            : e.message;
        _code.clear();
      });
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  Future<void> _renvoyer() async {
    setState(() {
      _renvoiEnCours = true;
      _erreur = null;
    });
    try {
      final nouveau =
          await ref
          .read(authRepositoryProvider(_defi.espace))
          .renvoyerCode(_defi.defi);
      if (!mounted) return;
      setState(() {
        _defi = nouveau;
        _code.clear();
      });
      _demarrerMinuteur();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(nouveau.message)));
    } on ApiException catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _renvoiEnCours = false);
    }
  }

  String _mmss(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          EnteteConnexion(
            titre: t.verificationTitre,
            sousTitre: _defi.adresse == null
                ? t.verificationConsigne
                : t.verificationConsigneAdresse(_defi.adresse!),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_defi.envoye) ...[
                  MessageErreur(_defi.message),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _code,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: theme.textTheme.headlineMedium?.copyWith(
                    letterSpacing: 12,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '••••••',
                    labelText: t.codeVerification,
                    floatingLabelAlignment: FloatingLabelAlignment.center,
                  ),
                  onChanged: (v) {
                    if (v.length == 6) _verifier();
                  },
                ),
                const SizedBox(height: 12),
                if (_defi.expireLe != null)
                  Text(
                    _expire ? t.codeExpire : t.codeExpireDans(_mmss(_restant)),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _expire
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (_erreur != null) ...[
                  const SizedBox(height: 16),
                  MessageErreur(_erreur!),
                ],
                const SizedBox(height: 24),
                BoutonEnvoi(
                  libelle: t.verifier,
                  enCours: _enCours,
                  onPressed: _expire ? null : _verifier,
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _renvoiEnCours ? null : _renvoyer,
                  icon: _renvoiEnCours
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.mark_email_unread_outlined),
                  label: Text(t.renvoyerCode),
                ),
                const SizedBox(height: 12),
                Text(
                  t.verificationAide,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: YsemTokens.of(context).neutre),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
