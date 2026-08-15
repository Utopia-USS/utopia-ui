// Table-driven tokenBindings expectations against the REAL utopia_ui
// sources (this repo checkout), per ledger/checkpoints/A3-spec.md. Expected
// sets are derived from research/wave2-utopia-ui-inventory.md's "Theme/token
// reads" lines; where the inventory and the source disagree, the source
// wins (see the divider case note below).
import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:utopia_design_tools/src/manifest/bindings.dart';

void main() {
  final repoRoot = Directory(p.normalize(p.join(Directory.current.path, '..', '..')));

  Set<String> bindingsOf(String repoRelativePath) {
    final absolute = p.join(repoRoot.path, repoRelativePath);
    final unit = parseFile(path: absolute, featureSet: FeatureSet.latestLanguageVersion()).unit;
    return extractTokenBindings(unit).toSet();
  }

  test('button: the gradient pair, the focus-ring tokens and the hover/press timings', () {
    // colors.surface backs the focus ring's opaque gap (the twin gets that gap
    // from outline-offset, which Flutter has no equivalent for), and
    // borders.thick sizes the ring itself.
    final bindings = bindingsOf('lib/src/widget/button/utopia_button.dart');
    expect(bindings, {
      'tokens.x',
      'colors.primary',
      'colors.accent',
      'colors.surface',
      'tokens.borders.thick',
      'tokens.durations.sm',
      'tokens.durations.xs',
      'theme.borderRadius',
      'textStyles.button',
    });
  });

  test(
    'divider: colors.divider, colors.text, colors.surface, theme.dividerThickness '
    '(matches the inventory exactly - no discrepancy found)',
    () {
      final bindings = bindingsOf('lib/src/widget/layout/utopia_divider.dart');
      expect(bindings, {'colors.divider', 'colors.text', 'colors.surface', 'theme.dividerThickness'});
    },
  );

  test('field-wrapper: the themeValues alias resolves every per-state decoration getter', () {
    // Whole-file scope also picks up utopiaFieldDecoration/utopiaPlaceholderStyle,
    // the two free functions sharing this file - hence colors.hint and
    // textStyles.caption (read only inside those) appear alongside
    // UtopiaFieldWrapper's own reads. The state colours themselves
    // (border/error/primary) are no longer read here: they moved into the
    // theme's field*Decoration getters, which this file reads by name.
    final bindings = bindingsOf('lib/src/widget/wrapper/utopia_field_wrapper.dart');
    expect(bindings, {
      'theme.fieldDecoration',
      'theme.fieldHoverDecoration',
      'theme.fieldFocusDecoration',
      'theme.fieldErrorDecoration',
      'theme.fieldErrorFocusDecoration',
      'theme.fieldReadOnlyDecoration',
      'theme.fieldContentPadding',
      'theme.fieldMinHeight',
      'tokens.durations.sm',
      'tokens.borders.hairline',
      'tokens.x',
      'tokens.fontWeights.regular',
      'colors.hint',
      'textStyles.text',
      'textStyles.caption',
    });
  });

  test('check-row: only the row-level reads remain after the box moved into UtopiaCheckbox', () {
    // The private _CheckBox is gone - UtopiaCheckRow composes UtopiaCheckbox
    // (readOnly: true), so the box's own reads (durations.xs, radius.xsAll,
    // colors.primary/disabled, borders.thin) now belong to the checkbox
    // component and must NOT leak into check-row's bindings.
    final bindings = bindingsOf('lib/src/widget/select/utopia_check_row.dart');
    expect(bindings, {
      'colors.hover',
      'tokens.spacing.md',
      'textStyles.text',
    });
  });

  test('dialog: three-hop theme.tokens.X.Y and theme.colors.X aliasing normalize correctly', () {
    // Whole-file scope also covers the `.form` constructor's closure body
    // (spacing.md gaps around the fade bar) and the private _TitleRow/
    // _DragHandle subwidgets in the same file.
    final bindings = bindingsOf('lib/src/widget/dialog/utopia_dialog.dart');
    expect(bindings, {
      'colors.surface',
      'textStyles.title',
      'textStyles.header',
      'colors.text',
      'theme.dialogDecoration',
      'theme.cardBorderDecoration',
      'tokens.spacing.xxxl',
      'tokens.radius.xl',
      'tokens.durations.sm',
      'tokens.spacing.xl',
      'tokens.spacing.lg',
      'tokens.spacing.md',
      'tokens.spacing.sm',
      'colors.border',
      'tokens.radius.fullAll',
      'tokens.x',
    });
  });

  test('overlay-anchor: theme local alias reused across two decoration reads plus a spacing read', () {
    final bindings = bindingsOf('lib/src/widget/overlay/utopia_overlay_anchor.dart');
    expect(bindings, {'theme.cardDecoration', 'theme.cardBorderDecoration', 'tokens.spacing.sm'});
  });

  test('sidebar: theme.tokens.durations.X (two-hop through the theme alias) normalizes to tokens.durations.X', () {
    // Whole-file scope also covers the private _UtopiaSidebarIconButton
    // subwidget in the same file (tokens.spacing.sm padding).
    final bindings = bindingsOf('lib/src/widget/sidebar/utopia_sidebar.dart');
    expect(bindings, {
      'tokens.durations.md',
      'tokens.durations.lg',
      'colors.surface',
      'colors.border',
      'theme.cardBorderWidth',
      'theme.cardRadius',
      'theme.cardShadow',
      'theme.menuShadow',
      'theme.pageTopPadding',
      'tokens.spacing.md',
      'tokens.spacing.xxs',
      'tokens.spacing.lg',
      'tokens.spacing.xs',
      'tokens.spacing.sm',
      'textStyles.button',
      'colors.onColoredContent',
      'colors.hint',
      'colors.onColoredHover',
      'colors.hover',
      'tokens.radius.mdAll',
    });
  });

  test('no spurious short bindings: a component that reads theme.colors.X never also emits a bare theme.colors', () {
    final bindings = bindingsOf('lib/src/widget/dialog/utopia_dialog.dart');
    expect(bindings.contains('theme.colors'), isFalse);
    expect(bindings.contains('theme.textStyles'), isFalse);
    final sidebarBindings = bindingsOf('lib/src/widget/sidebar/utopia_sidebar.dart');
    expect(sidebarBindings.contains('theme.tokens'), isFalse);
    expect(sidebarBindings.contains('theme.colors'), isFalse);
  });

  test('components with no theme/token reads produce an empty binding set', () {
    expect(bindingsOf('lib/src/widget/layout/utopia_form_layout.dart'), isEmpty);
    expect(bindingsOf('lib/src/widget/misc/utopia_collapsible.dart'), isEmpty);
    expect(bindingsOf('lib/src/widget/misc/utopia_multi_widget.dart'), isEmpty);
    expect(bindingsOf('lib/src/widget/loading/utopia_three_bounce.dart'), isEmpty);
  });
}
