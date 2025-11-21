#!/usr/bin/env python3
"""
PlayAround Firestore Database Population Script
================================================

This script populates the PlayAround app's Firestore database with realistic,
high-quality dummy data including:
- 100+ realistic player profiles
- 30+ professional coach profiles
- 12+ sports venues with 4K images
- 12+ active teams with group chats
- 10 tournaments (5 upcoming, 3 running, 2 finished)
- 25+ community posts with comments and likes
- 900+ total documents

Usage:
    python scripts/populate_firestore.py

Requirements:
    pip install firebase-admin
"""

import random
import datetime
import json
import itertools
from collections import defaultdict
from typing import Any, Dict, List, Optional, Set, Tuple

import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime as dt, timedelta

# ============================================================================
# CONFIGURATION
# ============================================================================

CLEAN_EXISTING_DATA = True
VERBOSE_LOGGING = True

# ============================================================================
# GLOBAL IN-MEMORY REGISTRIES
# ============================================================================

USER_CACHE: Dict[str, Dict[str, Any]] = {}
TEAM_CACHE: Dict[str, Dict[str, Any]] = {}
VENUE_CACHE: Dict[str, Dict[str, Any]] = {}
TOURNAMENT_CACHE: Dict[str, Dict[str, Any]] = {}
USER_TEAM_MEMBERSHIPS: Dict[str, List[Dict[str, Any]]] = defaultdict(list)
TEAM_TOURNAMENTS: Dict[str, Set[str]] = defaultdict(set)

TEAM_MATCH_PAYLOADS: List[Dict[str, Any]] = []

# ============================================================================
# HIGH-QUALITY IMAGE URLS (4K-compatible from Unsplash)
# ============================================================================

class ImageUrls:
    """High-quality image URLs for all content types"""
    
    # Male profile pictures (800x800)
    male_profiles = [
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800',
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800',
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800',
        'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=800',
        'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=800',
        'https://images.unsplash.com/photo-1552374196-c4e7ffc6e126?w=800',
        'https://images.unsplash.com/photo-1545167622-3a6ac756afa4?w=800',
        'https://images.unsplash.com/photo-1531427186611-ecfd6d936c79?w=800',
        'https://images.unsplash.com/photo-1557862921-37829c790f19?w=800',
        'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=800',
    ]
    
    # Female profile pictures (800x800)
    female_profiles = [
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=800',
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800',
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=800',
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=800',
        'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=800',
        'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=800',
        'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?w=800',
        'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=800',
        'https://images.unsplash.com/photo-1547425260-76bcadfb4f2c?w=800',
        'https://images.unsplash.com/photo-1520813792240-56fc4a3765a7?w=800',
    ]
    
    # Sports action photos (1920x1080)
    sports_photos = [
        'https://images.unsplash.com/photo-1517649763962-0c623066013b?w=1920',  # Basketball
        'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?w=1920',  # Football
        'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=1920',  # Tennis
        'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=1920',  # Cricket
        'https://images.unsplash.com/photo-1612872087720-bb876e2e67d1?w=1920',  # Volleyball
        'https://images.unsplash.com/photo-1599206676335-193c82b13c9e?w=1920',  # Running
        'https://images.unsplash.com/photo-1571008887538-b36bb32f4571?w=1920',  # Gym
        'https://images.unsplash.com/photo-1578762560042-46ad127c95ea?w=1920',  # Swimming
    ]
    
    # Venue images (1920x1080)
    venue_images = [
        'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=1920',  # Stadium
        'https://images.unsplash.com/photo-1459865264687-595d652de67e?w=1920',  # Basketball court
        'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=1920',  # Tennis court
        'https://images.unsplash.com/photo-1628779238951-1dc555961fdd?w=1920',  # Football field
        'https://images.unsplash.com/photo-1566577134770-3d85bb3a9cc4?w=1920',  # Sports complex
        'https://images.unsplash.com/photo-1624526267942-ab0ff8a3e972?w=1920',  # Indoor court
    ]
    
    # Team logos (800x800)
    team_logos = [
        'https://images.unsplash.com/photo-1606925797300-0b35e9d1794e?w=800',
        'https://images.unsplash.com/photo-1612287230202-1ff1d85d1bdf?w=800',
        'https://images.unsplash.com/photo-1614632537239-f47872eeee98?w=800',
    ]
    
    # Tournament banners (1920x1080)
    tournament_banners = [
        'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=1920',  # Trophy
        'https://images.unsplash.com/photo-1513028179155-801e5e8d375e?w=1920',  # Sports event
        'https://images.unsplash.com/photo-1517649763962-0c623066013b?w=1920',  # Championship
    ]
    
    # Community post images (1200x1200)
    community_images = [
        'https://images.unsplash.com/photo-1517649763962-0c623066013b?w=1200',
        'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?w=1200',
        'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=1200',
        'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=1200',
        'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=1200',
    ]
    
    # Coach certification images (1200x1200)
    certification_images = [
        'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?w=1200',
        'https://images.unsplash.com/photo-1521587760476-6c12a4b040da?w=1200',
    ]

# ============================================================================
# DATA GENERATOR
# ============================================================================

class DataGenerator:
    """Utility class for generating realistic dummy data"""
    
    # Pakistani cities with GPS coordinates
    CITIES = {
        'Karachi': {'lat': 24.8607, 'lng': 67.0011},
        'Lahore': {'lat': 31.5204, 'lng': 74.3587},
        'Islamabad': {'lat': 33.6844, 'lng': 73.0479},
        'Rawalpindi': {'lat': 33.5651, 'lng': 73.0169},
        'Faisalabad': {'lat': 31.4504, 'lng': 73.1350},
        'Multan': {'lat': 30.1575, 'lng': 71.5249},
        'Peshawar': {'lat': 34.0151, 'lng': 71.5249},
        'Quetta': {'lat': 30.1798, 'lng': 66.9750},
        'Sialkot': {'lat': 32.4945, 'lng': 74.5229},
        'Gujranwala': {'lat': 32.1877, 'lng': 74.1945},
    }
    
    # Sports available in the app
    SPORTS = ['Cricket', 'Football', 'Basketball', 'Tennis', 'Badminton', 
              'Volleyball', 'Swimming', 'Running', 'Cycling']
    
    # Names
    MALE_FIRST_NAMES = [
        'Ahmed', 'Ali', 'Hassan', 'Usman', 'Bilal', 'Faisal', 'Imran',
        'Kamran', 'Salman', 'Fahad', 'Zain', 'Hamza', 'Omar', 'Asad',
        'Rizwan', 'Shahid', 'Tariq', 'Younus', 'Zaheer', 'Adnan',
        'Arif', 'Kashif', 'Nasir', 'Saad', 'Waqar', 'Yasir', 'Aamir',
        'Farhan', 'Junaid', 'Majid', 'Naveed', 'Rashid', 'Shoaib'
    ]
    
    FEMALE_FIRST_NAMES = [
        'Ayesha', 'Fatima', 'Zainab', 'Mariam', 'Sara', 'Hira', 'Sana',
        'Alina', 'Anum', 'Hadia', 'Kinza', 'Mahnoor', 'Nida', 'Rabia',
        'Samina', 'Uzma', 'Warda', 'Zara', 'Bushra', 'Farah'
    ]
    
    LAST_NAMES = [
        'Khan', 'Ahmed', 'Ali', 'Hassan', 'Hussain', 'Malik', 'Sheikh',
        'Butt', 'Iqbal', 'Raza', 'Shah', 'Siddiqui', 'Mirza', 'Chaudhry',
        'Akram', 'Aziz', 'Bashir', 'Haider', 'Javed', 'Qadir'
    ]
    
    @staticmethod
    def random_name(is_male: bool) -> str:
        """Generate a random Pakistani name"""
        first = random.choice(DataGenerator.MALE_FIRST_NAMES if is_male else DataGenerator.FEMALE_FIRST_NAMES)
        last = random.choice(DataGenerator.LAST_NAMES)
        return f"{first} {last}"
    
    @staticmethod
    def random_city() -> str:
        """Get a random city"""
        return random.choice(list(DataGenerator.CITIES.keys()))
    
    @staticmethod
    def get_city_coords(city: str) -> Dict[str, float]:
        """Get GPS coordinates for a city"""
        return DataGenerator.CITIES.get(city, DataGenerator.CITIES['Karachi'])
    
    @staticmethod
    def random_sports(min_count: int = 2, max_count: int = 4) -> List[str]:
        """Get random sports"""
        count = random.randint(min_count, max_count)
        return random.sample(DataGenerator.SPORTS, count)
    
    @staticmethod
    def random_past_date(max_days_ago: int = 180) -> datetime.datetime:
        """Generate a random past date"""
        days_ago = random.randint(0, max_days_ago)
        return dt.now() - timedelta(days=days_ago)
    
    @staticmethod
    def random_future_date(max_days_ahead: int = 60) -> datetime.datetime:
        """Generate a random future date"""
        days_ahead = random.randint(1, max_days_ahead)
        return dt.now() + timedelta(days=days_ahead)
    
    @staticmethod
    def generate_player_bio(sports: List[str], skill_level: str) -> str:
        """Generate realistic player bio"""
        templates = [
            f"Passionate {sports[0].lower()} player looking for teammates. Love staying active!",
            f"Sports enthusiast with experience in {', '.join(sports)}. Always ready for a game!",
            f"Dedicated {skill_level} player. Believe in teamwork and fair play.",
            f"{sports[0]} is my passion! Looking to connect with players in my area.",
            f"Weekend warrior who loves {sports[0].lower()}. Let's play!",
            f"Fitness fanatic and {sports[0].lower()} player. Hit me up for a match!",
            f"Playing {sports[0].lower()} for {random.randint(2, 10)} years. Always learning!",
        ]
        return random.choice(templates)
    
    @staticmethod
    def generate_coach_bio(sport: str, experience: int) -> str:
        """Generate realistic coach bio"""
        templates = [
            f"Professional {sport} coach with {experience} years of experience. Certified trainer specializing in skill development.",
            f"Experienced {sport} coach dedicated to bringing out the best in athletes. {experience}+ years coaching all levels.",
            f"Passionate about {sport} coaching. {experience} years of transforming players into champions.",
            f"Elite {sport} coaching with focus on technique and mental preparation. {experience} years professional experience.",
            f"Certified {sport} coach. {experience} years helping athletes achieve their goals.",
        ]
        return random.choice(templates)

# ============================================================================
# FIREBASE INITIALIZATION
# ============================================================================

def initialize_firebase():
    """Initialize Firebase Admin SDK"""
    import os
    import glob
    
    try:
        # Try to initialize with default credentials (if already initialized)
        if not firebase_admin._apps:
            # Check for service account key files (common names)
            possible_paths = [
                'firebase-service-account.json',
                'playaround-6556e-firebase-adminsdk-fbsvc-26671daef7.json',
            ]
            
            # Also check for any JSON files matching Firebase admin SDK pattern
            firebase_json_files = glob.glob('*-firebase-adminsdk-*.json')
            possible_paths.extend(firebase_json_files)
            
            service_account_path = None
            for path in possible_paths:
                if os.path.exists(path):
                    service_account_path = path
                    break
            
            if service_account_path:
                # Use service account key
                cred = credentials.Certificate(service_account_path)
                firebase_admin.initialize_app(cred)
                print(f"   ✓ Using {service_account_path}")
            else:
                # Try default credentials (for development)
                print("   ⚠️  No Firebase service account JSON found")
                print("   Attempting to use default credentials...")
                firebase_admin.initialize_app()
        
        return firestore.client()
    except Exception as e:
        print(f"❌ Error initializing Firebase: {e}")
        print("\n💡 Solution:")
        print("1. Go to Firebase Console → Project Settings → Service Accounts")
        print("2. Click 'Generate New Private Key'")
        print("3. Save the downloaded file in the project root: D:\\FYP\\PlayAround\\")
        print("4. The script will automatically detect it (any *-firebase-adminsdk-*.json file)")
        print("\nSee PYTHON_DATABASE_SETUP.md for detailed instructions.")
        raise

# ============================================================================
# DATABASE CLEANUP
# ============================================================================

def clean_database(db):
    """Clean all existing dummy data from Firestore"""
    collections = [
        'users', 'coaches', 'venues', 'teams', 'tournaments',
        'community_posts', 'community_comments', 'community_likes',
        'chats', 'connections', 'matches', 'team_matches',
        'tournament_matches', 'bookings', 'notifications'
    ]
    
    print("🧹 Cleaning existing data...")
    for collection_name in collections:
        try:
            # Get all documents in batches
            docs = db.collection(collection_name).stream()
            batch = db.batch()
            count = 0
            
            for doc in docs:
                batch.delete(doc.reference)
                count += 1
                
                # Commit in batches of 500
                if count % 500 == 0:
                    batch.commit()
                    batch = db.batch()
                    if VERBOSE_LOGGING:
                        print(f"   Deleted {count} documents from {collection_name}...")
            
            # Commit remaining
            if count % 500 != 0:
                batch.commit()
            
            if VERBOSE_LOGGING and count > 0:
                print(f"   ✓ Cleaned {collection_name} ({count} documents)")
        except Exception as e:
            print(f"   ⚠️  Error cleaning {collection_name}: {e}")
    
    print("✅ Database cleaned\n")

# ============================================================================
# USER GENERATION
# ============================================================================

def generate_users(db, count: int = 110) -> List[str]:
    """Generate realistic user/player profiles"""
    print(f"👥 Generating {count}+ user profiles...")
    user_ids = []
    batch = db.batch()
    batch_count = 0
    
    for i in range(count):
        is_male = random.choice([True, False])
        full_name = DataGenerator.random_name(is_male)
        city = DataGenerator.random_city()
        coords = DataGenerator.get_city_coords(city)
        sports = DataGenerator.random_sports(2, 4)
        skill_level = random.choice(['beginner', 'intermediate', 'pro'])
        
        # Generate user ID
        user_ref = db.collection('users').document()
        user_id = user_ref.id
        
        # Select profile images
        profile_images = random.sample(
            ImageUrls.male_profiles if is_male else ImageUrls.female_profiles,
            min(3, len(ImageUrls.male_profiles))
        )
        
        # Create user data
        user_data = {
            'uid': user_id,
            'fullName': full_name,
            'nickname': full_name.split()[0],
            'bio': DataGenerator.generate_player_bio(sports, skill_level),
            'gender': 'male' if is_male else 'female',
            'age': random.randint(18, 45),
            'location': city,
            'latitude': coords['lat'] + random.uniform(-0.1, 0.1),
            'longitude': coords['lng'] + random.uniform(-0.1, 0.1),
            'profilePictureUrl': profile_images[0],
            'profilePhotos': profile_images,
            'role': 'player',
            'isProfileComplete': True,
            'sportsOfInterest': sports,
            'skillLevel': skill_level,
            'availability': [
                {'start': '18:00', 'end': '21:00'},
                {'start': '09:00', 'end': '12:00'},
            ],
            'preferredTrainingType': 'in_person',
            'createdAt': DataGenerator.random_past_date(180),
            'updatedAt': dt.now(),
        }

        matches_played = random.randint(8, 40)
        wins = random.randint(3, matches_played)
        player_stats = {
            'matchesPlayed': matches_played,
            'wins': wins,
            'goals': random.randint(2, 30),
            'assists': random.randint(1, 20),
            'tournamentsPlayed': random.randint(1, 6),
            'tournamentsWon': random.randint(0, 3),
            'mvpAwards': random.randint(0, 5),
        }
        user_data['playerStats'] = player_stats
        user_data['playerAchievements'] = [
            f"{wins} career wins",
            f"{player_stats['tournamentsPlayed']} tournament appearances",
        ]
        user_data['skillBadges'] = random.sample(
            ['Playmaker', 'Finisher', 'Leader', 'Defender', 'Strategist'],
            k=2,
        )
        
        batch.set(user_ref, user_data)
        USER_CACHE[user_id] = user_data
        user_ids.append(user_id)
        batch_count += 1
        
        # Commit in batches
        if batch_count >= 500:
            batch.commit()
            batch = db.batch()
            batch_count = 0
            if VERBOSE_LOGGING:
                print(f"   Generated {len(user_ids)} users...")
    
    # Commit remaining
    if batch_count > 0:
        batch.commit()
    
    print(f"✅ Generated {len(user_ids)} users\n")
    return user_ids

# ============================================================================
# COACH GENERATION
# ============================================================================

def generate_coaches(db, count: int = 35) -> List[str]:
    """Generate professional coach profiles"""
    print(f"🧑‍🏫 Generating {count}+ coach profiles...")
    coach_ids = []
    batch = db.batch()
    batch_count = 0
    
    for i in range(count):
        is_male = random.random() > 0.3  # 70% male coaches
        full_name = DataGenerator.random_name(is_male)
        city = DataGenerator.random_city()
        coords = DataGenerator.get_city_coords(city)
        sport = random.choice(DataGenerator.SPORTS)
        experience = random.randint(3, 15)
        
        # Generate coach ID
        coach_ref = db.collection('users').document()
        coach_id = coach_ref.id
        
        # Select profile images
        profile_images = random.sample(
            ImageUrls.male_profiles if is_male else ImageUrls.female_profiles,
            min(2, len(ImageUrls.male_profiles))
        )
        
        # Create coach data
        coach_data = {
            'uid': coach_id,
            'fullName': full_name,
            'nickname': f"Coach {full_name.split()[0]}",
            'bio': DataGenerator.generate_coach_bio(sport, experience),
            'gender': 'male' if is_male else 'female',
            'age': random.randint(28, 55),
            'location': city,
            'latitude': coords['lat'] + random.uniform(-0.1, 0.1),
            'longitude': coords['lng'] + random.uniform(-0.1, 0.1),
            'profilePictureUrl': profile_images[0],
            'profilePhotos': profile_images,
            'role': 'coach',
            'isProfileComplete': True,
            'specializationSports': [sport],
            'experienceYears': experience,
            'certifications': random.sample(ImageUrls.certification_images, random.randint(1, 2)),
            'hourlyRate': float(random.randint(15, 100) * 100),  # PKR 1500-10000
            'availableTimeSlots': [
                {'start': '06:00', 'end': '09:00'},
                {'start': '16:00', 'end': '20:00'},
            ],
            'coachingType': 'both',
            'createdAt': DataGenerator.random_past_date(365),
            'updatedAt': dt.now(),
        }
        coach_data['coachHighlights'] = [
            f"{experience}+ years mentoring {sport.lower()} squads",
            f"Certified in {random.choice(['nutrition', 'sports science', 'strength & conditioning'])}",
        ]
        
        batch.set(coach_ref, coach_data)
        USER_CACHE[coach_id] = coach_data
        coach_ids.append(coach_id)
        batch_count += 1
        
        # Commit in batches
        if batch_count >= 500:
            batch.commit()
            batch = db.batch()
            batch_count = 0
    
    # Commit remaining
    if batch_count > 0:
        batch.commit()
    
    print(f"✅ Generated {len(coach_ids)} coaches\n")
    return coach_ids

# ============================================================================
# VENUE GENERATION
# ============================================================================

def generate_venues(db, coach_ids: List[str]) -> List[str]:
    """Generate realistic sports venues linked to real coaches"""
    venue_names = [
        'Champions Sports Complex', 'Elite Football Arena', 'Prime Tennis Academy',
        'Victory Basketball Court', 'Grand Sports Stadium', 'Star Cricket Ground',
        'Phoenix Badminton Club', 'Royal Sports Center', 'Olympic Training Facility',
        'Metro Sports Hub', 'Legends Sports Arena', 'Premier League Ground'
    ]
    
    print(f"🏟️  Generating {len(venue_names)} venue listings...")
    venue_ids = []
    
    for i, venue_name in enumerate(venue_names):
        city = DataGenerator.random_city()
        coords = DataGenerator.get_city_coords(city)
        sport = random.choice(DataGenerator.SPORTS)
        
        # Generate venue ID
        venue_ref = db.collection('venues').document()
        venue_id = venue_ref.id
        
        # Select venue images
        venue_images = random.sample(ImageUrls.venue_images, random.randint(3, 5))
        
        # Determine ownership
        owner_id = None
        owner_name = 'Venue Management'
        owner_photo = None
        if coach_ids:
            owner_id = coach_ids[i % len(coach_ids)]
            owner_doc = USER_CACHE.get(owner_id, {})
            owner_name = owner_doc.get('fullName', owner_name)
            owner_photo = owner_doc.get('profilePictureUrl')
        else:
            owner_id = f'admin_{random.randint(1, 5)}'

        # Feature up to 3 coaches per venue (owner + peers)
        featured_coach_ids = []
        if coach_ids:
            shuffled_coaches = coach_ids.copy()
            random.shuffle(shuffled_coaches)
            featured_coach_ids = list(
                dict.fromkeys(
                    [owner_id, *shuffled_coaches[: max(1, min(3, len(shuffled_coaches)))]]
                )
            )

        featured_coach_cards = []
        for coach_id in featured_coach_ids:
            coach_data = USER_CACHE.get(coach_id)
            if not coach_data:
                continue
            specializations = coach_data.get('specializationSports') or []
            featured_coach_cards.append({
                'coachId': coach_id,
                'name': coach_data.get('fullName', 'Coach'),
                'specialization': ', '.join(specializations) if specializations else 'Performance Coach',
                'experienceYears': coach_data.get('experienceYears', random.randint(3, 12)),
                'profileImageUrl': coach_data.get('profilePictureUrl'),
                'hourlyRate': coach_data.get('hourlyRate', float(random.randint(20, 80)) * 100),
                'rating': round(random.uniform(4.0, 5.0), 1),
            })

        # Create venue data
        venue_data = {
            'id': venue_id,
            'ownerId': owner_id,
            'ownerName': owner_name,
            'ownerProfilePicture': owner_photo,
            'title': venue_name,
            'sportType': sport,
            'description': f'Professional {sport.lower()} facility with modern amenities and expert staff. Perfect for training, matches, and tournaments.',
            'location': f'{city}, Pakistan',
            'gpsCoordinates': f"{coords['lat'] + random.uniform(-0.05, 0.05)},{coords['lng'] + random.uniform(-0.05, 0.05)}",
            'hourlyRate': float(random.randint(10, 50) * 100),  # PKR 1000-5000
            'images': venue_images,
            'availableTimeSlots': [
                {'start': '06:00', 'end': '10:00'},
                {'start': '14:00', 'end': '22:00'},
            ],
            'availableDays': ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
            'amenities': ['Parking', 'Changing Rooms', 'Showers', 'Equipment Rental', 'Café', 'First Aid'],
            'contactInfo': f'+92-300-{random.randint(1000000, 9999999)}',
            'isActive': True,
            'averageRating': round(random.uniform(4.0, 5.0), 1),
            'totalBookings': random.randint(50, 300),
            'totalReviews': random.randint(20, 100),
            'createdAt': DataGenerator.random_past_date(365),
            'updatedAt': dt.now(),
            'metadata': {
                'coachIds': featured_coach_ids,
                'featuredCoaches': featured_coach_cards,
                'history': [],
                'recentHighlights': [],
            },
        }
        
        venue_ref.set(venue_data)
        venue_ids.append(venue_id)
        VENUE_CACHE[venue_id] = venue_data
        
        if VERBOSE_LOGGING:
            print(f"   Generated venue: {venue_name}")
    
    print(f"✅ Generated {len(venue_ids)} venues\n")
    return venue_ids

# ============================================================================
# TEAM GENERATION
# ============================================================================

def generate_teams(db, user_ids: List[str], coach_ids: List[str]) -> List[str]:
    """Generate active teams with members and chats"""
    team_names = [
        'Thunder Strikers', 'Phoenix Warriors', 'Victory Champions',
        'Elite Eagles', 'Royal Tigers', 'Mighty Lions',
        'Storm Riders', 'Galaxy Stars', 'Urban Legends',
        'Rapid Rockets', 'Dream Team', 'Power Panthers',
        'Steel Guardians', 'Dynasty Dragons', 'Aurora FC',
        'Crimson Wolves', 'Liberty Falcons', 'Metro Mavericks'
    ]
    
    print(f"🏅 Generating {len(team_names)} teams...")
    team_ids = []
    
    shuffled_users = user_ids.copy()
    random.shuffle(shuffled_users)
    user_index = 0
    
    for i, team_name in enumerate(team_names):
        city = DataGenerator.random_city()
        sport = random.choice(DataGenerator.SPORTS)
        
        # Generate team ID
        team_ref = db.collection('teams').document()
        team_id = team_ref.id
        
        # Select team members (8-15 players)
        member_count = random.randint(8, 15)
        team_members = []
        
        attempts = 0
        max_attempts = member_count * 2  # Try twice as many users if needed
        
        while len(team_members) < member_count and attempts < max_attempts:
            if user_index >= len(shuffled_users):
                user_index = 0  # Wrap around if needed
            
            member_id = shuffled_users[user_index]
            user_index += 1
            attempts += 1
            
            # Get user data
            try:
                user_doc = db.collection('users').document(member_id).get()
                if user_doc.exists:
                    user_data = user_doc.to_dict()
                    
                    # Skip if already in team
                    if any(m['id'] == member_id for m in team_members):
                        continue
                    
                    # Assign role
                    j = len(team_members)
                    if j == 0:
                        role = 'owner'
                    elif j == 1:
                        role = 'captain'
                    elif j == 2:
                        role = 'vice_captain'
                    else:
                        role = 'member'
                    
                    team_members.append({
                        'id': member_id,
                        'userId': member_id,
                        'name': user_data['fullName'],
                        'role': role,
                        'profileImageUrl': user_data.get('profilePictureUrl'),
                        'joinedAt': DataGenerator.random_past_date(90),
                    })
            except Exception as e:
                if VERBOSE_LOGGING:
                    print(f"   ⚠️  Error adding member {member_id}: {e}")
                continue
        
        # Ensure we have at least 3 members
        if len(team_members) < 3:
            if VERBOSE_LOGGING:
                print(f"   ⚠️  Team {team_name} only has {len(team_members)} members, skipping...")
            continue  # Skip this team
        
        # Select coaches (1-2)
        coach_count = random.randint(1, 2)
        team_coaches = []
        
        for j in range(coach_count):
            if j >= len(coach_ids):
                break
            
            coach_id = coach_ids[(i + j) % len(coach_ids)]
            coach_doc = db.collection('users').document(coach_id).get()
            
            if coach_doc.exists:
                coach_data = coach_doc.to_dict()
                team_coaches.append({
                    'id': coach_id,
                    'userId': coach_id,
                    'name': coach_data['fullName'],
                    'role': 'coach',
                    'profileImageUrl': coach_data.get('profilePictureUrl'),
                    'joinedAt': DataGenerator.random_past_date(120),
                })
        
        combined_members = team_members + team_coaches
        owner_id = team_members[0]['id'] if team_members else (
            team_coaches[0]['id'] if team_coaches else user_ids[0]
        )
        # Create team data
        team_data = {
            'id': team_id,
            'name': team_name,
            'nameLowercase': team_name.lower(),
            'city': city,
            'nameInitial': ''.join([w[0] for w in team_name.split()]),
            'profileImageUrl': ImageUrls.team_logos[i % len(ImageUrls.team_logos)],
            'bannerImageUrl': ImageUrls.sports_photos[i % len(ImageUrls.sports_photos)],
            'bio': f'Dedicated {sport} team based in {city}. Committed to excellence and teamwork.',
            'description': 'Looking for passionate players to join our squad!',
            'ownerId': owner_id,
            'createdBy': owner_id,
            'sportType': sport.lower(),
            'createdAt': DataGenerator.random_past_date(180),
            'members': combined_members,
            'players': team_members,
            'coaches': team_coaches,
            'stat': {
                'played': random.randint(10, 50),
                'won': random.randint(5, 30),
                'lost': random.randint(5, 20),
                'draw': random.randint(0, 5),
                'goalsScored': random.randint(20, 100),
                'goalsConceded': random.randint(15, 80),
            },
            'isPublic': True,
            'maxPlayers': 11,
            'maxRosterSize': 20,
            'venueIds': [],
            'tournamentIds': [],
            'matchIds': [],
            'memberIds': [member['id'] for member in combined_members],
        }
        
        team_ref.set(team_data)
        TEAM_CACHE[team_id] = {
            **team_data,
            'members': combined_members,
        }
        for member in team_members:
            USER_TEAM_MEMBERSHIPS[member['id']].append({
                'teamId': team_id,
                'teamName': team_name,
                'role': member['role'],
                'joinedAt': member['joinedAt'],
            })
        for coach_member in team_coaches:
            USER_TEAM_MEMBERSHIPS[coach_member['id']].append({
                'teamId': team_id,
                'teamName': team_name,
                'role': coach_member['role'],
                'joinedAt': coach_member['joinedAt'],
            })
        team_ids.append(team_id)
        
        # Create team group chat
        create_team_chat(db, team_id, team_members)
        
        if VERBOSE_LOGGING:
            print(f"   Generated team: {team_name}")
    
    print(f"✅ Generated {len(team_ids)} teams\n")
    return team_ids

# ============================================================================
# TEAM CHAT CREATION
# ============================================================================

def create_team_chat(db, team_id: str, members: List[Dict]):
    """Create team group chat with initial messages"""
    # Skip if no members
    if not members or len(members) == 0:
        if VERBOSE_LOGGING:
            print(f"   ⚠️  Skipping chat for team {team_id} - no members")
        return
    
    chat_id = f'team_{team_id}'
    
    chat_data = {
        'id': chat_id,
        'type': 'group',
        'name': 'Team Chat',
        'participantIds': [m['id'] for m in members],
        'createdAt': dt.now(),
        'updatedAt': dt.now(),
        'lastMessage': 'Welcome to the team!',
        'lastMessageTime': dt.now(),
    }
    
    db.collection('chats').document(chat_id).set(chat_data)
    
    # Add initial messages
    messages = [
        'Welcome everyone to the team! 🎉',
        'Looking forward to playing with you all!',
        'When is our next practice session?',
        'Great to be part of this team!',
        "Let's give our best this season! 💪",
        'Anyone free for practice this weekend?',
        'We need to work on our defense',
        'Excited for the upcoming tournament!',
        "Who's bringing the water bottles? 😄",
        "Let's coordinate our jerseys",
    ]
    
    message_count = random.randint(5, 10)
    for i in range(message_count):
        sender = members[i % len(members)]
        message_data = {
            'chatId': chat_id,
            'senderId': sender['id'],
            'senderName': sender['name'],
            'message': messages[i % len(messages)],
            'timestamp': DataGenerator.random_past_date(30),
            'type': 'text',
            'isRead': True,
        }
        db.collection('chats').document(chat_id).collection('messages').add(message_data)

# ============================================================================
# TOURNAMENT GENERATION
# ============================================================================

def generate_tournaments(db, team_ids: List[str], venue_ids: List[str], user_ids: List[str]) -> Tuple[List[str], List[Dict[str, Any]]]:
    """Generate tournaments with various states and seed bracket matches"""
    tournament_names = [
        'Summer Championship 2025', 'Elite League Tournament', 'Champions Cup',
        'Spring Festival Games', 'National Sports Fest', 'City Premier League',
        'Victory Tournament', 'Grand Championship Series', 'Regional Sports League',
        'Ultimate Sports Challenge'
    ]
    
    # 5 upcoming, 3 running, 2 finished
    statuses = ['upcoming'] * 5 + ['running'] * 3 + ['finished'] * 2
    
    print("🏆 Generating tournaments...")
    tournament_ids = []
    generated_matches: List[Dict[str, Any]] = []
    
    for i, tournament_name in enumerate(tournament_names):
        status = statuses[i]
        sport = random.choice(DataGenerator.SPORTS)
        
        # Generate tournament ID
        tournament_ref = db.collection('tournaments').document()
        tournament_id = tournament_ref.id
        
        # Calculate dates based on status
        if status == 'upcoming':
            start_date = DataGenerator.random_future_date(45)
            end_date = start_date + timedelta(days=random.randint(3, 14))
        elif status == 'running':
            start_date = dt.now() - timedelta(days=random.randint(1, 7))
            end_date = start_date + timedelta(days=random.randint(7, 21))
        else:  # finished
            end_date = dt.now() - timedelta(days=random.randint(1, 60))
            start_date = end_date - timedelta(days=random.randint(7, 14))
        
        # Select teams (6-12)
        team_count = random.randint(6, 12)
        selected_teams = random.sample(team_ids, min(team_count, len(team_ids)))
        
        # Create tournament data
        tournament_data = {
            'id': tournament_id,
            'name': tournament_name,
            'description': f'A premier {sport} tournament bringing together the best teams in the region. Join us for an exciting competition!',
            'profileImageUrl': ImageUrls.tournament_banners[i % len(ImageUrls.tournament_banners)],
            'bannerImageUrl': ImageUrls.tournament_banners[(i + 1) % len(ImageUrls.tournament_banners)],
            'type': ['knockOut', 'roundRobin', 'league'][i % 3],
            'sportType': sport.lower(),
            'status': status,
            'members': [{
                'id': user_ids[i % len(user_ids)],
                'name': 'Tournament Organizer',
                'role': 'organizer',
                'joinedAt': DataGenerator.random_past_date(90),
            }],
            'createdBy': user_ids[i % len(user_ids)],
            'createdAt': DataGenerator.random_past_date(120),
            'startDate': start_date,
            'endDate': end_date,
            'registrationDeadline': start_date - timedelta(days=3),
            'teamIds': selected_teams,
            'matchIds': [],
            'stat': {
                'totalMatches': team_count * 2,
                'completedMatches': (team_count * 2 if status == 'finished' 
                                   else random.randint(team_count, team_count * 2 - 1) if status == 'running' 
                                   else 0),
                'totalTeams': team_count,
                'activeTeams': team_count,
                'totalGoals': (random.randint(50, 150) if status == 'finished'
                             else random.randint(20, 80) if status == 'running'
                             else 0),
            },
            'isPublic': True,
            'maxTeams': 16,
            'minTeams': 4,
            'location': DataGenerator.random_city(),
            'venueId': venue_ids[i % len(venue_ids)] if venue_ids else None,
            'rules': [
                'All players must be registered before the tournament',
                'Teams must arrive 30 minutes before match time',
                f'Standard {sport} rules apply',
                'Fair play and sportsmanship expected',
            ],
            'prizes': {
                '1st': 'PKR 50,000 + Trophy',
                '2nd': 'PKR 25,000 + Medal',
                '3rd': 'PKR 10,000 + Medal',
            },
            'entryFee': float(random.randint(50, 200) * 100),
            'currency': 'PKR',
        }
        
        # Pre-compute team snapshots for match generation
        team_snapshots = []
        for team_id in selected_teams:
            snapshot = _extract_team_snapshot(db, team_id)
            if snapshot:
                team_snapshots.append(snapshot)
            TEAM_TOURNAMENTS[team_id].add(tournament_id)

        match_payloads = _create_tournament_matches(
            db=db,
            tournament_id=tournament_id,
            tournament_name=tournament_name,
            sport_type=sport.lower(),
            status=status,
            team_snapshots=team_snapshots,
            venue_ids=venue_ids,
        )
        generated_matches.extend(match_payloads)
        tournament_data['matchIds'] = [match['id'] for match in match_payloads]

        tournament_ref.set(tournament_data)
        TOURNAMENT_CACHE[tournament_id] = tournament_data
        tournament_ids.append(tournament_id)
        
        if VERBOSE_LOGGING:
            print(f"   Generated tournament: {tournament_name} ({status})")
    
    print(f"✅ Generated {len(tournament_ids)} tournaments\n")
    return tournament_ids, generated_matches


def _create_tournament_matches(
    db,
    tournament_id: str,
    tournament_name: str,
    sport_type: str,
    status: str,
    team_snapshots: List[Dict[str, Any]],
    venue_ids: List[str],
) -> List[Dict[str, Any]]:
    """Create realistic tournament matches and persist them"""
    if len(team_snapshots) < 2:
        return []

    rounds = [
        'Group Stage',
        'Group Stage',
        'Quarter Final',
        'Semi Final',
        'Final',
    ]
    match_payloads: List[Dict[str, Any]] = []
    total_matches = min(len(rounds), max(2, len(team_snapshots)))

    for idx in range(total_matches):
        team1, team2 = random.sample(team_snapshots, 2)
        scheduled_time = DataGenerator.random_future_date(20) if status == 'upcoming' else dt.now() + timedelta(days=idx)
        match_status = 'scheduled'
        if status == 'running':
            match_status = random.choice(['scheduled', 'live'])
        elif status == 'finished':
            match_status = 'completed'

        team1_score = random.randint(0, 4)
        team2_score = random.randint(0, 4)
        if match_status == 'completed':
            if team1_score == team2_score:
                team1_score += 1
        elif match_status == 'live':
            team2_score = max(0, team1_score - random.randint(0, 1))

        winner_id = None
        result_text = 'Match drawn'
        if team1_score > team2_score:
            winner_id = team1['id']
            result_text = f"{team1['name']} won by {team1_score - team2_score} goals"
        elif team2_score > team1_score:
            winner_id = team2['id']
            result_text = f"{team2['name']} won by {team2_score - team1_score} goals"

        venue_id = venue_ids[idx % len(venue_ids)] if venue_ids else None
        venue_name = VENUE_CACHE.get(venue_id, {}).get('title', 'Champions Sports Complex') if venue_id else 'Champions Sports Complex'

        commentary = [{
            'id': f"{idx}_kickoff",
            'text': f"{team1['name']} vs {team2['name']} kicks off!",
            'timestamp': scheduled_time - timedelta(minutes=1),
            'minute': "0'",
        }]

        match_id = db.collection('tournament_matches').document().id
        match_payload = _build_match_payload(
            match_id=match_id,
            tournament_id=tournament_id,
            tournament_name=tournament_name,
            sport_type=sport_type,
            team1=team1,
            team2=team2,
            scheduled_time=scheduled_time,
            status=match_status,
            round_name=rounds[idx],
            result_meta={
                'team1Score': team1_score,
                'team2Score': team2_score,
                'winnerTeamId': winner_id,
                'resultText': result_text,
                'commentary': commentary,
                'matchNumber': f'Match {idx + 1}',
                'venueName': venue_name,
                'venueId': venue_id,
            },
        )

        db.collection('tournament_matches').document(match_id).set(match_payload)
        match_payloads.append(match_payload)
        TEAM_MATCH_PAYLOADS.append(match_payload)

    return match_payloads

# ============================================================================
# COMMUNITY POSTS GENERATION
# ============================================================================

def generate_community_posts(db, user_ids: List[str], coach_ids: List[str]):
    """Generate community posts with engagement"""
    all_user_ids = user_ids + coach_ids
    
    post_contents = [
        'Just finished an amazing training session! Feeling pumped for the weekend match! 💪⚽',
        'Looking for players to join our weekend football game. DM me if interested!',
        'What a game today! Congratulations to both teams for great sportsmanship 👏',
        'New personal best in the 5K run today! Consistency is key! 🏃‍♂️',
        'Anyone know good cricket coaching centers in the area?',
        'That last match was intense! Great teamwork from everyone! 🔥',
        "Reminder: Tournament registration closes this Friday. Don't miss out!",
        'Just joined a new basketball team. Excited to play with new teammates!',
        "Practice makes perfect! Here's some clips from today's training session.",
        "Weather looking perfect for outdoor sports this weekend! Who's playing?",
        'Huge thanks to our coach for the amazing training program! 🙏',
        'Anyone interested in a friendly badminton match this evening?',
        'Just completed my first tournament! What an experience!',
        'Looking to improve my tennis serve. Any tips?',
        'Great atmosphere at today\'s match! Love this community!',
        'Who else is excited for the upcoming championship? 🏆',
        'Fitness tip: Always warm up before playing. Prevents injuries!',
        'Shoutout to all the amazing players I met this week!',
        'New gear just arrived! Ready to dominate the field! 😎',
        "What's everyone's favorite sport to play?",
        'Just discovered this amazing sports facility near my area!',
        'Anyone want to form a volleyball team?',
        'Recovery day! Remember to rest between training sessions.',
        "That winning goal was incredible! Still can't believe it!",
        'Sports brings us together. Grateful for this community! ❤️',
    ]
    
    print("💬 Generating community posts...")
    
    for i, content in enumerate(post_contents):
        if VERBOSE_LOGGING:
            print(f"   Generating post {i+1}/{len(post_contents)}...")
        
        # Select author
        author_id = all_user_ids[i % len(all_user_ids)]
        
        try:
            author_doc = db.collection('users').document(author_id).get()
            
            if not author_doc.exists:
                continue
            
            author_data = author_doc.to_dict()
        except Exception as e:
            if VERBOSE_LOGGING:
                print(f"   ⚠️  Error fetching author: {e}")
            continue
        
        # Generate post ID
        post_ref = db.collection('community_posts').document()
        post_id = post_ref.id
        
        # Add images (0-3)
        has_images = random.choice([True, False])
        images = random.sample(ImageUrls.community_images, random.randint(0, 3)) if has_images else []
        
        created_at = DataGenerator.random_past_date(180)
        
        # Create post data
        post_data = {
            'id': post_id,
            'authorId': author_id,
            'authorNickname': author_data.get('nickname', author_data['fullName']),
            'authorProfilePicture': author_data.get('profilePictureUrl'),
            'content': content,
            'images': images,
            'createdAt': created_at,
            'updatedAt': created_at,
            'likesCount': random.randint(10, 80),
            'dislikesCount': random.randint(0, 5),
            'commentsCount': random.randint(5, 30),
            'isActive': True,
        }
        
        try:
            post_ref.set(post_data)
            
            # Generate likes (simplified and faster)
            generate_post_likes(db, post_id, all_user_ids, post_data['likesCount'])
            
            # Generate comments (simplified and faster)
            generate_post_comments(db, post_id, all_user_ids, post_data['commentsCount'])
            
            if VERBOSE_LOGGING:
                print(f"   ✓ Post {i+1}/{len(post_contents)} with {post_data['commentsCount']} comments")
        except Exception as e:
            if VERBOSE_LOGGING:
                print(f"   ⚠️  Error creating post {i+1}: {e}")
            continue
    
    print("✅ Generated community content\n")

# ============================================================================
# POST LIKES GENERATION
# ============================================================================

def generate_post_likes(db, post_id: str, user_ids: List[str], count: int):
    """Generate likes/dislikes for a post"""
    # Limit to reasonable number and use batch writes
    count = min(count, 30)  # Max 30 likes per post
    
    shuffled_users = user_ids.copy()
    random.shuffle(shuffled_users)
    
    batch = db.batch()
    batch_count = 0
    
    for i in range(min(count, len(shuffled_users))):
        user_id = shuffled_users[i]
        
        # Simplified: Don't fetch user data for likes, use cached nickname
        like_ref = db.collection('community_likes').document()
        like_data = {
            'postId': post_id,
            'userId': user_id,
            'userNickname': f'User{i}',  # Simplified to avoid extra reads
            'isLike': random.random() > 0.1,  # 90% likes, 10% dislikes
            'createdAt': DataGenerator.random_past_date(90),
        }
        
        batch.set(like_ref, like_data)
        batch_count += 1
        
        # Commit in batches of 100
        if batch_count >= 100:
            try:
                batch.commit()
                batch = db.batch()
                batch_count = 0
            except Exception as e:
                if VERBOSE_LOGGING:
                    print(f"   ⚠️  Error committing likes batch: {e}")
    
    # Commit remaining
    if batch_count > 0:
        try:
            batch.commit()
        except Exception as e:
            if VERBOSE_LOGGING:
                print(f"   ⚠️  Error committing final likes: {e}")

# ============================================================================
# POST COMMENTS GENERATION
# ============================================================================

def generate_post_comments(db, post_id: str, user_ids: List[str], count: int):
    """Generate comments and replies for a post"""
    comment_texts = [
        'Great post!', 'Totally agree with this!', 'This is amazing! 🔥',
        'Well said!', 'Thanks for sharing!', 'I had the same experience!',
        'Count me in!', 'When and where?', 'This is so true!',
        'Love this! ❤️', "Couldn't have said it better!", 'Absolutely!',
        'This made my day!', 'So inspiring!', "Let's do this!",
        "I'm interested!", 'Perfect timing!', 'Exactly what I needed to hear!',
        "Can't wait!", 'This is the way!',
    ]
    
    # Limit comment count to reasonable number
    count = min(count, 20)  # Max 20 comments per post to avoid hanging
    
    shuffled_users = user_ids.copy()
    random.shuffle(shuffled_users)
    comment_ids = []
    
    # Cache user data to avoid repeated Firestore reads
    user_cache = {}
    
    # Generate top-level comments
    for i in range(min(count, len(shuffled_users))):
        user_id = shuffled_users[i]
        
        # Get from cache or fetch
        if user_id not in user_cache:
            try:
                user_doc = db.collection('users').document(user_id).get()
                if not user_doc.exists:
                    continue
                user_cache[user_id] = user_doc.to_dict()
            except Exception as e:
                if VERBOSE_LOGGING:
                    print(f"   ⚠️  Error fetching user {user_id}: {e}")
                continue
        
        user_data = user_cache[user_id]
        
        comment_ref = db.collection('community_comments').document()
        comment_id = comment_ref.id
        
        comment_data = {
            'id': comment_id,
            'postId': post_id,
            'authorId': user_id,
            'authorNickname': user_data.get('nickname', user_data.get('fullName', 'User')),
            'authorProfilePicture': user_data.get('profilePictureUrl'),
            'content': comment_texts[i % len(comment_texts)],
            'createdAt': DataGenerator.random_past_date(90),
            'updatedAt': DataGenerator.random_past_date(90),
            'parentCommentId': None,
            'repliesCount': 0,
            'isActive': True,
        }
        
        try:
            comment_ref.set(comment_data)
            comment_ids.append(comment_id)
        except Exception as e:
            if VERBOSE_LOGGING:
                print(f"   ⚠️  Error creating comment: {e}")
            continue
    
    # Generate replies (about 33% of comments, max 5 replies per post)
    if len(comment_ids) == 0:
        return  # No comments to reply to
    
    reply_count = min(count // 3, len(comment_ids), 5)  # Limit to 5 replies
    
    for i in range(reply_count):
        user_idx = (i + count) % len(shuffled_users)
        user_id = shuffled_users[user_idx]
        
        # Get from cache or fetch
        if user_id not in user_cache:
            try:
                user_doc = db.collection('users').document(user_id).get()
                if not user_doc.exists:
                    continue
                user_cache[user_id] = user_doc.to_dict()
            except Exception as e:
                if VERBOSE_LOGGING:
                    print(f"   ⚠️  Error fetching user for reply: {e}")
                continue
        
        user_data = user_cache[user_id]
        parent_comment_id = comment_ids[i % len(comment_ids)]
        
        reply_data = {
            'postId': post_id,
            'authorId': user_id,
            'authorNickname': user_data.get('nickname', user_data.get('fullName', 'User')),
            'authorProfilePicture': user_data.get('profilePictureUrl'),
            'content': comment_texts[(i + 10) % len(comment_texts)],
            'createdAt': DataGenerator.random_past_date(80),
            'updatedAt': DataGenerator.random_past_date(80),
            'parentCommentId': parent_comment_id,
            'repliesCount': 0,
            'isActive': True,
        }
        
        try:
            db.collection('community_comments').add(reply_data)
            
            # Update parent comment's reply count
            db.collection('community_comments').document(parent_comment_id).update({
                'repliesCount': firestore.Increment(1)
            })
        except Exception as e:
            if VERBOSE_LOGGING:
                print(f"   ⚠️  Error creating reply: {e}")
            continue

# ============================================================================
# SHOWCASE TOURNAMENT WITH REAL MATCH DATA
# ============================================================================

def _extract_team_snapshot(db, team_id: str) -> Dict[str, Any]:
    """Fetch team document and normalize useful fields"""
    doc = db.collection('teams').document(team_id).get()
    if not doc.exists:
        return {}

    data = doc.to_dict() or {}
    players_raw = data.get('players') or data.get('members') or []

    def _normalize_player(entry: Dict[str, Any]) -> Dict[str, Any]:
        player_id = entry.get('userId') or entry.get('id') or entry.get('uid')
        name = entry.get('userName') or entry.get('name') or entry.get('fullName') or 'Player'
        return {
            'id': player_id,
            'name': name,
            'profileImageUrl': entry.get('profileImageUrl') or entry.get('avatarUrl'),
        }

    players = []
    for raw_player in players_raw:
        normalized = _normalize_player(raw_player)
        if normalized.get('id'):
            players.append(normalized)
    if not players:
        # Fallback to owner if no players list exists
        owner_id = data.get('ownerId') or data.get('createdBy')
        if owner_id:
            players = [{
                'id': owner_id,
                'name': data.get('ownerName') or data.get('name') or 'Captain',
                'profileImageUrl': data.get('teamImageUrl'),
            }]

    captain = next(
        (p for p in players_raw if str(p.get('role', '')).lower() in ['captain', 'owner']),
        None,
    )

    return {
        'id': team_id,
        'name': data.get('name') or 'Team',
        'logo': data.get('teamImageUrl') or data.get('profileImageUrl'),
        'city': data.get('city') or data.get('location') or 'Karachi',
        'players': players,
        'captainName': captain.get('name') if isinstance(captain, dict) else (players[0]['name'] if players else 'Captain'),
        'captainId': captain.get('userId') if isinstance(captain, dict) else (players[0]['id'] if players else None),
    }

def _build_match_payload(match_id: str,
                         tournament_id: str,
                         tournament_name: str,
                         sport_type: str,
                         team1: Dict[str, Any],
                         team2: Dict[str, Any],
                         scheduled_time: datetime.datetime,
                         status: str,
                         round_name: str,
                         result_meta: Dict[str, Any]) -> Dict[str, Any]:
    now = dt.now()

    def _score_entry(team: Dict[str, Any], score: int) -> Dict[str, Any]:
        return {
            'teamId': team['id'],
            'teamName': team['name'],
            'teamLogoUrl': team['logo'],
            'score': score,
            'playerIds': [p['id'] for p in team['players']][:15],
        }

    payload = {
        'id': match_id,
        'tournamentId': tournament_id,
        'tournamentName': tournament_name,
        'sportType': sport_type,
        'team1': _score_entry(team1, result_meta['team1Score']),
        'team2': _score_entry(team2, result_meta['team2Score']),
        'matchNumber': result_meta['matchNumber'],
        'round': round_name,
        'scheduledTime': scheduled_time,
        'status': status,
        'commentary': result_meta['commentary'],
        'createdAt': now,
        'updatedAt': now,
        'venueName': result_meta.get('venueName', 'Champions Sports Complex'),
        'venueId': result_meta.get('venueId'),
        'metadata': {
            'broadcast': result_meta.get('broadcast', 'PlayAround TV'),
            'weather': result_meta.get('weather', 'Clear 26°C'),
        },
    }

    if status in ['live', 'completed']:
        payload['actualStartTime'] = scheduled_time - timedelta(minutes=15)

    if status == 'completed':
        payload['actualEndTime'] = scheduled_time + timedelta(minutes=110)
        payload['result'] = result_meta['resultText']
        payload['winnerTeamId'] = result_meta['winnerTeamId']

    if status == 'live':
        payload['commentary'] += [{
            'id': f"{match_id}_live_{i}",
            'text': text,
            'timestamp': now - timedelta(minutes=(5 - i)),
            'minute': f"{60 + (i * 5)}'",
        } for i, text in enumerate([
            '⚽ Intense midfield battle underway.',
            '🟨 Yellow card issued after a rough tackle.',
            '🔥 Close miss! The stadium gasps.',
        ], start=1)]

    return payload

def create_showcase_tournament(db, team_ids: List[str], user_ids: List[str]) -> Tuple[str, List[Dict[str, Any]]]:
    """Create flagship tournament with rich Firebase data"""
    print("🎯 Creating showcase tournament with live data...")

    if len(team_ids) < 8:
        print("   ⚠️ Not enough teams to create showcase tournament. Skipping.")
        return '', []

    selected_team_ids = team_ids[:min(len(team_ids), 16)]
    tournament_ref = db.collection('tournaments').document()
    tournament_id = tournament_ref.id

    team_snapshots = []
    for team_id in selected_team_ids:
        snapshot = _extract_team_snapshot(db, team_id)
        if snapshot:
            team_snapshots.append(snapshot)
            TEAM_TOURNAMENTS[team_id].add(tournament_id)

    if len(team_snapshots) < 8:
        print("   ⚠️ Unable to fetch enough team details. Skipping showcase tournament.")
        return '', []

    random.shuffle(team_snapshots)
    tournament_name = 'PlayAround Super League'
    start_date = dt.now() + timedelta(days=5)
    end_date = start_date + timedelta(days=10)
    organizer_id = user_ids[0] if user_ids else 'system_admin'

    profile_image = ImageUrls.tournament_banners[0]
    banner_image = ImageUrls.tournament_banners[1]

    metadata_leaderboard = []
    base_points = 36
    for position, team in enumerate(team_snapshots[:15], start=1):
        wins = max(0, 10 - position)
        draws = max(0, 3 - (position // 4))
        losses = max(0, position - 5)
        goals_for = 20 + random.randint(0, 12) - position
        goals_against = 10 + position
        metadata_leaderboard.append({
            'teamId': team['id'],
            'teamName': team['name'],
            'position': position,
            'wins': wins,
            'draws': draws,
            'losses': losses,
            'points': wins * 3 + draws,
            'goalsFor': goals_for,
            'goalsAgainst': goals_against,
            'goalDifference': goals_for - goals_against,
            'captainName': team['captainName'],
            'roster': [player['name'] for player in team['players'][:11]],
        })

    tournament_data = {
        'id': tournament_id,
        'name': tournament_name,
        'description': 'Fully managed invitational league with live scoring, commentary, and leaderboards.',
        'sportType': 'football',
        'format': 'league',
        'status': 'running',
        'organizerId': organizer_id,
        'organizerName': 'PlayAround Admin',
        'registrationStartDate': start_date - timedelta(days=25),
        'registrationEndDate': start_date - timedelta(days=5),
        'startDate': start_date,
        'endDate': end_date,
        'maxTeams': 16,
        'minTeams': 8,
        'currentTeamsCount': len(team_snapshots),
        'location': 'Karachi, Pakistan',
        'venueName': 'Champions Sports Complex',
        'imageUrl': profile_image,
        'bannerImageUrl': banner_image,
        'profileImageUrl': profile_image,
        'rules': [
            'FIFA standard rules apply.',
            'Rolling substitutions available.',
            'Match duration 2 x 45 mins plus stoppage time.',
        ],
        'prizes': {
            '1st': 'PKR 150,000 + Trophy',
            '2nd': 'PKR 75,000 + Medals',
            '3rd': 'PKR 35,000 + Medals',
        },
        'isPublic': True,
        'winningPrize': 150000.0,
        'entryFee': 15000.0,
        'teamIds': [team['id'] for team in team_snapshots],
        'stat': {
            'totalMatches': 10,
            'completedMatches': 3,
            'upcomingMatches': 4,
            'activeTeams': len(team_snapshots),
            'totalGoals': 42,
        },
        'metadata': {
            'manualLeaderboard': metadata_leaderboard,
            'city': 'Karachi',
            'sponsor': 'PlayAround',
            'winningPrizeLabel': 'PKR 150k + Trophy',
        },
        'createdAt': dt.now(),
        'updatedAt': dt.now(),
    }

    tournament_ref.set(tournament_data)
    TOURNAMENT_CACHE[tournament_id] = tournament_data

    # Create registrations for each team
    for team in team_snapshots:
        registration_ref = db.collection('tournament_registrations').document()
        registration_ref.set({
            'id': registration_ref.id,
            'tournamentId': tournament_id,
            'tournamentName': tournament_name,
            'teamId': team['id'],
            'teamName': team['name'],
            'registeredBy': organizer_id,
            'registeredByName': 'Tournament Admin',
            'status': 'approved',
            'registeredAt': dt.now() - timedelta(days=4),
            'approvalDate': dt.now() - timedelta(days=3),
            'teamMemberIds': [player['id'] for player in team['players']],
            'teamMemberNames': [player['name'] for player in team['players']],
        })

    # Build matches (scheduled + live + completed)
    match_ids = []
    match_payloads: List[Dict[str, Any]] = []
    schedule_base = dt.now() + timedelta(days=1)
    match_templates = [
        ('scheduled', 'Group Stage'),
        ('scheduled', 'Group Stage'),
        ('scheduled', 'Group Stage'),
        ('live', 'Group Stage'),
        ('live', 'Group Stage'),
        ('completed', 'Group Stage'),
        ('completed', 'Group Stage'),
        ('completed', 'Quarter Final'),
        ('scheduled', 'Quarter Final'),
        ('scheduled', 'Semi Final'),
    ]

    for idx, (status, round_name) in enumerate(match_templates, start=1):
        team1, team2 = random.sample(team_snapshots, 2)
        scheduled_time = schedule_base + timedelta(days=idx // 2, hours=(idx % 3) * 2 + 14)

        team1_score = random.randint(0, 4)
        team2_score = random.randint(0, 4)
        if status == 'completed':
            if team1_score == team2_score:
                team1_score += 1
        if status == 'live':
            # Keep score close for live matches
            team2_score = max(0, team1_score - random.randint(0, 1))

        winner_id = None
        result_text = 'Match drawn'
        if team1_score > team2_score:
            winner_id = team1['id']
            result_text = f"{team1['name']} won by {team1_score - team2_score} goals"
        elif team2_score > team1_score:
            winner_id = team2['id']
            result_text = f"{team2['name']} won by {team2_score - team1_score} goals"

        commentary = [{
            'id': f"{idx}_kickoff",
            'text': f"{team1['name']} vs {team2['name']} kicks off!",
            'timestamp': scheduled_time - timedelta(minutes=1),
            'minute': "0'",
        }]

        match_id = db.collection('tournament_matches').document().id
        match_payload = _build_match_payload(
            match_id=match_id,
            tournament_id=tournament_id,
            tournament_name=tournament_name,
            sport_type='football',
            team1=team1,
            team2=team2,
            scheduled_time=scheduled_time,
            status=status,
            round_name=round_name,
            result_meta={
                'team1Score': team1_score,
                'team2Score': team2_score,
                'winnerTeamId': winner_id,
                'resultText': result_text,
                'commentary': commentary,
                'matchNumber': f'Match {idx}',
                'venueName': 'Champions Sports Complex',
            },
        )

        db.collection('tournament_matches').document(match_id).set(match_payload)
        match_ids.append(match_id)
        match_payloads.append(match_payload)
        TEAM_MATCH_PAYLOADS.append(match_payload)

    tournament_ref.update({
        'matchIds': match_ids,
        'stat': {
            'totalMatches': len(match_ids),
            'completedMatches': len([m for m in match_templates if m[0] == 'completed']),
            'upcomingMatches': len([m for m in match_templates if m[0] == 'scheduled']),
            'liveMatches': len([m for m in match_templates if m[0] == 'live']),
            'activeTeams': len(team_snapshots),
            'totalGoals': random.randint(30, 60),
        },
    })

    print(f"✅ Showcase tournament created with {len(match_ids)} matches and {len(team_snapshots)} teams.")
    return tournament_id, match_payloads

# ============================================================================
# DATA POST-PROCESSING / SYNCHRONIZATION
# ============================================================================

def post_process_data(
    db,
    user_ids: List[str],
    coach_ids: List[str],
    team_ids: List[str],
    venue_ids: List[str],
    tournament_ids: List[str],
    match_payloads: List[Dict[str, Any]],
):
    """Hydrate cross-module data so every surface has consistent content."""
    print("🔁 Post-processing generated data...")

    match_lookup = _build_team_match_lookup(match_payloads)
    _write_team_match_documents(db, match_payloads)
    _update_team_documents(db, match_lookup)

    follower_map, following_map = _build_connection_graph(
        db=db,
        user_pool=list(dict.fromkeys(user_ids + coach_ids)),
    )

    _seed_public_profiles(
        db=db,
        user_pool=list(dict.fromkeys(user_ids + coach_ids)),
        match_lookup=match_lookup,
        follower_map=follower_map,
        following_map=following_map,
    )

    _seed_venue_reviews_and_bookings(
        db=db,
        venue_ids=venue_ids,
        author_pool=list(dict.fromkeys(user_ids + coach_ids)),
    )

    print("✅ Data graph synchronized across modules.\n")


def _build_team_match_lookup(match_payloads: List[Dict[str, Any]]) -> Dict[str, List[Dict[str, Any]]]:
    lookup: Dict[str, List[Dict[str, Any]]] = defaultdict(list)
    for match in match_payloads:
        for team_key in ['team1', 'team2']:
            team_info = match.get(team_key) or {}
            team_id = team_info.get('teamId')
            if not team_id:
                continue
            lookup[team_id].append({
                'match': match,
                'teamKey': team_key,
            })
    return lookup


def _convert_match_to_team_match_doc(match: Dict[str, Any]) -> Dict[str, Any]:
    def _score_payload(entry: Dict[str, Any]) -> Dict[str, Any]:
        return {
            'teamId': entry.get('teamId'),
            'teamName': entry.get('teamName'),
            'teamLogoUrl': entry.get('teamLogoUrl'),
            'score': entry.get('score', 0),
            'playerIds': entry.get('playerIds', []),
        }

    scheduled_time = match.get('scheduledTime') or dt.now()
    status = match.get('status', 'scheduled')

    payload = {
        'id': match['id'],
        'homeTeamId': match['team1']['teamId'],
        'awayTeamId': match['team2']['teamId'],
        'homeTeam': _score_payload(match['team1']),
        'awayTeam': _score_payload(match['team2']),
        'sportType': match.get('sportType', 'football'),
        'matchType': 'tournament',
        'status': status,
        'scheduledTime': scheduled_time,
        'actualStartTime': match.get('actualStartTime'),
        'actualEndTime': match.get('actualEndTime'),
        'tournamentId': match.get('tournamentId'),
        'tournamentName': match.get('tournamentName'),
        'venueId': match.get('venueId'),
        'venueName': match.get('venueName'),
        'venueLocation': VENUE_CACHE.get(match.get('venueId'), {}).get('location'),
        'result': match.get('result'),
        'winnerTeamId': match.get('winnerTeamId'),
        'notes': match.get('metadata', {}).get('broadcast'),
        'metadata': {
            'round': match.get('round'),
            'commentary': match.get('commentary', []),
        },
        'createdAt': match.get('createdAt', dt.now()),
        'createdBy': 'system_seed_script',
    }
    return payload


def _write_team_match_documents(db, match_payloads: List[Dict[str, Any]]):
    matches_collection = db.collection('team_matches')
    for match in match_payloads:
        doc_payload = _convert_match_to_team_match_doc(match)
        matches_collection.document(match['id']).set(doc_payload)
        for team_key in ['team1', 'team2']:
            team_id = match[team_key]['teamId']
            team_ref = db.collection('teams').document(team_id).collection('matches').document(match['id'])
            team_ref.set(doc_payload, merge=True)


def _compute_team_stats(team_id: str, matches: List[Dict[str, Any]]) -> Dict[str, Any]:
    stats = {
        'played': 0,
        'wins': 0,
        'losses': 0,
        'draws': 0,
        'goalsScored': 0,
        'goalsConceded': 0,
        'cleanSheets': 0,
        'matchIds': [],
        'tournamentIds': set(),
        'venueIds': set(),
        'recentOpponents': [],
    }

    for wrapper in matches:
        match = wrapper['match']
        stats['matchIds'].append(match['id'])
        if match.get('tournamentId'):
            stats['tournamentIds'].add(match['tournamentId'])
        if match.get('venueId'):
            stats['venueIds'].add(match['venueId'])

        team_key = wrapper['teamKey']
        opponent_key = 'team1' if team_key == 'team2' else 'team2'
        team_entry = match[team_key]
        opponent_entry = match[opponent_key]

        team_score = team_entry.get('score', 0)
        opponent_score = opponent_entry.get('score', 0)

        stats['goalsScored'] += team_score
        stats['goalsConceded'] += opponent_score

        if match['status'] == 'completed':
            stats['played'] += 1
            winner = match.get('winnerTeamId')
            if winner == team_id:
                stats['wins'] += 1
            elif winner:
                stats['losses'] += 1
            else:
                stats['draws'] += 1
            if opponent_score == 0:
                stats['cleanSheets'] += 1
        elif match['status'] != 'scheduled':
            stats['played'] += 1

        stats['recentOpponents'].append({
            'opponentId': opponent_entry.get('teamId'),
            'opponentName': opponent_entry.get('teamName'),
            'result': match.get('result'),
            'round': match.get('round'),
            'time': match.get('scheduledTime'),
            'venueId': match.get('venueId'),
            'venueName': match.get('venueName'),
            'matchId': match['id'],
        })

    if stats['played'] == 0:
        stats['winPercentage'] = 0.0
    else:
        stats['winPercentage'] = round((stats['wins'] / stats['played']) * 100, 2)

    return stats


def _update_team_documents(db, match_lookup: Dict[str, List[Dict[str, Any]]]):
    if not match_lookup:
        return

    print("   › Updating team stats, history, and achievements...")
    for team_id, matches in match_lookup.items():
        team_data = TEAM_CACHE.get(team_id)
        if not team_data:
            continue

        stats = _compute_team_stats(team_id, matches)
        metadata = dict(team_data.get('metadata') or {})
        metadata.update({
            'matchesPlayed': stats['played'],
            'matchesWon': stats['wins'],
            'matchesLost': stats['losses'],
            'winPercentage': stats['winPercentage'],
            'lastSyncedAt': dt.now(),
            'recentOpponents': stats['recentOpponents'][:5],
        })

        team_ref = db.collection('teams').document(team_id)
        update_payload = {
            'matchIds': stats['matchIds'],
            'tournamentIds': list(stats['tournamentIds']),
            'venueIds': list(stats['venueIds']),
            'metadata': metadata,
            'stat': {
                'played': stats['played'],
                'won': stats['wins'],
                'lost': stats['losses'],
                'draw': stats['draws'],
                'goalsScored': stats['goalsScored'],
                'goalsConceded': stats['goalsConceded'],
                'points': stats['wins'] * 3 + stats['draws'],
            },
        }
        team_ref.update(update_payload)

        TEAM_CACHE[team_id]['metadata'] = metadata
        TEAM_CACHE[team_id]['stat'] = update_payload['stat']
        TEAM_CACHE[team_id]['matchIds'] = stats['matchIds']
        TEAM_CACHE[team_id]['tournamentIds'] = list(stats['tournamentIds'])
        TEAM_CACHE[team_id]['venueIds'] = list(stats['venueIds'])

        _write_team_subcollections(db, team_id, stats, matches)


def _write_team_subcollections(db, team_id: str, stats: Dict[str, Any], matches: List[Dict[str, Any]]):
    team_ref = db.collection('teams').document(team_id)

    # Overview cards
    overview_cards = _build_overview_cards(stats)
    overview_collection = team_ref.collection('overview_cards')
    for card in overview_cards:
        card_id = card.pop('id')
        overview_collection.document(card_id).set(card, merge=True)

    # Achievements
    achievements = _build_team_achievements(team_id, matches, stats)
    achievements_collection = team_ref.collection('achievements')
    for achievement in achievements:
        achievement_id = achievement.pop('id')
        achievements_collection.document(achievement_id).set(achievement, merge=True)

    # History
    history_entries = _build_team_history_entries(team_id, matches)
    history_collection = team_ref.collection('history')
    for entry in history_entries:
        entry_id = entry.pop('id')
        history_collection.document(entry_id).set(entry, merge=True)

    # Tournaments
    tournament_entries = _build_tournament_entries(team_id)
    tournaments_collection = team_ref.collection('tournaments')
    for entry in tournament_entries:
        entry_id = entry.pop('id')
        tournaments_collection.document(entry_id).set(entry, merge=True)

    # Player highlights
    highlights = _build_player_highlights(team_id)
    highlights_collection = team_ref.collection('player_highlights')
    for highlight in highlights:
        player_id = highlight.pop('playerId')
        highlights_collection.document(player_id).set(highlight, merge=True)

    # Performance aggregate
    performance_ref = team_ref.collection('performance').document('aggregate')
    performance_ref.set({
        'teamId': team_id,
        'teamName': TEAM_CACHE.get(team_id, {}).get('name'),
        'totalMatches': stats['played'],
        'wins': stats['wins'],
        'losses': stats['losses'],
        'draws': stats['draws'],
        'winPercentage': stats['winPercentage'],
        'totalGoalsScored': stats['goalsScored'],
        'totalGoalsConceded': stats['goalsConceded'],
        'cleanSheets': stats['cleanSheets'],
        'averageGoalsPerMatch': round(
            stats['goalsScored'] / stats['played'], 2
        ) if stats['played'] else 0.0,
        'lastUpdated': dt.now(),
    }, merge=True)


def _build_team_history_entries(team_id: str, matches: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    history_entries = []
    team_name = TEAM_CACHE.get(team_id, {}).get('name', 'Team')
    for wrapper in matches:
        match = wrapper['match']
        opponent_key = 'team1' if wrapper['teamKey'] == 'team2' else 'team2'
        opponent = match[opponent_key]
        venue = VENUE_CACHE.get(match.get('venueId'), {})

        history_entries.append({
            'id': f"{team_id}_{match['id']}",
            'venue': match.get('venueName') or venue.get('title', 'Home Ground'),
            'opponent': opponent.get('teamName'),
            'date': match.get('scheduledTime') or dt.now(),
            'matchType': match.get('round') or 'Tournament',
            'result': match.get('result') or 'Scheduled',
            'summary': f"{team_name} vs {opponent.get('teamName')} at {match.get('venueName', 'venue TBA')}",
            'location': venue.get('location', 'Pakistan'),
            'matchId': match['id'],
            'venueId': match.get('venueId'),
        })
    return history_entries[:10]


def _build_team_achievements(team_id: str, matches: List[Dict[str, Any]], stats: Dict[str, Any]) -> List[Dict[str, Any]]:
    achievements = []
    for wrapper in matches:
        match = wrapper['match']
        if match.get('status') != 'completed':
            continue
        if match.get('round', '').lower() == 'final' and match.get('winnerTeamId') == team_id:
            achievements.append({
                'id': f"{team_id}_{match['id']}_champion",
                'teamId': team_id,
                'title': f"{match.get('tournamentName')} Champions",
                'description': f"Victory against {match['team2']['teamName']} with result {match.get('result')}",
                'type': 'tournament_win',
                'achievedAt': match.get('scheduledTime') or dt.now(),
                'metadata': {
                    'tournamentId': match.get('tournamentId'),
                },
            })
        elif match.get('round', '').lower() == 'final':
            achievements.append({
                'id': f"{team_id}_{match['id']}_finalist",
                'teamId': team_id,
                'title': f"{match.get('tournamentName')} Finalist",
                'description': f"Reached the final against {match['team2']['teamName']}",
                'type': 'tournament_finalist',
                'achievedAt': match.get('scheduledTime') or dt.now(),
                'metadata': {
                    'tournamentId': match.get('tournamentId'),
                },
            })

    achievements.append({
        'id': f"{team_id}_season_highlight",
        'teamId': team_id,
        'title': f"{stats['wins']} Wins this Season",
        'description': 'Auto-generated based on live tournament data.',
        'type': 'season_highlight',
        'achievedAt': dt.now(),
        'metadata': {},
    })

    return achievements


def _build_overview_cards(stats: Dict[str, Any]) -> List[Dict[str, Any]]:
    return [
        {
            'id': 'matches_played',
            'title': 'Matches Played',
            'value': str(stats['played']),
            'trendLabel': f"{stats['wins']} wins",
            'trendIsPositive': stats['wins'] >= stats['losses'],
            'description': 'Across league and knockout fixtures',
            'iconName': 'sports_score',
        },
        {
            'id': 'goals_scored',
            'title': 'Goals Scored',
            'value': str(stats['goalsScored']),
            'trendLabel': f"{stats['goalsConceded']} conceded",
            'trendIsPositive': stats['goalsScored'] >= stats['goalsConceded'],
            'description': 'Team attacking output',
            'iconName': 'sports_soccer',
        },
        {
            'id': 'win_rate',
            'title': 'Win %',
            'value': f"{stats['winPercentage']}%",
            'trendLabel': 'Season-to-date',
            'trendIsPositive': stats['winPercentage'] >= 50,
            'description': 'Calculated from tournament games',
            'iconName': 'military_tech',
        },
    ]


def _build_player_highlights(team_id: str) -> List[Dict[str, Any]]:
    highlights = []
    team_data = TEAM_CACHE.get(team_id, {})
    for member in team_data.get('players', [])[:3]:
        player_id = member.get('id') or member.get('userId')
        if not player_id:
            continue
        user_data = USER_CACHE.get(player_id, {})
        player_stats = user_data.get('playerStats', {})
        matches_played = player_stats.get('matchesPlayed')
        if matches_played is None:
            matches_played = stats_random(12, 30)
        goals = player_stats.get('goals')
        if goals is None:
            goals = stats_random(2, 15)
        assists = player_stats.get('assists')
        if assists is None:
            assists = stats_random(1, 10)
        mvps = player_stats.get('mvpAwards')
        if mvps is None:
            mvps = stats_random(0, 5)
        highlights.append({
            'playerId': player_id,
            'playerName': member.get('name') or user_data.get('fullName'),
            'avatarUrl': member.get('profileImageUrl') or user_data.get('profilePictureUrl', ''),
            'metrics': {
                'Matches': matches_played,
                'Goals': goals,
                'Assists': assists,
                'MVPs': mvps,
            },
        })
    return highlights


def stats_random(low: int, high: int) -> int:
    return random.randint(low, high)


def _build_tournament_entries(team_id: str) -> List[Dict[str, Any]]:
    entries = []
    for tournament_id in TEAM_TOURNAMENTS.get(team_id, []):
        tournament = TOURNAMENT_CACHE.get(tournament_id)
        if not tournament:
            continue
        entries.append({
            'id': tournament_id,
            'tournamentName': tournament.get('name'),
            'status': tournament.get('status', 'upcoming'),
            'stage': tournament.get('type', 'league'),
            'startDate': tournament.get('startDate', dt.now()),
            'tournamentId': tournament_id,
            'logoUrl': tournament.get('profileImageUrl'),
        })
    return entries


def _build_association_card(
    entity_id: str,
    title: str,
    subtitle: str,
    role: str,
    image_url: str,
    tags: List[str],
    location: Optional[str] = None,
    status: Optional[str] = None,
    description: Optional[str] = None,
    since: Any = None,
    owner_name: Optional[str] = None,
    owner_id: Optional[str] = None,
) -> Dict[str, Any]:
    card = {
        'id': entity_id,
        'title': title,
        'subtitle': subtitle,
        'role': role,
        'imageUrl': image_url,
        'tags': tags,
    }
    if location:
        card['location'] = location
    if status:
        card['status'] = status
    if description:
        card['description'] = description
    if since:
        card['since'] = since
    if owner_name:
        card['ownerName'] = owner_name
    if owner_id:
        card['ownerId'] = owner_id
    return card


def _build_connection_graph(db, user_pool: List[str]) -> Tuple[Dict[str, Set[str]], Dict[str, Set[str]]]:
    follower_map: Dict[str, Set[str]] = defaultdict(set)
    following_map: Dict[str, Set[str]] = defaultdict(set)
    connection_collection = db.collection('connections')
    seen_pairs: Set[Tuple[str, str]] = set()

    for user_id in user_pool:
        others = [uid for uid in user_pool if uid != user_id]
        if not others:
            continue
        sample_size = min(6, len(others))
        for target_id in random.sample(others, sample_size):
            pair = tuple(sorted((user_id, target_id)))
            if pair in seen_pairs:
                continue
            seen_pairs.add(pair)

            from_id, to_id = pair
            from_user = USER_CACHE.get(from_id)
            to_user = USER_CACHE.get(to_id)
            if not from_user or not to_user:
                continue

            doc_id = f"{pair[0]}_{pair[1]}"
            connection_collection.document(doc_id).set({
                'id': doc_id,
                'fromUserId': from_id,
                'toUserId': to_id,
                'fromUserName': from_user.get('fullName'),
                'toUserName': to_user.get('fullName'),
                'fromUserImageUrl': from_user.get('profilePictureUrl'),
                'toUserImageUrl': to_user.get('profilePictureUrl'),
                'status': 'accepted',
                'message': "Let's connect on PlayAround!",
                'createdAt': DataGenerator.random_past_date(45),
                'updatedAt': dt.now(),
                'respondedAt': dt.now(),
            })

            follower_map[from_id].add(to_id)
            follower_map[to_id].add(from_id)
            following_map[from_id].add(to_id)
            following_map[to_id].add(from_id)

    return follower_map, following_map


def _build_connection_entries(target_ids: Set[str], following_lookup: Set[str]) -> List[Dict[str, Any]]:
    entries = []
    for uid in target_ids:
        user_data = USER_CACHE.get(uid)
        if not user_data:
            continue
        entries.append({
            'userId': uid,
            'name': user_data.get('fullName', 'Athlete'),
            'avatarUrl': user_data.get('profilePictureUrl', ''),
            'isFollowing': uid in following_lookup,
        })
    return entries


def _seed_public_profiles(
    db,
    user_pool: List[str],
    match_lookup: Dict[str, List[Dict[str, Any]]],
    follower_map: Dict[str, Set[str]],
    following_map: Dict[str, Set[str]],
):
    print("   › Hydrating public profiles...")
    profiles_collection = db.collection('public_profiles')

    for user_id in user_pool:
        user_data = USER_CACHE.get(user_id)
        if not user_data:
            continue

        memberships = USER_TEAM_MEMBERSHIPS.get(user_id, [])
        teams_cards: Dict[str, Dict[str, Any]] = {}
        tournament_cards: Dict[str, Dict[str, Any]] = {}
        venue_cards: Dict[str, Dict[str, Any]] = {}
        coach_cards: Dict[str, Dict[str, Any]] = {}

        for membership in memberships:
            team_id = membership['teamId']
            team = TEAM_CACHE.get(team_id, {})
            if team:
                card = _build_association_card(
                    entity_id=team_id,
                    title=team.get('name', 'Team'),
                    subtitle=f"{team.get('sportType', 'sport').title()} • {team.get('city', 'Pakistan')}",
                    role=membership['role'].replace('_', ' ').title(),
                    image_url=team.get('profileImageUrl', ''),
                    tags=[team.get('city', 'Pakistan'), team.get('sportType', 'sport').title()],
                    location=team.get('city'),
                    status='Active',
                    description=team.get('bio'),
                    since=membership.get('joinedAt'),
                    owner_name=USER_CACHE.get(team.get('ownerId'), {}).get('fullName'),
                    owner_id=team.get('ownerId'),
                )
                teams_cards[team_id] = card

                for venue_id in team.get('venueIds', []):
                    venue = VENUE_CACHE.get(venue_id)
                    if not venue:
                        continue
                    venue_cards[venue_id] = _build_association_card(
                        entity_id=venue_id,
                        title=venue['title'],
                        subtitle=venue['location'],
                        role='Training Venue',
                        image_url=(venue.get('images') or [''])[0],
                        tags=[venue.get('sportType', '').title()],
                        location=venue.get('location'),
                        status='Partner',
                        description=venue.get('description'),
                    )

                for tournament_id in TEAM_TOURNAMENTS.get(team_id, []):
                    tournament = TOURNAMENT_CACHE.get(tournament_id)
                    if not tournament:
                        continue
                    tournament_cards[tournament_id] = _build_association_card(
                        entity_id=tournament_id,
                        title=tournament['name'],
                        subtitle=tournament.get('status', 'upcoming').title(),
                        role='Participant',
                        image_url=tournament.get('profileImageUrl', ''),
                        tags=[tournament.get('sportType', '').title()],
                        status=tournament.get('status', 'upcoming').title(),
                        description=tournament.get('description'),
                        since=tournament.get('startDate'),
                    )

                for coach in team.get('coaches', []):
                    coach_id = coach.get('id') or coach.get('userId')
                    if not coach_id:
                        continue
                    coach_user = USER_CACHE.get(coach_id)
                    if not coach_user:
                        continue
                    coach_cards[coach_id] = _build_association_card(
                        entity_id=coach_id,
                        title=coach_user.get('fullName', coach.get('name', 'Coach')),
                        subtitle=', '.join(coach_user.get('specializationSports', [])) or 'Performance Coach',
                        role='Coach',
                        image_url=coach_user.get('profilePictureUrl', ''),
                        tags=[coach_user.get('location', 'Pakistan')],
                        status='Active',
                    )

        if user_data.get('role') == 'coach' and user_id not in coach_cards:
            coach_cards[user_id] = _build_association_card(
                entity_id=user_id,
                title=user_data.get('fullName', 'Coach'),
                subtitle=', '.join(user_data.get('specializationSports', [])) or 'Coach',
                role='Coach',
                image_url=user_data.get('profilePictureUrl', ''),
                tags=user_data.get('specializationSports', []),
                status='Available',
            )

        followers = _build_connection_entries(follower_map.get(user_id, set()), following_map.get(user_id, set()))
        following = _build_connection_entries(following_map.get(user_id, set()), follower_map.get(user_id, set()))
        follower_ids = {entry['userId'] for entry in followers}
        following_ids = {entry['userId'] for entry in following}
        mutual_ids = follower_ids & following_ids
        mutual = [entry for entry in followers if entry['userId'] in mutual_ids][:10]

        player_stats = user_data.get('playerStats', {})
        matches_count = player_stats.get('matchesPlayed')
        if not matches_count:
            matches_count = sum(len(match_lookup.get(m['teamId'], [])) for m in memberships) or 0
        posts_count = random.randint(12, 48)

        skill_metrics = _build_skill_metrics(user_data)
        skill_achievements = [
            {
                'title': 'Consistency Award',
                'subtitle': 'Maintained 80% attendance for team sessions',
                'date': dt.now() - timedelta(days=random.randint(20, 120)),
            },
            {
                'title': 'Tournament Highlights',
                'subtitle': f"Involved in {player_stats.get('tournamentsPlayed', 1)} tournaments",
                'date': dt.now() - timedelta(days=random.randint(60, 200)),
            },
        ]

        associations_payload = {
            'teams': list(teams_cards.values()),
            'tournaments': list(tournament_cards.values()),
            'venues': list(venue_cards.values()),
            'coaches': list(coach_cards.values()),
        }

        matchmaking_payload = {
            'tagline': user_data.get('bio') or 'Ready to compete & collaborate.',
            'about': user_data.get('bio') or 'Passionate about community-driven sports.',
            'images': user_data.get('profilePhotos', ImageUrls.sports_photos[:3]),
            'age': user_data.get('age', 24),
            'city': user_data.get('location', 'Karachi'),
            'sports': user_data.get('sportsOfInterest') or user_data.get('specializationSports', ['cricket']),
            'seeking': ['Scrimmages', 'Tournaments', 'Training'],
            'distanceKm': round(random.uniform(1, 15), 1),
            'distanceLink': None,
            'featuredTeam': associations_payload['teams'][0] if associations_payload['teams'] else None,
            'featuredVenue': associations_payload['venues'][0] if associations_payload['venues'] else None,
            'featuredCoach': associations_payload['coaches'][0] if associations_payload['coaches'] else None,
            'featuredTournament': associations_payload['tournaments'][0] if associations_payload['tournaments'] else None,
            'allowMessagesFromFriendsOnly': random.random() < 0.3,
        }

        contact_links = {
            'instagram': f"https://instagram.com/{user_data.get('nickname', user_data.get('fullName', 'player')).lower().replace(' ', '')}",
            'whatsapp': f"https://wa.me/92{random.randint(3000000000, 3999999999)}",
        }

        profile_payload = {
            'identity': {
                'fullName': user_data.get('fullName'),
                'role': user_data.get('role', 'player'),
                'tagline': user_data.get('bio', 'Athlete'),
                'city': user_data.get('location', 'Pakistan'),
                'age': user_data.get('age'),
                'profilePictureUrl': user_data.get('profilePictureUrl'),
                'coverMediaUrl': (user_data.get('profilePhotos') or ImageUrls.sports_photos)[0],
                'badges': user_data.get('playerAchievements', []),
                'isVerified': False,
            },
            'about': {
                'bio': user_data.get('bio', ''),
                'sports': user_data.get('sportsOfInterest') or user_data.get('specializationSports', []),
                'position': random.choice(['Forward', 'Midfielder', 'Defender', 'All-Rounder']),
                'availability': 'Evenings & Weekends',
                'highlights': user_data.get('playerAchievements', []),
                'attributes': {
                    'Preferred Surface': random.choice(['Grass', 'Hardwood', 'Clay']),
                    'Play Style': random.choice(['Aggressive', 'Balanced', 'Tactical']),
                },
                'statusMessage': 'Open for scrimmages and community events.',
            },
            'skillPerformance': {
                'overallRating': round(random.uniform(3.5, 5.0), 2),
                'metrics': skill_metrics,
                'trends': [
                    {'label': 'Last 5 games', 'value': round(random.uniform(3.0, 5.0), 2)},
                    {'label': 'Season', 'value': round(random.uniform(3.0, 5.0), 2)},
                ],
                'achievements': skill_achievements,
            },
            'associations': associations_payload,
            'followers': followers,
            'following': following,
            'mutualConnections': mutual,
            'postsCount': posts_count,
            'matchesCount': matches_count,
            'followersCount': len(followers),
            'followingCount': len(following),
            'matchmaking': matchmaking_payload,
            'contact': {
                'primaryActionLabel': 'Request Match',
                'allowMessagesFromFriendsOnly': matchmaking_payload['allowMessagesFromFriendsOnly'],
                'links': contact_links,
            },
            'availableAssociations': associations_payload,
            'matchmakingLibrary': user_data.get('profilePhotos', ImageUrls.sports_photos[:4]),
            'featuredPostIds': [],
            'updatedAt': firestore.SERVER_TIMESTAMP,
        }

        profiles_collection.document(user_id).set(profile_payload, merge=True)


def _build_skill_metrics(user_data: Dict[str, Any]) -> List[Dict[str, Any]]:
    stats = user_data.get('playerStats', {})
    return [
        {
            'name': 'Match Fitness',
            'score': min(stats.get('matchesPlayed', 0) * 2, 100),
            'maxScore': 100,
            'description': 'Matches played across tournaments',
        },
        {
            'name': 'Teamwork',
            'score': min(stats.get('assists', 0) * 5, 100),
            'maxScore': 100,
            'description': 'Assists and playmaking impact',
        },
        {
            'name': 'Clutch Rating',
            'score': min((stats.get('mvpAwards', 0) + stats.get('wins', 0)) * 4, 100),
            'maxScore': 100,
            'description': 'MVP nods & decisive plays',
        },
    ]


def _seed_venue_reviews_and_bookings(db, venue_ids: List[str], author_pool: List[str]):
    print("   › Writing venue reviews, history, and bookings...")
    review_collection = db.collection('venue_reviews')
    bookings_collection = db.collection('venue_bookings')

    review_templates = [
        'Excellent lighting and turf quality.',
        'Great staff support and punctual scheduling.',
        'Loved the atmosphere and amenities.',
        'Perfect for high-intensity scrimmages.',
        'Booking process was seamless and quick.',
    ]

    for venue_id in venue_ids:
        venue = VENUE_CACHE.get(venue_id)
        if not venue:
            continue

        ratings = []
        for _ in range(random.randint(4, 9)):
            reviewer_id = random.choice(author_pool)
            reviewer = USER_CACHE.get(reviewer_id)
            if not reviewer:
                continue
            rating = round(random.uniform(4.1, 5.0), 1)
            ratings.append(rating)
            review_doc = {
                'id': db.collection('venue_reviews').document().id,
                'venueId': venue_id,
                'userId': reviewer_id,
                'userName': reviewer.get('fullName'),
                'userProfilePicture': reviewer.get('profilePictureUrl'),
                'rating': rating,
                'comment': random.choice(review_templates),
                'createdAt': DataGenerator.random_past_date(120),
            }
            review_collection.document(review_doc['id']).set(review_doc)

        avg_rating = round(sum(ratings) / len(ratings), 1) if ratings else venue.get('averageRating', 4.5)

        booking_slots = venue.get('availableTimeSlots', [{'start': '18:00', 'end': '20:00'}])
        for _ in range(random.randint(3, 7)):
            player_id = random.choice(author_pool)
            player = USER_CACHE.get(player_id)
            if not player:
                continue
            slot = random.choice(booking_slots)
            status = random.choice(['pending', 'confirmed', 'completed'])
            selected_date = dt.now() + timedelta(days=random.randint(-15, 25))
            booking_doc = {
                'id': bookings_collection.document().id,
                'userId': player_id,
                'userName': player.get('fullName'),
                'userProfilePicture': player.get('profilePictureUrl'),
                'venueId': venue_id,
                'venueTitle': venue.get('title'),
                'venueOwnerId': venue.get('ownerId'),
                'venueOwnerName': venue.get('ownerName'),
                'sportType': venue.get('sportType', 'football'),
                'selectedDate': selected_date,
                'timeSlot': {
                    'day': random.choice(venue.get('availableDays', ['Saturday'])),
                    'startTime': slot.get('start'),
                    'endTime': slot.get('end'),
                },
                'status': status,
                'totalAmount': venue.get('hourlyRate', 1000.0) * 2,
                'hourlyRate': venue.get('hourlyRate', 1000.0),
                'location': venue.get('location'),
                'notes': 'Auto-generated booking seed.',
                'createdAt': dt.now(),
                'updatedAt': dt.now(),
            }
            if status == 'completed':
                booking_doc['completedAt'] = selected_date + timedelta(hours=2)
            elif status == 'confirmed':
                booking_doc['confirmedAt'] = dt.now()
            bookings_collection.document(booking_doc['id']).set(booking_doc)

        history_entries = [
            {
                'title': 'Hosted elite scrimmage',
                'timestamp': dt.now() - timedelta(days=random.randint(5, 40)),
                'summary': 'High intensity matchup featuring seeded teams.',
            },
            {
                'title': 'Facility upgrade',
                'timestamp': dt.now() - timedelta(days=random.randint(40, 90)),
                'summary': 'Added biometric access & hydration lounge.',
            },
        ]
        highlights = [
            {
                'label': 'Avg. rating',
                'value': avg_rating,
            },
            {
                'label': 'Bookings this month',
                'value': random.randint(8, 18),
            },
        ]

        venue_ref = db.collection('venues').document(venue_id)
        venue_ref.update({
            'totalReviews': len(ratings),
            'averageRating': avg_rating,
            'metadata.history': history_entries,
            'metadata.recentHighlights': highlights,
        })

        VENUE_CACHE[venue_id]['totalReviews'] = len(ratings)
        VENUE_CACHE[venue_id]['averageRating'] = avg_rating
        VENUE_CACHE[venue_id].setdefault('metadata', {})
        VENUE_CACHE[venue_id]['metadata']['history'] = history_entries
        VENUE_CACHE[venue_id]['metadata']['recentHighlights'] = highlights


def _pick_random_users(pool: List[str], count: int = 3, exclude: Set[str] | None = None) -> List[str]:
    exclude = exclude or set()
    filtered = [uid for uid in pool if uid not in exclude]
    if not filtered:
        return []
    sample_size = min(count, len(filtered))
    return random.sample(filtered, sample_size)

# ============================================================================
# MAIN SCRIPT
# ============================================================================

def main():
    """Main execution function"""
    print("╔════════════════════════════════════════════════════════════╗")
    print("║   PlayAround Database Population Script (Python)          ║")
    print("║   Generating realistic dummy data...                       ║")
    print("╚════════════════════════════════════════════════════════════╝\n")
    
    try:
        # Initialize Firebase
        print("🔥 Initializing Firebase...")
        db = initialize_firebase()
        print("✅ Firebase initialized\n")
        
        # Clean existing data
        if CLEAN_EXISTING_DATA:
            clean_database(db)
        
        # Generate users
        user_ids = generate_users(db, count=110)
        
        # Generate coaches
        coach_ids = generate_coaches(db, count=35)
        
        # Generate venues
        venue_ids = generate_venues(db, coach_ids)
        
        # Generate teams
        team_ids = generate_teams(db, user_ids, coach_ids)
        
        # Generate tournaments
        tournament_ids, tournament_matches = generate_tournaments(db, team_ids, venue_ids, user_ids)
        
        # Create flagship showcase tournament with live-ready data
        showcase_id, showcase_matches = create_showcase_tournament(db, team_ids, user_ids)
        if showcase_id:
            tournament_ids.append(showcase_id)
            tournament_matches.extend(showcase_matches)

        # Generate community posts
        generate_community_posts(db, user_ids, coach_ids)

        # Post-process to synchronize associations and analytics
        post_process_data(
            db=db,
            user_ids=user_ids,
            coach_ids=coach_ids,
            team_ids=team_ids,
            venue_ids=venue_ids,
            tournament_ids=tournament_ids,
            match_payloads=tournament_matches,
        )
        
        # Final summary
        print("╔════════════════════════════════════════════════════════════╗")
        print("║   ✅ DATABASE POPULATION COMPLETE!                         ║")
        print("╚════════════════════════════════════════════════════════════╝")
        print(f"\n📊 Summary:")
        print(f"   • {len(user_ids)} Players")
        print(f"   • {len(coach_ids)} Coaches")
        print(f"   • {len(venue_ids)} Venues")
        print(f"   • {len(team_ids)} Teams")
        print(f"   • {len(tournament_ids)} Tournaments")
        print(f"   • 25+ Community Posts")
        print(f"   • 150+ Comments")
        print(f"   • 500+ Likes")
        print(f"\n🎉 Your PlayAround app is now fully populated!")
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        return 1
    
    return 0

if __name__ == '__main__':
    exit(main())

