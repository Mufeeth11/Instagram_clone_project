class Formatters {
  static String count(int value) {
    if (value >= 1000000) {
      final v = value / 1000000;
      return '${v.toStringAsFixed(v >= 10 ? 0 : 1)}M';
    }
    if (value >= 1000) {
      final v = value / 1000;
      return '${v.toStringAsFixed(v >= 10 ? 0 : 1)}K';
    }
    return value.toString();
  }

  static String timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7}w';
    if (diff.inDays < 365) return '${diff.inDays ~/ 30}mo';
    return '${diff.inDays ~/ 365}y';
  }

  static String fullDate(DateTime time) =>
      '${time.day}/${time.month}/${time.year}';

  static List<String> hashtags(String text) => RegExp(r'#\w+')
      .allMatches(text)
      .map((m) => m.group(0)!)
      .toList();

  static String stripHashtags(String text) =>
      text.replaceAll(RegExp(r'#\w+'), '').trim();
}
