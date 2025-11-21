#!/usr/bin/env node

/**
 * Seed script for the public player profile (Phase 1 bootstrap).
 *
 * Usage:
 *   node scripts/seed_public_profile.js \
 *     --serviceAccount=/absolute/path/to/serviceAccount.json \
 *     --projectId=your-firebase-project-id
 *
 * The script will:
 * 1. Ensure the player account exists (creates if missing) and marks email as verified.
 * 2. Populate core `users`, `player_profiles`, and `public_profiles` documents.
 * 3. Create example collections for stats, posts, matchmaking gallery, and reviews.
 *
 * IMPORTANT:
 * - This script uses firebase-admin. Install dependencies first:
 *      npm install firebase-admin yargs
 * - Run with Node.js >= 18.
 * - Review the payloads before running in production.
 */

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');
const yargs = require('yargs/yargs');

const argv = yargs(process.argv.slice(2))
  .option('serviceAccount', {
    type: 'string',
    demandOption: true,
    describe: 'Path to the Firebase service account JSON file',
  })
  .option('projectId', {
    type: 'string',
    demandOption: true,
    describe: 'Firebase project ID',
  })
  .option('email', {
    type: 'string',
    default: 'mahmadafzal880@gmail.com',
    describe: 'Seed user email',
  })
  .option('password', {
    type: 'string',
    default: 'AHmed5114@',
    describe: 'Seed user password',
  })
  .help()
  .alias('help', 'h').argv;

const serviceAccountPath = path.resolve(argv.serviceAccount);
if (!fs.existsSync(serviceAccountPath)) {
  console.error(`Service account file not found at ${serviceAccountPath}`);
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(require(serviceAccountPath)),
  projectId: argv.projectId,
});

const auth = admin.auth();
const firestore = admin.firestore();

const seedEmail = argv.email;
const seedPassword = argv.password;

async function ensureUser() {
  try {
    const userRecord = await auth.getUserByEmail(seedEmail);
    console.log(`ℹ️  Found existing user: ${userRecord.uid}`);

    if (!userRecord.emailVerified) {
      await auth.updateUser(userRecord.uid, { emailVerified: true });
      console.log('✅ Marked email as verified');
    }

    return userRecord.uid;
  } catch (error) {
    if (error.code !== 'auth/user-not-found') {
      throw error;
    }

    console.log('ℹ️  Creating new user...');
    const { uid } = await auth.createUser({
      email: seedEmail,
      password: seedPassword,
      emailVerified: true,
      displayName: 'Ayaan Malik',
      photoURL:
        'https://res.cloudinary.com/demo/image/upload/v1700000000/playaround/ayaan/profile.jpg',
    });
    console.log(`✅ Created user ${uid}`);
    return uid;
  }
}

function baseUserDoc(uid) {
  const now = admin.firestore.Timestamp.now();
  return {
    uid,
    fullName: 'Ayaan Malik',
    nickname: 'SkyStride',
    bio:
      'Explosive winger comfortable on either flank. Thrives in high-tempo systems and brings data-driven match prep to every squad.',
    gender: 'male',
    age: 24,
    location: 'Karachi, Pakistan',
    latitude: 24.8607,
    longitude: 67.0011,
    profilePictureUrl:
      'https://res.cloudinary.com/demo/image/upload/v1700000000/playaround/ayaan/profile.jpg',
    profilePhotos: [
      'https://res.cloudinary.com/demo/image/upload/v1700000000/playaround/matchmaking/ayaan_1.jpg',
      'https://res.cloudinary.com/demo/image/upload/v1700000000/playaround/matchmaking/ayaan_2.jpg',
      'https://res.cloudinary.com/demo/image/upload/v1700000000/playaround/matchmaking/ayaan_3.jpg',
    ],
    followers: [
      {
        userId: 'follower_lara',
        name: 'Lara Ibrahim',
        avatarUrl:
          'https://res.cloudinary.com/demo/image/upload/v1700000000/playaround/followers/lara.jpg',
        isFollowing: true,
      },
      {
        userId: 'follower_nabeel',
        name: 'Nabeel Farooq',
        avatarUrl:
          'https://res.cloudinary.com/demo/image/upload/v1700000000/playaround/followers/nabeel.jpg',
        isFollowing: true,
      },
      {
        userId: 'follower_emma',
        name: 'Emma Johnson',
        avatarUrl:
          'https://res.cloudinary.com/demo/image/upload/v1700000000/playaround/followers/emma.jpg',
        isFollowing: false,
      },
    ],
    following: [
      {
        userId: 'following_mikael',
        name: 'Coach Mikael',
        avatarUrl:
          'https://res.cloudinary.com/demo/image/upload/v1700000000/playaround/following/mikael.jpg',
        isFollowing: true,
      },
      {
        userId: 'following_samira',
        name: 'Coach Samira',
        avatarUrl:
          'https://res.cloudinary.com/demo/image/upload/v1700000000/playaround/following/samira.jpg',
        isFollowing: true,
      },
      {
        userId: 'following_thunder_fc',
        name: 'Thunder FC',
        avatarUrl:
          'https://res.cloudinary.com/demo/image/upload/v1700000000/playaround/teams/thunder_fc.jpg',
        isFollowing: true,
      },
    ],
    mutualConnections: [
      {
        userId: 'follower_lara',
        name: 'Lara Ibrahim',
        avatarUrl:
          'https://res.cloudinary.com/demo/image/upload/v1700000000/playaround/followers/lara.jpg',
        isFollowing: true,
      },
      {
        userId: 'following_mikael',
        name: 'Coach Mikael',
        avatarUrl:
          'https://res.cloudinary.com/demo/image/upload/v1700000000/playaround/following/mikael.jpg',
        isFollowing: true,
      },
    ],
    role: 'player',
    isProfileComplete: true,
    createdAt: now,
    updatedAt: now,
  };
}

function playerProfileDoc() {
  return {
    sportsOfInterest: ['Football', 'Futsal', 'Padel'],
    skillLevel: 'elite',
    availability: [
      { day: 'Mon', startTime: '19:00', endTime: '22:00' },
      { day: 'Wed', startTime: '19:00', endTime: '22:00' },
      { day: 'Sat', startTime: '10:00', endTime: '14:00' },
    ],
    preferredTrainingType: 'both',
  };
}

function publicProfileDoc(uid) {
  const now = admin.firestore.Timestamp.now();
  return {
    userId: uid,
    identity: {
      fullName: 'Ayaan Malik',
      role: 'Elite Wing Forward',
      tagline: 'Captain • Thunder FC | MVP 2024',
      city: 'Karachi, Pakistan',
      age: 24,
      profilePictureUrl:
        'https://res.cloudinary.com/demo/image/upload/v1700000000/playaround/ayaan/profile.jpg',
      coverMediaUrl:
        'https://images.unsplash.com/photo-1521412644187-c49fa049e84d?auto=format&fit=crop&w=1600&q=80',
      badges: [
        '⚡️ 2024 Tournament MVP',
        '🏆 City League Champion',
        '🎯 97% Training Consistency',
      ],
      isVerified: true,
    },
    stats: [
      { label: 'Posts', value: 12, icon: 'article_outlined' },
      { label: 'Swipe matches', value: 6, icon: 'link_rounded' },
      { label: 'Following', value: 24, icon: 'favorite_outline' },
      { label: 'Followers', value: 312, icon: 'groups_3_outlined' },
    ],
    postsCount: 12,
    matchesCount: 6,
    followersCount: 312,
    followingCount: 24,
    isFollowing: false,
    isFollowedByViewer: false,
    about: {
      bio:
        'Explosive winger comfortable on either flank. Thrives in high-tempo systems and brings data-driven match prep to every squad.',
      sports: ['Football', 'Futsal', 'Padel'],
      position: 'Right/Left Wing',
      availability: 'Available for elite futsal and 7-a-side tournaments',
      highlights: [
        'Led Thunder FC to back-to-back league titles',
        'Recorded 9 goals and 4 assists at PlayAround Champions Cup 2024',
        'Hosts weekly acceleration clinics for youth squads',
      ],
      attributes: {
        'Dominant Foot': 'Right',
        'Preferred Formation': '4-3-3 / 3-4-3',
        'Training Focus': 'Acceleration & Pressing',
        Languages: 'English, Urdu',
      },
      statusMessage:
        'Looking to collaborate with performance analysts and conditioning coaches.',
    },
    skillPerformance: {
      overallRating: 94,
      metrics: [
        {
          name: 'Acceleration',
          score: 96,
          maxScore: 100,
          description: '0-30m sprint in 3.98s; maintains burst late in matches.',
          icon: 'flash_on',
        },
        {
          name: 'Vision',
          score: 92,
          maxScore: 100,
          description: 'Averages 5 key passes per match with radar-guided scouting.',
          icon: 'remove_red_eye',
        },
        {
          name: 'Stamina',
          score: 95,
          maxScore: 100,
          description: 'Completes 97% of scheduled endurance drills each block.',
          icon: 'favorite',
        },
      ],
      trends: [
        { label: 'Feb', value: 86 },
        { label: 'Mar', value: 88 },
        { label: 'Apr', value: 90 },
        { label: 'May', value: 93 },
        { label: 'Jun', value: 95 },
      ],
      achievements: [
        {
          title: 'MVP • Champions Cup',
          subtitle: 'Golden Boot with 9 goals',
          icon: 'emoji_events',
          date: now,
        },
      ],
    },
    associations: {
      teams: [
        {
          id: 'team_thunder_fc',
          title: 'Thunder FC',
          subtitle: 'Karachi Premier League',
          role: 'Captain & RW',
          imageUrl:
            'https://res.cloudinary.com/demo/image/upload/v1700000000/playaround/teams/thunder_fc.jpg',
          tags: ['High Press', 'Title Holders'],
          location: 'Karachi',
          ownerName: 'Manager Adeel Khattak',
          ownerId: 'user_manager_adeel',
        },
      ],
      tournaments: [
        {
          id: 'tournament_champions_cup',
          title: 'PlayAround Champions Cup 2024',
          subtitle: 'International Showcase',
          role: 'MVP & Golden Boot',
          imageUrl:
            'https://res.cloudinary.com/demo/image/upload/v1700000000/playaround/tournaments/champions_cup.jpg',
          tags: ['MVP', 'Champion'],
          ownerName: 'PlayAround Events Desk',
          ownerId: 'organization_playaround_events',
        },
      ],
      venues: [
        {
          id: 'venue_riverside_arena',
          title: 'Riverside Arena',
          subtitle: 'Premier Futsal Facility',
          role: 'Weekly Training Ground',
          imageUrl:
            'https://res.cloudinary.com/demo/image/upload/v1700000000/playaround/venues/riverside_arena.jpg',
          tags: ['Indoor', 'Smart Lighting', 'Analytics'],
          ownerName: 'Riverside Sports Collective',
          ownerId: 'venue_riverside_collective',
        },
      ],
      coaches: [
        {
          id: 'coach_samira',
          title: 'Coach Samira Akhtar',
          subtitle: 'Attack Specialist • UEFA B',
          role: 'Personal Mentor',
          imageUrl:
            'https://res.cloudinary.com/demo/image/upload/v1700000000/playaround/coaches/samira.jpg',
          tags: ['Finishing', 'Acceleration'],
          ownerName: 'Coach Samira',
          ownerId: 'coach_samira_uid',
        },
      ],
    },
    availableAssociations: {
      teams: [
        {
          id: 'team_velocity_five',
          title: 'Velocity Five',
          subtitle: 'Doha Futsal Super Series',
          role: 'Scouted',
          imageUrl:
            'https://res.cloudinary.com/demo/image/upload/v1700000000/playaround/teams/velocity_five.jpg',
          tags: ['High Tempo', 'Analytics Driven'],
          ownerName: 'Coach Silvia Andrade',
          ownerId: 'coach_silvia_uid',
        },
        {
          id: 'team_pulse_united',
          title: 'Pulse United',
          subtitle: 'Dubai Regional Cup',
          role: 'Tryout Invitation',
          imageUrl:
            'https://res.cloudinary.com/demo/image/upload/v1700000000/playaround/teams/pulse_united.jpg',
          tags: ['Adaptive', 'Emerging Talent'],
          ownerName: 'GM Imran Shah',
          ownerId: 'manager_imran_uid',
        },
      ],
      tournaments: [
        {
          id: 'tournament_asia_elite',
          title: 'Asia Elite Showcase 2025',
          subtitle: 'Invitation Confirmed',
          role: 'Shortlisted Player',
          imageUrl:
            'https://res.cloudinary.com/demo/image/upload/v1700000000/playaround/tournaments/asia_showcase.jpg',
          tags: ['International', 'Scouting'],
          ownerName: 'Asia Elite Board',
          ownerId: 'org_asia_elite',
        },
      ],
      venues: [
        {
          id: 'venue_lakeside_dome',
          title: 'Lakeside Dome',
          subtitle: 'Climate Controlled Arena',
          role: 'AI Tracking Sessions',
          imageUrl:
            'https://res.cloudinary.com/demo/image/upload/v1700000000/playaround/venues/lakeside_dome.jpg',
          tags: ['AI Tracking', 'Indoor'],
          ownerName: 'Lakeside Performance Labs',
          ownerId: 'venue_lakeside_labs',
        },
      ],
      coaches: [
        {
          id: 'coach_lara_ibrahim',
          title: 'Coach Lara Ibrahim',
          subtitle: 'Mindset Mentor',
          role: 'Sports Psychologist',
          imageUrl:
            'https://res.cloudinary.com/demo/image/upload/v1700000000/playaround/coaches/lara.jpg',
          tags: ['Mindset', 'Visualization'],
          ownerName: 'Coach Lara',
          ownerId: 'coach_lara_uid',
        },
      ],
    },
    matchmaking: {
      tagline: 'Looking to join high-press futsal squads & data-driven collectives.',
      about:
        'Comfortable as inverted winger or advanced 10. Combines pace and vision to spark transitions.',
      images: [
        'https://res.cloudinary.com/demo/image/upload/v1700000000/playaround/matchmaking/ayaan_1.jpg',
        'https://res.cloudinary.com/demo/image/upload/v1700000000/playaround/matchmaking/ayaan_2.jpg',
        'https://res.cloudinary.com/demo/image/upload/v1700000000/playaround/matchmaking/ayaan_3.jpg',
        'https://res.cloudinary.com/demo/image/upload/v1700000000/playaround/matchmaking/ayaan_4.jpg',
        'https://res.cloudinary.com/demo/image/upload/v1700000000/playaround/matchmaking/ayaan_5.jpg',
      ],
      age: 24,
      city: 'Karachi, Pakistan',
      sports: ['Football', 'Futsal'],
      seeking: [
        'High-tempo futsal crews',
        'Analytics-driven squads',
        'Elite invitational tournaments',
      ],
      distanceKm: 4.6,
      distanceLink:
        'https://cloud.google.com/maps-platform?utm_source=playaround',
      featuredTeam: {
        id: 'team_thunder_fc',
        title: 'Thunder FC',
        subtitle: 'Karachi Premier League',
        role: 'Captain & RW',
        imageUrl:
          'https://res.cloudinary.com/demo/image/upload/v1700000000/playaround/teams/thunder_fc.jpg',
        tags: ['High Press', 'Title Holders'],
        ownerName: 'Manager Adeel Khattak',
        ownerId: 'user_manager_adeel',
      },
      featuredVenue: {
        id: 'venue_riverside_arena',
        title: 'Riverside Arena',
        subtitle: 'Premier Futsal Facility',
        role: 'Weekly Training Ground',
        imageUrl:
          'https://res.cloudinary.com/demo/image/upload/v1700000000/playaround/venues/riverside_arena.jpg',
        tags: ['Indoor', 'Smart Lighting'],
        ownerName: 'Riverside Sports Collective',
        ownerId: 'venue_riverside_collective',
      },
      featuredCoach: {
        id: 'coach_samira',
        title: 'Coach Samira Akhtar',
        subtitle: 'Attack Specialist • UEFA B',
        role: 'Personal Mentor',
        imageUrl:
          'https://res.cloudinary.com/demo/image/upload/v1700000000/playaround/coaches/samira.jpg',
        tags: ['Finishing', 'Acceleration'],
        ownerName: 'Coach Samira',
        ownerId: 'coach_samira_uid',
      },
      featuredTournament: {
        id: 'tournament_champions_cup',
        title: 'PlayAround Champions Cup 2024',
        subtitle: 'International Showcase',
        role: 'MVP & Golden Boot',
        imageUrl:
          'https://res.cloudinary.com/demo/image/upload/v1700000000/playaround/tournaments/champions_cup.jpg',
        tags: ['MVP', 'Champion'],
        ownerName: 'PlayAround Events Desk',
        ownerId: 'organization_playaround_events',
      },
      allowMessagesFromFriendsOnly: false,
    },
    matchmakingLibrary: [
      'https://res.cloudinary.com/demo/image/upload/v1700000000/playaround/matchmaking/gallery_1.jpg',
      'https://res.cloudinary.com/demo/image/upload/v1700000000/playaround/matchmaking/gallery_2.jpg',
      'https://res.cloudinary.com/demo/image/upload/v1700000000/playaround/matchmaking/gallery_3.jpg',
      'https://res.cloudinary.com/demo/image/upload/v1700000000/playaround/matchmaking/gallery_4.jpg',
    ],
    reviews: [
      {
        id: 'review_1',
        authorName: 'Coach Samira Akhtar',
        authorAvatarUrl:
          'https://res.cloudinary.com/demo/image/upload/v1700000000/playaround/coaches/samira.jpg',
        rating: 4.9,
        comment:
          'Elite decision-making in the final third. Reads defensive shape quickly and adjusts pressing triggers without prompting.',
        relationship: 'Personal Coach',
        createdAt: now,
      },
    ],
    contact: {
      primaryActionLabel: 'Start Chat',
      allowMessagesFromFriendsOnly: false,
      links: {
        instagram: 'https://instagram.com/ayaan.stride',
        youtube: 'https://youtube.com/@ayaanstride',
        facebook: 'https://facebook.com/ayaanstride',
      },
    },
    featuredPostIds: ['post_tactical_breakdown', 'post_recovery'],
    updatedAt: now,
  };
}

async function seed() {
  const uid = await ensureUser();
  console.log('ℹ️  Writing profile documents...');

  await firestore.collection('users').doc(uid).set(baseUserDoc(uid));
  await firestore
      .collection('player_profiles')
      .doc(uid)
      .set(playerProfileDoc(), { merge: true });
  await firestore
      .collection('public_profiles')
      .doc(uid)
      .set(publicProfileDoc(uid), { merge: true });

  console.log('✅ Seeded public profile data for:', uid);
  console.log('\nNext steps:');
  console.log(' - Run the app and sign in with the seeded credentials.');
  console.log(' - The new public profile screen will surface this data in Phase 2.');
  process.exit(0);
}

seed().catch((error) => {
  console.error('❌ Seed failed:', error);
  process.exit(1);
});

