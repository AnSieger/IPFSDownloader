String formatBytes(num? bytes, {int decimals = 1}) {
  if (bytes == null || bytes < 0) return '–';
  if (bytes < 1024) return '${bytes.round()} B';
  const units = <String>['KB', 'MB', 'GB', 'TB', 'PB'];
  var value = bytes.toDouble();
  var unitIndex = -1;
  do {
    value /= 1024;
    unitIndex++;
  } while (value >= 1024 && unitIndex < units.length - 1);
  final precision = value >= 100 ? 0 : decimals;
  return '${value.toStringAsFixed(precision)} ${units[unitIndex]}';
}

String formatSpeed(double bytesPerSecond) {
  if (bytesPerSecond <= 0) return '–';
  return '${formatBytes(bytesPerSecond)}/s';
}

String formatDuration(Duration? duration) {
  if (duration == null) return '–';
  if (duration <= Duration.zero) return '0 s';
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  if (hours > 0) return '$hours Std. $minutes Min.';
  if (minutes > 0) return '$minutes Min. $seconds Sek.';
  return '$seconds Sek.';
}

String compactCid(String cid, {int leading = 10, int trailing = 7}) {
  if (cid.length <= leading + trailing + 1) return cid;
  return '${cid.substring(0, leading)}…${cid.substring(cid.length - trailing)}';
}

String formatCount(int count, String singular, String plural) =>
    count == 1 ? '1 $singular' : '$count $plural';
