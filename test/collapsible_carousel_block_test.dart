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

  testWidgets('selected collapsed carousel locks when edit mode activates', (
    tester,
  ) async {
    // Under the new double-tap-to-edit gesture model the carousel's
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
