String safePrefix(String? s, int length) {
  if (s == null) return '';
  if (s.length <= length) return s;
  return s.substring(0, length);
}


