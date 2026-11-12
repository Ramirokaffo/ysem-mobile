import 'package:flutter/widgets.dart';

/// Joue [ouvrir] une seule fois, après la première image de [child].
///
/// Sert aux sections ouvertes depuis une notification qui désigne un objet
/// (`devoirs?devoir=12`) : la liste s'affiche, puis la fiche s'ouvre par-dessus
/// — si bien que le retour ramène à la liste, comme depuis le menu.
class OuvertureInitiale extends StatefulWidget {
  const OuvertureInitiale({super.key, required this.ouvrir, required this.child});

  /// `null` : rien à ouvrir.
  final void Function(BuildContext context)? ouvrir;
  final Widget child;

  @override
  State<OuvertureInitiale> createState() => _OuvertureInitialeState();
}

class _OuvertureInitialeState extends State<OuvertureInitiale> {
  @override
  void initState() {
    super.initState();
    final ouvrir = widget.ouvrir;
    if (ouvrir == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ouvrir(context);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
