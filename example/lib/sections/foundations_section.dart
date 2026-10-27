import 'dart:async';

import 'package:flutter/material.dart';
import 'package:utopia_ui/utopia_ui.dart';

import '../widgets/section.dart';

class FoundationsSection extends StatelessWidget {
  const FoundationsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return SheetSection(
      title: 'Foundations',
      subtitle: 'Every dimension below is a multiple of one base unit - x = ${tokens.x.toStringAsFixed(1)} right now.',
      note:
          'Spacing has eight named steps and nothing in between; when a gap wants 10px, it takes 8 or 12 instead, '
          'and the page stays on one rhythm. Radius steps map to roles - xs tags, sm fields, md chips and buttons, '
          'lg menus, xl cards - so rounding encodes what kind of surface you are looking at. Durations scale the '
          'same way: instant feedback sits at xs, structural motion at lg.',
      child: const Wrap(
        spacing: 40,
        runSpacing: 32,
        children: [
          _SpacingLadder(),
          _RadiusLadder(),
          _BorderStrokes(),
          _DurationDots(),
        ],
      ),
    );
  }
}

class _SpacingLadder extends StatelessWidget {
  const _SpacingLadder();

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final steps = <(String, double)>[
      ('xxs', spacing.xxs),
      ('xs', spacing.xs),
      ('sm', spacing.sm),
      ('md', spacing.md),
      ('lg', spacing.lg),
      ('xl', spacing.xl),
      ('xxl', spacing.xxl),
      ('xxxl', spacing.xxxl),
    ];
    return _Ladder(
      label: 'spacing',
      children: [
        for (final (name, value) in steps)
          _LadderRow(
            name: name,
            value: value,
            child: AnimatedContainer(
              duration: context.tokens.durations.md,
              width: value * 4,
              height: 10,
              decoration: BoxDecoration(
                color: context.colors.primary,
                borderRadius: BorderRadius.circular(context.tokens.radius.xs),
              ),
            ),
          ),
      ],
    );
  }
}

class _RadiusLadder extends StatelessWidget {
  const _RadiusLadder();

  @override
  Widget build(BuildContext context) {
    final radius = context.radius;
    final steps = <(String, double, String)>[
      ('xs', radius.xs, 'tags'),
      ('sm', radius.sm, 'fields'),
      ('md', radius.md, 'chips, buttons'),
      ('lg', radius.lg, 'menus'),
      ('xl', radius.xl, 'cards'),
    ];
    return _Ladder(
      label: 'radius',
      children: [
        for (final (name, value, role) in steps)
          _LadderRow(
            name: name,
            value: value,
            role: role,
            child: AnimatedContainer(
              duration: context.tokens.durations.md,
              width: 44,
              height: 28,
              decoration: BoxDecoration(
                color: context.colors.chipBackground,
                border: Border.all(color: context.colors.primary, width: context.tokens.borders.thin),
                borderRadius: BorderRadius.circular(value),
              ),
            ),
          ),
      ],
    );
  }
}

class _BorderStrokes extends StatelessWidget {
  const _BorderStrokes();

  @override
  Widget build(BuildContext context) {
    final borders = context.tokens.borders;
    final steps = <(String, double, String)>[
      ('hairline', borders.hairline, 'dividers'),
      ('thin', borders.thin, 'card outlines'),
      ('thick', borders.thick, 'focus, emphasis'),
    ];
    return _Ladder(
      label: 'borders',
      children: [
        for (final (name, value, role) in steps)
          _LadderRow(
            name: name,
            value: value,
            role: role,
            child: SizedBox(
              width: 64,
              height: 28,
              child: Center(child: Container(height: value, color: context.colors.text)),
            ),
          ),
      ],
    );
  }
}

class _DurationDots extends StatelessWidget {
  const _DurationDots();

  @override
  Widget build(BuildContext context) {
    final durations = context.tokens.durations;
    final steps = <(String, Duration, String)>[
      ('xs', durations.xs, 'hovers'),
      ('sm', durations.sm, 'toggles'),
      ('md', durations.md, 'fades'),
      ('lg', durations.lg, 'expand'),
      ('xl', durations.xl, 'panels'),
    ];
    return _Ladder(
      label: 'durations',
      children: [
        for (final (name, value, role) in steps)
          _LadderRow(name: name, value: value.inMilliseconds.toDouble(), unit: 'ms', role: role, child: _Pulse(duration: value)),
      ],
    );
  }
}

class _Pulse extends StatefulWidget {
  final Duration duration;

  const _Pulse({required this.duration});

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: widget.duration)
    ..repeat(reverse: true);

  @override
  void didUpdateWidget(_Pulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
      unawaited(_controller.repeat(reverse: true));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 28,
      child: Center(
        child: FadeTransition(
          opacity: Tween(begin: 0.25, end: 1.0).animate(_controller),
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(color: context.colors.primary, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}

class _Ladder extends StatelessWidget {
  final String label;
  final List<Widget> children;

  const _Ladder({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: context.textStyles.caption.copyWith(color: context.colors.hint)),
        const SizedBox(height: 12),
        for (final child in children) Padding(padding: const EdgeInsets.only(bottom: 8), child: child),
      ],
    );
  }
}

class _LadderRow extends StatelessWidget {
  final String name;
  final double value;
  final String unit;
  final String? role;
  final Widget child;

  const _LadderRow({required this.name, required this.value, this.unit = 'px', this.role, required this.child});

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;
    final colors = context.colors;
    final display = value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(1);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 56,
          child: Text(name, style: textStyles.caption.copyWith(color: colors.text)),
        ),
        SizedBox(
          width: 64,
          child: Text(
            '$display $unit',
            style: textStyles.caption.copyWith(
              color: colors.hint,
              fontWeight: context.tokens.fontWeights.regular,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        child,
        if (role != null) ...[
          const SizedBox(width: 12),
          Text(role!, style: textStyles.caption.copyWith(color: colors.hint, fontWeight: context.tokens.fontWeights.regular)),
        ],
      ],
    );
  }
}
