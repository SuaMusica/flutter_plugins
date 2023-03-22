// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'previous_playlist_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters

extension GetPreviousPlaylistMusicsCollection on Isar {
  IsarCollection<PreviousPlaylistMusics> get previousPlaylistMusics =>
      this.collection();
}

const PreviousPlaylistMusicsSchema = CollectionSchema(
  name: r'PreviousPlaylistMusics',
  id: 1445680560601406369,
  properties: {
    r'musics': PropertySchema(
      id: 0,
      name: r'musics',
      type: IsarType.stringList,
    )
  },
  estimateSize: _previousPlaylistMusicsEstimateSize,
  serialize: _previousPlaylistMusicsSerialize,
  deserialize: _previousPlaylistMusicsDeserialize,
  deserializeProp: _previousPlaylistMusicsDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _previousPlaylistMusicsGetId,
  getLinks: _previousPlaylistMusicsGetLinks,
  attach: _previousPlaylistMusicsAttach,
  version: '3.0.5',
);

int _previousPlaylistMusicsEstimateSize(
  PreviousPlaylistMusics object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final list = object.musics;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += value.length * 3;
        }
      }
    }
  }
  return bytesCount;
}

void _previousPlaylistMusicsSerialize(
  PreviousPlaylistMusics object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeStringList(offsets[0], object.musics);
}

PreviousPlaylistMusics _previousPlaylistMusicsDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PreviousPlaylistMusics(
    id: id,
    musics: reader.readStringList(offsets[0]),
  );
  return object;
}

P _previousPlaylistMusicsDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringList(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _previousPlaylistMusicsGetId(PreviousPlaylistMusics object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _previousPlaylistMusicsGetLinks(
    PreviousPlaylistMusics object) {
  return [];
}

void _previousPlaylistMusicsAttach(
    IsarCollection<dynamic> col, Id id, PreviousPlaylistMusics object) {
  object.id = id;
}

extension PreviousPlaylistMusicsQueryWhereSort
    on QueryBuilder<PreviousPlaylistMusics, PreviousPlaylistMusics, QWhere> {
  QueryBuilder<PreviousPlaylistMusics, PreviousPlaylistMusics, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PreviousPlaylistMusicsQueryWhere on QueryBuilder<
    PreviousPlaylistMusics, PreviousPlaylistMusics, QWhereClause> {
  QueryBuilder<PreviousPlaylistMusics, PreviousPlaylistMusics,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<PreviousPlaylistMusics, PreviousPlaylistMusics,
      QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<PreviousPlaylistMusics, PreviousPlaylistMusics,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PreviousPlaylistMusics, PreviousPlaylistMusics,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PreviousPlaylistMusics, PreviousPlaylistMusics,
      QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension PreviousPlaylistMusicsQueryFilter on QueryBuilder<
    PreviousPlaylistMusics, PreviousPlaylistMusics, QFilterCondition> {
  QueryBuilder<PreviousPlaylistMusics, PreviousPlaylistMusics,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PreviousPlaylistMusics, PreviousPlaylistMusics,
      QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PreviousPlaylistMusics, PreviousPlaylistMusics,
      QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PreviousPlaylistMusics, PreviousPlaylistMusics,
      QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PreviousPlaylistMusics, PreviousPlaylistMusics,
      QAfterFilterCondition> musicsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'musics',
      ));
    });
  }

  QueryBuilder<PreviousPlaylistMusics, PreviousPlaylistMusics,
      QAfterFilterCondition> musicsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'musics',
      ));
    });
  }

  QueryBuilder<PreviousPlaylistMusics, PreviousPlaylistMusics,
      QAfterFilterCondition> musicsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'musics',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PreviousPlaylistMusics, PreviousPlaylistMusics,
      QAfterFilterCondition> musicsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'musics',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PreviousPlaylistMusics, PreviousPlaylistMusics,
      QAfterFilterCondition> musicsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'musics',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PreviousPlaylistMusics, PreviousPlaylistMusics,
      QAfterFilterCondition> musicsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'musics',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PreviousPlaylistMusics, PreviousPlaylistMusics,
      QAfterFilterCondition> musicsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'musics',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PreviousPlaylistMusics, PreviousPlaylistMusics,
      QAfterFilterCondition> musicsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'musics',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PreviousPlaylistMusics, PreviousPlaylistMusics,
          QAfterFilterCondition>
      musicsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'musics',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PreviousPlaylistMusics, PreviousPlaylistMusics,
          QAfterFilterCondition>
      musicsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'musics',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PreviousPlaylistMusics, PreviousPlaylistMusics,
      QAfterFilterCondition> musicsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'musics',
        value: '',
      ));
    });
  }

  QueryBuilder<PreviousPlaylistMusics, PreviousPlaylistMusics,
      QAfterFilterCondition> musicsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'musics',
        value: '',
      ));
    });
  }

  QueryBuilder<PreviousPlaylistMusics, PreviousPlaylistMusics,
      QAfterFilterCondition> musicsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'musics',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<PreviousPlaylistMusics, PreviousPlaylistMusics,
      QAfterFilterCondition> musicsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'musics',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<PreviousPlaylistMusics, PreviousPlaylistMusics,
      QAfterFilterCondition> musicsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'musics',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<PreviousPlaylistMusics, PreviousPlaylistMusics,
      QAfterFilterCondition> musicsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'musics',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<PreviousPlaylistMusics, PreviousPlaylistMusics,
      QAfterFilterCondition> musicsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'musics',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<PreviousPlaylistMusics, PreviousPlaylistMusics,
      QAfterFilterCondition> musicsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'musics',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension PreviousPlaylistMusicsQueryObject on QueryBuilder<
    PreviousPlaylistMusics, PreviousPlaylistMusics, QFilterCondition> {}

extension PreviousPlaylistMusicsQueryLinks on QueryBuilder<
    PreviousPlaylistMusics, PreviousPlaylistMusics, QFilterCondition> {}

extension PreviousPlaylistMusicsQuerySortBy
    on QueryBuilder<PreviousPlaylistMusics, PreviousPlaylistMusics, QSortBy> {}

extension PreviousPlaylistMusicsQuerySortThenBy on QueryBuilder<
    PreviousPlaylistMusics, PreviousPlaylistMusics, QSortThenBy> {
  QueryBuilder<PreviousPlaylistMusics, PreviousPlaylistMusics, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PreviousPlaylistMusics, PreviousPlaylistMusics, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }
}

extension PreviousPlaylistMusicsQueryWhereDistinct
    on QueryBuilder<PreviousPlaylistMusics, PreviousPlaylistMusics, QDistinct> {
  QueryBuilder<PreviousPlaylistMusics, PreviousPlaylistMusics, QDistinct>
      distinctByMusics() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'musics');
    });
  }
}

extension PreviousPlaylistMusicsQueryProperty on QueryBuilder<
    PreviousPlaylistMusics, PreviousPlaylistMusics, QQueryProperty> {
  QueryBuilder<PreviousPlaylistMusics, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PreviousPlaylistMusics, List<String>?, QQueryOperations>
      musicsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'musics');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters

extension GetPreviousPlaylistCurrentIndexCollection on Isar {
  IsarCollection<PreviousPlaylistCurrentIndex>
      get previousPlaylistCurrentIndexs => this.collection();
}

const PreviousPlaylistCurrentIndexSchema = CollectionSchema(
  name: r'PreviousPlaylistCurrentIndex',
  id: -9036091697598573141,
  properties: {
    r'currentIndex': PropertySchema(
      id: 0,
      name: r'currentIndex',
      type: IsarType.long,
    )
  },
  estimateSize: _previousPlaylistCurrentIndexEstimateSize,
  serialize: _previousPlaylistCurrentIndexSerialize,
  deserialize: _previousPlaylistCurrentIndexDeserialize,
  deserializeProp: _previousPlaylistCurrentIndexDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _previousPlaylistCurrentIndexGetId,
  getLinks: _previousPlaylistCurrentIndexGetLinks,
  attach: _previousPlaylistCurrentIndexAttach,
  version: '3.0.5',
);

int _previousPlaylistCurrentIndexEstimateSize(
  PreviousPlaylistCurrentIndex object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _previousPlaylistCurrentIndexSerialize(
  PreviousPlaylistCurrentIndex object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.currentIndex);
}

PreviousPlaylistCurrentIndex _previousPlaylistCurrentIndexDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PreviousPlaylistCurrentIndex(
    currentIndex: reader.readLongOrNull(offsets[0]),
    id: id,
  );
  return object;
}

P _previousPlaylistCurrentIndexDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _previousPlaylistCurrentIndexGetId(PreviousPlaylistCurrentIndex object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _previousPlaylistCurrentIndexGetLinks(
    PreviousPlaylistCurrentIndex object) {
  return [];
}

void _previousPlaylistCurrentIndexAttach(
    IsarCollection<dynamic> col, Id id, PreviousPlaylistCurrentIndex object) {
  object.id = id;
}

extension PreviousPlaylistCurrentIndexQueryWhereSort on QueryBuilder<
    PreviousPlaylistCurrentIndex, PreviousPlaylistCurrentIndex, QWhere> {
  QueryBuilder<PreviousPlaylistCurrentIndex, PreviousPlaylistCurrentIndex,
      QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PreviousPlaylistCurrentIndexQueryWhere on QueryBuilder<
    PreviousPlaylistCurrentIndex, PreviousPlaylistCurrentIndex, QWhereClause> {
  QueryBuilder<PreviousPlaylistCurrentIndex, PreviousPlaylistCurrentIndex,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<PreviousPlaylistCurrentIndex, PreviousPlaylistCurrentIndex,
      QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<PreviousPlaylistCurrentIndex, PreviousPlaylistCurrentIndex,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PreviousPlaylistCurrentIndex, PreviousPlaylistCurrentIndex,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PreviousPlaylistCurrentIndex, PreviousPlaylistCurrentIndex,
      QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension PreviousPlaylistCurrentIndexQueryFilter on QueryBuilder<
    PreviousPlaylistCurrentIndex,
    PreviousPlaylistCurrentIndex,
    QFilterCondition> {
  QueryBuilder<PreviousPlaylistCurrentIndex, PreviousPlaylistCurrentIndex,
      QAfterFilterCondition> currentIndexIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'currentIndex',
      ));
    });
  }

  QueryBuilder<PreviousPlaylistCurrentIndex, PreviousPlaylistCurrentIndex,
      QAfterFilterCondition> currentIndexIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'currentIndex',
      ));
    });
  }

  QueryBuilder<PreviousPlaylistCurrentIndex, PreviousPlaylistCurrentIndex,
      QAfterFilterCondition> currentIndexEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currentIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<PreviousPlaylistCurrentIndex, PreviousPlaylistCurrentIndex,
      QAfterFilterCondition> currentIndexGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currentIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<PreviousPlaylistCurrentIndex, PreviousPlaylistCurrentIndex,
      QAfterFilterCondition> currentIndexLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currentIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<PreviousPlaylistCurrentIndex, PreviousPlaylistCurrentIndex,
      QAfterFilterCondition> currentIndexBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currentIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PreviousPlaylistCurrentIndex, PreviousPlaylistCurrentIndex,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PreviousPlaylistCurrentIndex, PreviousPlaylistCurrentIndex,
      QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PreviousPlaylistCurrentIndex, PreviousPlaylistCurrentIndex,
      QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PreviousPlaylistCurrentIndex, PreviousPlaylistCurrentIndex,
      QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension PreviousPlaylistCurrentIndexQueryObject on QueryBuilder<
    PreviousPlaylistCurrentIndex,
    PreviousPlaylistCurrentIndex,
    QFilterCondition> {}

extension PreviousPlaylistCurrentIndexQueryLinks on QueryBuilder<
    PreviousPlaylistCurrentIndex,
    PreviousPlaylistCurrentIndex,
    QFilterCondition> {}

extension PreviousPlaylistCurrentIndexQuerySortBy on QueryBuilder<
    PreviousPlaylistCurrentIndex, PreviousPlaylistCurrentIndex, QSortBy> {
  QueryBuilder<PreviousPlaylistCurrentIndex, PreviousPlaylistCurrentIndex,
      QAfterSortBy> sortByCurrentIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentIndex', Sort.asc);
    });
  }

  QueryBuilder<PreviousPlaylistCurrentIndex, PreviousPlaylistCurrentIndex,
      QAfterSortBy> sortByCurrentIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentIndex', Sort.desc);
    });
  }
}

extension PreviousPlaylistCurrentIndexQuerySortThenBy on QueryBuilder<
    PreviousPlaylistCurrentIndex, PreviousPlaylistCurrentIndex, QSortThenBy> {
  QueryBuilder<PreviousPlaylistCurrentIndex, PreviousPlaylistCurrentIndex,
      QAfterSortBy> thenByCurrentIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentIndex', Sort.asc);
    });
  }

  QueryBuilder<PreviousPlaylistCurrentIndex, PreviousPlaylistCurrentIndex,
      QAfterSortBy> thenByCurrentIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentIndex', Sort.desc);
    });
  }

  QueryBuilder<PreviousPlaylistCurrentIndex, PreviousPlaylistCurrentIndex,
      QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PreviousPlaylistCurrentIndex, PreviousPlaylistCurrentIndex,
      QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }
}

extension PreviousPlaylistCurrentIndexQueryWhereDistinct on QueryBuilder<
    PreviousPlaylistCurrentIndex, PreviousPlaylistCurrentIndex, QDistinct> {
  QueryBuilder<PreviousPlaylistCurrentIndex, PreviousPlaylistCurrentIndex,
      QDistinct> distinctByCurrentIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currentIndex');
    });
  }
}

extension PreviousPlaylistCurrentIndexQueryProperty on QueryBuilder<
    PreviousPlaylistCurrentIndex,
    PreviousPlaylistCurrentIndex,
    QQueryProperty> {
  QueryBuilder<PreviousPlaylistCurrentIndex, int, QQueryOperations>
      idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PreviousPlaylistCurrentIndex, int?, QQueryOperations>
      currentIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentIndex');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters

extension GetPreviousPlaylistPositionCollection on Isar {
  IsarCollection<PreviousPlaylistPosition> get previousPlaylistPositions =>
      this.collection();
}

const PreviousPlaylistPositionSchema = CollectionSchema(
  name: r'PreviousPlaylistPosition',
  id: 4468986416954213317,
  properties: {
    r'duration': PropertySchema(
      id: 0,
      name: r'duration',
      type: IsarType.double,
    ),
    r'position': PropertySchema(
      id: 1,
      name: r'position',
      type: IsarType.double,
    )
  },
  estimateSize: _previousPlaylistPositionEstimateSize,
  serialize: _previousPlaylistPositionSerialize,
  deserialize: _previousPlaylistPositionDeserialize,
  deserializeProp: _previousPlaylistPositionDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _previousPlaylistPositionGetId,
  getLinks: _previousPlaylistPositionGetLinks,
  attach: _previousPlaylistPositionAttach,
  version: '3.0.5',
);

int _previousPlaylistPositionEstimateSize(
  PreviousPlaylistPosition object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _previousPlaylistPositionSerialize(
  PreviousPlaylistPosition object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.duration);
  writer.writeDouble(offsets[1], object.position);
}

PreviousPlaylistPosition _previousPlaylistPositionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PreviousPlaylistPosition(
    duration: reader.readDouble(offsets[0]),
    id: id,
    position: reader.readDouble(offsets[1]),
  );
  return object;
}

P _previousPlaylistPositionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _previousPlaylistPositionGetId(PreviousPlaylistPosition object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _previousPlaylistPositionGetLinks(
    PreviousPlaylistPosition object) {
  return [];
}

void _previousPlaylistPositionAttach(
    IsarCollection<dynamic> col, Id id, PreviousPlaylistPosition object) {
  object.id = id;
}

extension PreviousPlaylistPositionQueryWhereSort on QueryBuilder<
    PreviousPlaylistPosition, PreviousPlaylistPosition, QWhere> {
  QueryBuilder<PreviousPlaylistPosition, PreviousPlaylistPosition, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PreviousPlaylistPositionQueryWhere on QueryBuilder<
    PreviousPlaylistPosition, PreviousPlaylistPosition, QWhereClause> {
  QueryBuilder<PreviousPlaylistPosition, PreviousPlaylistPosition,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<PreviousPlaylistPosition, PreviousPlaylistPosition,
      QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<PreviousPlaylistPosition, PreviousPlaylistPosition,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PreviousPlaylistPosition, PreviousPlaylistPosition,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PreviousPlaylistPosition, PreviousPlaylistPosition,
      QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension PreviousPlaylistPositionQueryFilter on QueryBuilder<
    PreviousPlaylistPosition, PreviousPlaylistPosition, QFilterCondition> {
  QueryBuilder<PreviousPlaylistPosition, PreviousPlaylistPosition,
      QAfterFilterCondition> durationEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'duration',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PreviousPlaylistPosition, PreviousPlaylistPosition,
      QAfterFilterCondition> durationGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'duration',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PreviousPlaylistPosition, PreviousPlaylistPosition,
      QAfterFilterCondition> durationLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'duration',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PreviousPlaylistPosition, PreviousPlaylistPosition,
      QAfterFilterCondition> durationBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'duration',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PreviousPlaylistPosition, PreviousPlaylistPosition,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PreviousPlaylistPosition, PreviousPlaylistPosition,
      QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PreviousPlaylistPosition, PreviousPlaylistPosition,
      QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PreviousPlaylistPosition, PreviousPlaylistPosition,
      QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PreviousPlaylistPosition, PreviousPlaylistPosition,
      QAfterFilterCondition> positionEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'position',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PreviousPlaylistPosition, PreviousPlaylistPosition,
      QAfterFilterCondition> positionGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'position',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PreviousPlaylistPosition, PreviousPlaylistPosition,
      QAfterFilterCondition> positionLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'position',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PreviousPlaylistPosition, PreviousPlaylistPosition,
      QAfterFilterCondition> positionBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'position',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension PreviousPlaylistPositionQueryObject on QueryBuilder<
    PreviousPlaylistPosition, PreviousPlaylistPosition, QFilterCondition> {}

extension PreviousPlaylistPositionQueryLinks on QueryBuilder<
    PreviousPlaylistPosition, PreviousPlaylistPosition, QFilterCondition> {}

extension PreviousPlaylistPositionQuerySortBy on QueryBuilder<
    PreviousPlaylistPosition, PreviousPlaylistPosition, QSortBy> {
  QueryBuilder<PreviousPlaylistPosition, PreviousPlaylistPosition, QAfterSortBy>
      sortByDuration() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'duration', Sort.asc);
    });
  }

  QueryBuilder<PreviousPlaylistPosition, PreviousPlaylistPosition, QAfterSortBy>
      sortByDurationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'duration', Sort.desc);
    });
  }

  QueryBuilder<PreviousPlaylistPosition, PreviousPlaylistPosition, QAfterSortBy>
      sortByPosition() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'position', Sort.asc);
    });
  }

  QueryBuilder<PreviousPlaylistPosition, PreviousPlaylistPosition, QAfterSortBy>
      sortByPositionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'position', Sort.desc);
    });
  }
}

extension PreviousPlaylistPositionQuerySortThenBy on QueryBuilder<
    PreviousPlaylistPosition, PreviousPlaylistPosition, QSortThenBy> {
  QueryBuilder<PreviousPlaylistPosition, PreviousPlaylistPosition, QAfterSortBy>
      thenByDuration() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'duration', Sort.asc);
    });
  }

  QueryBuilder<PreviousPlaylistPosition, PreviousPlaylistPosition, QAfterSortBy>
      thenByDurationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'duration', Sort.desc);
    });
  }

  QueryBuilder<PreviousPlaylistPosition, PreviousPlaylistPosition, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PreviousPlaylistPosition, PreviousPlaylistPosition, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PreviousPlaylistPosition, PreviousPlaylistPosition, QAfterSortBy>
      thenByPosition() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'position', Sort.asc);
    });
  }

  QueryBuilder<PreviousPlaylistPosition, PreviousPlaylistPosition, QAfterSortBy>
      thenByPositionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'position', Sort.desc);
    });
  }
}

extension PreviousPlaylistPositionQueryWhereDistinct on QueryBuilder<
    PreviousPlaylistPosition, PreviousPlaylistPosition, QDistinct> {
  QueryBuilder<PreviousPlaylistPosition, PreviousPlaylistPosition, QDistinct>
      distinctByDuration() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'duration');
    });
  }

  QueryBuilder<PreviousPlaylistPosition, PreviousPlaylistPosition, QDistinct>
      distinctByPosition() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'position');
    });
  }
}

extension PreviousPlaylistPositionQueryProperty on QueryBuilder<
    PreviousPlaylistPosition, PreviousPlaylistPosition, QQueryProperty> {
  QueryBuilder<PreviousPlaylistPosition, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PreviousPlaylistPosition, double, QQueryOperations>
      durationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'duration');
    });
  }

  QueryBuilder<PreviousPlaylistPosition, double, QQueryOperations>
      positionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'position');
    });
  }
}
