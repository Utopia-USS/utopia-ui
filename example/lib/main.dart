import 'package:flutter/material.dart';
import 'package:utopia_hooks/utopia_hooks.dart';
import 'package:utopia_ui/utopia_ui.dart';

import 'sections/buttons_section.dart';
import 'sections/chips_text_section.dart';
import 'sections/colors_section.dart';
import 'sections/dialogs_section.dart';
import 'sections/fields_section.dart';
import 'sections/loading_section.dart';
import 'sections/selection_section.dart';
import 'sections/sidebar_section.dart';
import 'sections/surfaces_section.dart';
import 'sections/table_section.dart';
import 'sections/typography_section.dart';
import 'state/theme_mode_state.dart';
import 'theme.dart';
import 'widgets/theme_mode_picker.dart';

void main() => runApp(const DesignSystemApp());

/// App-wide hook providers. [ThemeModeState] holds the selected theme mode,
/// written by [ThemeModePicker] and read by [DesignSystemSheet] to re-theme
/// the whole sheet.
const _providers = <Type, Object? Function()>{ThemeModeState: useThemeModeState};

/// A design-system reference for `utopia_ui`: every token and component
/// laid out on one themable page, so a change to a widget or a theme value is
/// visible across the whole catalog at once.
class DesignSystemApp extends HookWidget {
  /// Creates the design-system sheet app.
  const DesignSystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'utopia_ui - Design System',
      debugShowCheckedModeBanner: false,
      home: const DesignSystemSheet(),
      builder: (context, child) =>
          HookProviderContainerWidget(_providers, alwaysNotifyDependents: false, child: child!),
    );
  }
}

/// The sheet itself: a header band with the title and [ThemeModePicker],
/// followed by one scrollable column of sections, each demonstrating a slice
/// of the design system under the currently selected theme. Sections open
/// with the library's flagship component - the table - before working down
/// to individual controls and finally the raw tokens.
class DesignSystemSheet extends HookWidget {
  /// Creates the design-system sheet page.
  const DesignSystemSheet({super.key});

  static const double _maxContentWidth = 1120;

  @override
  Widget build(BuildContext context) {
    final themeMode = useProvided<ThemeModeState>();
    final theme = themeFor(themeMode.mode.value);
    return UtopiaTheme(
      data: theme,
      child: Scaffold(
        backgroundColor: theme.colors.canvas,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Wrap(
                spacing: 24,
                runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('utopia_ui', style: theme.textStyles.header),
                      const SizedBox(height: 4),
                      Text(
                        'Design system reference - every token and component, themed live.',
                        style: theme.textStyles.text.copyWith(color: theme.colors.hint),
                      ),
                    ],
                  ),
                  const ThemeModePicker(),
                ],
              ),
            ),
            const UtopiaDivider(),
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                    child: const Padding(
                      padding: EdgeInsets.fromLTRB(24, 8, 24, 64),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TableSection(),
                          SizedBox(height: 48),
                          FieldsSection(),
                          SizedBox(height: 48),
                          ButtonsSection(),
                          SizedBox(height: 48),
                          SelectionSection(),
                          SizedBox(height: 48),
                          ChipsTextSection(),
                          SizedBox(height: 48),
                          DialogsSection(),
                          SizedBox(height: 48),
                          SidebarSection(),
                          SizedBox(height: 48),
                          LoadingSection(),
                          SizedBox(height: 48),
                          ColorsSection(),
                          SizedBox(height: 48),
                          TypographySection(),
                          SizedBox(height: 48),
                          SurfacesSection(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
