# Erzeugt Anleitung.swift je Rätsel-/Wort-/Arcade-Spiel und ergänzt die Strings (de/en/es/fr).
# Aufruf aus dem Repo-Wurzelordner: python3 Werkzeug/anleitung-spiele.py
import json, os, re
Z = lambda r,c,R,C: f".zelle({r}, {c}, zeilen: {R}, spalten: {C})"
G = {}
def raster(sym, t, x, geste, v, n=None, zelle=44):
    return dict(k="r", sym=sym, t=t, x=x, geste=geste, v=v, n=n, zelle=zelle)
def bild(sym, t, x, b, geste=".keine"): return dict(k="b", sym=sym, t=t, x=x, b=b, geste=geste)
def cust(sym, t, x, geste, body): return dict(k="c", sym=sym, t=t, x=x, geste=geste, body=body)

# ---- Texte: de -> (en, es, fr)
T = {}
def tr(de, en, es, fr): T[de] = (en, es, fr); return de
S = lambda *a: tr(*a)

PLAYFIELD = lambda inner: inner
# Bühnen für Arcade/Sonderfälle
HANOI = '''GeometryReader { g in
    let s = anleitungAbschnitt(p, von: 0.25, bis: 0.75)
    let x0 = g.size.width * 0.2, x2 = g.size.width * 0.8
    ForEach(0..<3, id: \\.self) { i in
        Capsule().fill(Color.appFlaeche.opacity(0.3)).frame(width: 8, height: 130).position(x: g.size.width * (0.2 + 0.3 * Double(i)), y: g.size.height * 0.58)
    }
    ForEach(0..<3, id: \\.self) { k in
        let breite = CGFloat(110 - k * 30), fest = k > 0
        Capsule().fill(Color.appFlaeche.opacity(1 - Double(k) * 0.2)).frame(width: breite, height: 22)
            .position(x: fest ? x0 : x0 + (x2 - x0) * s, y: fest ? g.size.height * (0.78 - Double(k - 1) * 0.1) + 0 : g.size.height * 0.6 - 60 * sin(s * .pi) + 38 * s)
    }
}'''
HANOI_NEIN = '''GeometryReader { g in
    Capsule().fill(Color.appFlaeche).frame(width: 50, height: 22).position(x: g.size.width * 0.5, y: g.size.height * 0.62)
    Capsule().fill(Color.appFlaeche.opacity(0.5)).frame(width: 110, height: 22)
        .position(x: g.size.width * 0.5, y: g.size.height * (0.62 - 0.2 * anleitungAbschnitt(p, von: 0.1, bis: 0.4)))
    Image(systemName: "xmark.circle.fill").font(.system(size: 34)).foregroundStyle(.red)
        .position(x: g.size.width * 0.5, y: g.size.height * 0.2).opacity(p > 0.4 ? 1 : 0)
}'''
ZAHL = lambda txt, sz=54: f'''Text("{txt}").font(.system(size: {sz}, weight: .bold, design: .rounded).monospacedDigit()).foregroundStyle(Color.accentText).scaleEffect(1 + 0.05 * sin(p * .pi * 2))'''
BALLWECHSEL = '''GeometryReader { g in
    let w = g.size.width, h = g.size.height
    let bx = w * (0.5 + 0.28 * sin(p * .pi * 2)), by = h * (0.5 - 0.3 * cos(p * .pi * 4))
    Capsule().fill(Color.appFlaeche.opacity(0.4)).frame(width: 70, height: 10).position(x: w * (0.5 - 0.2 * sin(p * .pi * 2 + 0.6)), y: h * 0.1)
    Capsule().fill(Color.appFlaeche).frame(width: 70, height: 12).position(x: w * (0.5 + 0.26 * sin(p * .pi * 2 + 0.3)), y: h * 0.9)
    Circle().fill(Color(.systemBackground)).shadow(radius: 2, y: 1).frame(width: 16, height: 16).position(x: bx, y: by)
}'''
BALL_KANTE = '''GeometryReader { g in
    let w = g.size.width, h = g.size.height
    let t = anleitungAbschnitt(p, von: 0.1, bis: 0.9)
    Capsule().fill(Color.appFlaeche).frame(width: 90, height: 12).position(x: w * 0.4, y: h * 0.85)
    Circle().fill(Color(.systemBackground)).shadow(radius: 2, y: 1).frame(width: 16, height: 16)
        .position(x: w * (0.46 + 0.4 * max(0, t - 0.5) * 2), y: t < 0.5 ? h * (0.2 + 0.6 * t * 2) : h * (0.8 - 0.6 * (t - 0.5) * 2))
}'''
LAEUFER = '''GeometryReader { g in
    let w = g.size.width, h = g.size.height
    let boden = h * 0.75
    let sprung = anleitungAbschnitt(p, von: 0.3, bis: 0.5) * (1 - anleitungAbschnitt(p, von: 0.5, bis: 0.7))
    Rectangle().fill(Color.appFlaeche.opacity(0.3)).frame(width: w, height: 4).position(x: w / 2, y: boden + 12)
    RoundedRectangle(cornerRadius: 4).fill(Color.appFlaeche).frame(width: 18, height: 34).position(x: w * (0.78 - 0.5 * p), y: boden - 6)
    Circle().fill(Color.appFlaeche).frame(width: 28, height: 28).position(x: w * 0.3, y: boden - 20 - 70 * sprung)
}'''
DUCKEN = '''GeometryReader { g in
    let w = g.size.width, h = g.size.height
    let boden = h * 0.75
    let duck = anleitungAbschnitt(p, von: 0.35, bis: 0.5) * (1 - anleitungAbschnitt(p, von: 0.6, bis: 0.75))
    Rectangle().fill(Color.appFlaeche.opacity(0.3)).frame(width: w, height: 4).position(x: w / 2, y: boden + 12)
    RoundedRectangle(cornerRadius: 4).fill(Color.appFlaeche).frame(width: 90, height: 14).position(x: w * (0.85 - 0.6 * p), y: boden - 34)
    Capsule().fill(Color.appFlaeche).frame(width: 28, height: 52 - 22 * duck).position(x: w * 0.3, y: boden - (52 - 22 * duck) / 2 + 10)
}'''
MAUER = '''GeometryReader { g in
    let w = g.size.width, h = g.size.height
    let bx = w * (0.5 + 0.2 * sin(p * .pi * 2)), by = h * (0.62 - 0.4 * abs(sin(p * .pi * 2)))
    VStack(spacing: 4) { ForEach(0..<3, id: \\.self) { r in HStack(spacing: 4) { ForEach(0..<6, id: \\.self) { c in
        RoundedRectangle(cornerRadius: 4).fill(Color.appFlaeche.opacity(r == 2 && c == 2 && p > 0.25 ? 0.05 : 0.35 + Double(r) * 0.2)).frame(width: 40, height: 16) } } } }
        .position(x: w / 2, y: h * 0.2)
    Capsule().fill(Color.appFlaeche).frame(width: 80, height: 12).position(x: w * (0.5 + 0.2 * sin(p * .pi * 2)), y: h * 0.88)
    Circle().fill(Color(.systemBackground)).shadow(radius: 2, y: 1).frame(width: 14, height: 14).position(x: bx, y: by)
}'''
MAUER_GABEN = '''HStack(spacing: 18) {
    ForEach(Array(["arrow.left.and.right", "circle.grid.3x3.fill", "heart.fill"].enumerated()), id: \\.offset) { i, name in
        let t = anleitungAbschnitt(p, von: 0.1 + Double(i) * 0.1, bis: 0.8)
        Image(systemName: name).font(.system(size: 28)).foregroundStyle(.white)
            .frame(width: 56, height: 56).background(Color.appFlaeche, in: .circle).offset(y: CGFloat(t) * 50 - 25)
    }
}'''
STEIN = '''GeometryReader { g in
    let w = g.size.width, h = g.size.height
    let z: CGFloat = 26
    let fall = anleitungAbschnitt(p, von: 0.1, bis: 0.6)
    ZStack(alignment: .topLeading) {
        Color.clear
        ForEach(0..<5, id: \\.self) { c in RoundedRectangle(cornerRadius: 5).fill(Color.appFlaeche.opacity(p > 0.7 ? 0 : 0.6)).frame(width: z, height: z).offset(x: CGFloat(c) * (z + 2), y: 5 * (z + 2)) }
        ForEach(0..<5, id: \\.self) { c in RoundedRectangle(cornerRadius: 5).fill(Color.appFlaeche.opacity(c == 2 && p < 0.6 ? 0 : 0.35)).frame(width: z, height: z).offset(x: CGFloat(c) * (z + 2), y: 6 * (z + 2)) }
        ForEach(0..<2, id: \\.self) { k in RoundedRectangle(cornerRadius: 5).fill(Color.appFlaeche).frame(width: z, height: z).offset(x: 2 * (z + 2), y: (CGFloat(fall) * 5 + CGFloat(k) * 0 - 5) * (z + 2) + (z + 2) * CGFloat(k) + 0) }
    }
    .frame(width: 5 * (z + 2), height: 7 * (z + 2)).position(x: w / 2, y: h / 2)
}'''
STEIN_DREHEN = '''HStack(spacing: 28) {
    Image(systemName: "arrow.left.and.right").font(.system(size: 34)).foregroundStyle(Color.appFlaeche).offset(x: CGFloat(sin(p * .pi * 2)) * 8)
    Image(systemName: "arrow.clockwise").font(.system(size: 34)).foregroundStyle(Color.appFlaeche).rotationEffect(.degrees(p * 360))
    Image(systemName: "arrow.down.to.line").font(.system(size: 34)).foregroundStyle(Color.appFlaeche).offset(y: CGFloat(abs(sin(p * .pi * 2))) * 8)
}'''
WOLKE = '''GeometryReader { g in
    let w = g.size.width, h = g.size.height
    let hoch = 0.5 - 0.5 * cos(p * .pi * 2)
    ForEach(0..<3, id: \\.self) { i in
        Capsule().fill(i == 1 ? Color.blue.opacity(0.6) : (i == 2 ? Color.gray.opacity(0.5) : Color(.systemBackground))).shadow(radius: 2, y: 1)
            .frame(width: 70, height: 16).position(x: w * [0.3, 0.65, 0.45][i], y: h * [0.85, 0.55, 0.25][i])
    }
    Circle().fill(Color.appFlaeche).frame(width: 26, height: 26).position(x: w * 0.4, y: h * (0.78 - 0.3 * hoch))
}'''

# ---- Spiele
G["Hanoi"] = dict(mod="Hanoi", farbe="blau", steps=[
 cust("line.3.horizontal.decrease", S("Scheibe versetzen","Move a disc","Mover un disco","Déplacer un disque"), S("Tippe erst den Stab, von dem du nimmst, dann den Zielstab. Du darfst immer nur die oberste Scheibe nehmen.","Tap the peg you take from, then the target peg. You may only take the top disc.","Toca primero el palo del que coges y luego el de destino. Solo puedes coger el disco de arriba.","Touche d’abord le piquet de départ, puis celui d’arrivée. Tu ne peux prendre que le disque du dessus."), ".tippen(UnitPoint(x: 0.2, y: 0.5))", HANOI),
 cust("xmark.octagon", S("Nie groß auf klein","Never big on small","Nunca grande sobre pequeño","Jamais grand sur petit"), S("Eine größere Scheibe darf nie auf einer kleineren liegen.","A larger disc may never lie on a smaller one.","Un disco mayor nunca puede estar sobre uno menor.","Un grand disque ne doit jamais reposer sur un plus petit."), ".keine", HANOI_NEIN),
 cust("number", S("Wenige Züge","Few moves","Pocos movimientos","Peu de coups"), S("Mit n Scheiben schaffst du es in mindestens 2ⁿ − 1 Zügen.","With n discs you need at least 2ⁿ − 1 moves.","Con n discos lo logras como mínimo en 2ⁿ − 1 movimientos.","Avec n disques, il faut au moins 2ⁿ − 1 coups."), ".keine", ZAHL("2ⁿ − 1")),
])
G["Hoelzchen"] = dict(mod="Hoelzchen", farbe="braun", steps=[
 raster("hand.tap", S("Aus einer Reihe nehmen","Take from one row","Coger de una fila","Prendre dans une rangée"), S("Du nimmst aus genau einer Reihe beliebig viele Hölzchen, mindestens eines. Tippe auf ein Hölzchen: Es wird mit allen rechts davon markiert.","You take any number of sticks from exactly one row, at least one. Tap a stick: it is marked together with all sticks to its right.","Coges de una sola fila tantos palillos como quieras, al menos uno. Toca un palillo: se marca junto con todos los de su derecha.","Tu prends autant d’allumettes que tu veux dans une seule rangée, au moins une. Touche une allumette : elle est marquée avec toutes celles à sa droite."), ".tippen(.zelle(1, 2, zeilen: 3, spalten: 5))", ["*****","*****","*****"], ["*****","**   ","*****"]),
 bild("flag.checkered", S("Klassisch","Classic","Clásico","Classique"), S("Im Modus „Klassisch“ gewinnt, wer das letzte Hölzchen nimmt.","In “Classic” mode, whoever takes the last stick wins.","En el modo «Clásico» gana quien coja el último palillo.","En mode « Classique », celui qui prend la dernière allumette gagne."), "trophy.fill"),
 bild("exclamationmark.triangle", S("Pechvogel","Booby","Pichón","Malchanceux"), S("Im Modus „Pechvogel“ verliert, wer das letzte Hölzchen nehmen muss.","In “Booby” mode, whoever has to take the last stick loses.","En el modo «Pichón» pierde quien tenga que coger el último palillo.","En mode « Malchanceux », celui qui doit prendre la dernière allumette perd."), "exclamationmark.triangle.fill"),
])
G["Kakuro"] = dict(mod="Kakuro", farbe="blau", steps=[
 raster("sum", S("Summen bilden","Make the sums","Formar sumas","Former des sommes"), S("Die Zahl im Hinweisfeld ist die Summe der Ziffern daneben beziehungsweise darunter bis zum nächsten dunklen Feld.","The number in a clue cell is the sum of the digits next to it or below it up to the next dark cell.","El número de la casilla de pista es la suma de las cifras a su lado o debajo hasta la siguiente casilla oscura.","Le nombre de la case indice est la somme des chiffres à côté ou en dessous jusqu’à la prochaine case sombre."), ".tippen(.zelle(0, 1, zeilen: 2, spalten: 3))", ["7..","#.."], ["725","#.."]),
 raster("xmark.circle", S("Keine Ziffer doppelt","No digit twice","Ninguna cifra repetida","Aucun chiffre en double"), S("Innerhalb einer Summe darf keine Ziffer doppelt vorkommen. Doppelte oder zu große Summen werden rot markiert.","Within one sum no digit may appear twice. Duplicates or sums that are too large are marked red.","Dentro de una suma no puede repetirse ninguna cifra. Los duplicados o las sumas demasiado grandes se marcan en rojo.","Dans une somme, aucun chiffre ne peut apparaître deux fois. Les doublons ou les sommes trop grandes sont marqués en rouge."), ".keine", ["8..","#.."], ["8rr","#.."]),
])
G["Nonogramm"] = dict(mod="Nonogramm", farbe="blau", steps=[
 raster("number.square", S("Zahlen am Rand","Numbers at the edge","Números al borde","Chiffres au bord"), S("Die Zahlen am Rand sagen, wie lang die Blöcke gefüllter Felder in dieser Zeile oder Spalte sind – mit mindestens einem leeren Feld dazwischen.","The numbers at the edge tell you how long the blocks of filled squares are in that row or column – with at least one empty square between them.","Los números del borde indican la longitud de los bloques de casillas rellenas en esa fila o columna, con al menos una casilla vacía entre ellos.","Les chiffres au bord indiquent la longueur des blocs de cases remplies dans cette ligne ou colonne – avec au moins une case vide entre eux."), ".tippen(.zelle(0, 1, zeilen: 2, spalten: 4))", ["2...","...."], ["2.**","...."]),
 raster("hand.tap", S("Füllen und markieren","Fill and mark","Rellenar y marcar","Remplir et marquer"), S("Tippe ein Feld, um es zu füllen. Halte es gedrückt, um es als leer zu markieren.","Tap a square to fill it. Press and hold to mark it as empty.","Toca una casilla para rellenarla. Mantenla pulsada para marcarla como vacía.","Touche une case pour la remplir. Maintiens-la pour la marquer comme vide."), ".tippen(.zelle(0, 1, zeilen: 2, spalten: 3))", ["...","..."], ["*..","..."]),
])
G["Bruecken"] = dict(mod="Bruecken", farbe="blau", steps=[
 raster("link", S("Inseln verbinden","Connect the islands","Unir las islas","Relier les îles"), S("Tippe nacheinander zwei benachbarte Inseln an: einmal ergibt eine Brücke, zweimal eine doppelte, dreimal löscht sie.","Tap two neighbouring islands in a row: once makes a bridge, twice a double bridge, three times removes it.","Toca dos islas vecinas seguidas: una vez crea un puente, dos veces uno doble y tres veces lo borra.","Touche deux îles voisines à la suite : une fois pour un pont, deux fois pour un pont double, trois fois pour l’effacer."), ".tippen(.zelle(0, 0, zeilen: 1, spalten: 3))", ["1 2"], ["1~2"]),
 bild("number.circle", S("Die Zahl zählt","The number counts","El número cuenta","Le chiffre compte"), S("Die Zahl auf einer Insel sagt, wie viele Brücken von ihr ausgehen. Am Ende müssen alle Inseln zusammenhängen.","The number on an island says how many bridges leave it. In the end all islands must be connected.","El número de una isla indica cuántos puentes salen de ella. Al final todas las islas deben estar conectadas.","Le chiffre d’une île indique combien de ponts en partent. À la fin, toutes les îles doivent être reliées."), "point.3.connected.trianglepath.dotted"),
])
G["Farbcode"] = dict(mod="Farbcode", farbe="violett", steps=[
 raster("paintpalette", S("Tipp legen","Place a guess","Colocar una propuesta","Placer une proposition"), S("Der Computer denkt sich einen Code aus Farbpunkten aus. Lege mit den Farben unten einen Tipp und tippe auf „Prüfen“.","The computer thinks up a code of coloured dots. Place a guess with the colours below and tap “Check”.","El ordenador inventa un código de puntos de colores. Coloca una propuesta con los colores de abajo y toca «Comprobar».","L’ordinateur invente un code de points de couleur. Place une proposition avec les couleurs du bas et touche « Vérifier »."), ".tippen(.zelle(0, 1, zeilen: 1, spalten: 4))", ["....","rgby"][0:1], ["rgby"], zelle=50),
 raster("circle.lefthalf.filled", S("Dunkel und hell","Dark and light","Oscuro y claro","Foncé et clair"), S("Ein dunkler Punkt heißt: richtige Farbe an der richtigen Stelle. Ein heller Punkt: richtige Farbe, aber an der falschen Stelle.","A dark dot means: right colour in the right place. A light dot: right colour, wrong place.","Un punto oscuro significa: color correcto en el sitio correcto. Un punto claro: color correcto, pero en el sitio equivocado.","Un point foncé signifie : bonne couleur au bon endroit. Un point clair : bonne couleur, mais au mauvais endroit."), ".keine", ["rgby","  *~"][1:2] and ["rgby","...."], ["rgby","**~~"], zelle=44),
])
G["Farbflut"] = dict(mod="Farbflut", farbe="tuerkis", steps=[
 raster("drop.fill", S("Farbe wählen","Pick a colour","Elegir color","Choisir une couleur"), S("Die Flut beginnt oben links. Tippe unten eine Farbe an: Die ganze Flut nimmt sie an und schluckt angrenzende Felder in dieser Farbe.","The flood starts at the top left. Tap a colour below: the whole flood takes it and swallows adjacent squares of that colour.","La inundación empieza arriba a la izquierda. Toca un color abajo: toda la inundación lo adopta y absorbe las casillas contiguas de ese color.","L’inondation commence en haut à gauche. Touche une couleur en bas : toute la zone la prend et avale les cases voisines de cette couleur."), ".tippen(UnitPoint(x: 0.5, y: 0.9))", ["rbb","bgg","rgr"], ["bbb","bgg","rgr"]),
 bild("checkmark.seal", S("Eine Farbe, wenige Züge","One colour, few moves","Un color, pocos movimientos","Une couleur, peu de coups"), S("Färbe das ganze Feld in einer Farbe, bevor deine Züge aufgebraucht sind. Jedes Feld ist garantiert lösbar.","Colour the whole board in one colour before your moves run out. Every board is guaranteed solvable.","Colorea todo el tablero de un solo color antes de que se acaben tus movimientos. Cada tablero tiene solución garantizada.","Colorie tout le plateau d’une seule couleur avant la fin de tes coups. Chaque plateau est garanti résoluble."), "checkmark.seal.fill"),
])
G["Irrgang"] = dict(mod="Irrgang", farbe="schiefer", steps=[
 raster("arrow.right", S("Wischen und laufen","Swipe and run","Deslizar y correr","Glisser et courir"), S("Wische in eine Richtung: Dein Läufer geht geradeaus und hält erst vor einer Wand, an einer Abzweigung oder am Ausgang an.","Swipe in a direction: your runner goes straight and only stops at a wall, a junction or the exit.","Desliza en una dirección: tu corredor avanza recto y solo se detiene ante una pared, una bifurcación o la salida.","Glisse dans une direction : ton coureur va tout droit et ne s’arrête qu’à un mur, une bifurcation ou la sortie."), ".wischen(von: UnitPoint(x: 0.3, y: 0.5), nach: UnitPoint(x: 0.7, y: 0.5))", ["*..#","#.##","#..."][0:1] and ["*..~"], [".. *"][0:0] or [".. *".replace(" ", ".")] and ["...*"]),
 bild("sparkles", S("Funken sammeln","Collect sparks","Recoger chispas","Ramasser des étincelles"), S("Funken liegen in Sackgassen und bringen 50 Punkte extra. Je kürzer dein Weg, desto mehr Bonus.","Sparks lie in dead ends and give 50 extra points. The shorter your route, the bigger the bonus.","Las chispas están en callejones sin salida y dan 50 puntos extra. Cuanto más corto tu camino, mayor la bonificación.","Les étincelles se trouvent dans les impasses et rapportent 50 points de plus. Plus ton chemin est court, plus le bonus est grand."), "sparkles"),
])
G["Lagerplatz"] = dict(mod="Lagerplatz", farbe="braun", steps=[
 raster("shippingbox", S("Kisten schieben","Push the crates","Empujar cajas","Pousser les caisses"), S("Ziehe den Finger über das Feld, um dich zu bewegen. Läufst du gegen eine Kiste, schiebst du sie ein Feld weiter.","Drag your finger across the board to move. Walk into a crate and you push it one square further.","Arrastra el dedo por el tablero para moverte. Si chocas con una caja, la empujas una casilla.","Fais glisser le doigt sur le plateau pour te déplacer. En marchant contre une caisse, tu la pousses d’une case."), ".ziehen(von: UnitPoint(x: 0.3, y: 0.5), nach: UnitPoint(x: 0.55, y: 0.5))", ["Mo~"], ["  Mo"][0:0] or ["~oM"][0:0] or [".Mo"]) if False else raster("shippingbox", S("Kisten schieben","Push the crates","Empujar cajas","Pousser les caisses"), S("Ziehe den Finger über das Feld, um dich zu bewegen. Läufst du gegen eine Kiste, schiebst du sie ein Feld weiter.","Drag your finger across the board to move. Walk into a crate and you push it one square further.","Arrastra el dedo por el tablero para moverte. Si chocas con una caja, la empujas una casilla.","Fais glisser le doigt sur le plateau pour te déplacer. En marchant contre une caisse, tu la pousses d’une case."), ".ziehen(von: UnitPoint(x: 0.3, y: 0.5), nach: UnitPoint(x: 0.55, y: 0.5))", ["*B~"], [".*B"]),
 bild("exclamationmark.triangle", S("Nur schieben, nicht ziehen","Push only, never pull","Solo empujar, nunca tirar","Seulement pousser, jamais tirer"), S("Kisten kannst du nicht ziehen und nur einzeln schieben. Steckt eine Kiste fest, hilft der Neustart.","You cannot pull crates and can only push one at a time. If a crate gets stuck, restart.","No puedes tirar de las cajas y solo puedes empujar de una en una. Si una caja se atasca, reinicia.","Tu ne peux pas tirer les caisses et seulement en pousser une à la fois. Si une caisse est coincée, recommence."), "arrow.uturn.backward.circle"),
])
G["LichterAus"] = dict(mod="LichterAus", farbe="blau", steps=[
 raster("lightbulb", S("Ein Tipp, fünf Felder","One tap, five squares","Un toque, cinco casillas","Un toucher, cinq cases"), S("Ein Tipp schaltet das Feld und seine vier Nachbarn um: an wird aus, aus wird an.","A tap switches the square and its four neighbours: on becomes off, off becomes on.","Un toque cambia la casilla y sus cuatro vecinas: encendida pasa a apagada y al revés.","Un toucher bascule la case et ses quatre voisines : allumé devient éteint et inversement."), ".tippen(.zelle(1, 1, zeilen: 3, spalten: 3))", ["*.*",".*.","*.*"], [".*.","***",".*."]),
 bild("lightbulb.slash", S("Alle Lichter aus","All lights off","Todas las luces apagadas","Toutes les lumières éteintes"), S("Bring alle Lichter zum Erlöschen, mit möglichst wenigen Tipps.","Turn all the lights off with as few taps as possible.","Apaga todas las luces con el menor número posible de toques.","Éteins toutes les lumières avec le moins de touchers possible."), "lightbulb.slash.fill"),
])
G["MahjongPaare"] = dict(mod="MahjongPaare", farbe="blau", steps=[
 raster("square.on.square", S("Zwei gleiche Steine","Two matching tiles","Dos fichas iguales","Deux tuiles identiques"), S("Entferne alle Steine, indem du zwei gleiche freie Steine antippst.","Remove all tiles by tapping two matching free tiles.","Quita todas las fichas tocando dos fichas libres iguales.","Retire toutes les tuiles en touchant deux tuiles libres identiques."), ".tippen(.zelle(0, 0, zeilen: 2, spalten: 3))", ["AB.","CAB"], ["~B.","CAB"]),
 bild("lock.open", S("Frei oder nicht?","Free or not?","¿Libre o no?","Libre ou non ?"), S("Ein Stein ist frei, wenn kein anderer auf ihm liegt und er links oder rechts nichts berührt. Der Tipp zeigt ein mögliches Paar.","A tile is free when nothing lies on top of it and it touches nothing on its left or right. The hint shows a possible pair.","Una ficha está libre si no hay otra encima y no toca nada a izquierda o derecha. La pista muestra una pareja posible.","Une tuile est libre si rien n’est posé dessus et si elle ne touche rien à gauche ou à droite. L’indice montre une paire possible."), "lock.open.fill"),
])
G["Schiebepuzzle"] = dict(mod="Schiebepuzzle", farbe="blau", steps=[
 raster("square.grid.3x3", S("Kachel verschieben","Slide a tile","Mover una pieza","Faire glisser une tuile"), S("Tippe eine Kachel in der Reihe der Lücke, um sie (und alle dazwischen) zu verschieben.","Tap a tile in the row of the gap to slide it (and all tiles in between).","Toca una pieza de la fila del hueco para moverla (y todas las que hay entre medias).","Touche une tuile dans la rangée de la case vide pour la faire glisser (avec toutes celles entre les deux)."), ".tippen(.zelle(1, 1, zeilen: 2, spalten: 3))", ["123","45 "], ["123","4 5"]),
 raster("flag.checkered", S("Ordnung herstellen","Put in order","Ordenar","Remettre en ordre"), S("Schiebe, bis die Zahlen der Reihe nach stehen und die Lücke unten rechts ist. Weniger Züge sind besser.","Slide until the numbers are in order and the gap is at the bottom right. Fewer moves are better.","Desliza hasta que los números estén en orden y el hueco quede abajo a la derecha. Cuantos menos movimientos, mejor.","Fais glisser jusqu’à ce que les nombres soient dans l’ordre et que la case vide soit en bas à droite. Moins de coups, c’est mieux."), ".keine", ["123","4 5"], ["123","45 "]),
])
G["Steckspiel"] = dict(mod="Steckspiel", farbe="indigo", steps=[
 raster("arrow.up.forward", S("Über einen Stecker springen","Jump over a peg","Saltar sobre una clavija","Sauter par-dessus une cheville"), S("Du springst mit einem Stecker waagrecht oder senkrecht über einen Nachbarn in ein leeres Loch. Der übersprungene Stecker wird entfernt.","You jump a peg horizontally or vertically over a neighbour into an empty hole. The jumped peg is removed.","Saltas con una clavija en horizontal o vertical sobre una vecina hasta un agujero vacío. La clavija saltada se retira.","Tu sautes avec une cheville à l’horizontale ou à la verticale par-dessus une voisine vers un trou vide. La cheville sautée est retirée."), ".ziehen(von: UnitPoint(x: 0.34, y: 0.5), nach: UnitPoint(x: 0.66, y: 0.5))", ["**."], [" ", "..*"][1:2]),
 bild("1.circle", S("Einer bleibt übrig","One is left","Queda una","Il n’en reste qu’une"), S("Ziel: Am Ende soll nur ein einziger Stecker übrig sein. Gehen keine Sprünge mehr, ist das Spiel zu Ende.","Goal: only a single peg should be left at the end. When no jumps remain, the game is over.","Objetivo: al final debe quedar una sola clavija. Cuando ya no hay saltos, el juego termina.","But : à la fin, il ne doit rester qu’une seule cheville. Quand plus aucun saut n’est possible, la partie est terminée."), "1.circle.fill"),
])
G["Ungleichung"] = dict(mod="Ungleichung", farbe="schiefer", steps=[
 raster("lessthan", S("Zeichen lesen","Read the signs","Leer los signos","Lire les signes"), S("Die Spitze eines Zeichens zeigt zur kleineren Zahl: „<“ heißt, die linke (obere) Zahl ist kleiner als die rechte (untere).","The point of a sign faces the smaller number: “<” means the left (upper) number is smaller than the right (lower) one.","La punta del signo señala el número menor: «<» significa que el número de la izquierda (arriba) es menor que el de la derecha (abajo).","La pointe du signe désigne le plus petit nombre : « < » signifie que le nombre de gauche (du haut) est plus petit que celui de droite (du bas)."), ".tippen(.zelle(0, 2, zeilen: 1, spalten: 3))", ["1<."], ["1<3"]),
 bild("square.grid.3x3", S("Jede Zahl einmal","Each number once","Cada número una vez","Chaque nombre une fois"), S("Fülle das Quadrat mit den Zahlen von 1 bis zur Kantenlänge: in jeder Zeile und Spalte jede Zahl genau einmal.","Fill the square with the numbers from 1 up to its side length: every number exactly once in each row and column.","Rellena el cuadrado con los números del 1 hasta la longitud del lado: cada número exactamente una vez en cada fila y columna.","Remplis le carré avec les nombres de 1 à la longueur du côté : chaque nombre exactement une fois par ligne et par colonne."), "square.grid.3x3.fill"),
])
G["Zahlenfusion"] = dict(mod="Zahlenfusion", farbe="blau", steps=[
 raster("arrow.left", S("Wischen und verschmelzen","Swipe and merge","Deslizar y fusionar","Glisser et fusionner"), S("Wische in eine Richtung: Alle Kacheln rutschen dorthin, gleiche Zahlen verschmelzen zur Summe.","Swipe in a direction: all tiles slide that way and equal numbers merge into their sum.","Desliza en una dirección: todas las fichas se mueven hacia allí y los números iguales se fusionan en su suma.","Glisse dans une direction : toutes les tuiles vont de ce côté et les nombres identiques fusionnent en leur somme."), ".wischen(von: UnitPoint(x: 0.7, y: 0.5), nach: UnitPoint(x: 0.3, y: 0.5))", ["2 2 "[0:0] + "2.2.", ], ["4..."]),
 bild("2.square", S("Bis zur 2048","On to 2048","Hasta el 2048","Jusqu’à 2048"), S("Nach jedem Zug erscheint eine neue 2 oder 4. Erreiche die 2048 – oder so viele Punkte wie möglich.","After every move a new 2 or 4 appears. Reach 2048 – or score as many points as you can.","Tras cada movimiento aparece un 2 o un 4 nuevo. Llega al 2048 o consigue tantos puntos como puedas.","Après chaque coup, un nouveau 2 ou 4 apparaît. Atteins 2048 – ou marque autant de points que possible."), "square.fill"),
])
G["Ballwechsel"] = dict(mod="Ballwechsel", farbe="rot", steps=[
 cust("hand.draw", S("Schläger bewegen","Move the paddle","Mover la pala","Bouger la raquette"), S("Ziehe den Finger, um den Schläger zu bewegen – er folgt dir, so schnell er kann. Schlage den Ball zurück und lass ihn beim Gegner durch.","Drag your finger to move the paddle – it follows you as fast as it can. Hit the ball back and get it past your opponent.","Arrastra el dedo para mover la pala; te sigue todo lo rápido que puede. Devuelve la pelota y haz que pase al rival.","Fais glisser le doigt pour bouger la raquette – elle te suit aussi vite qu’elle peut. Renvoie la balle et fais-la passer chez l’adversaire."), ".wischen(von: UnitPoint(x: 0.35, y: 0.9), nach: UnitPoint(x: 0.65, y: 0.9))", BALLWECHSEL),
 cust("arrow.up.right", S("Kante macht schräg","The edge makes it slant","El borde la desvía","Le bord la fait dévier"), S("Trifft der Ball die Kante des Schlägers, fliegt er schräger und schneller weg. Jeder Schlag macht ihn schneller.","If the ball hits the edge of the paddle it flies off at a steeper angle and faster. Every hit makes it faster.","Si la pelota toca el borde de la pala, sale más inclinada y rápida. Cada golpe la acelera.","Si la balle touche le bord de la raquette, elle repart plus en biais et plus vite. Chaque coup l’accélère."), ".keine", BALL_KANTE),
 bild("7.circle", S("Sieben Punkte","Seven points","Siete puntos","Sept points"), S("Wer zuerst sieben Punkte hat, gewinnt. Zu zweit zieht der zweite Spieler im oberen Feld.","The first to seven points wins. With two players, the second one drags in the upper half.","Gana quien consiga primero siete puntos. Entre dos, el segundo jugador arrastra en la mitad de arriba.","Le premier à sept points gagne. À deux, le second joueur glisse dans la moitié du haut."), "7.circle.fill"),
])
G["Dauerlauf"] = dict(mod="Dauerlauf", farbe="orange", steps=[
 cust("arrow.up", S("Springen","Jump","Saltar","Sauter"), S("Dein Läufer rennt von allein und wird schneller. Tippe aufs Feld, um zu springen: über Hürden und über Löcher.","Your runner runs by itself and gets faster. Tap the screen to jump: over hurdles and over gaps.","Tu corredor corre solo y cada vez más rápido. Toca la pantalla para saltar: sobre vallas y huecos.","Ton coureur court tout seul et accélère. Touche l’écran pour sauter : par-dessus les haies et les trous."), ".tippen(UnitPoint(x: 0.5, y: 0.5))", LAEUFER),
 cust("arrow.down", S("Ducken","Duck","Agacharse","Se baisser"), S("Wische nach unten, um dich zu ducken, wenn ein Balken in der Luft hängt.","Swipe down to duck when a bar hangs in the air.","Desliza hacia abajo para agacharte cuando hay una barra en el aire.","Glisse vers le bas pour te baisser quand une barre est suspendue en l’air."), ".wischen(von: UnitPoint(x: 0.5, y: 0.35), nach: UnitPoint(x: 0.5, y: 0.65))", DUCKEN),
 bild("circle.fill", S("Perlen sammeln","Collect pearls","Recoger perlas","Ramasser des perles"), S("Sammle die Perlen auf dem Weg, jede bringt zehn Punkte extra. Stößt du an oder fällst du in ein Loch, ist der Lauf vorbei.","Collect the pearls on the way, each is worth ten extra points. If you hit something or fall into a gap, the run is over.","Recoge las perlas del camino, cada una da diez puntos extra. Si chocas o caes en un hueco, la carrera termina.","Ramasse les perles sur le chemin, chacune rapporte dix points de plus. Si tu heurtes un obstacle ou tombes dans un trou, la course est finie."), "circle.hexagongrid.fill"),
])
G["Mauerbrecher"] = dict(mod="Mauerbrecher", farbe="rot", steps=[
 cust("hand.draw", S("Schläger lenken","Steer the paddle","Dirigir la pala","Diriger la raquette"), S("Lenke den Schläger mit dem Finger und lass den Ball nicht fallen. Tippe, um den Ball abzuschießen. Jeder Treffer bricht einen Stein.","Steer the paddle with your finger and don’t let the ball drop. Tap to launch the ball. Every hit breaks a brick.","Dirige la pala con el dedo y no dejes caer la pelota. Toca para lanzarla. Cada golpe rompe un ladrillo.","Dirige la raquette avec le doigt et ne laisse pas tomber la balle. Touche pour la lancer. Chaque coup casse une brique."), ".wischen(von: UnitPoint(x: 0.35, y: 0.88), nach: UnitPoint(x: 0.65, y: 0.88))", MAUER),
 cust("gift", S("Gaben fangen","Catch the gifts","Atrapar regalos","Attraper les bonus"), S("Aus Steinen fallen manchmal Gaben: breiter Schläger, drei Bälle oder ein Extraleben. Fange sie mit dem Schläger.","Bricks sometimes drop gifts: a wider paddle, three balls or an extra life. Catch them with the paddle.","De los ladrillos caen a veces regalos: pala más ancha, tres pelotas o una vida extra. Atrápalos con la pala.","Les briques lâchent parfois des bonus : raquette plus large, trois balles ou une vie en plus. Attrape-les avec la raquette."), ".keine", MAUER_GABEN),
 bild("arrow.down.to.line", S("Die Mauer rückt vor","The wall advances","El muro avanza","Le mur avance"), S("Die Mauer rückt langsam nach unten; erreicht sie den Schläger, ist das Spiel aus. Du hast drei Leben.","The wall slowly moves down; if it reaches the paddle the game is over. You have three lives.","El muro baja despacio; si llega a la pala, el juego termina. Tienes tres vidas.","Le mur descend lentement ; s’il atteint la raquette, la partie est finie. Tu as trois vies."), "arrow.down.to.line"),
])
G["Steinfall"] = dict(mod="Steinfall", farbe="violett", steps=[
 cust("square.grid.3x3.fill", S("Reihe auflösen","Clear a row","Eliminar una fila","Effacer une ligne"), S("Fünferteile fallen in ein Feld. Ist eine Reihe lückenlos gefüllt, löst sie sich auf und bringt Punkte – mehrere Reihen zugleich bringen deutlich mehr.","Five-square pieces fall into a field. A completely filled row disappears and scores points – several rows at once score much more.","Piezas de cinco cuadros caen en un campo. Una fila completamente llena desaparece y da puntos; varias filas a la vez dan muchos más.","Des pièces de cinq carrés tombent dans un champ. Une ligne entièrement remplie disparaît et rapporte des points – plusieurs lignes à la fois en rapportent bien plus."), ".keine", STEIN),
 cust("arrow.left.and.right", S("Schieben und drehen","Move and rotate","Mover y girar","Déplacer et tourner"), S("Verschiebe die Teile, drehe sie und lass sie landen. Ein gelandetes Teil lässt sich noch kurz verschieben.","Move the pieces, rotate them and let them land. A landed piece can still be moved briefly.","Mueve las piezas, gíralas y déjalas caer. Una pieza ya aterrizada aún se puede mover un momento.","Déplace les pièces, tourne-les et laisse-les tomber. Une pièce posée peut encore être déplacée un court instant."), ".keine", STEIN_DREHEN),
])
G["Wolkenhuepfer"] = dict(mod="Wolkenhuepfer", farbe="tuerkis", steps=[
 cust("cloud", S("Von Wolke zu Wolke","From cloud to cloud","De nube en nube","De nuage en nuage"), S("Dein Hüpfer springt von allein. Ziehe den Finger nach links und rechts, um ihn zu lenken – am Rand kommst du auf der anderen Seite wieder heraus.","Your hopper jumps by itself. Drag your finger left and right to steer – at the edge you come out on the other side.","Tu saltarín salta solo. Arrastra el dedo a izquierda y derecha para dirigirlo; por un borde sales por el otro.","Ton sauteur saute tout seul. Fais glisser le doigt à gauche et à droite pour le diriger – par un bord, tu ressors de l’autre côté."), ".wischen(von: UnitPoint(x: 0.35, y: 0.6), nach: UnitPoint(x: 0.65, y: 0.6))", WOLKE),
 bild("cloud.fill", S("Weiß, blau, grau","White, blue, grey","Blanca, azul, gris","Blanc, bleu, gris"), S("Weiße Wolken tragen immer, blaue wandern hin und her, graue brechen nach dem Sprung weg. Die gelbe Feder schleudert dich besonders hoch.","White clouds always hold, blue ones drift back and forth, grey ones break away after the jump. The yellow feather launches you extra high.","Las nubes blancas siempre sostienen, las azules van de un lado a otro, las grises se rompen tras el salto. La pluma amarilla te lanza muy alto.","Les nuages blancs portent toujours, les bleus vont et viennent, les gris se brisent après le saut. La plume jaune te propulse très haut."), "cloud.fill"),
])
G["StadtLandFluss"] = dict(mod="StadtLandFluss", farbe="pink", steps=[
 raster("textformat.abc", S("Ein Buchstabe pro Runde","One letter per round","Una letra por ronda","Une lettre par manche"), S("Pro Runde wird ein Buchstabe gezogen. Trage zu jeder Kategorie ein Wort ein, das mit diesem Buchstaben beginnt.","One letter is drawn each round. Enter a word for each category that starts with that letter.","En cada ronda se saca una letra. Escribe una palabra por categoría que empiece con esa letra.","À chaque manche, une lettre est tirée. Écris pour chaque catégorie un mot qui commence par cette lettre."), ".tippen(.zelle(0, 1, zeilen: 2, spalten: 3))", ["B..","..."], ["BER","..."]),
 bild("star.circle", S("Punkte","Points","Puntos","Points"), S("Je Kategorie: 10 Punkte, 5 bei gleicher Antwort mehrerer Spieler, 20 wenn nur du eine gültige Antwort hast. Fünf Runden, die meisten Punkte gewinnen.","Per category: 10 points, 5 if several players gave the same answer, 20 if only you have a valid answer. Five rounds, most points wins.","Por categoría: 10 puntos, 5 si varios jugadores dan la misma respuesta, 20 si solo tú tienes una respuesta válida. Cinco rondas; gana quien tenga más puntos.","Par catégorie : 10 points, 5 si plusieurs joueurs ont la même réponse, 20 si tu es seul à avoir une réponse valable. Cinq manches, le plus de points gagne."), "star.circle.fill"),
])

def q(s): return json.dumps(s, ensure_ascii=False)
def swift_steps(steps):
    out = []
    for st in steps:
        head = f'symbol: {q(st["sym"])}, titel: {q(st["t"])}, text: {q(st["x"])}'
        if st["k"] == "r":
            out.append(f'        .raster({head}, geste: {st["geste"]}, {json.dumps(st["v"], ensure_ascii=False)}, {json.dumps(st["n"], ensure_ascii=False) if st["n"] else "nil"}, zelle: {st["zelle"]}),')
        elif st["k"] == "b":
            out.append(f'        .bild({head}, bild: {q(st["b"])}, geste: {st["geste"]}),')
        else:
            body = "\n".join("            " + l for l in st["body"].split("\n"))
            out.append(f'        AnleitungSchritt({head}, geste: {st["geste"]}) {{ p, _ in\n{body}\n        }},')
    return "\n".join(out)

for g, d in G.items():
    mod = d["mod"]
    code = f'''#if canImport(UIKit)
import SwiftUI
import KlarGlas

/// Anleitung zum Durchwischen (KlarGlas `AnleitungBlatt`); der Rahmen hängt die Regelseite als „Alle Regeln lesen“ an.
extension {mod}Modul {{
    static var anleitung: [AnleitungSchritt] {{ [
{swift_steps(d["steps"])}
    ] }}
}}
#endif
'''
    open(f"Pakete/Spiel{mod}/Sources/Spiel{mod}/Anleitung.swift", "w").write(code)
    # Modul-Datei: .mitAnleitung anhängen
    for root, _, files in os.walk(f"Pakete/Spiel{mod}/Sources"):
        for f in files:
            if not f.endswith(".swift"): continue
            pth = os.path.join(root, f); s = open(pth).read()
            if "AnyView(SpielRahmen(" in s and "mitAnleitung" not in s:
                s = s.replace("\n        })\n", "\n        }.mitAnleitung(Self.anleitung))\n", 1)
                open(pth, "w").write(s)

# Strings
p = "App/Ressourcen/Localizable.xcstrings"; d = json.load(open(p)); neu = 0
for k, (en, es, fr) in T.items():
    if k in d["strings"]: continue
    d["strings"][k] = {"localizations": {l: {"stringUnit": {"state": "translated", "value": v}} for l, v in zip(["de", "en", "es", "fr"], [k, en, es, fr])}}; neu += 1
open(p, "w").write(json.dumps(d, ensure_ascii=False, indent=2) + "\n")
print("Spiele:", len(G), "neue Strings:", neu)
