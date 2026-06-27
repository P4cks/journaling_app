import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_button.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dialog_actions.dart';

void main() {
  testWidgets(
    'AppDialogActions lays dialog buttons inline (single row) without overflow',
    (tester) async {
      // Narrow surface so the old OverflowBar would have stacked the pills.
      tester.view.physicalSize = const Size(360, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Unsaved changes'),
                      content: const Text('Save before leaving?'),
                      actions: [
                        AppDialogActions(
                          children: [
                            AppButton(
                              variant: AppButtonVariant.text,
                              onPressed: () {},
                              label: 'Cancel',
                            ),
                            AppButton(
                              variant: AppButtonVariant.text,
                              onPressed: () {},
                              label: 'Discard',
                            ),
                            AppButton(
                              variant: AppButtonVariant.primary,
                              onPressed: () {},
                              label: 'Save',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // No layout/render exception was thrown.
      expect(tester.takeException(), isNull);

      // All three labels visible.
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      // Inline == same vertical position, increasing horizontal position.
      final cancel = tester.getCenter(find.text('Cancel'));
      final discard = tester.getCenter(find.text('Discard'));
      final save = tester.getCenter(find.text('Save'));
      expect(cancel.dy, moreOrLessEquals(discard.dy, epsilon: 1.0));
      expect(discard.dy, moreOrLessEquals(save.dy, epsilon: 1.0));
      expect(cancel.dx, lessThan(discard.dx));
      expect(discard.dx, lessThan(save.dx));
    },
  );
}
