// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: camel_case_types

import 'dart:typed_data';

import 'package:objectbox/flatbuffers/flat_buffers.dart' as fb;
import 'package:objectbox/internal.dart'; // generated code can access "internal" functionality
import 'package:objectbox/objectbox.dart';

import 'models/model_search.dart';

export 'package:objectbox/objectbox.dart'; // so that callers only have to import this file

final _entities = <ModelEntity>[
  ModelEntity(
      id: const IdUid(1, 1300888286620171038),
      name: 'Search',
      lastPropertyId: const IdUid(7, 876347798358778359),
      flags: 0,
      properties: <ModelProperty>[
        ModelProperty(
            id: const IdUid(1, 626322754835402977),
            name: 'id',
            type: 6,
            flags: 1),
        ModelProperty(
            id: const IdUid(2, 805347721755060495),
            name: 'date',
            type: 9,
            flags: 0),
        ModelProperty(
            id: const IdUid(3, 4379675612182026945),
            name: 'title',
            type: 9,
            flags: 0),
        ModelProperty(
            id: const IdUid(4, 1864623405138966659),
            name: 'url',
            type: 9,
            flags: 0),
        ModelProperty(
            id: const IdUid(5, 8957970468578435878),
            name: 'isHistory',
            type: 1,
            flags: 0),
        ModelProperty(
            id: const IdUid(6, 5239133102376816446),
            name: 'isIncognito',
            type: 1,
            flags: 0),
        ModelProperty(
            id: const IdUid(7, 876347798358778359),
            name: 'hashValue',
            type: 6,
            flags: 0)
      ],
      relations: <ModelRelation>[],
      backlinks: <ModelBacklink>[])
];

/// Open an ObjectBox store with the model declared in this file.
Store openStore(
        {String? directory,
        int? maxDBSizeInKB,
        int? fileMode,
        int? maxReaders,
        bool queriesCaseSensitiveDefault = true,
        String? macosApplicationGroup}) =>
    Store(getObjectBoxModel(),
        directory: directory,
        maxDBSizeInKB: maxDBSizeInKB,
        fileMode: fileMode,
        maxReaders: maxReaders,
        queriesCaseSensitiveDefault: queriesCaseSensitiveDefault,
        macosApplicationGroup: macosApplicationGroup);

/// ObjectBox model definition, pass it to [Store] - Store(getObjectBoxModel())
ModelDefinition getObjectBoxModel() {
  final model = ModelInfo(
      entities: _entities,
      lastEntityId: const IdUid(1, 1300888286620171038),
      lastIndexId: const IdUid(0, 0),
      lastRelationId: const IdUid(0, 0),
      lastSequenceId: const IdUid(0, 0),
      retiredEntityUids: const [],
      retiredIndexUids: const [],
      retiredPropertyUids: const [],
      retiredRelationUids: const [],
      modelVersion: 5,
      modelVersionParserMinimum: 5,
      version: 1);

  final bindings = <Type, EntityDefinition>{
    Search: EntityDefinition<Search>(
        model: _entities[0],
        toOneRelations: (Search object) => [],
        toManyRelations: (Search object) => {},
        getId: (Search object) => object.id,
        setId: (Search object, int id) {
          object.id = id;
        },
        objectToFB: (Search object, fb.Builder fbb) {
          final dateOffset = fbb.writeString(object.date);
          final titleOffset = fbb.writeString(object.title);
          final urlOffset = fbb.writeString(object.url);
          fbb.startTable(8);
          fbb.addInt64(0, object.id);
          fbb.addOffset(1, dateOffset);
          fbb.addOffset(2, titleOffset);
          fbb.addOffset(3, urlOffset);
          fbb.addBool(4, object.isHistory);
          fbb.addBool(5, object.isIncognito);
          fbb.addInt64(6, object.hashValue);
          fbb.finish(fbb.endTable());
          return object.id;
        },
        objectFromFB: (Store store, ByteData fbData) {
          final buffer = fb.BufferContext(fbData);
          final rootOffset = buffer.derefObject(0);

          final object = Search(
              date:
                  const fb.StringReader().vTableGet(buffer, rootOffset, 6, ''),
              title:
                  const fb.StringReader().vTableGet(buffer, rootOffset, 8, ''),
              url:
                  const fb.StringReader().vTableGet(buffer, rootOffset, 10, ''),
              isHistory: const fb.BoolReader()
                  .vTableGet(buffer, rootOffset, 12, false),
              hashValue:
                  const fb.Int64Reader().vTableGet(buffer, rootOffset, 16, 0),
              isIncognito: const fb.BoolReader()
                  .vTableGet(buffer, rootOffset, 14, false))
            ..id = const fb.Int64Reader().vTableGet(buffer, rootOffset, 4, 0);

          return object;
        })
  };

  return ModelDefinition(model, bindings);
}

/// [Search] entity fields to define ObjectBox queries.
class Search_ {
  /// see [Search.id]
  static final id = QueryIntegerProperty<Search>(_entities[0].properties[0]);

  /// see [Search.date]
  static final date = QueryStringProperty<Search>(_entities[0].properties[1]);

  /// see [Search.title]
  static final title = QueryStringProperty<Search>(_entities[0].properties[2]);

  /// see [Search.url]
  static final url = QueryStringProperty<Search>(_entities[0].properties[3]);

  /// see [Search.isHistory]
  static final isHistory =
      QueryBooleanProperty<Search>(_entities[0].properties[4]);

  /// see [Search.isIncognito]
  static final isIncognito =
      QueryBooleanProperty<Search>(_entities[0].properties[5]);

  /// see [Search.hashValue]
  static final hashValue =
      QueryIntegerProperty<Search>(_entities[0].properties[6]);
}
