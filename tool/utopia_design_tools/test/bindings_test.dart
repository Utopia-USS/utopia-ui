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

  test('button: tokens.x, colors.primary, colors.accent, colors.onColoredHover, theme.borderRadius, '
      'textStyles.button', () {
    final bindings = bindingsOf('lib/src/widget/button/utopia_button.dart');
    expect(bindings, {
      'tokens.x',
      'colors.primary',
      'colors.accent',
      'colors.onColoredHover',
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

  test('field-wrapper: aliased locals (fieldTheme/themeValues) resolve through one-hop aliasing', () {
    // Whole-file scope also picks up utopiaFieldDecoration/utopiaPlaceholderStyle,
    // the two free functions sharing this file - hence colors.hint (only read
    // inside utopiaPlaceholderStyle) appears alongside UtopiaFieldWrapper's
    // own reads.
    final bindings = bindingsOf('lib/src/widget/wrapper/utopia_field_wrapper.dart');
    expect(bindings, {
      'theme.fieldDecoration',
      'tokens.durations.sm',
      'colors.error',
      'colors.border',
      'colors.hint',
      'tokens.borders.hairline',
      'theme.fieldContentPadding',
      'theme.fieldMinHeight',
      'tokens.x',
      'textStyles.text',
      'textStyles.label',
      'tokens.fontWeights.regular',
    });
  });

  test('check-row: tokens.durations.xs and the row/checkbox theme reads', () {
    final bindings = bindingsOf('lib/src/widget/select/utopia_check_row.dart');
    expect(bindings, {
      'colors.hover',
      'tokens.spacing.md',
      'textStyles.text',
      'tokens.durations.xs',
      'colors.accent',
      'tokens.radius.smAll',
      'colors.disabled',
      'tokens.borders.thin',
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
      'theme.cardDecoration',
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
