// ===========================================================================
//  page_backdrop.dart  =  FUNDALURI DECORATIVE (estompate) PENTRU PAGINI
// ---------------------------------------------------------------------------
//  Fiecare pagina din meniu primeste un desen simbolic, desenat cu linii, la
//  o transparenta foarte mare ("faded"), asezat IN SPATELE continutului.
//  Desenele sunt vectoriale (CustomPainter), deci:
//    - nu adauga imagini in aplicatie (nu creste marimea instalarii);
//    - arata clar pe orice ecran, la orice rezolutie;
//    - se coloreaza singure in tema deschisa / intunecata.
//
//  Textele care apar in desene (facturi, calendar) sunt FICTIVE: sunt doar
//  bare si linii, fara cuvinte reale, ca sa nu para date adevarate.
//
//  Ca sa adaugi un fundal nou: (1) o valoare in BackdropMotif, (2) un caz in
//  _BackdropPainter._draw, (3) il legi de pagina in home_shell.dart.
// ===========================================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Desenul folosit pe fundalul unei pagini.
enum BackdropMotif {
  /// Acasa: o casa cu initialele AIF pe fronton.
  house,

  /// Istoric facturi: o factura fictiva (fara text real).
  invoice,

  /// Transmitere index: un apometru.
  waterMeter,

  /// Istoric plati: un calendar si un teanc de facturi langa el.
  calendarInvoices,

  /// Istoric consum: un grafic liniar.
  lineChart,

  /// Grafic: coloane cu o linie de tendinta peste ele.
  barChart,

  /// Actualizare date cont: o persoana cu o hartie in mana.
  personDocument,

  /// Configurari: roti dintate.
  gears,

  /// Schimbare parola: campul de parola cu stelute.
  passwordStars,

  /// Contact: un operator de call-center cu casti.
  headsetAgent,
}

/// Aseaza desenul decorativ in spatele continutului paginii.
///
/// Daca [motif] este `null`, pagina ramane clasica (fundal simplu) - asa cum
/// e cerut pentru "Informatii cont" si "Stergere cont".
class PageBackdrop extends StatelessWidget {
  final BackdropMotif? motif;
  final Widget child;

  const PageBackdrop({super.key, required this.motif, required this.child});

  @override
  Widget build(BuildContext context) {
    final motif = this.motif;
    if (motif == null) return child;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Foarte estompat: se vede, dar nu concureaza cu textul de deasupra.
    final color = (isDark ? Colors.white : theme.colorScheme.primary)
        .withValues(alpha: isDark ? 0.10 : 0.09);

    return Stack(
      children: [
        // Desenul: pe tot ecranul, nu prinde atingerile (IgnorePointer).
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _BackdropPainter(motif: motif, color: color),
              ),
            ),
          ),
        ),
        // Continutul real al paginii.
        Positioned.fill(child: child),
      ],
    );
  }
}

// ===========================================================================
//  PICTORUL
// ---------------------------------------------------------------------------
//  Toate desenele sunt gandite intr-un patrat "de proiectare" de 100x100.
//  Pictorul il scaleaza si il centreaza pe ecranul real, oricare ar fi el.
// ===========================================================================
class _BackdropPainter extends CustomPainter {
  final BackdropMotif motif;
  final Color color;

  const _BackdropPainter({required this.motif, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    // Cat de mare e desenul fata de latura mica a ecranului.
    final side = math.min(size.width, size.height) * 0.82;

    canvas.save();
    canvas.translate(
      (size.width - side) / 2,
      (size.height - side) / 2 + size.height * 0.03,
    );
    canvas.scale(side / 100);
    _draw(canvas);
    canvas.restore();
  }

  void _draw(Canvas canvas) {
    switch (motif) {
      case BackdropMotif.house:
        _house(canvas);
      case BackdropMotif.invoice:
        _invoice(canvas);
      case BackdropMotif.waterMeter:
        _waterMeter(canvas);
      case BackdropMotif.calendarInvoices:
        _calendarInvoices(canvas);
      case BackdropMotif.lineChart:
        _lineChart(canvas);
      case BackdropMotif.barChart:
        _barChart(canvas);
      case BackdropMotif.personDocument:
        _personDocument(canvas);
      case BackdropMotif.gears:
        _gears(canvas);
      case BackdropMotif.passwordStars:
        _passwordStars(canvas);
      case BackdropMotif.headsetAgent:
        _headsetAgent(canvas);
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter old) =>
      old.motif != motif || old.color != color;

  // --------------------------------------------------------------- pensule
  Paint _stroke([double width = 1.6]) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round
    ..color = color;

  Paint _fill([double factor = 0.45]) => Paint()
    ..style = PaintingStyle.fill
    ..color = color.withValues(alpha: color.a * factor);

  // O "linie de text" fictiva: o bara rotunjita, fara litere.
  void _textBar(Canvas canvas, double x, double y, double w,
      {double h = 2.6, double factor = 0.45}) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h),
        Radius.circular(h / 2),
      ),
      _fill(factor),
    );
  }

  void _rrect(Canvas canvas, Rect rect, double radius, Paint paint) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      paint,
    );
  }

  // Scrie un text scurt (folosit doar pentru initialele AIF de pe casa).
  void _label(Canvas canvas, String text, Offset center, double fontSize) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: fontSize * 0.12,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  // ============================================================ ACASA (casa)
  void _house(Canvas canvas) {
    final line = _stroke(2.0);

    // Acoperisul.
    final roof = Path()
      ..moveTo(6, 47)
      ..lineTo(50, 15)
      ..lineTo(94, 47);
    canvas.drawPath(roof, line);

    // Cosul de fum.
    canvas.drawPath(
      Path()
        ..moveTo(74, 32)
        ..lineTo(74, 21)
        ..lineTo(82, 21)
        ..lineTo(82, 38),
      line,
    );

    // Peretii + solul.
    canvas.drawRect(const Rect.fromLTRB(16, 47, 84, 90), line);
    canvas.drawLine(const Offset(8, 90), const Offset(92, 90), line);

    // Initialele companiei, pe fronton.
    _label(canvas, 'AIF', const Offset(50, 36), 11);

    // Ferestre cu cruce.
    for (final left in [26.0, 60.0]) {
      final window = Rect.fromLTWH(left, 55, 14, 14);
      canvas.drawRect(window, line);
      canvas.drawLine(
        Offset(left + 7, 55),
        Offset(left + 7, 69),
        _stroke(1.0),
      );
      canvas.drawLine(
        Offset(left, 62),
        Offset(left + 14, 62),
        _stroke(1.0),
      );
    }

    // Usa cu arcada si clanta.
    final door = Path()
      ..moveTo(44, 90)
      ..lineTo(44, 78)
      ..arcToPoint(const Offset(56, 78), radius: const Radius.circular(6))
      ..lineTo(56, 90);
    canvas.drawPath(door, line);
    canvas.drawCircle(const Offset(53, 84), 1.2, _fill(0.9));

    // Picaturi de apa pe pereti - marca activitatii companiei.
    _waterDrop(canvas, const Offset(33, 80), 0.9);
    _waterDrop(canvas, const Offset(67, 80), 0.9);
  }

  // Picatura de apa (varful in sus), cu centrul in [center].
  void _waterDrop(Canvas canvas, Offset center, double scale) {
    final s = scale == 0 ? 1.0 : scale;
    final path = Path()
      ..moveTo(center.dx, center.dy - 5 * s)
      ..cubicTo(
        center.dx + 4.5 * s,
        center.dy - 0.5 * s,
        center.dx + 3.6 * s,
        center.dy + 4.5 * s,
        center.dx,
        center.dy + 4.5 * s,
      )
      ..cubicTo(
        center.dx - 3.6 * s,
        center.dy + 4.5 * s,
        center.dx - 4.5 * s,
        center.dy - 0.5 * s,
        center.dx,
        center.dy - 5 * s,
      );
    canvas.drawPath(path, _stroke(1.2));
  }

  // ================================================= ISTORIC FACTURI (factura)
  void _invoice(Canvas canvas) {
    final line = _stroke(1.8);

    // Foaia, cu coltul din dreapta-sus indoit.
    final sheet = Path()
      ..moveTo(20, 8)
      ..lineTo(68, 8)
      ..lineTo(82, 22)
      ..lineTo(82, 92)
      ..lineTo(20, 92)
      ..close();
    canvas.drawPath(sheet, line);
    canvas.drawPath(
      Path()
        ..moveTo(68, 8)
        ..lineTo(68, 22)
        ..lineTo(82, 22),
      _stroke(1.2),
    );

    // Antet fictiv: un bloc gros + doua linii scurte.
    _textBar(canvas, 27, 17, 24, h: 5, factor: 0.55);
    _textBar(canvas, 27, 26, 32);
    _textBar(canvas, 27, 31, 22);

    // Tabelul de consum: cap de tabel + trei randuri, fara cifre reale.
    canvas.drawLine(const Offset(27, 41), const Offset(75, 41), _stroke(1.2));
    for (var i = 0; i < 3; i++) {
      final y = 47.0 + i * 8;
      _textBar(canvas, 27, y, 22, factor: 0.35);
      _textBar(canvas, 58, y, 17, factor: 0.35);
      canvas.drawLine(
        Offset(27, y + 5),
        Offset(75, y + 5),
        _stroke(0.7),
      );
    }

    // Caseta de total.
    const total = Rect.fromLTWH(50, 72, 25, 11);
    _rrect(canvas, total, 2, _stroke(1.2));
    _textBar(canvas, 54, 76, 17, h: 3.4, factor: 0.6);

    // Stampila rotunda (goala pe dinauntru - factura e fictiva).
    canvas.save();
    canvas.translate(35, 78);
    canvas.rotate(-0.22);
    canvas.drawCircle(Offset.zero, 9, _stroke(1.4));
    canvas.drawCircle(Offset.zero, 6, _stroke(0.8));
    canvas.restore();
  }

  // ================================================ TRANSMITERE INDEX (apometru)
  void _waterMeter(Canvas canvas) {
    const center = Offset(50, 50);
    final line = _stroke(2.0);

    // Tevile de racord, stanga si dreapta.
    for (final dir in [-1.0, 1.0]) {
      final x = center.dx + dir * 32;
      canvas.drawRect(
        Rect.fromLTRB(
          math.min(x, x + dir * 12),
          43,
          math.max(x, x + dir * 12),
          57,
        ),
        line,
      );
      canvas.drawRect(
        Rect.fromLTRB(
          math.min(x + dir * 12, x + dir * 16),
          39,
          math.max(x + dir * 12, x + dir * 16),
          61,
        ),
        _stroke(1.4),
      );
    }

    // Corpul contorului.
    canvas.drawCircle(center, 32, line);
    canvas.drawCircle(center, 26, _stroke(1.2));

    // Gradatiile cadranului.
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      final outer = Offset(
        center.dx + 30 * math.cos(a),
        center.dy + 30 * math.sin(a),
      );
      final inner = Offset(
        center.dx + 27 * math.cos(a),
        center.dy + 27 * math.sin(a),
      );
      canvas.drawLine(inner, outer, _stroke(1.0));
    }

    // Fereastra cu cifre (casute goale - index fictiv).
    const window = Rect.fromLTWH(31, 38, 38, 12);
    _rrect(canvas, window, 2, _stroke(1.4));
    for (var i = 1; i < 6; i++) {
      final x = window.left + window.width * i / 6;
      canvas.drawLine(
        Offset(x, window.top),
        Offset(x, window.bottom),
        _stroke(0.8),
      );
    }

    // Acul indicator si butucul.
    canvas.drawLine(const Offset(50, 64), const Offset(61, 58), _stroke(1.6));
    canvas.drawCircle(const Offset(50, 64), 2.4, _fill(0.9));

    // Picatura de apa, ca simbol al consumului.
    _waterDrop(canvas, const Offset(38, 62), 0.9);
  }

  // ========================================= ISTORIC PLATI (calendar + facturi)
  void _calendarInvoices(Canvas canvas) {
    final line = _stroke(1.8);

    // --- Teancul de facturi (in spatele calendarului, spre dreapta).
    for (var i = 2; i >= 0; i--) {
      final rect = Rect.fromLTWH(50 + i * 4.0, 18 + i * 6.0, 36, 46);
      _rrect(canvas, rect, 2, _stroke(i == 0 ? 1.8 : 1.2));
      if (i == 0) {
        _textBar(canvas, rect.left + 5, rect.top + 7, 16, h: 3.4, factor: 0.55);
        for (var l = 0; l < 3; l++) {
          _textBar(
            canvas,
            rect.left + 5,
            rect.top + 16.0 + l * 6,
            l == 2 ? 14 : 26,
            factor: 0.35,
          );
        }
        _textBar(canvas, rect.left + 18, rect.top + 37, 13, h: 4, factor: 0.6);
      }
    }

    // --- Calendarul (in fata, spre stanga).
    const body = Rect.fromLTWH(6, 26, 46, 60);
    _rrect(canvas, body, 4, line);
    // Banda de sus (luna).
    _rrect(
      canvas,
      const Rect.fromLTWH(6, 26, 46, 12),
      4,
      _fill(0.35),
    );
    canvas.drawLine(const Offset(6, 38), const Offset(52, 38), _stroke(1.2));
    // Inelele de prindere.
    for (final x in [17.0, 41.0]) {
      canvas.drawLine(Offset(x, 19), Offset(x, 31), _stroke(1.8));
    }
    // Zilele: puncte, cu ziua scadentei incercuita.
    for (var row = 0; row < 4; row++) {
      for (var col = 0; col < 5; col++) {
        final c = Offset(13 + col * 8.5, 47 + row * 9.5);
        canvas.drawCircle(c, 1.7, _fill(0.5));
        if (row == 2 && col == 3) {
          canvas.drawCircle(c, 4.2, _stroke(1.4));
        }
      }
    }
  }

  // ============================================ ISTORIC CONSUM (grafic liniar)
  void _lineChart(Canvas canvas) {
    _chartAxes(canvas);

    const values = [70.0, 58.0, 63.0, 44.0, 50.0, 30.0, 36.0];
    final points = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(18 + i * 11.7, values[i]),
    ];

    // Suprafata de sub linie, foarte estompata.
    final area = Path()..moveTo(points.first.dx, 84);
    for (final p in points) {
      area.lineTo(p.dx, p.dy);
    }
    area
      ..lineTo(points.last.dx, 84)
      ..close();
    canvas.drawPath(area, _fill(0.18));

    // Linia propriu-zisa.
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, _stroke(2.4));

    for (final p in points) {
      canvas.drawCircle(p, 2.2, _fill(0.9));
    }
  }

  // ============================================ GRAFIC (coloane + tendinta)
  void _barChart(Canvas canvas) {
    _chartAxes(canvas);

    const heights = [26.0, 40.0, 33.0, 52.0, 45.0, 60.0];
    final tops = <Offset>[];
    for (var i = 0; i < heights.length; i++) {
      final x = 19 + i * 12.5;
      final top = 84 - heights[i];
      tops.add(Offset(x + 4.5, top));
      _rrect(
        canvas,
        Rect.fromLTRB(x, top, x + 9, 84),
        1.5,
        _fill(0.28),
      );
      _rrect(
        canvas,
        Rect.fromLTRB(x, top, x + 9, 84),
        1.5,
        _stroke(1.2),
      );
    }

    // Linia de tendinta peste coloane.
    final trend = Path()..moveTo(tops.first.dx, tops.first.dy - 6);
    for (final p in tops.skip(1)) {
      trend.lineTo(p.dx, p.dy - 6);
    }
    canvas.drawPath(trend, _stroke(2.0));
    for (final p in tops) {
      canvas.drawCircle(Offset(p.dx, p.dy - 6), 2.0, _fill(0.9));
    }
  }

  // Axele + liniile ajutatoare, comune celor doua grafice.
  void _chartAxes(Canvas canvas) {
    canvas.drawLine(const Offset(12, 14), const Offset(12, 84), _stroke(1.8));
    canvas.drawLine(const Offset(12, 84), const Offset(94, 84), _stroke(1.8));
    for (var i = 1; i <= 4; i++) {
      final y = 84 - i * 16.0;
      canvas.drawLine(Offset(12, y), Offset(94, y), _stroke(0.6));
    }
  }

  // ================================== ACTUALIZARE DATE (omulet cu o hartie)
  void _personDocument(Canvas canvas) {
    final line = _stroke(2.0);

    // Capul.
    canvas.drawCircle(const Offset(30, 30), 12, line);

    // Umerii / bustul, ridicati pana sub barbie (fara "gat" gol).
    canvas.drawPath(
      Path()
        ..moveTo(10, 88)
        ..cubicTo(10, 30, 50, 30, 50, 88),
      line,
    );

    // Bratul care tine hartia.
    canvas.drawPath(
      Path()
        ..moveTo(48, 62)
        ..quadraticBezierTo(56, 64, 59, 69),
      _stroke(2.0),
    );
    canvas.drawCircle(const Offset(59, 69), 3.4, _stroke(1.4));

    // Hartia din mana (usor inclinata), cu randuri fictive si o semnatura.
    canvas.save();
    canvas.translate(76, 57);
    canvas.rotate(0.14);
    final page = Rect.fromCenter(center: Offset.zero, width: 32, height: 42);
    _rrect(canvas, page, 2, _stroke(1.6));
    for (var i = 0; i < 4; i++) {
      _textBar(
        canvas,
        page.left + 5,
        page.top + 8.0 + i * 6,
        i.isEven ? 22 : 16,
        factor: 0.35,
      );
    }
    // Linia de semnatura.
    canvas.drawPath(
      Path()
        ..moveTo(page.left + 5, page.bottom - 8)
        ..quadraticBezierTo(
          page.left + 12,
          page.bottom - 14,
          page.left + 17,
          page.bottom - 8,
        )
        ..quadraticBezierTo(
          page.left + 21,
          page.bottom - 2,
          page.left + 26,
          page.bottom - 9,
        ),
      _stroke(1.2),
    );
    canvas.restore();
  }

  // ================================================ CONFIGURARI (roti dintate)
  void _gears(Canvas canvas) {
    _gear(canvas, const Offset(38, 40), 22, 12);
    _gear(canvas, const Offset(72, 62), 15, 10);
    _gear(canvas, const Offset(30, 78), 11, 8);
  }

  void _gear(Canvas canvas, Offset center, double radius, int teeth) {
    final root = radius * 0.80;
    final path = Path();
    final pitch = 2 * math.pi / teeth;
    var first = true;
    for (var i = 0; i < teeth; i++) {
      final base = i * pitch;
      final steps = <(double, double)>[
        (base, root),
        (base + pitch * 0.12, radius),
        (base + pitch * 0.38, radius),
        (base + pitch * 0.50, root),
      ];
      for (final (angle, r) in steps) {
        final p = Offset(
          center.dx + r * math.cos(angle),
          center.dy + r * math.sin(angle),
        );
        if (first) {
          path.moveTo(p.dx, p.dy);
          first = false;
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
    }
    path.close();
    canvas.drawPath(path, _stroke(1.8));
    canvas.drawCircle(center, radius * 0.60, _stroke(1.2));
    canvas.drawCircle(center, radius * 0.26, _fill(0.35));
  }

  // ======================================= SCHIMBARE PAROLA (camp cu stelute)
  void _passwordStars(Canvas canvas) {
    // Eticheta de deasupra campului.
    _textBar(canvas, 14, 30, 26, h: 4, factor: 0.5);

    // Campul de parola.
    const field = Rect.fromLTWH(12, 40, 76, 22);
    _rrect(canvas, field, 6, _stroke(1.8));

    // Lacatul din stanga campului.
    _rrect(
      canvas,
      const Rect.fromLTRB(19, 50, 29, 58),
      1.6,
      _stroke(1.4),
    );
    canvas.drawArc(
      const Rect.fromLTRB(20.5, 44, 27.5, 52),
      math.pi,
      math.pi,
      false,
      _stroke(1.4),
    );

    // Stelutele care ascund parola.
    for (var i = 0; i < 6; i++) {
      _star(canvas, Offset(38 + i * 8.0, 51), 3.4, _stroke(1.1));
    }

    // Cateva stelute plutitoare, in jurul campului.
    _star(canvas, const Offset(22, 18), 6.5, _stroke(1.4));
    _star(canvas, const Offset(78, 22), 5.0, _stroke(1.2));
    _star(canvas, const Offset(66, 78), 7.0, _stroke(1.4));
    _star(canvas, const Offset(30, 82), 4.5, _stroke(1.2));
    _star(canvas, const Offset(50, 90), 3.2, _stroke(1.0));
  }

  // O steluta cu 5 colturi.
  void _star(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    const points = 5;
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : radius * 0.44;
      final a = -math.pi / 2 + i * math.pi / points;
      final p = Offset(
        center.dx + r * math.cos(a),
        center.dy + r * math.sin(a),
      );
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  // ================================================ CONTACT (agent cu casti)
  void _headsetAgent(Canvas canvas) {
    final line = _stroke(2.0);

    // Capul.
    canvas.drawCircle(const Offset(50, 36), 15, line);

    // Banda castilor, peste cap.
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(50, 36), radius: 21),
      math.pi,
      math.pi,
      false,
      _stroke(2.2),
    );

    // Castile de pe urechi.
    for (final left in [24.0, 66.0]) {
      _rrect(
        canvas,
        Rect.fromLTWH(left, 30, 10, 15),
        3.5,
        _stroke(1.8),
      );
    }

    // Bratul microfonului + capsula, pe langa obraz.
    canvas.drawPath(
      Path()
        ..moveTo(69, 45)
        ..quadraticBezierTo(68, 58, 57, 59),
      _stroke(1.6),
    );
    canvas.drawCircle(const Offset(56, 59), 2.6, _fill(0.9));

    // Umerii, ridicati pana sub barbie (fara "gat" gol).
    canvas.drawPath(
      Path()
        ..moveTo(18, 92)
        ..cubicTo(18, 40, 82, 40, 82, 92),
      line,
    );

    // Undele sonore, spre dreapta - semn ca se vorbeste.
    for (var i = 1; i <= 3; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: const Offset(84, 30), radius: 4.0 + i * 5),
        -math.pi / 4,
        math.pi / 2,
        false,
        _stroke(1.2),
      );
    }
  }
}
