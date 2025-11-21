import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Populates Firestore with editable, realistic dummy data so the UI looks full.
/// Safe to re-run (uses merge semantics).
class DemoDataPopulator {
  final FirebaseFirestore db;
  final FirebaseStorage storage;
  final Random _random = Random();

  DemoDataPopulator(this.db, this.storage);

  Future<void> populateAll() async {
    await _populateUsers();
    await _populateVenues();
    await _populateCoaches();
    await _populateTeams();
    await _populateTournaments();
    await _populateProducts();
    await _populateCommunityPosts();
    await _populateReviews();
    await _populateChats();
  }

  Future<void> _populateUsers() async {
    final users = [
      {
        'id': 'player_001',
        'name': 'Ali Raza',
        'role': 'athlete',
        'sport': 'Football',
        'rating': 4.7,
        'photoUrl': await _uploadPlaceholder('user1'),
      },
      {
        'id': 'coach_001',
        'name': 'Sara Khan',
        'role': 'coach',
        'sport': 'Tennis',
        'rating': 4.9,
        'photoUrl': await _uploadPlaceholder('user2'),
      },
      {
        'id': 'admin_001',
        'name': 'Admin Team',
        'role': 'admin',
        'photoUrl': await _uploadPlaceholder('user3'),
      },
    ];
    for (final u in users) {
      await db.collection('users').doc(u['id'] as String).set(u, SetOptions(merge: true));
    }
  }

  Future<void> _populateVenues() async {
    final venues = [
      {
        'id': 'venue_0',
        'name': 'Aurora Sports Dome',
        'location': 'Islamabad',
        'sport': 'Football',
        'themeColor': '#FF6F61',
        'amenities': ['Locker Rooms', 'LED Lighting', 'On-site Cafe'],
        'pricePerHour': 1900,
        'image': 'venue1',
      },
      {
        'id': 'venue_1',
        'name': 'Velocity Cricket Arena',
        'location': 'Rawalpindi',
        'sport': 'Cricket',
        'themeColor': '#42A5F5',
        'amenities': ['Practice Nets', 'Coach Lounge', 'Live Scoreboard'],
        'pricePerHour': 2100,
        'image': 'venue2',
      },
      {
        'id': 'venue_2',
        'name': 'Zenith Tennis Courts',
        'location': 'Lahore',
        'sport': 'Tennis',
        'themeColor': '#AB47BC',
        'amenities': ['Ball Machine', 'Shaded Seating', 'Hydration Bar'],
        'pricePerHour': 1700,
        'image': 'venue3',
      },
      {
        'id': 'venue_3',
        'name': 'Summit Multi-Sports Complex',
        'location': 'Karachi',
        'sport': 'Multi-sport',
        'themeColor': '#26C6DA',
        'amenities': ['Indoor Track', 'Spa & Sauna', 'Nutrition Kiosk'],
        'pricePerHour': 2400,
        'image': 'venue4',
      },
      {
        'id': 'venue_4',
        'name': 'Neon Nights Futsal',
        'location': 'Islamabad',
        'sport': 'Futsal',
        'themeColor': '#FF7043',
        'amenities': ['Glow Turf', 'DJ Booth', 'Snack Bar'],
        'pricePerHour': 1600,
        'image': 'venue5',
      },
    ];

    for (int i = 0; i < venues.length; i++) {
      final venue = venues[i];
      await db.collection('venues').doc(venue['id'] as String).set({
        'name': venue['name'],
        'location': venue['location'],
        'sport': venue['sport'],
        'rating': 4.2 + _random.nextDouble() * 0.8,
        'imageUrl': await _uploadPlaceholder(venue['image'] as String),
        'pricePerHour': venue['pricePerHour'],
        'amenities': venue['amenities'],
        'themeColor': venue['themeColor'],
        'gallery': [
          await _uploadPlaceholder(venue['image'] as String),
          await _uploadPlaceholder('post${(i % 3) + 1}'),
        ],
      }, SetOptions(merge: true));
    }
  }

  Future<void> _populateCoaches() async {
    final coaches = [
      {
        'id': 'coach_0',
        'name': 'Coach Imran Malik',
        'sport': 'Cricket',
        'tagline': 'Perfect your swing with precision drills.',
      },
      {
        'id': 'coach_1',
        'name': 'Coach Fatima Rehman',
        'sport': 'Football',
        'tagline': 'Mastering footwork and strategic play.',
      },
      {
        'id': 'coach_2',
        'name': 'Coach Bilal Ahmed',
        'sport': 'Badminton',
        'tagline': 'Speed meets accuracy on court.',
      },
      {
        'id': 'coach_3',
        'name': 'Coach Mehak Ali',
        'sport': 'Tennis',
        'tagline': 'Build confidence with championship drills.',
      },
      {
        'id': 'coach_4',
        'name': 'Coach Umar Qureshi',
        'sport': 'Basketball',
        'tagline': 'Elevate your game with elite conditioning.',
      },
    ];

    for (int i = 0; i < coaches.length; i++) {
      final coach = coaches[i];
      await db.collection('coachListings').doc(coach['id'] as String).set({
        'name': coach['name'],
        'sport': coach['sport'],
        'pricePerHour': 2000 + i * 450,
        'experience': '${4 + i} years',
        'rating': 4.4 + _random.nextDouble() * 0.6,
        'imageUrl': await _uploadPlaceholder(['coach1', 'coach2', 'coach3'][i % 3]),
        'tagline': coach['tagline'],
        'accentColor': ['#FF8A65', '#4DD0E1', '#BA68C8', '#81C784', '#FFD54F'][i],
        'specialties': [
          'Personalized Training Plans',
          'Live Match Analysis',
          'Weekly Progress Reports'
        ],
      }, SetOptions(merge: true));
    }
  }

  Future<void> _populateTeams() async {
    final teams = [
      {
        'id': 'team_0',
        'name': 'Falcon Flyers',
        'sport': 'Football',
        'logo': 'team1',
        'colors': ['#FF7043', '#311B92'],
      },
      {
        'id': 'team_1',
        'name': 'Titan Blitz',
        'sport': 'Cricket',
        'logo': 'team2',
        'colors': ['#29B6F6', '#1B5E20'],
      },
      {
        'id': 'team_2',
        'name': 'Warrior Pulse',
        'sport': 'Basketball',
        'logo': 'team3',
        'colors': ['#AB47BC', '#FFEB3B'],
      },
      {
        'id': 'team_3',
        'name': 'Neon Strikers',
        'sport': 'Futsal',
        'logo': 'team4',
        'colors': ['#26C6DA', '#FF5252'],
      },
    ];

    for (int i = 0; i < teams.length; i++) {
      final team = teams[i];
      await db.collection('teams').doc(team['id'] as String).set({
        'name': team['name'],
        'members': ['player_001', 'coach_001'],
        'captain': 'player_001',
        'sport': team['sport'],
        'logoUrl': await _uploadPlaceholder('team${(i % 3) + 1}'),
        'wins': 6 + _random.nextInt(6),
        'losses': _random.nextInt(4),
        'upcomingMatches': [
          {
            'opponent': 'Galaxy United',
            'date': DateTime.now().add(const Duration(days: 4)),
            'location': 'Aurora Sports Dome',
          },
          {
            'opponent': 'Velocity Crew',
            'date': DateTime.now().add(const Duration(days: 11)),
            'location': 'Summit Multi-Sports Complex',
          },
        ],
        'brandColors': team['colors'],
      }, SetOptions(merge: true));
    }
  }

  Future<void> _populateTournaments() async {
    final tournaments = [
      {
        'id': 'tournament_0',
        'name': 'Championship 2024',
        'sport': 'Football',
        'image': 'tournament1',
        'palette': '#FF6F61',
      },
      {
        'id': 'tournament_1',
        'name': 'Emerald Cup 2025',
        'sport': 'Cricket',
        'image': 'tournament2',
        'palette': '#26A69A',
      },
      {
        'id': 'tournament_2',
        'name': 'Neon Slam 3x3',
        'sport': 'Basketball',
        'image': 'tournament3',
        'palette': '#7E57C2',
      },
    ];

    for (int i = 0; i < tournaments.length; i++) {
      final tournament = tournaments[i];
      await db.collection('tournaments').doc(tournament['id'] as String).set({
        'name': tournament['name'],
        'sport': tournament['sport'],
        'teams': ['team_0', 'team_1', 'team_2'],
        'startDate': DateTime.now().add(Duration(days: 5 + i * 6)),
        'endDate': DateTime.now().add(Duration(days: 8 + i * 6)),
        'prizePool': 500000 + (i * 150000),
        'imageUrl': await _uploadPlaceholder(tournament['image'] as String),
        'themeColor': tournament['palette'],
        'highlight': 'Featuring live DJs, glow visuals, and halftime skill showcases.',
        'schedule': [
          {
            'round': 'Group Stage',
            'date': DateTime.now().add(Duration(days: 5 + i * 6)),
          },
          {
            'round': 'Semi Finals',
            'date': DateTime.now().add(Duration(days: 7 + i * 6)),
          },
          {
            'round': 'Final',
            'date': DateTime.now().add(Duration(days: 8 + i * 6)),
          },
        ],
      }, SetOptions(merge: true));
    }
  }

  Future<void> _populateProducts() async {
    for (int i = 0; i < 6; i++) {
      await db.collection('products').doc('product_$i').set({
        'title': ['Cricket Bat', 'Football', 'Jersey', 'Shoes', 'Racket', 'Gloves'][i],
        'price': 2000 + i * 400,
        'category': ['Gear', 'Apparel', 'Shoes'][i % 3],
        'rating': 4 + _random.nextDouble(),
        'imageUrl': await _uploadPlaceholder('product${(i % 3) + 1}'),
        'accentColor': ['#FF8A80', '#FFD180', '#80D8FF', '#A7FFEB', '#EA80FC', '#B9F6CA'][i],
      }, SetOptions(merge: true));
    }
  }

  Future<void> _populateCommunityPosts() async {
    final posts = [
      {
        'id': 'post_0',
        'body':
            'Energy was unreal at Neon Nights Futsal today! ⚡ Who wants in for tomorrow?',
        'image': 'post1',
        'tags': ['#futsal', '#nightlife', '#playaround'],
        'dominantColor': '#FF6F61',
      },
      {
        'id': 'post_1',
        'body':
            'Coach Fatima dropped the sharpest midfield drills. Feeling game-ready!',
        'image': 'post2',
        'tags': ['#football', '#coachfatima', '#skills'],
        'dominantColor': '#42A5F5',
      },
      {
        'id': 'post_2',
        'body':
            'Aurora Sports Dome lit up for the Falcon Flyers! Massive win tonight! 🔥',
        'image': 'post3',
        'tags': ['#falcons', '#matchday', '#victory'],
        'dominantColor': '#AB47BC',
      },
      {
        'id': 'post_3',
        'body':
            'Hydration bar + recovery stretch session = best post-match ritual.',
        'image': 'post1',
        'tags': ['#recovery', '#wellness', '#summitcomplex'],
        'dominantColor': '#26C6DA',
      },
      {
        'id': 'post_4',
        'body':
            'Who’s joining the Neon Slam 3x3? Bring that street flair and flair!',
        'image': 'post2',
        'tags': ['#basketball', '#3x3', '#neonslam'],
        'dominantColor': '#FF8A65',
      },
    ];

    for (final post in posts) {
      await db.collection('community_posts').doc(post['id'] as String).set({
        'authorId': 'player_001',
        'body': post['body'],
        'imageUrl': await _uploadPlaceholder(post['image'] as String),
        'createdAt': FieldValue.serverTimestamp(),
        'likes': 18 + _random.nextInt(40),
        'likeUserIds': ['coach_001', 'player_001', 'admin_001'],
        'tags': post['tags'],
        'dominantColor': post['dominantColor'],
        'commentCount': 0,
      }, SetOptions(merge: true));
    }

    await _populateCommunityComments(posts.map((post) => post['id'] as String).toList());
  }

  Future<void> _populateCommunityComments(List<String> postIds) async {
    final comments = [
      {
        'authorId': 'coach_001',
        'body': 'Loved the intensity! Let’s schedule a team scrimmage soon.',
        'moodColor': '#4DD0E1',
      },
      {
        'authorId': 'admin_001',
        'body': 'Highlights will be up on the app by 9 PM. Stay tuned!',
        'moodColor': '#FFD54F',
      },
      {
        'authorId': 'player_001',
        'body': 'Tag your squad and claim those prime slots before they disappear!',
        'moodColor': '#BA68C8',
      },
      {
        'authorId': 'coach_001',
        'body': 'Remember to hydrate and stretch! Recovery corner is open.',
        'moodColor': '#81C784',
      },
    ];

    for (final postId in postIds) {
      for (int i = 0; i < comments.length; i++) {
        final comment = comments[i];
        await db
            .collection('community_posts')
            .doc(postId)
            .collection('comments')
            .doc('comment_$i')
            .set({
          'authorId': comment['authorId'],
          'body': comment['body'],
          'createdAt': FieldValue.serverTimestamp(),
          'likes': _random.nextInt(12),
          'moodColor': comment['moodColor'],
        }, SetOptions(merge: true));
      }
      await db.collection('community_posts').doc(postId).set({
        'commentCount': comments.length,
      }, SetOptions(merge: true));
    }
  }

  Future<void> _populateReviews() async {
    final reviews = [
      {
        'collection': 'venueReviews',
        'docId': 'venue_0_review_0',
        'data': {
          'venueId': 'venue_0',
          'authorId': 'player_001',
          'rating': 4.8,
          'title': 'Lights, music, energy!',
          'comment': 'Aurora Sports Dome is a vibe. Loved the curated playlists and neon ambience.',
          'createdAt': FieldValue.serverTimestamp(),
          'highlightColor': '#FF6F61',
        },
      },
      {
        'collection': 'venueReviews',
        'docId': 'venue_1_review_0',
        'data': {
          'venueId': 'venue_1',
          'authorId': 'coach_001',
          'rating': 4.6,
          'title': 'Perfect wicket conditions',
          'comment': 'Velocity Arena keeps the pitch tight and the tech support even tighter.',
          'createdAt': FieldValue.serverTimestamp(),
          'highlightColor': '#42A5F5',
        },
      },
      {
        'collection': 'coachReviews',
        'docId': 'coach_1_review_0',
        'data': {
          'coachId': 'coach_1',
          'authorId': 'player_001',
          'rating': 5.0,
          'title': 'Game-changing training',
          'comment': 'Coach Fatima revamped our midfield transitions in two sessions.',
          'createdAt': FieldValue.serverTimestamp(),
          'highlightColor': '#26C6DA',
        },
      },
      {
        'collection': 'coachReviews',
        'docId': 'coach_3_review_0',
        'data': {
          'coachId': 'coach_3',
          'authorId': 'admin_001',
          'rating': 4.7,
          'title': 'Technique + vibe',
          'comment': 'Balanced drills with positive energy. Team morale is soaring.',
          'createdAt': FieldValue.serverTimestamp(),
          'highlightColor': '#AB47BC',
        },
      },
      {
        'collection': 'productReviews',
        'docId': 'product_2_review_0',
        'data': {
          'productId': 'product_2',
          'authorId': 'player_001',
          'rating': 4.5,
          'title': 'Tactile jersey feel',
          'comment': 'Breathable fabric with a bold gradient. Looks elite on the pitch.',
          'createdAt': FieldValue.serverTimestamp(),
          'highlightColor': '#FF8A65',
        },
      },
      {
        'collection': 'productReviews',
        'docId': 'product_4_review_0',
        'data': {
          'productId': 'product_4',
          'authorId': 'coach_001',
          'rating': 4.9,
          'title': 'String tension perfection',
          'comment': 'Racket comes pre-strung with pro specs. Drop shots feel buttery.',
          'createdAt': FieldValue.serverTimestamp(),
          'highlightColor': '#26A69A',
        },
      },
    ];

    for (final review in reviews) {
      await db.collection(review['collection'] as String).doc(review['docId'] as String).set(
            review['data'] as Map<String, dynamic>,
            SetOptions(merge: true),
          );
    }
  }

  Future<void> _populateChats() async {
    final threads = [
      {
        'id': 'thread_demo_1',
        'participants': ['player_001', 'coach_001'],
        'accentColor': '#29B6F6',
        'messages': [
          {
            'fromId': 'player_001',
            'body': 'Hi Coach! Neon Nights slot free tomorrow?',
          },
          {
            'fromId': 'coach_001',
            'body': 'Yes! 5 PM works. I’ll bring the agility cones.',
          },
          {
            'fromId': 'player_001',
            'body': 'Perfect—adding the team now. Need any gear?',
          },
          {
            'fromId': 'coach_001',
            'body': 'We’re good. Hydration packs are stocked. See you there!',
          },
        ],
      },
      {
        'id': 'thread_review_feedback',
        'participants': ['player_001', 'admin_001'],
        'accentColor': '#FF7043',
        'messages': [
          {
            'fromId': 'admin_001',
            'body': 'Thanks for the glowing review on Aurora Dome! Want to feature it?',
          },
          {
            'fromId': 'player_001',
            'body': 'Absolutely! That neon setup deserves the spotlight.',
          },
          {
            'fromId': 'admin_001',
            'body': 'We’ll publish it with your highlight reel tomorrow morning.',
          },
          {
            'fromId': 'player_001',
            'body': 'Let me know if you need more clips or quotes.',
          },
        ],
      },
      {
        'id': 'thread_team_strategy',
        'participants': ['player_001', 'coach_001', 'admin_001'],
        'accentColor': '#AB47BC',
        'messages': [
          {
            'fromId': 'coach_001',
            'body': 'Sharing tactical board for Emerald Cup. Check file attachments.',
          },
          {
            'fromId': 'admin_001',
            'body': 'Venue lighting set to “Aurora Mode” for warmups.',
          },
          {
            'fromId': 'player_001',
            'body': 'Team loves it! Uploading our stretch routine as well.',
          },
          {
            'fromId': 'coach_001',
            'body': 'Great! Let’s sync 30 mins early for walkthrough.',
          },
        ],
      },
    ];

    for (final thread in threads) {
      await db.collection('messageThreads').doc(thread['id'] as String).set({
        'participants': thread['participants'],
        'updatedAt': FieldValue.serverTimestamp(),
        'accentColor': thread['accentColor'],
      }, SetOptions(merge: true));

      final messages = thread['messages'] as List<Map<String, String>>;
      for (int i = 0; i < messages.length; i++) {
        final message = messages[i];
        await db
            .collection('messageThreads')
            .doc(thread['id'] as String)
            .collection('messages')
            .doc('msg_$i')
            .set({
          'fromId': message['fromId'],
          'body': message['body'],
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'delivered',
        }, SetOptions(merge: true));
      }
    }
  }

  /// Uploads a bundled local placeholder image to Storage if not already there.
  Future<String> _uploadPlaceholder(String name) async {
    final ref = storage.ref('demo/$name.jpg');
    try {
      await ref.getDownloadURL();
      return await ref.getDownloadURL();
    } catch (_) {
      final data = await rootBundle.load('assets/demo/placeholders/$name.jpg');
      await ref.putData(
        data.buffer.asUint8List(),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await ref.getDownloadURL();
    }
  }
}

