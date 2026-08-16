import 'package:flutter/material.dart';

import '../sections/buttons_section.dart';
import '../sections/chips_text_section.dart';
import '../sections/colors_section.dart';
import '../sections/dialogs_section.dart';
import '../sections/fields_section.dart';
import '../sections/loading_section.dart';
import '../sections/selection_section.dart';
import '../sections/sidebar_section.dart';
import '../sections/surfaces_section.dart';
import '../sections/table_section.dart';
import '../sections/typography_section.dart';
import '../widgets/page_scaffold.dart';

/// The design-system reference sheet: every token and component on one page.
///
/// Sections run from foundations to composites - colors, typography, surfaces,
/// buttons, selection, fields, chips & text, loading, table, dialogs, sidebar.
/// twin/gallery.src.html mirrors this page section for section, in this order.
class ComponentsPage extends StatelessWidget {
  const ComponentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageScaffold(
      title: 'Components',
      subtitle: 'Design system reference - every token and component, themed live.',
      child: PageBody(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ColorsSection(),
                SizedBox(height: 48),
                TypographySection(),
                SizedBox(height: 48),
                SurfacesSection(),
                SizedBox(height: 48),
                ButtonsSection(),
                SizedBox(height: 48),
                SelectionSection(),
                SizedBox(height: 48),
                FieldsSection(),
                SizedBox(height: 48),
                ChipsTextSection(),
                SizedBox(height: 48),
                LoadingSection(),
                SizedBox(height: 48),
                TableSection(),
                SizedBox(height: 48),
                DialogsSection(),
                SizedBox(height: 48),
                SidebarSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
