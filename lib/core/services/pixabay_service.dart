import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// A free Mixkit track paired with a Pixabay video by its tags.
class _AudioTrack {
  const _AudioTrack(this.keywords, this.url, this.title);

  final List<String> keywords;
  final String url;
  final String title;
}

const _audioTracks = <_AudioTrack>[
  _AudioTrack(['forest', 'wood', 'tree', 'nature', 'garden'],
      'https://assets.mixkit.co/music/138/138.mp3', 'Forest Treasure'),
  _AudioTrack(['flower', 'bloom', 'petal', 'butterfly', 'plant'],
      'https://assets.mixkit.co/music/493/493.mp3', 'Beautiful Dream'),
  _AudioTrack(['city', 'urban', 'street', 'traffic', 'night'],
      'https://assets.mixkit.co/music/623/623.mp3', 'Deep Urban'),
  _AudioTrack(['travel', 'drive', 'car', 'road', 'journey', 'discover'],
      'https://assets.mixkit.co/music/32/32.mp3', 'Driving Ambition'),
  _AudioTrack(['food', 'cook', 'kitchen', 'party', 'dance', 'groove'],
      'https://assets.mixkit.co/music/872/872.mp3', 'Gimme that Groove!'),
  _AudioTrack(['sport', 'run', 'gym', 'fitness', 'football', 'basketball'],
      'https://assets.mixkit.co/music/51/51.mp3', 'Sports Highlights'),
  _AudioTrack(['beach', 'sea', 'ocean', 'island', 'summer'],
      'https://assets.mixkit.co/music/250/250.mp3', 'Island Beat'),
  _AudioTrack(['water', 'river', 'sky', 'calm', 'serene', 'mountain'],
      'https://assets.mixkit.co/music/443/443.mp3', 'Serene View'),
];

const _defaultAudio = _AudioTrack(
  [''],
  'https://assets.mixkit.co/music/587/587.mp3',
  'Discover',
);

_AudioTrack _audioFor(String tags) {
  final lowered = tags.toLowerCase();
  for (final track in _audioTracks) {
    if (track.keywords.any(lowered.contains)) return track;
  }
  return _defaultAudio;
}

/// A Pixabay video, reduced to what the Reels screen actually needs.
class PixabayVideo {
  const PixabayVideo({
    required this.id,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.tags,
    required this.author,
    required this.duration,
    required this.pageUrl,
    required this.audioUrl,
    required this.audioTitle,
  });

  final String id;
  final String videoUrl;
  final String thumbnailUrl;
  final String tags;
  final String author;
  final int duration;
  final String pageUrl;
  final String audioUrl;
  final String audioTitle;

  factory PixabayVideo.fromJson(Map<String, dynamic> json) {
    final videos = json['videos'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final medium = videos['medium'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final small =
        videos['small'] as Map<String, dynamic>? ?? const <String, dynamic>{};

    // "medium" is available for every Pixabay video; fall back to "small".
    final rendition =
        (medium['url'] as String? ?? '').trim().isNotEmpty ? medium : small;
    final tags = (json['tags'] as String? ?? '').trim();
    final audio = _audioFor(tags);

    return PixabayVideo(
      id: (json['id'] ?? '').toString(),
      videoUrl: (rendition['url'] as String? ?? '').trim(),
      thumbnailUrl: (rendition['thumbnail'] as String? ?? '').trim(),
      tags: tags,
      author: (json['user'] as String? ?? '').trim(),
      duration: json['duration'] is int ? json['duration'] as int : 0,
      pageUrl: (json['pageURL'] as String? ?? '').trim(),
      audioUrl: audio.url,
      audioTitle: audio.title,
    );
  }
}

/// Supplies working video URLs to the Reels tab without touching app state.
class PixabayService {
  // Demo key provided for this project. In production, keep keys off the
  // client and proxy requests through a backend instead.
  static const _apiKey = '58696321-7bb693b7e85709755de7c4d7a';
  static const _endpoint = 'https://pixabay.com/api/videos/';
  static const _cacheLifetime = Duration(hours: 24);

  static List<PixabayVideo>? _cache;
  static DateTime? _cachedAt;

  static Future<List<PixabayVideo>> fetchVideos() async {
    final now = DateTime.now();
    final cached = _cache;
    final cachedAt = _cachedAt;
    if (cached != null &&
        cachedAt != null &&
        cached.isNotEmpty &&
        now.difference(cachedAt) < _cacheLifetime) {
      return cached;
    }

    final uri = Uri.parse(_endpoint).replace(queryParameters: {
      'key': _apiKey,
      'video_type': 'film',
      'per_page': '30',
      'safesearch': 'true',
      'order': 'popular',
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception('Pixabay request failed (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final hits = decoded['hits'] as List<dynamic>? ?? const <dynamic>[];
    final videos = hits
        .whereType<Map<String, dynamic>>()
        .map(PixabayVideo.fromJson)
        .where((video) => video.videoUrl.isNotEmpty)
        .toList(growable: false);

    if (videos.isEmpty) {
      throw Exception('Pixabay returned no playable videos');
    }

    _cache = videos;
    _cachedAt = now;
    return videos;
  }
}

final pixabayVideosProvider =
    FutureProvider<List<PixabayVideo>>((ref) => PixabayService.fetchVideos());
