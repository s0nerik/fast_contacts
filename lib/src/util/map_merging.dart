// Replaces empty or missing values in map1 with values from map2.
void mergeMapValues(Map map1, Map map2) {
  for (final key in map2.keys) {
    if (!_isEmpty(map2[key]) && _isEmpty(map1[key])) {
      map1[key] = map2[key];
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
