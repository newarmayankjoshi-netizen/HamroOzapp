Map<String, dynamic> toStringKeyMap(dynamic input) {
  if (input is Map) {
    final out = <String, dynamic>{};
    input.forEach((k, v) {
      out[k.toString()] = v;
    });
    return out;
  }
  return <String, dynamic>{};
}
