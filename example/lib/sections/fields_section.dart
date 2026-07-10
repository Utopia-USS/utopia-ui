import 'package:flutter/material.dart';
import 'package:utopia_hooks/utopia_hooks.dart';
import 'package:utopia_ui/utopia_ui.dart';

import '../widgets/section.dart';

/// Text inputs, pickers and dropdowns - one shared chrome, one height.
class FieldsSection extends HookWidget {
  /// Creates the fields section.
  const FieldsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final searchState = useState('');
    final roleState = useState<String?>('Editor');
    final publishedState = useState<DateTime?>(DateTime(2026, 3, 14));

    return SheetSection(
      title: 'Fields',
      subtitle: 'Text inputs, pickers and dropdowns - one shared chrome, one height.',
      child: Wrap(
        spacing: 32,
        runSpacing: 24,
        children: [
          SpecimenTile(
            label: 'Text - label',
            width: 320,
            child: UtopiaTextField(value: 'Ava Chen', label: const Text('Name'), onChanged: (_) {}),
          ),
          SpecimenTile(
            label: 'Text - hint',
            width: 320,
            child: UtopiaTextField(value: '', hint: const Text('Type to search...'), onChanged: (_) {}),
          ),
          SpecimenTile(
            label: 'Text - error',
            width: 320,
            child: UtopiaTextField(
              value: '',
              label: const Text('Email'),
              error: const Text('Required field'),
              onChanged: (_) {},
            ),
          ),
          SpecimenTile(
            label: 'Text - suffix',
            width: 320,
            child: UtopiaTextField(
              value: 'ava@example.com',
              label: const Text('Email'),
              suffix: UtopiaRemoveIconButton(onPressed: () {}),
              onChanged: (_) {},
            ),
          ),
          SpecimenTile(
            label: 'Text - multiline (lines: 3)',
            width: 320,
            child: UtopiaTextField(value: '', lines: 3, label: const Text('Notes'), onChanged: (_) {}),
          ),
          SpecimenTile(
            label: 'Text - obscured',
            width: 320,
            child: UtopiaTextField(
              value: 'correct horse',
              obscureText: true,
              label: const Text('Password'),
              onChanged: (_) {},
            ),
          ),
          SpecimenTile(
            label: 'Text - read only',
            width: 320,
            child: UtopiaTextField(value: 'v0.1.0', readOnly: true, label: const Text('Version'), onChanged: (_) {}),
          ),
          SpecimenTile(
            label: 'Search',
            width: 320,
            child: UtopiaSearchField(
              value: searchState.value,
              hint: 'Search components...',
              onChanged: (value) => searchState.value = value ?? '',
            ),
          ),
          const SpecimenTile(
            label: 'Labeled (read-only base)',
            width: 320,
            child: UtopiaLabeledField(
              label: 'Status',
              value: 'Active',
              suffix: Icon(Icons.keyboard_arrow_down, size: 18),
            ),
          ),
          SpecimenTile(
            label: 'Dropdown',
            width: 320,
            child: UtopiaDropdownField<String>(
              label: 'Role',
              value: roleState.value,
              values: const ['Admin', 'Editor', 'Viewer'],
              valueLabelBuilder: (value) => value,
              onChanged: (value) => roleState.value = value,
            ),
          ),
          SpecimenTile(
            label: 'Date picker',
            width: 320,
            child: UtopiaDatePicker(
              label: 'Published',
              date: publishedState.value,
              onDateChanged: (value) => publishedState.value = value,
            ),
          ),
        ],
      ),
    );
  }
}
