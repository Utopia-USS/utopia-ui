// Golden-ish spot checks of component/model/helper extraction against the
// real utopia_ui sources (this repo checkout), per ledger/checkpoints/A3-spec.md.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:utopia_design_tools/src/manifest/extract.dart';
import 'package:utopia_design_tools/src/manifest/source_model.dart';

void main() {
  final repoRoot = Directory(p.join(Directory.current.path, '..', '..'));
  late final model = SourceModel.parse(repoRoot);
  late final extraction = extractAll(model);

  setUpAll(() {
    expect(extraction.errors, isEmpty, reason: 'extraction must not report fatal errors against real sources');
    resolveComposes(model, extraction.components);
  });

  ExtractedComponent component(String id) => extraction.components.firstWhere(
    (c) => c.id == id,
    orElse: () => throw StateError('no component with id "$id"'),
  );

  group('kebabId', () {
    test('strips the Utopia prefix and splits on uppercase boundaries', () {
      expect(kebabId('UtopiaButton'), 'button');
      expect(kebabId('UtopiaRemoveIconButton'), 'remove-icon-button');
      expect(kebabId('UtopiaChipList'), 'chip-list');
      expect(kebabId('UtopiaThreeBounce'), 'three-bounce');
      expect(kebabId('UtopiaMockLoadingBox'), 'mock-loading-box');
    });
  });

  group('component census', () {
    test('every component id is unique and kebab-derived from its class name', () {
      final seen = <String>{};
      for (final c in extraction.components) {
        expect(seen.add(c.id), isTrue, reason: 'duplicate id ${c.id}');
        expect(c.id, kebabId(c.name));
      }
    });

    test('UtopiaTheme, UtopiaBreakpoints are excluded (not components, not models/helpers)', () {
      expect(extraction.components.any((c) => c.name == 'UtopiaTheme'), isFalse);
      expect(extraction.components.any((c) => c.name == 'UtopiaBreakpoints'), isFalse);
      expect(extraction.models.any((m) => m.name == 'UtopiaTheme'), isFalse);
      expect(extraction.models.any((m) => m.name == 'UtopiaBreakpoints'), isFalse);
    });

    test('UtopiaTableSort and UtopiaSidebarHeaderBuilder are typedef helpers, not components/models', () {
      expect(extraction.components.any((c) => c.name == 'UtopiaTableSort'), isFalse);
      expect(extraction.models.any((m) => m.name == 'UtopiaTableSort'), isFalse);
      final tableSort = extraction.helpers.firstWhere((h) => h.name == 'UtopiaTableSort');
      expect(tableSort.kind, 'typedef');

      expect(extraction.components.any((c) => c.name == 'UtopiaSidebarHeaderBuilder'), isFalse);
      final headerBuilder = extraction.helpers.firstWhere((h) => h.name == 'UtopiaSidebarHeaderBuilder');
      expect(headerBuilder.kind, 'typedef');
    });

    test('expects free-function helpers per the inventory', () {
      const expectedFunctionNames = {
        'utopiaCardSliver',
        'utopiaDatePickerMaterialTheme',
        'utopiaFieldDecoration',
        'utopiaPlaceholderStyle',
      };
      final actualFunctionNames = extraction.helpers
          .where((h) => h.kind == 'function')
          .map((h) => h.name)
          .toSet();
      expect(actualFunctionNames, expectedFunctionNames);

      final hook = extraction.helpers.singleWhere((h) => h.name == 'useUtopiaTableState');
      expect(hook.kind, 'hook');
    });
  });

  group('button (golden spot check)', () {
    test('id, props, defaults', () {
      final button = component('button');
      expect(button.name, 'UtopiaButton');
      expect(button.generic, isFalse);
      expect(button.constructors, hasLength(1));

      final ctor = button.constructors.single;
      expect(ctor.name, '');
      final propsByName = {for (final p in ctor.props) p.name: p};

      expect(propsByName['child']!.required, isTrue);
      expect(propsByName['child']!.type, 'widget-slot');

      expect(propsByName['onTap']!.required, isTrue);
      expect(propsByName['onTap']!.type, 'callback');
      expect(propsByName['onTap']!.dartType, 'void Function()');

      expect(propsByName['isEnabled']!.required, isFalse);
      expect(propsByName['isEnabled']!.defaultValue, 'true');

      expect(propsByName['loading']!.defaultValue, 'false');
      expect(propsByName['dense']!.defaultValue, 'false');

      expect(propsByName['maxWidth']!.type, 'number');
      expect(propsByName['maxWidth']!.defaultValue, '300');

      expect(propsByName['colors']!.type, 'list');
      expect(propsByName['colors']!.itemType, 'color');
      expect(propsByName['colors']!.required, isFalse);
      expect(propsByName['colors']!.defaultValue, isNull);

      expect(propsByName['height']!.type, 'number');
      expect(propsByName['height']!.dartType, 'double?');
    });
  });

  group('dialog (two constructors, differing maxWidth defaults)', () {
    test('raw ctor defaults maxWidth to 1000, form ctor to 600', () {
      final dialog = component('dialog');
      expect(dialog.constructors, hasLength(2));

      final raw = dialog.constructors.firstWhere((c) => c.name == '');
      final rawMaxWidth = raw.props.firstWhere((p) => p.name == 'maxWidth');
      expect(rawMaxWidth.defaultValue, '1000');

      final form = dialog.constructors.firstWhere((c) => c.name == 'form');
      final formMaxWidth = form.props.firstWhere((p) => p.name == 'maxWidth');
      expect(formMaxWidth.defaultValue, '600');

      // Both constructors share the same field set (title/builder/maxWidth/
      // dismissible), including on the `.form` ctor where `builder` is
      // synthesized as a closure rather than a plain parameter.
      final formPropNames = form.props.map((p) => p.name).toSet();
      expect(formPropNames, contains('title'));
      expect(formPropNames, contains('maxWidth'));
      expect(formPropNames, contains('dismissible'));
    });

    test('builder prop is a builder-slot on the raw constructor', () {
      final dialog = component('dialog');
      final raw = dialog.constructors.firstWhere((c) => c.name == '');
      final builder = raw.props.firstWhere((p) => p.name == 'builder');
      expect(builder.type, 'builder-slot');
      expect(builder.required, isTrue);
    });
  });

  group('table (generic + rowKey generic-model)', () {
    test('table is generic, entries -> list of model UtopiaTableEntry, rowKey is generic-model callback', () {
      final table = component('table');
      expect(table.generic, isTrue);
      final ctor = table.constructors.single;
      final propsByName = {for (final p in ctor.props) p.name: p};

      final entries = propsByName['entries']!;
      expect(entries.type, 'list');
      expect(entries.itemType, 'model');
      expect(entries.modelName, 'UtopiaTableEntry');

      final rowKey = propsByName['rowKey']!;
      expect(rowKey.type, 'callback');
      expect(rowKey.dartType, 'Object Function(T row)');

      final rows = propsByName['rows']!;
      expect(rows.type, 'list');
      expect(rows.itemType, 'generic-model');
    });
  });

  group('sidebar (items list -> model UtopiaSidebarItem)', () {
    test('items is a list of model UtopiaSidebarItem; style is a model prop', () {
      final sidebar = component('sidebar');
      final ctor = sidebar.constructors.single;
      final propsByName = {for (final p in ctor.props) p.name: p};

      final items = propsByName['items']!;
      expect(items.type, 'list');
      expect(items.itemType, 'model');
      expect(items.modelName, 'UtopiaSidebarItem');

      final style = propsByName['style']!;
      expect(style.type, 'model');
      expect(style.modelName, 'UtopiaSidebarStyle');

      final presentation = propsByName['presentation']!;
      expect(presentation.type, 'enum');
      expect(presentation.enumName, 'UtopiaSidebarPresentation');
      expect(presentation.values, ['rail', 'drawer']);
    });
  });

  group('copyable-text (positional optional String)', () {
    test('positional String? text is required (positional without default) and portable-typed string', () {
      final copyableText = component('copyable-text');
      final ctor = copyableText.constructors.single;
      final textProp = ctor.props.singleWhere((p) => p.name == 'text');
      expect(textProp.type, 'string');
      expect(textProp.dartType, 'String?');
      expect(textProp.required, isTrue);
    });
  });

  group('model closure', () {
    test('resolves the sidebar sealed hierarchy + table entry family (spec v0 practical outcome)', () {
      final modelNames = extraction.models.map((m) => m.name).toSet();
      expect(modelNames, {
        'UtopiaSidebarItem',
        'UtopiaSidebarDestination',
        'UtopiaSidebarAction',
        'UtopiaSidebarCustom',
        'UtopiaSidebarStyle',
        'UtopiaTableEntry',
        'UtopiaTableSortOption',
      });

      final sidebarItem = extraction.models.firstWhere((m) => m.name == 'UtopiaSidebarItem');
      expect(sidebarItem.kind, 'sealed-class');

      final destination = extraction.models.firstWhere((m) => m.name == 'UtopiaSidebarDestination');
      expect(destination.kind, 'class');
      expect(destination.supertype, 'UtopiaSidebarItem');
    });
  });

  group('empty tokenBindings components (SPEC: schema requires the array, [] is valid)', () {
    test('components with no theme/token reads get an empty tokenBindings array, not omitted', () {
      for (final id in ['form-layout', 'multi-widget', 'collapsible', 'three-bounce']) {
        final c = component(id);
        final file = model.fileDeclaring(c.name)!;
        expect(file, isNotNull);
      }
    });
  });
}
