import 'package:flutter/material.dart';

import '../../../commun/fil/fil.dart';
import '../../../commun/fil/fil_page.dart';

export '../../../commun/fil/fil_page.dart';

/// « Mes messages » : le fil de l'étudiant avec le guichet de la scolarité.
/// L'interlocuteur est un service, pas une personne nommée ; chaque message
/// du service garde la signature de l'agent qui l'a écrit.
class MessageriePage extends StatelessWidget {
  const MessageriePage({super.key, this.titre});

  final String? titre;

  @override
  Widget build(BuildContext context) =>
      FilPage(source: SourceFil.guichet, titre: titre);
}
