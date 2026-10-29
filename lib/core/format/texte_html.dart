/// Texte lisible tiré du HTML d'un éditeur (programme d'une liste…) : les
/// blocs deviennent des paragraphes, les éléments de liste des puces, les
/// entités courantes sont décodées. Aucune mise en forme n'est rendue.
String texteDuHtml(String html) {
  var texte = html
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '\n• ')
      .replaceAll(
          RegExp(r'</(p|div|h[1-6]|li|ul|ol|blockquote)>',
              caseSensitive: false),
          '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '');
  const entites = {
    '&nbsp;': ' ',
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&#39;': "'",
    '&rsquo;': '’',
    '&lsquo;': '‘',
    '&laquo;': '«',
    '&raquo;': '»',
    '&eacute;': 'é',
    '&egrave;': 'è',
    '&agrave;': 'à',
    '&ccedil;': 'ç',
    '&ecirc;': 'ê',
    '&ocirc;': 'ô',
    '&hellip;': '…',
    '&ndash;': '–',
    '&mdash;': '—',
  };
  entites.forEach((entite, caractere) {
    texte = texte.replaceAll(entite, caractere);
  });
  texte = texte.replaceAllMapped(RegExp(r'&#(\d+);'),
      (m) => String.fromCharCode(int.parse(m.group(1)!)));
  return texte
      .split('\n')
      .map((ligne) => ligne.replaceAll(RegExp(r'[ \t]+'), ' ').trim())
      .join('\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}
