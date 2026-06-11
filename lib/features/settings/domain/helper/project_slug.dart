final _nonAlphanumericRun = RegExp(r'[^a-z0-9]+');

String slugify(String name) {
  final lowered = name.toLowerCase();
  final collapsed = lowered.replaceAll(_nonAlphanumericRun, '-');
  return collapsed.replaceAll(RegExp(r'^-+|-+$'), '');
}

String uniqueSlug(String name, Iterable<String> existingSlugs) {
  final base = slugify(name);
  final taken = existingSlugs.toSet();
  if (!taken.contains(base)) return base;

  var suffix = 2;
  while (taken.contains('$base-$suffix')) {
    suffix++;
  }
  return '$base-$suffix';
}
