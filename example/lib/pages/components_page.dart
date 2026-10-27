import 'dart:async';

import 'package:flutter/material.dart';
import 'package:utopia_hooks/utopia_hooks.dart';
import 'package:utopia_ui/utopia_ui.dart';

import '../sections/buttons_section.dart';
import '../sections/chips_text_section.dart';
import '../sections/colors_section.dart';
import '../sections/dialogs_section.dart';
import '../sections/fields_section.dart';
import '../sections/foundations_section.dart';
import '../sections/loading_section.dart';
import '../sections/principles_section.dart';
import '../sections/selection_section.dart';
import '../sections/sidebar_section.dart';
import '../sections/surfaces_section.dart';
import '../sections/table_section.dart';
import '../sections/typography_section.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/section.dart';
import '../widgets/theme_lab.dart';

/// The whole design system on one page: the theme lab drives the ambient
/// theme, everything below is a live specimen of it.
///
/// twin/gallery.src.html mirrors this page one-to-one, in the same order -
/// keep the section list below and the twin's TOC in lockstep.
class ComponentsPage extends HookWidget {
  const ComponentsPage({super.key});

  static const _sections = <(String, Widget)>[
    ('Theme lab', ThemeLab()),
    ('Foundations', FoundationsSection()),
    ('Colors', ColorsSection()),
    ('Typography', TypographySection()),
    ('Surfaces & shape', SurfacesSection()),
    ('Buttons', ButtonsSection()),
    ('Selection', SelectionSection()),
    ('Fields', FieldsSection()),
    ('Chips & text', ChipsTextSection()),
    ('Loading', LoadingSection()),
    ('Table', TableSection()),
    ('Dialogs', DialogsSection()),
    ('Sidebar', SidebarSection()),
    ('Principles', PrinciplesSection()),
  ];

  @override
  Widget build(BuildContext context) {
    final keys = useMemoized(() => List.generate(_sections.length, (_) => GlobalKey()));
    return PageScaffold(
      title: 'utopia_ui',
      subtitle: 'One token scale, one theme object, every component below rebuilt from it - live.',
      eyebrow: 'Design system',
      badge: 'v0.1.0 · protocol 0.3.0',
      child: PageBody(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Toc(keys: keys),
                const SizedBox(height: 24),
                for (var i = 0; i < _sections.length; i++) ...[
                  if (i > 0) const SizedBox(height: 48),
                  SectionScope(
                    key: keys[i],
                    index: i + 1,
                    child: _sections[i].$2,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Toc extends StatelessWidget {
  final List<GlobalKey> keys;

  const _Toc({required this.keys});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: context.spacing.sm,
      runSpacing: context.spacing.sm,
      children: [
        for (var i = 0; i < ComponentsPage._sections.length; i++)
          _TocChip(index: i + 1, label: ComponentsPage._sections[i].$1, sectionKey: keys[i]),
      ],
    );
  }
}

class _TocChip extends StatelessWidget {
  final int index;
  final String label;
  final GlobalKey sectionKey;

  const _TocChip({required this.index, required this.label, required this.sectionKey});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tokens = context.tokens;
    final caption = context.textStyles.caption;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(tokens.radius.full),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          final target = sectionKey.currentContext;
          if (target == null) return;
          unawaited(Scrollable.ensureVisible(target, duration: tokens.durations.lg, curve: Curves.easeOutExpo));
        },
        hoverColor: colors.chipBackground,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: context.spacing.md, vertical: context.spacing.xs),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(tokens.radius.full),
            border: Border.all(color: colors.border, width: tokens.borders.hairline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                index.toString().padLeft(2, '0'),
                style: caption.copyWith(
                  color: colors.hint,
                  fontWeight: tokens.fontWeights.semiBold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              SizedBox(width: context.spacing.sm),
              Text(label, style: caption.copyWith(fontWeight: tokens.fontWeights.medium)),
            ],
          ),
        ),
      ),
    );
  }
}
