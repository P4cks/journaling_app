import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journaling_app_rewrite/ui/blocks/widgets/collapsible_carousel_block.dart';

void main() {
  testWidgets(
    'unselected carousel stays collapsed until edit mode is engaged',
    (tester) async {
      // Per the architecture rewrite, the carousel no longer
      // auto-expands when `selected == null`. The user must
      // double-tap the host tile to flip `editing: true`. Outside
      // edit mode the carousel just shows the collapsed placeholder.
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

      expect(find.text('first'), findsNothing);
      expect(find.text('collapsed:null'), findsOneWidget);
      expect(locks, isEmpty);
    },
  );

  testWidgets('selected collapsed carousel locks when edit mode activates', (
    tester,
  ) async {
    // Under the double-tap-to-edit gesture model the carousel's
    // internal tap-to-expand no longer fires — expansion is triggered
    // by the host setting `editing: true`. This test simulates the
    // grid flipping that flag.
    final locks = <bool>[];
    final key = GlobalKey<_StatefulHarnessState>();

    await tester.pumpWidget(
      _Harness(
        child: _StatefulHarness(
          key: key,
          builder: (editing) => _TestCarousel(
            selected: 'first',
            editing: editing,
            onLockChanged: (_, locked) => locks.add(locked),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(locks, isEmpty);

    key.currentState!.setEditing(true);
    await tester.pump();
    await tester.pump();

    expect(locks, [true]);

    await tester.pump(const Duration(milliseconds: 1500));

    expect(locks, [true, false]);
  });

  testWidgets('carousel fires onRequestExitEdit after 1.5s auto-collapse', (
    tester,
  ) async {
    // The auto-collapse timer should also signal the host so it can
    // drop `_editingBlockId` — in-place edit outline disappears in
    // lock-step with the carousel collapsing.
    var exitCount = 0;
    final key = GlobalKey<_StatefulHarnessState>();

    await tester.pumpWidget(
      _Harness(
        child: _StatefulHarness(
          key: key,
          builder: (editing) => SizedBox(
            width: 240,
            height: 120,
            child: CollapsibleCarouselBlock<String>(
              blockId: 'test-carousel',
              options: const ['first', 'second'],
              selected: 'first',
              editing: editing,
              itemBuilder: (_, option, _) => Text(option),
              collapsedBuilder: (_, selected) => Text('collapsed:$selected'),
              onSelected: (_) {},
              onRequestExitEdit: () => exitCount++,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(exitCount, 0);

    key.currentState!.setEditing(true);
    await tester.pump();
    await tester.pump();
    expect(exitCount, 0);

    // After the 1.5 s timer fires the host should be signalled.
    await tester.pump(const Duration(milliseconds: 1500));
    expect(exitCount, 1);
  });

  testWidgets('autoCollapse=false keeps the carousel open past 1.5s', (
    tester,
  ) async {
    // The expanded route passes autoCollapse=false so the picker
    // stays open until the user dismisses the route.
    final locks = <bool>[];
    var exitCount = 0;

    await tester.pumpWidget(
      _Harness(
        child: SizedBox(
          width: 240,
          height: 120,
          child: CollapsibleCarouselBlock<String>(
            blockId: 'test-carousel',
            options: const ['first', 'second'],
            selected: 'first',
            editing: true,
            autoCollapse: false,
            itemBuilder: (_, option, _) => Text(option),
            collapsedBuilder: (_, selected) => Text('collapsed:$selected'),
            onSelected: (_) {},
            onInteractionLockChanged: (_, locked) => locks.add(locked),
            onRequestExitEdit: () => exitCount++,
          ),
        ),
      ),
    );
    // Initial pump + post-frame for the lock acquisition.
    await tester.pump();
    await tester.pump();

    expect(locks, [true]);

    await tester.pump(const Duration(milliseconds: 1500));

    // No collapse, no exit signal — picker stays interactive.
    expect(locks, [true]);
    expect(exitCount, 0);
  });
}

class _StatefulHarness extends StatefulWidget {
  const _StatefulHarness({super.key, required this.builder});
  final Widget Function(bool editing) builder;

  @override
  State<_StatefulHarness> createState() => _StatefulHarnessState();
}

class _StatefulHarnessState extends State<_StatefulHarness> {
  bool _editing = false;
  void setEditing(bool value) {
    if (!mounted) return;
    setState(() => _editing = value);
  }

  @override
  Widget build(BuildContext context) => widget.builder(_editing);
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
  const _TestCarousel({
    required this.selected,
    required this.onLockChanged,
    this.editing = false,
  });

  final String? selected;
  final void Function(String blockId, bool locked) onLockChanged;
  final bool editing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 120,
      child: CollapsibleCarouselBlock<String>(
        blockId: 'test-carousel',
        options: const ['first', 'second'],
        selected: selected,
        editing: editing,
        itemBuilder: (_, option, _) => Text(option),
        collapsedBuilder: (_, selected) => Text('collapsed:$selected'),
        onSelected: (_) {},
        onInteractionLockChanged: onLockChanged,
      ),
    );
  }
}
