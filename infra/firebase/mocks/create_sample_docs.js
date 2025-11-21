#!/usr/bin/env node
/**
 * Seeds Firestore with deterministic sample documents for local development.
 * Safe to run multiple times; each document is written with merge semantics.
 */
const admin = require('firebase-admin');

if (admin.apps.length === 0) {
  const projectId = process.env.FIREBASE_PROJECT_ID || 'demo-sports-app';
  admin.initializeApp({
    projectId,
    credential: process.env.GOOGLE_APPLICATION_CREDENTIALS
      ? admin.credential.applicationDefault()
      : undefined
  });
  admin.firestore().settings({ ignoreUndefinedProperties: true });
}

const db = admin.firestore();

async function upsert(collectionPath, id, data) {
  const ref = db.collection(collectionPath).doc(id);
  await ref.set({ updatedAt: admin.firestore.FieldValue.serverTimestamp(), ...data }, { merge: true });
}

async function seedUsers() {
  await upsert('users', 'player_001', {
    role: 'athlete',
    displayName: 'Sam Player',
    email: 'sam.player@example.com',
    homeClubId: 'club_north',
    rating: 4.2,
    lastActiveAt: admin.firestore.FieldValue.serverTimestamp()
  });

  await upsert('users', 'coach_001', {
    role: 'coach',
    displayName: 'Casey Coach',
    email: 'casey.coach@example.com',
    homeClubId: 'club_central',
    rating: 4.8,
    lastActiveAt: admin.firestore.FieldValue.serverTimestamp()
  });

  await upsert('users', 'admin_001', {
    role: 'admin',
    displayName: 'Al Admin',
    email: 'al.admin@example.com',
    lastActiveAt: admin.firestore.FieldValue.serverTimestamp()
  });
}

async function seedVenues() {
  await upsert('venues', 'venue_central', {
    name: 'Central Courts',
    city: 'Austin',
    rating: 4.6,
    managerId: 'coach_001',
    status: 'active'
  });

  await upsert('venues', 'venue_north', {
    name: 'Northside Dome',
    city: 'Dallas',
    rating: 4.1,
    managerId: 'admin_001',
    status: 'active'
  });
}

async function seedCoachListings() {
  await upsert('coachListings', 'listing_casey_peak', {
    coachId: 'coach_001',
    sportId: 'tennis',
    pricePerHour: 80,
    rating: 4.8,
    startsAt: new Date().toISOString()
  });
}

async function seedListings() {
  await upsert('listings', 'listing_central_morning', {
    venueId: 'venue_central',
    coachId: 'coach_001',
    startsAt: new Date(Date.now() + 86400000).toISOString(),
    capacity: 8,
    status: 'open'
  });
}

async function seedBookings() {
  await upsert('bookings', 'booking_1001', {
    venueId: 'venue_central',
    userId: 'player_001',
    coachId: 'coach_001',
    venueManagerId: 'coach_001',
    startTime: new Date(Date.now() + 86400000).toISOString(),
    status: 'confirmed'
  });
}

async function seedTournaments() {
  await upsert('tournaments', 'tournament_fall', {
    name: 'Fall Classic',
    seasonId: '2025_fall',
    startDate: new Date(Date.now() + 1209600000).toISOString()
  });
}

async function seedMatches() {
  await upsert('matches', 'match_fall_01', {
    tournamentId: 'tournament_fall',
    venueId: 'venue_central',
    startTime: new Date(Date.now() + 1213200000).toISOString(),
    homeTeamId: 'team_alpha',
    awayTeamId: 'team_beta'
  });
}

async function seedTeams() {
  await upsert('teams', 'team_alpha', {
    name: 'Alpha Aces',
    clubId: 'club_north',
    coachId: 'coach_001'
  });

  await upsert('teams', 'team_beta', {
    name: 'Beta Bashers',
    clubId: 'club_central',
    coachId: 'coach_001'
  });

  await upsert('teamMembers', 'member_alpha_player_001', {
    teamId: 'team_alpha',
    athleteId: 'player_001',
    coachId: 'coach_001',
    role: 'starter'
  });
}

async function seedLeaderboard() {
  await upsert('leaderboardEntries', 'leader_fall_alpha', {
    tournamentId: 'tournament_fall',
    teamId: 'team_alpha',
    score: 12,
    wins: 4
  });

  await upsert('leaderboardEntries', 'leader_fall_beta', {
    tournamentId: 'tournament_fall',
    teamId: 'team_beta',
    score: 8,
    wins: 2
  });
}

async function seedProducts() {
  await upsert('products', 'prod_performance_ball', {
    name: 'Performance Ball Pack',
    price: 29.99,
    currency: 'USD',
    tags: ['equipment', 'tennis']
  });
}

async function seedPosts() {
  await upsert('posts', 'post_training_tips', {
    authorId: 'coach_001',
    tags: ['training', 'tennis'],
    publishedAt: new Date().toISOString(),
    title: 'Top 5 Footwork Drills'
  });
}

async function seedMessaging() {
  await upsert('messageThreads', 'thread_booking_help', {
    participants: ['player_001', 'coach_001'],
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });

  const messagesRef = db.collection('messageThreads').doc('thread_booking_help').collection('messages').doc('msg_001');
  await messagesRef.set(
    {
      threadId: 'thread_booking_help',
      senderId: 'player_001',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      body: 'Hey coach, is the Saturday slot still free?'
    },
    { merge: true }
  );
}

async function seedNotifications() {
  await upsert('notifications', 'notif_player_booking', {
    userId: 'player_001',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    type: 'booking_update',
    bookingId: 'booking_1001'
  });
}

async function run() {
  try {
    await Promise.all([
      seedUsers(),
      seedVenues(),
      seedCoachListings(),
      seedListings(),
      seedBookings(),
      seedTournaments(),
      seedMatches(),
      seedTeams(),
      seedLeaderboard(),
      seedProducts(),
      seedPosts(),
      seedMessaging(),
      seedNotifications()
    ]);
    console.log('Sample documents created or updated successfully.');
    process.exit(0);
  } catch (err) {
    console.error('Failed to seed sample documents:', err);
    process.exit(1);
  }
}

run();

