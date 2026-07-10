/// Component/model/helper extraction from a parsed [SourceModel]: classifies
/// every exported declaration per protocol SPEC section 3.2, derives kebab
/// component ids, maps Dart parameter types to the portable prop-type
/// vocabulary (SPEC 3.5), and finds internal `composes` references.
library;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import 'source_model.dart';

/// A single extracted constructor prop (protocol manifest `prop` shape).
class ExtractedProp {
  const ExtractedProp({
    required this.name,
    required this.type,
    required this.dartType,
    required this.required,
    this.defaultValue,
    this.description,
    this.enumName,
    this.values,
    this.itemType,
    this.itemDartType,
    this.modelName,
  });

  /// The parameter name.
  final String name;

  /// Portable prop type (SPEC 3.5 closed vocabulary).
  final String type;

  /// Verbatim Dart type of the parameter, including `?`.
  final String dartType;

  /// Whether the prop must be supplied by callers.
  final bool required;

  /// Verbatim Dart default-value expression, if any.
  final String? defaultValue;

  /// Cleaned first-paragraph description, if any.
  final String? description;

  /// For `type: "enum"`: the Dart enum's name.
  final String? enumName;

  /// For `type: "enum"`: the enum's value names.
  final List<String>? values;

  /// For `type: "list"`: the portable type of the list elements.
  final String? itemType;

  /// For `type: "list"`: the verbatim Dart type of the list elements.
  final String? itemDartType;

  /// For `type: "model"` (or a list of models): the referenced model name.
  final String? modelName;

  /// Renders to the manifest JSON shape, in schema property order, omitting
  /// absent fields.
  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
    'dartType': dartType,
    'required': required,
    if (defaultValue != null) 'default': defaultValue,
    if (description != null) 'description': description,
    if (enumName != null) 'enumName': enumName,
    if (values != null) 'values': values,
    if (itemType != null) 'itemType': itemType,
    if (itemDartType != null) 'itemDartType': itemDartType,
    if (modelName != null) 'modelName': modelName,
  };
}

/// A single extracted constructor (protocol manifest `constructor` shape).
class ExtractedConstructor {
  const ExtractedConstructor({required this.name, this.description, required this.props});

  /// `""` for the unnamed constructor, else the named-constructor name.
  final String name;

  /// Cleaned constructor doc comment, if any.
  final String? description;

  /// The constructor's props, in declaration order.
  final List<ExtractedProp> props;

  /// Renders to the manifest JSON `constructor` shape.
  Map<String, dynamic> toJson() => {
    'name': name,
    if (description != null) 'description': description,
    'props': props.map((p) => p.toJson()).toList(),
  };
}

/// A single extracted component (protocol manifest `component` shape, minus
/// the overlay-only and generation-time fields `states`/`twin`/`examples`/
/// `notes`, added later by the generator).
class ExtractedComponent {
  ExtractedComponent({
    required this.id,
    required this.name,
    required this.description,
    required this.file,
    required this.generic,
    required this.constructors,
    required this.tokenBindings,
    required this.composes,
  });

  /// Stable kebab-case id (class name minus the `Utopia` prefix).
  final String id;

  /// The Dart class name.
  final String name;

  /// Cleaned first-paragraph class doc comment.
  final String description;

  /// Repo-relative source path.
  final String file;

  /// Whether the widget is generic over a row/item type.
  final bool generic;

  /// Every public constructor.
  final List<ExtractedConstructor> constructors;

  /// Dotted `UtopiaThemeData` member paths this component reads. Assigned
  /// after extraction (bindings extraction runs per-component over the
  /// already-parsed file).
  List<String> tokenBindings;

  /// Ids of other extracted components this component's file body
  /// constructs. Resolved in a second pass, after every component id is
  /// known.
  List<String> composes;
}

/// A single extracted model (protocol manifest `model` shape).
class ExtractedModel {
  const ExtractedModel({
    required this.name,
    required this.description,
    required this.file,
    required this.kind,
    this.supertype,
    this.values,
    this.constructors,
  });

  /// The Dart class/enum name.
  final String name;

  /// Cleaned first-paragraph doc comment.
  final String description;

  /// Repo-relative source path.
  final String file;

  /// One of `class`, `sealed-class`, `enum`, `record`.
  final String kind;

  /// For a subtype of a sealed hierarchy: the sealed parent's name.
  final String? supertype;

  /// For `kind: "enum"`: the value names.
  final List<String>? values;

  /// For class/sealed-class kinds: the public constructors.
  final List<ExtractedConstructor>? constructors;

  /// Renders to the manifest JSON `model` shape.
  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'file': file,
    'kind': kind,
    if (supertype != null) 'supertype': supertype,
    if (values != null) 'values': values,
    if (constructors != null) 'constructors': constructors!.map((c) => c.toJson()).toList(),
  };
}

/// A single extracted helper (protocol manifest `helper` shape).
class ExtractedHelper {
  const ExtractedHelper({
    required this.name,
    required this.kind,
    required this.description,
    required this.file,
    this.signature,
  });

  /// The Dart declaration name.
  final String name;

  /// One of `function`, `hook`, `typedef`, `extension`.
  final String kind;

  /// Cleaned first-paragraph doc comment.
  final String description;

  /// Repo-relative source path.
  final String file;

  /// Verbatim declaration signature up to the body.
  final String? signature;

  /// Renders to the manifest JSON `helper` shape.
  Map<String, dynamic> toJson() => {
    'name': name,
    'kind': kind,
    'description': description,
    'file': file,
    if (signature != null) 'signature': signature,
  };
}

/// The full extraction result: components, models and helpers, plus any
/// fatal errors (missing `Utopia` prefix, id collisions) that should abort
/// generation before any bindings extraction or output happens.
class ExtractionResult {
  ExtractionResult({required this.components, required this.models, required this.helpers, required this.errors});

  /// Every extracted component, sorted by id.
  final List<ExtractedComponent> components;

  /// Every extracted model, sorted by name.
  final List<ExtractedModel> models;

  /// Every extracted helper, sorted by name.
  final List<ExtractedHelper> helpers;

  /// Fatal extraction errors (one-line, actionable). Non-empty means
  /// generation must fail with exit 1 before writing anything.
  final List<String> errors;
}

const Set<String> _widgetSuperclasses = {'StatelessWidget', 'StatefulWidget', 'HookWidget'};

/// Names excluded from model/helper classification even though they are
/// public exported declarations: theme plumbing and compile-time-only
/// constant holders that carry no runtime API surface worth mirroring.
const Set<String> _excludedClassNames = {'UtopiaTheme', 'UtopiaBreakpoints'};

/// Converts a Utopia class name to its manifest kebab-case id: strips the
/// `Utopia` prefix, then splits on uppercase boundaries and lowercases/joins
/// with `-` (`UtopiaRemoveIconButton` -> `remove-icon-button`).
String kebabId(String className) {
  const prefix = 'Utopia';
  final stripped = className.startsWith(prefix) ? className.substring(prefix.length) : className;
  final buffer = StringBuffer();
  for (var i = 0; i < stripped.length; i++) {
    final char = stripped[i];
    final isUpper = char.toUpperCase() == char && char.toLowerCase() != char;
    if (isUpper && i > 0) {
      buffer.write('-');
    }
    buffer.write(char.toLowerCase());
  }
  return buffer.toString();
}

/// Runs the full extraction pipeline over [model]: classification, kebab-id
/// derivation, prop/type mapping, model closure and helper collection.
/// `composes` is left empty here; call [resolveComposes] afterward once the
/// full component id set is fixed.
ExtractionResult extractAll(SourceModel model) {
  final errors = <String>[];
  final componentClasses = <String, ClassDeclaration>{};
  final componentFiles = <String, ParsedFile>{};
  final idByClassName = <String, String>{};
  final usedIds = <String, String>{};

  // Pass 1: classify every top-level class as component or "falls through"
  // to model/helper classification.
  for (final file in model.files) {
    for (final cls in file.classes) {
      final className = cls.name.lexeme;
      if (!isPublicName(className)) continue;
      final superName = cls.extendsClause?.superclass.name.lexeme;
      if (superName != null && _widgetSuperclasses.contains(superName)) {
        if (!className.startsWith('Utopia')) {
          errors.add(
            'component class "$className" in ${file.repoRelativePath} is missing the required "Utopia" prefix',
          );
          continue;
        }
        final id = kebabId(className);
        final existing = usedIds[id];
        if (existing != null) {
          errors.add('component id "$id" collides between "$existing" and "$className"');
          continue;
        }
        usedIds[id] = className;
        idByClassName[className] = id;
        componentClasses[className] = cls;
        componentFiles[className] = file;
      }
    }
  }

  if (errors.isNotEmpty) {
    return ExtractionResult(components: const [], models: const [], helpers: const [], errors: errors);
  }

  // Pass 2: build each component's constructors/props; model references
  // encountered along the way are collected as bare Dart names, resolved
  // into full ExtractedModel entries in pass 3.
  final referencedModelNames = <String>{};
  final components = <ExtractedComponent>[];
  for (final entry in componentClasses.entries) {
    final className = entry.key;
    final cls = entry.value;
    final file = componentFiles[className]!;
    final constructors = _extractConstructors(cls, model, referencedModelNames);
    components.add(
      ExtractedComponent(
        id: idByClassName[className]!,
        name: className,
        description: cleanDescription(rawDocComment(cls.documentationComment)) ?? '',
        file: file.repoRelativePath,
        generic: cls.typeParameters != null,
        constructors: constructors,
        tokenBindings: const [],
        composes: const [],
      ),
    );
  }
  components.sort((a, b) => a.id.compareTo(b.id));

  // Pass 3: resolve the model closure - every directly referenced model,
  // plus (recursively) types referenced in a model's own props, plus every
  // exported subtype of any sealed model referenced.
  final models = _resolveModelClosure(model, referencedModelNames);

  // Pass 4: helpers - exported top-level functions/hooks/typedefs.
  final helpers = _extractHelpers(model);

  return ExtractionResult(components: components, models: models, helpers: helpers, errors: const []);
}

/// Resolves `composes`: for each component, scans its declaring file's AST
/// for constructor-invocation expressions naming another component's class,
/// deduped and self-excluded. A separate pass because a component's file may
/// construct a component declared in a different file - the full id set
/// must be known first.
void resolveComposes(SourceModel model, List<ExtractedComponent> components) {
  final idByClassName = {for (final c in components) c.name: c.id};
  for (final component in components) {
    final file = model.fileDeclaring(component.name);
    if (file == null) continue;
    final visitor = _ComposesVisitor(idByClassName, component.name);
    file.unit.accept(visitor);
    final ids = visitor.found.toList()..sort();
    component.composes = ids;
  }
}

class _ComposesVisitor extends RecursiveAstVisitor<void> {
  _ComposesVisitor(this.idByClassName, this.selfName);

  final Map<String, String> idByClassName;
  final String selfName;
  final Set<String> found = {};

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _record(node.constructorName.type.name.lexeme);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Parse-only (no element resolution) cannot distinguish a named-
    // constructor invocation (`UtopiaFormLayout.raw(...)`) or even an
    // unprefixed default-constructor call (`UtopiaPageWrapper(...)`, which
    // without resolution parses as a bare MethodInvocation rather than an
    // InstanceCreationExpression) from an ordinary static-method call - per
    // spec, a plain identifier-name match on invocation nodes is an
    // acceptable v0 heuristic for `composes`.
    final target = node.target;
    if (target == null) {
      _record(node.methodName.name);
    } else if (target is SimpleIdentifier) {
      _record(target.name);
    }
    super.visitMethodInvocation(node);
  }

  void _record(String typeName) {
    if (typeName != selfName && idByClassName.containsKey(typeName)) {
      found.add(idByClassName[typeName]!);
    }
  }
}

// ---------------------------------------------------------------------
// Constructors + props
// ---------------------------------------------------------------------

List<ExtractedConstructor> _extractConstructors(
  ClassDeclaration cls,
  SourceModel model,
  Set<String> referencedModelNames,
) {
  final fieldDocs = _collectFieldDocs(cls);
  final fieldTypes = _collectFieldTypes(cls);
  final typeParamNames = _typeParameterNames(cls.typeParameters);
  final constructors = <ExtractedConstructor>[];
  for (final member in cls.members) {
    if (member is! ConstructorDeclaration) continue;
    if (member.factoryKeyword != null) continue; // factories are not modeled as separate constructors in v0.
    final ctorName = member.name?.lexeme ?? '';
    if (ctorName.startsWith('_')) continue;
    final props = <ExtractedProp>[];
    final parameterList = member.parameters;
    for (final param in parameterList.parameters) {
      // `super.key` (and any other super-forwarded parameter) is not a
      // widget-authored prop - it simply forwards to the Flutter Widget
      // constructor - so it is never part of the manifest's prop list.
      final normal = param is DefaultFormalParameter ? param.parameter : param;
      if (normal is SuperFormalParameter) continue;
      props.add(_extractProp(param, fieldDocs, fieldTypes, typeParamNames, model, referencedModelNames));
    }
    constructors.add(
      ExtractedConstructor(
        name: ctorName,
        description: cleanDescription(rawDocComment(member.documentationComment)),
        props: props,
      ),
    );
  }
  return constructors;
}

/// Maps `final <field>` declarations in [cls] to their doc comments, for
/// resolving a `this.x` constructor parameter's description from its backing
/// field (per spec: "doc comment of the backing field when the param is
/// `this.x`").
Map<String, Comment?> _collectFieldDocs(ClassDeclaration cls) {
  final docs = <String, Comment?>{};
  for (final member in cls.members) {
    if (member is FieldDeclaration) {
      for (final variable in member.fields.variables) {
        docs[variable.name.lexeme] = member.documentationComment;
      }
    }
  }
  return docs;
}

/// Maps `final <field>` declarations in [cls] to their declared type, used
/// as the type source for a `this.x` (field-formal) constructor parameter
/// that omits its own type annotation (the common case: the type lives on
/// the field only, and the parameter inherits it - which parse-only AST does
/// not resolve automatically since that requires element resolution).
Map<String, TypeAnnotation?> _collectFieldTypes(ClassDeclaration cls) {
  final types = <String, TypeAnnotation?>{};
  for (final member in cls.members) {
    if (member is FieldDeclaration) {
      for (final variable in member.fields.variables) {
        types[variable.name.lexeme] = member.fields.type;
      }
    }
  }
  return types;
}

Set<String> _typeParameterNames(TypeParameterList? typeParameters) {
  if (typeParameters == null) return const {};
  return typeParameters.typeParameters.map((t) => t.name.lexeme).toSet();
}

ExtractedProp _extractProp(
  FormalParameter param,
  Map<String, Comment?> fieldDocs,
  Map<String, TypeAnnotation?> fieldTypes,
  Set<String> typeParamNames,
  SourceModel model,
  Set<String> referencedModelNames,
) {
  final defaultValueCode = param is DefaultFormalParameter ? param.defaultValue?.toSource() : null;
  final normal = param is DefaultFormalParameter ? param.parameter : param;
  final name = normal.name?.lexeme ?? '';
  final required = param.isRequired;

  String dartType;
  TypeAnnotation? typeAnnotation;
  bool isFieldFormal = false;
  if (normal is SimpleFormalParameter) {
    typeAnnotation = normal.type;
    dartType = typeAnnotation?.toSource() ?? 'dynamic';
  } else if (normal is FieldFormalParameter) {
    isFieldFormal = true;
    // `this.x` almost always omits its own type annotation - the type lives
    // on the backing field - so prefer the field's declared type; fall back
    // to the parameter's own annotation on the rare explicitly-retyped case.
    typeAnnotation = fieldTypes[name] ?? normal.type;
    dartType = typeAnnotation?.toSource() ?? 'dynamic';
  } else if (normal is FunctionTypedFormalParameter) {
    final returnSrc = normal.returnType?.toSource() ?? '';
    final paramsSrc = normal.parameters.toSource();
    dartType = '$returnSrc Function$paramsSrc'.trim();
    typeAnnotation = null;
  } else {
    dartType = 'dynamic';
  }

  String? description;
  if (isFieldFormal) {
    final fieldDoc = fieldDocs[name];
    description = cleanDescription(rawDocComment(fieldDoc));
  } else if (normal is NormalFormalParameter) {
    description = cleanDescription(rawDocComment(normal.documentationComment));
  }

  final mapped = _mapPortableType(
    dartType: dartType,
    typeAnnotation: typeAnnotation,
    isFunctionTyped: normal is FunctionTypedFormalParameter,
    functionTypedNode: normal is FunctionTypedFormalParameter ? normal : null,
    typeParamNames: typeParamNames,
    model: model,
  );

  if (mapped.modelName != null) referencedModelNames.add(mapped.modelName!);
  if (mapped.itemModelName != null) referencedModelNames.add(mapped.itemModelName!);

  return ExtractedProp(
    name: name,
    type: mapped.type,
    dartType: dartType,
    required: required,
    defaultValue: defaultValueCode,
    description: description,
    enumName: mapped.enumName,
    values: mapped.values,
    itemType: mapped.itemType,
    itemDartType: mapped.itemDartType,
    modelName: mapped.modelName ?? mapped.itemModelName,
  );
}

// ---------------------------------------------------------------------
// Portable type mapping (SPEC 3.5)
// ---------------------------------------------------------------------

class _MappedType {
  const _MappedType(
    this.type, {
    this.enumName,
    this.values,
    this.itemType,
    this.itemDartType,
    this.modelName,
    this.itemModelName,
  });

  final String type;
  final String? enumName;
  final List<String>? values;
  final String? itemType;
  final String? itemDartType;
  final String? modelName;
  final String? itemModelName;
}


_MappedType _mapPortableType({
  required String dartType,
  required TypeAnnotation? typeAnnotation,
  required bool isFunctionTyped,
  required FunctionTypedFormalParameter? functionTypedNode,
  required Set<String> typeParamNames,
  required SourceModel model,
}) {
  final bareType = dartType.endsWith('?') ? dartType.substring(0, dartType.length - 1) : dartType;

  // 1. The widget's own type parameter, bare.
  if (typeParamNames.contains(bareType)) {
    return const _MappedType('generic-model');
  }

  // 2. Function types: literal `Function(...)` shapes, plus Flutter's own
  // named function-type aliases (`VoidCallback` -> callback, `WidgetBuilder`
  // -> builder-slot - it is exactly `Widget Function(BuildContext)`).
  if (isFunctionTyped) {
    final returnsWidget = _functionReturnsWidgetLike(functionTypedNode!.returnType);
    return _MappedType(returnsWidget ? 'builder-slot' : 'callback');
  }
  if (typeAnnotation is GenericFunctionType) {
    final returnsWidget = _functionReturnsWidgetLike(typeAnnotation.returnType);
    return _MappedType(returnsWidget ? 'builder-slot' : 'callback');
  }
  if (bareType == 'WidgetBuilder') {
    return const _MappedType('builder-slot');
  }
  if (bareType == 'VoidCallback') {
    return const _MappedType('callback');
  }

  // 3. Primitive/known-shape scalars.
  switch (bareType) {
    case 'String':
      return const _MappedType('string');
    case 'double':
    case 'int':
    case 'num':
      return const _MappedType('number');
    case 'bool':
      return const _MappedType('bool');
    case 'Color':
      return const _MappedType('color');
    case 'Duration':
      return const _MappedType('duration');
    case 'DateTime':
      return const _MappedType('date');
    case 'Widget':
      return const _MappedType('widget-slot');
  }

  // 4. List<X> / IList<X> -> list + itemType/itemDartType. The item type
  // recurses through this full mapping (SPEC 3.5 rule 4), so function-typed
  // items land on builder-slot/callback instead of falling to "other". The
  // item's own AST node (when available) carries function-type shapes the
  // source string alone cannot classify.
  final listItem = _listItemType(bareType);
  if (listItem != null) {
    TypeAnnotation? itemNode;
    if (typeAnnotation is NamedType) {
      final args = typeAnnotation.typeArguments?.arguments;
      if (args != null && args.length == 1) itemNode = args.first;
    }
    final itemMapped = _mapPortableType(
      dartType: listItem,
      typeAnnotation: itemNode,
      isFunctionTyped: false,
      functionTypedNode: null,
      typeParamNames: typeParamNames,
      model: model,
    );
    return _MappedType(
      'list',
      itemType: itemMapped.type,
      itemDartType: listItem,
      itemModelName: itemMapped.type == 'model' ? itemMapped.modelName : null,
    );
  }

  // 5. Exported utopia_ui enum.
  final bareName = _stripTypeArguments(bareType);
  final enumDecl = model.enumsByName[bareName];
  if (enumDecl != null) {
    final values = enumDecl.constants.map((c) => c.name.lexeme).toList();
    return _MappedType('enum', enumName: bareName, values: values);
  }

  // 6. Exported utopia_ui class.
  if (model.classesByName.containsKey(bareName)) {
    return _MappedType('model', modelName: bareName);
  }

  // 7. Anything else (EdgeInsets, Curve, Key, FocusNode, TextInputType,
  // TextInputFormatter, Axis, IconData, generics of unknown shape, ...).
  return const _MappedType('other');
}

/// Whether a `List<X>`/`IList<X>` [bareType] denotes a list, returning `X`'s
/// verbatim type text, or `null` if [bareType] is not a recognized list
/// shape.
String? _listItemType(String bareType) {
  final match = RegExp(r'^(?:List|IList)<(.+)>$').firstMatch(bareType);
  return match?.group(1);
}

/// Strips a trailing `<...>` type-argument suffix from a verbatim type name
/// (`UtopiaTableEntry<T>` -> `UtopiaTableEntry`), for looking a type up by
/// its bare declaration name in [SourceModel.classesByName]/`enumsByName`.
/// Manifest `modelName`/`enumName` fields carry only the bare declaration
/// name (schema `dartName` pattern disallows `<`/`>`); the instantiated form
/// is preserved separately in `dartType`/`itemDartType`.
String _stripTypeArguments(String typeName) {
  final index = typeName.indexOf('<');
  return index == -1 ? typeName : typeName.substring(0, index);
}

/// Whether a builder/callback's return type is `Widget`-shaped: bare
/// `Widget` or any type whose name ends with `Widget` (matching the spec's
/// "returns Widget (or Widget-suffixed)" rule).
bool _functionReturnsWidgetLike(TypeAnnotation? returnType) {
  if (returnType == null) return false;
  if (returnType is NamedType) {
    return returnType.name.lexeme == 'Widget' || returnType.name.lexeme.endsWith('Widget');
  }
  return false;
}

// ---------------------------------------------------------------------
// Model closure (pass 3)
// ---------------------------------------------------------------------

List<ExtractedModel> _resolveModelClosure(SourceModel model, Set<String> initialNames) {
  final resolved = <String, ExtractedModel>{};
  final pending = List<String>.from(initialNames);
  final seen = <String>{};

  while (pending.isNotEmpty) {
    final name = pending.removeLast();
    if (!seen.add(name)) continue;
    if (_excludedClassNames.contains(name)) continue;

    final enumDecl = model.enumsByName[name];
    if (enumDecl != null) {
      // Per spec: enums referenced only as prop types stay inline in the
      // prop (enumName+values) and do NOT get a separate models entry.
      continue;
    }

    final cls = model.classesByName[name];
    if (cls == null) continue;
    final file = model.fileDeclaring(name);
    if (file == null) continue;

    final isSealed = cls.sealedKeyword != null;
    final superName = cls.extendsClause?.superclass.name.lexeme;
    final isSubtypeOfSealed = superName != null && model.classesByName[superName]?.sealedKeyword != null;

    final referencedInThisModel = <String>{};
    final constructors = _extractConstructors(cls, model, referencedInThisModel);
    for (final refName in referencedInThisModel) {
      if (!seen.contains(refName)) pending.add(refName);
    }

    resolved[name] = ExtractedModel(
      name: name,
      description: cleanDescription(rawDocComment(cls.documentationComment)) ?? '',
      file: file.repoRelativePath,
      // typedef-backed records surface only in helpers (extracted classes
      // are always `class`/`sealed-class`; `record` is reserved for a
      // record-shaped typedef promoted to a model in a future iteration).
      kind: isSealed ? 'sealed-class' : 'class',
      supertype: isSubtypeOfSealed ? superName : null,
      constructors: constructors.isEmpty ? null : constructors,
    );

    // If this model is itself a sealed hierarchy, pull in every exported
    // subtype so the manifest lists the full closed set.
    if (isSealed) {
      for (final otherFile in model.files) {
        for (final otherCls in otherFile.classes) {
          final otherSuper = otherCls.extendsClause?.superclass.name.lexeme;
          if (otherSuper == name && isPublicName(otherCls.name.lexeme)) {
            if (!seen.contains(otherCls.name.lexeme)) pending.add(otherCls.name.lexeme);
          }
        }
      }
    }
  }

  final list = resolved.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  return list;
}

// ---------------------------------------------------------------------
// Helpers (pass 4)
// ---------------------------------------------------------------------

List<ExtractedHelper> _extractHelpers(SourceModel model) {
  final helpers = <ExtractedHelper>[];
  for (final file in model.files) {
    for (final fn in file.functions) {
      final name = fn.name.lexeme;
      if (!isPublicName(name)) continue;
      final kind = name.startsWith('use') ? 'hook' : 'function';
      helpers.add(
        ExtractedHelper(
          name: name,
          kind: kind,
          description: cleanDescription(rawDocComment(fn.documentationComment)) ?? '',
          file: file.repoRelativePath,
          signature: _functionSignature(fn),
        ),
      );
    }
    for (final typedefNode in file.typedefs) {
      if (typedefNode is! GenericTypeAlias) continue;
      final name = typedefNode.name.lexeme;
      if (!isPublicName(name)) continue;
      helpers.add(
        ExtractedHelper(
          name: name,
          kind: 'typedef',
          description: cleanDescription(rawDocComment(typedefNode.documentationComment)) ?? '',
          file: file.repoRelativePath,
          signature: 'typedef $name${typedefNode.typeParameters?.toSource() ?? ''} = ${typedefNode.type.toSource()};',
        ),
      );
    }
  }
  helpers.sort((a, b) => a.name.compareTo(b.name));
  return helpers;
}

/// Verbatim declaration signature of a top-level function, up to (not
/// including) its body: `<returnType> <name>(<params>)`.
String _functionSignature(FunctionDeclaration fn) {
  final returnTypeSrc = fn.returnType?.toSource();
  final functionExpr = fn.functionExpression;
  final typeParamsSrc = functionExpr.typeParameters?.toSource() ?? '';
  final paramsSrc = functionExpr.parameters?.toSource() ?? '()';
  final prefix = returnTypeSrc != null && returnTypeSrc.isNotEmpty ? '$returnTypeSrc ' : '';
  return '$prefix${fn.name.lexeme}$typeParamsSrc$paramsSrc';
}
