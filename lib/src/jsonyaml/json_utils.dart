library util.json;

import 'package:path/path.dart' as path;
import 'package:option/option.dart';

final _p = path.url;

abstract class Jsonable {
  Map toJson();
}

//List fromJsonList(List l, create(i)) =>
//    l != null ? l.map(create).toList(growable: false) : [];
//
//List toJsonList(List l) =>
//    l != null ? l.map((i) => i.toJson()).toList(growable: false) : [];
//
//Map toJsonObject(o) => o != null ? o.toJson() : null;
//
//fromJsonObject(Map json, create(i)) => json != null ? create(json) : null;
//
//String toJsonUrl(Uri url) => url != null ? url.toString() : null;
//
//Map toJsonOption(Option o) => o.map((v) => v.toJson()).getOrElse(() => {});
//
//void addToJsonOption(Option o, Map json, String fieldName) {
//  o.map((v) => v.toJson()).map((j) {
//    json[fieldName] = j;
//  });
//}

JsonBuilder get buildJson => new JsonBuilder();
JsonParser parseJson(Map j) => new JsonParser(j);

class JsonBuilder {
  final Map json = {};

  void addOption(String fieldName, Option o) {
    o.map((v) => v.toJson()).map((j) {
      json[fieldName] = j;
    });
  }

  void addObject(String fieldName, o) {
    if (o != null) {
      json[fieldName] = o.toJson();
    }
  }

  void add(String fieldName, v) {
    if (v != null) {
      json[fieldName] = _transformValue(v);
    }
  }

  _transformValue(value, [transform(v)]) {
    if (transform != null) {
      return transform(value);
    }
    if (value is Jsonable) {
      return value.toJson();
    }
    if (value is Map) {
      final result = {};
      (value as Map).forEach((k, v) {
        result[k] = _transformValue(value, null);
      });
      return result;
    }
    if (value is Iterable) {
      return (value as Iterable).map((v) => _transformValue(v, null)).toList();
    }
    return value.toString();
  }
}

_identity(v) => v;

class JsonParser {
  final Map _json;
  final bool _consumeMap;

  JsonParser(Map json, {bool consumeMap: false})
      : this._json = consumeMap ? new Map.from(json) : json,
        this._consumeMap = consumeMap;

  List list(String fieldName, [create(i) = _identity]) {
    final List l = _getField(fieldName);
    return l != null ? l.map(create).toList(growable: false) : [];
  }

  single(String fieldName, [create(i) = _identity]) {
    final j = _getField(fieldName);
    return j != null ? create(j) : null;
  }

  Map mapValues(String fieldName, [create(i) = _identity]) {
    Map result = {};
    final Map m = _getField(fieldName);

    m.forEach((k, v) {
      result[k] = create(v);
    });

    return result;
  }

  Option option(String fieldName, [create(i) = _identity]) =>
      new Option(single(fieldName, create));

  _getField(String fieldName) =>
      _consumeMap ? _json.remove(fieldName) : _json[fieldName];

  Map get unconsumed {
    if (!_consumeMap) {
      throw new StateError('unconsumed called on non consuming parser');
    }

    return _json;
  }
}
