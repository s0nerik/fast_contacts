extension MapMergeExt on Map {
  // Replaces empty or missing values in map1 with values from map2.
  void mergeWith(Map map) {
    for (final key in map.keys) {
      if (!_isEmpty(map[key]) && _isEmpty(this[key])) {
        this[key] = map[key];
      }
    }
  }
}

bool _isEmpty(dynamic value) {
  return value == null ||
      value == '' ||
      value == const [] ||
      value == const <dynamic>{} ||
      value == const <dynamic, dynamic>{};
}
