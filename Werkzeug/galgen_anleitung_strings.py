#!/usr/bin/env python3
"""galgen_anleitung_strings.py: Anleitung Galgenmännchen (Runde 5, Blatt 14, KI-4), de/en/es/fr. Überschreibt nichts. Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Ein Wort ist gesucht. Finde es, bevor der letzte von acht Ballons platzt.": (
    "A word is hidden. Find it before the last of eight balloons pops.",
    "Hay una palabra oculta. Adivínala antes de que explote el último de los ocho globos.",
    "Un mot est caché. Trouve-le avant que le dernier des huit ballons n'éclate."),
"Tippe einen Buchstaben. Steckt er im Wort, erscheint er an allen Stellen.": (
    "Tap a letter. If it is in the word, it appears in every place it belongs.",
    "Toca una letra. Si está en la palabra, aparece en todos los sitios donde va.",
    "Touche une lettre. Si elle est dans le mot, elle apparaît à tous ses emplacements."),
"Acht Ballons": ("Eight balloons", "Ocho globos", "Huit ballons"),
"Jeder falsche Buchstabe lässt einen Ballon platzen. Platzt der achte, ist das Wort verloren.": (
    "Every wrong letter pops a balloon. When the eighth pops, the word is lost.",
    "Cada letra equivocada hace explotar un globo. Si explota el octavo, la palabra está perdida.",
    "Chaque mauvaise lettre fait éclater un ballon. Quand le huitième éclate, le mot est perdu."),
"Hinweis und Lösen": ("Hint and Solve", "Pista y Resolver", "Indice et Résoudre"),
"Ein Hinweis deckt einen Buchstaben auf. Du hast zwei, in „Kinderleicht“ vier. Mit „Lösen“ rätst du das ganze Wort. Ein falscher Versuch kostet zwei Ballons.": (
    "A hint reveals one letter. You have two, or four in “Kids' mode”. With “Solve” you guess the whole word. A wrong attempt costs two balloons.",
    "Una pista descubre una letra. Tienes dos, o cuatro en «Modo infantil». Con «Resolver» adivinas la palabra entera. Un intento fallido cuesta dos globos.",
    "Un indice dévoile une lettre. Tu en as deux, quatre en « Mode enfant ». Avec « Résoudre », tu devines le mot entier. Un essai raté coûte deux ballons."),
"Allein oder zu mehreren": ("Alone or with others", "Solo o en grupo", "Seul ou à plusieurs"),
"Allein wählst du Kategorie und Stufe, das Wort des Tages oder „Überleben“ mit drei Leben. Zu mehreren rät reihum einer. Das Wort zieht die App, oder der Spieler nach ihm denkt es sich aus.": (
    "Alone, you choose a category and level, play the word of the day, or “Survival” with three lives. In a group, players take turns guessing. The app draws the word, or the next player in turn thinks one up.",
    "Solo eliges categoría y nivel, juegas la palabra del día o «Supervivencia» con tres vidas. En grupo adivina uno por turno. La app elige la palabra, o el siguiente jugador se la inventa.",
    "Seul, tu choisis la catégorie et le niveau, le mot du jour ou « Survie » avec trois vies. À plusieurs, on devine chacun son tour. L'appli tire le mot, ou le joueur suivant l'invente."),
"Tiere · leicht": ("Animals · easy", "Animales · fácil", "Animaux · facile"),
"Party: reihum": ("Party: in turn", "Fiesta: por turnos", "Soirée : chacun son tour"),
}
cat = json.load(open(KAT)); s = cat['strings']; n = 0
for k, t in U.items():
    loc = s.setdefault(k, {}).setdefault('localizations', {})
    if 'en' in loc and 'fr' in loc: continue
    loc.setdefault('de', {"stringUnit": {"state": "translated", "value": k}})
    for sp, v in zip(('en', 'es', 'fr'), t): loc.setdefault(sp, {"stringUnit": {"state": "translated", "value": v}})
    n += 1
orig = open(KAT).read()
open(KAT, 'w').write(json.dumps(cat, ensure_ascii=False, indent=2, separators=(',', ': ')) + ('\n' if orig.endswith('\n') else ''))
print('eingetragen:', n)
