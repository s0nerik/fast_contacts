// Replaces empty or missing values in map1 with values from map2.
void mergeMapValues(Map map1, Map map2) {
  for (final key in map2.keys) {
    if (map1[key] == null ||
        map1[key] == '' ||
        map1[key] == const [] ||
        map1[key] == const <dynamic>{} ||
        map1[key] == const <dynamic, dynamic>{}) {
      map1[key] = map2[key];
    }
  }
}
