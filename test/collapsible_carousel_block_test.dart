import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journaling_app_rewrite/ui/blocks/widgets/collapsible_carousel_block.dart';

void main() {
  testWidgets('unselected initial carousel does not lock the pager', (
    tester,
  ) async {
    final locks = <bool>[];

    await tester.pumpWidget(
      _Harness(
        child: _TestCarousel(
          selected: null,
          onLockChanged: (_, locked) => locks.add(locked),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('first'), findsOneWidget);
    expect(find.text('collapsed:null'), findsNothing);
    expect(locks, isEmpty);
  });

  testWidgets('selected collapsed carousel locks when opened', (tester) async {
    final locks = <bool>[];

    await tester.pumpWidget(
      _Harness(
        child: _TestCarousel(
          selected: 'first',
          onLockChanged: (_, locked) => locks.add(locked),
        ),
      ),
    );

    await tester.tap(find.text('collapsed:first'));
    await tester.pump();

    expect(locks, [true]);

    await tester.pump(const Duration(milliseconds: 1500));

    expect(locks, [true, false]);
  });
}

class _Harness extends StatelessWidget {
  const _Harness({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }
}

class _TestCarousel extends StatelessWidget {
  const _TestCarousel({required this.selected, required this.onLockChanged});

  final String? selected;
  final void Function(String blockId, bool locked) onLockChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 120,
      child: CollapsibleCarouselBlock<String>(
        blockId: 'test-carousel',
        options: const ['first', 'second'],
        selected: selected,
        itemBuilder: (_, option, _) => Text(option),
        collapsedBuilder: (_, selected) => Text('collapsed:$selected'),
        onSelected: (_) {},
        onInteractionLockChanged: onLockChanged,
      ),
    );
  }
}
