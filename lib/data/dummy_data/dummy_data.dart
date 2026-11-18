import '../../models/comment_model.dart';
import '../../models/notification_model.dart';
import '../../models/post_model.dart';
import '../../models/reel_model.dart';
import '../../models/story_model.dart';
import '../../models/user_model.dart';

/// All local seed content for the app. Nothing here talks to a paid service.
class AppDummyData {
  static const String currentUserId = 'u0';

  static String img(String seed, {int size = 900}) =>
      'https://picsum.photos/seed/$seed/$size/$size';

  static const List<String> videoUrls = [
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WhatCarCanYouGetForAGrand.mp4',
  ];

  static const List<String> sampleImages = [
    'https://picsum.photos/seed/demoa/1000/1000',
    'https://picsum.photos/seed/demob/1000/1000',
    'https://picsum.photos/seed/democ/1000/1000',
    'https://picsum.photos/seed/demod/1000/1000',
    'https://picsum.photos/seed/demoe/1000/1000',
    'https://picsum.photos/seed/demof/1000/1000',
    'https://picsum.photos/seed/demog/1000/1000',
    'https://picsum.photos/seed/demoh/1000/1000',
    'https://picsum.photos/seed/demoi/1000/1000',
  ];

  static const List<String> locations = [
    'Colombo, Sri Lanka',
    'Kandy, Sri Lanka',
    'Galle Fort, Sri Lanka',
    'Tokyo, Japan',
    'Paris, France',
    'New York, USA',
    'Bali, Indonesia',
    'London, UK',
    'Dubai, UAE',
    'Sydney, Australia',
  ];

  static const List<String> audioNames = [
    'Original audio • creator',
    'Sunset Lover — Petit Biscuit',
    'Blinding Lights — The Weeknd',
    'Levitating — Dua Lipa',
    'Ocean Eyes — Billie Eilish',
    'Trending sound • remix',
    'Midnight City — M83',
    'Feel Good — feel.theme',
  ];

  static const List<_SeedUser> _userSeeds = [
    _SeedUser('demo_user', 'Demo User', 'Exploring the world, one frame at a time ✨', true),
    _SeedUser('anushka.ray', 'Anushka Ray', 'Photographer | Storyteller | Coffee ☕', true),
    _SeedUser('kavindu_dev', 'Kavindu Perera', 'Flutter developer & design enthusiast', false),
    _SeedUser('maya.studio', 'Maya Studio', 'Art, fashion & everything in between', true),
    _SeedUser('nimal.travels', 'Nimal Travels', 'Wanderlust | Sri Lanka 🇱🇰', false),
    _SeedUser('sara.waves', 'Sara Fernando', 'Ocean lover 🌊 | Surf | Sunsets', false),
    _SeedUser('thefooddiary', 'The Food Diary', 'Eat. Cook. Repeat. 🍜', true),
    _SeedUser('arjun.clicks', 'Arjun Clicks', 'Street photography & night lights', false),
    _SeedUser('lini.designs', 'Lini Designs', 'UI/UX designer • minimal everything', false),
    _SeedUser('chamila.fit', 'Chamila Fitness', 'Stronger every day 💪', false),
    _SeedUser('raj.music', 'Raj Music', 'Producer | Piano | Late night sessions 🎹', true),
    _SeedUser('dilu.paints', 'Dilu Paints', 'Colour is life 🎨', false),
    _SeedUser('wild.lanka', 'Wild Lanka', 'Wildlife & nature photography', true),
    _SeedUser('ishara.reads', 'Ishara Reads', 'Books, tea and quiet mornings 📚', false),
    _SeedUser('noah.skates', 'Noah Skates', 'Skateboarding & city culture', false),
    _SeedUser('aisha.style', 'Aisha Style', 'Style inspiration | Outfit diary', true),
    _SeedUser('saman.builds', 'Saman Builds', 'Architecture & interiors', false),
    _SeedUser('nethmi.bakes', 'Nethmi Bakes', 'Home baker 🧁 | Recipes & treats', false),
    _SeedUser('yoga.with.me', 'Yoga With Me', 'Mindful movement & calm living 🧘', false),
    _SeedUser('mike.motion', 'Mike Motion', 'Motion designer | 3D & animation', true),
    _SeedUser('travelwith.ami', 'Travel With Ami', 'Passport stamps & mountain air', false),
    _SeedUser('kids.of.sun', 'Kids Of Sun', 'Little moments, big love ☀️', false),
    _SeedUser('dennis.tech', 'Dennis Tech', 'Gadgets, code & coffee', false),
    _SeedUser('ruth.plants', 'Ruth Plants', 'Plant parent | Urban jungle 🌿', false),
    _SeedUser('offical.ig', 'Instagram Inspired', 'A local demo community', true),
  ];

  static List<UserModel> buildUsers() {
    final users = <UserModel>[];
    for (var i = 0; i < _userSeeds.length; i++) {
      final seed = _userSeeds[i];
      final followers = <String>[];
      final following = <String>[];
      for (var j = 0; j < _userSeeds.length; j++) {
        if (i == j) continue;
        if ((i * 5 + j * 3) % 7 < 3) followers.add('u$j');
        if ((i * 3 + j * 5) % 7 < 3) following.add('u$j');
      }
      if (i == 0) {
        following.addAll(['u1', 'u2', 'u3', 'u4', 'u5', 'u6', 'u7', 'u8']);
        followers.addAll(['u1', 'u2', 'u3', 'u5', 'u8', 'u11', 'u15', 'u20']);
      }
      users.add(UserModel(
        id: 'u$i',
        username: seed.username,
        displayName: seed.displayName,
        bio: seed.bio,
        website: i % 3 == 0 ? 'https://${seed.username.replaceAll('.', '')}.com' : '',
        profileImage: img('avatar$i', size: 300),
        isVerified: seed.verified,
        isPrivate: i == 14 || i == 19,
        followers: followers.toSet().toList(),
        following: following.toSet().toList(),
        email: i == 0 ? 'demo@instagram.local' : '${seed.username.replaceAll('.', '')}@mail.com',
        password: i == 0 ? 'demo123' : 'pass123',
      ));
    }
    return users;
  }

  static const List<String> _captions = [
    'Golden hour feels like a warm hug 🌅 #sunset #photography',
    'A little reminder to slow down and breathe 🌿 #mindful #life',
    'Found this hidden gem on my morning walk ✨ #explore #city',
    'Weekend plans: good food and better company 🍜 #foodie',
    'New edits finally done. What do you think? 🎨 #design #art',
    'Somewhere between the mountains and the clouds ☁️ #travel #nature',
    'Late night code, early morning coffee ☕ #developer #flutter',
    'Colour palette of the day 🧡 #inspiration #style',
    'The ocean always knows how to fix a bad day 🌊 #beach #summer',
    'Tiny details make the biggest difference 📷 #details #photo',
    'Made this from scratch and I am weirdly proud of it 🧁 #baking',
    'Move your body, quiet your mind 💪 #fitness #wellness',
    'Throwback to the best trip of the year 🧳 #throwback #friends',
    'Studio lights, good vibes, endless ideas 💡 #creative #studio',
    'Books and rain: the perfect combination 📚 #books #cosy',
    'Every frame tells a story. This one is about hope 🕊️ #storytelling',
    'Building things that make people smile 🏗️ #architecture #design',
    'Green is my happy place 🌱 #plants #home',
  ];

  static List<PostModel> buildPosts() {
    final posts = <PostModel>[];
    final now = DateTime.now();
    for (var i = 0; i < 34; i++) {
      final author = i % 5 == 0 ? 1 + (i ~/ 5) % 24 : (i * 7 + 3) % 25;
      final imageCount = i % 7 == 0 ? 3 : (i % 4 == 0 ? 2 : 1);
      final urls = <String>[
        for (var k = 0; k < imageCount; k++) img('post${i}_$k'),
      ];
      final caption = _captions[i % _captions.length];
      posts.add(PostModel(
        id: 'p$i',
        userId: 'u$author',
        caption: i == 0
            ? '$caption #instagram #clone'
            : caption,
        imageUrls: urls,
        location: i % 4 == 0 ? locations[i % locations.length] : '',
        createdAt: now.subtract(Duration(hours: i * 5 + 2)),
        likeCount: 120 + ((i * 937) % 18400),
        taggedUserIds: i % 6 == 0
            ? ['u${(i + 2) % 25}', 'u${(i + 9) % 25}']
            : (i % 3 == 0 ? ['u${(i + 4) % 25}'] : const []),
      ));
    }
    return posts;
  }

  static List<ReelModel> buildReels() {
    final reels = <ReelModel>[];
    final now = DateTime.now();
    final captions = [
      'POV: you finally tried that thing you kept postponing ✨ #motivation',
      '30 seconds of pure colour 🎨 #art #process',
      'My favourite spot in the city at night 🌃 #citylights',
      'Easy recipe you can make tonight 🍜 #food #quickrecipe',
      'A day in my life, no filter ☀️ #dailyvlog',
      'This sound is stuck in my head 🎵 #trending',
      'Nothing beats the first sip of coffee ☕ #morning',
      'Behind the scenes of a photoshoot 📸 #bts',
      'Little dance break because why not 💃 #fun',
      'Sunset drive with the windows down 🌅 #drive',
      'How I organise my creative space 🧠 #productivity',
      'Testing a new camera lens, thoughts? 🎥 #gear',
      'A quiet moment before the chaos begins 🕊️ #calm',
      'Travel montage | places that felt like home ✈️ #travel',
      'Before / after: studio makeover 🛠️ #diy',
      'Just vibes and good music 🎧 #vibes',
    ];
    for (var i = 0; i < 16; i++) {
      reels.add(ReelModel(
        id: 'r$i',
        userId: 'u${(i * 3 + 2) % 25}',
        videoUrl: videoUrls[i % videoUrls.length],
        thumbnailUrl: img('reel$i', size: 800),
        caption: captions[i],
        audioName: audioNames[i % audioNames.length],
        likeCount: 800 + ((i * 2137) % 92000),
        shareCount: 20 + i * 13,
        createdAt: now.subtract(Duration(days: i)),
      ));
    }
    return reels;
  }

  static List<StoryModel> buildStories() {
    final stories = <StoryModel>[];
    final now = DateTime.now();
    final captions = [
      'Morning coffee ☕', 'On my way ✈️', 'New drop 🔥', 'Studio time 🎨',
      'Sunset 🌅', 'Weekend vibes', 'Beach day 🌊', 'Late night thoughts',
      'Just because ✨', 'Behind the scenes', 'Good news! 🎉', 'Take a guess 👀',
      'Freshly baked 🧁', 'Training day 💪', 'Hello from Tokyo 🗼',
      'Today\'s palette 🎨', 'A little update', 'See you soon 👋',
    ];
    for (var i = 0; i < 18; i++) {
      stories.add(StoryModel(
        id: 's$i',
        userId: 'u${i % 25}',
        mediaUrl: i % 6 == 4 ? videoUrls[i % videoUrls.length] : img('story$i', size: 800),
        isVideo: i % 6 == 4,
        caption: captions[i],
        createdAt: now.subtract(Duration(minutes: i * 37)),
      ));
    }
    return stories;
  }

  static List<CommentModel> buildComments() {
    final texts = [
      'This is absolutely stunning! 😍', 'Love the colours here 🔥',
      'Where was this taken? 📍', 'Amazing work as always 👏',
      'Needed this today, thank you ✨', 'Okay this is goals 😭',
      'The composition is perfect 📷', 'Can you share the preset?',
      'So happy for you! 🎉', 'This made me smile ☺️',
      'Adding this to my inspiration board', 'Incredible detail 👌',
      'Come visit me in Colombo 🇱🇰', 'More of this please! 🙏',
      'The vibes are immaculate 🌊', 'How did you edit this?',
      'Simply beautiful ❤️', 'Saving this for later 🔖',
      'Your best post yet!', 'This is pure magic ✨',
      'That light though ☀️', 'So creative! 💡',
      'I agree completely', 'Check out my latest post too!',
      'This is exactly what I needed to see 👀', 'Woah 🤩',
      'Classy as always', 'Love the energy here 💃',
      'Perfect timing for this post', 'Following you from today ✅',
    ];
    final comments = <CommentModel>[];
    final now = DateTime.now();
    for (var i = 0; i < 30; i++) {
      comments.add(CommentModel(
        id: 'c$i',
        targetId: i < 21 ? 'p${i % 8}' : 'r${i % 6}',
        targetType: i < 21 ? 'post' : 'reel',
        userId: 'u${(i * 4 + 1) % 25}',
        text: texts[i],
        createdAt: now.subtract(Duration(minutes: i * 19 + 5)),
        likeCount: i * 3,
      ));
    }
    return comments;
  }

  static List<NotificationModel> buildNotifications() {
    final data = [
      ('u1', 'like', 'liked your photo.'),
      ('u3', 'follow', 'started following you.'),
      ('u6', 'comment', 'commented: "This is gorgeous!"'),
      ('u11', 'like', 'liked your reel.'),
      ('u15', 'mention', 'mentioned you in a comment.'),
      ('u2', 'follow', 'started following you.'),
      ('u8', 'like', 'and 12 others liked your post.'),
      ('u17', 'comment', 'commented: "Love this 🔥"'),
      ('u20', 'like', 'liked your photo.'),
      ('u5', 'follow', 'started following you.'),
      ('u13', 'mention', 'tagged you in a photo.'),
      ('u9', 'like', 'liked your comment.'),
    ];
    final now = DateTime.now();
    return [
      for (var i = 0; i < data.length; i++)
        NotificationModel(
          id: 'n$i',
          userId: data[i].$1,
          type: data[i].$2,
          text: data[i].$3,
          createdAt: now.subtract(Duration(hours: i * 4 + 1)),
          isRead: i > 4,
        ),
    ];
  }
}

class _SeedUser {
  final String username;
  final String displayName;
  final String bio;
  final bool verified;
  const _SeedUser(this.username, this.displayName, this.bio, this.verified);
}
