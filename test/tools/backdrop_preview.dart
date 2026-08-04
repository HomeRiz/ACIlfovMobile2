// Utilitar de dezvoltare: deseneaza toate fundalurile intr-un singur PNG, ca
// sa poata fi verificate vizual. Nu verifica nimic - doar produce imaginea.
//
// NU se numeste `*_test.dart`, ca sa nu incetineasca `flutter test`. Se ruleaza
// manual, cand modifici desenele din page_backdrop.dart:
//
//   BACKDROP_OUT=/tmp/fundaluri.png flutter test test/tools/backdrop_preview.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:acilfov_mobile/core/widgets/page_backdrop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('deseneaza toate fundalurile', (tester) async {
    const cell = Size(300, 400);
    const columns = 5;
    final rows = (BackdropMotif.values.length / columns).ceil();
    tester.view.physicalSize =
        Size(cell.width * columns, cell.height * rows);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF335C80)),
        ),
        home: RepaintBoundary(
          key: const ValueKey('shot'),
          child: Scaffold(
            body: GridView.count(
              crossAxisCount: columns,
              childAspectRatio: cell.width / cell.height,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final motif in BackdropMotif.values)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0x22000000)),
                    ),
                    child: PageBackdrop(
                      motif: motif,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Text(motif.name),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('shot')),
    );
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    final path = Platform.environment['BACKDROP_OUT'] ??
        '${Directory.systemTemp.path}/backdrops.png';
    File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
