#!/usr/bin/env python3
"""
Create a fully-populated sample tournament using existing Firestore data.

Usage:
    python scripts/create_sample_tournament.py \
        --service-account playaround-6556e-firebase-adminsdk-fbsvc-26671daef7.json \
        --tournament-name "Aurora Clash Showcase"
"""

from __future__ import annotations

import argparse
import glob
import os
import random
import uuid
from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional, Sequence

import firebase_admin
from firebase_admin import credentials, firestore


# -----------------------------------------------------------------------------
# Firebase bootstrap
# -----------------------------------------------------------------------------

def initialize_firebase(service_account: Optional[str] = None) -> firestore.Client:
    """Initialize Firebase Admin SDK."""
    if firebase_admin._apps:
        return firestore.client()

    candidate_paths: List[str] = []
    if service_account:
        candidate_paths.append(service_account)

    candidate_paths.extend([
        "playaround-6556e-firebase-adminsdk-fbsvc-26671daef7.json",
        "firebase-service-account.json",
    ])
    candidate_paths.extend(glob.glob("*-firebase-adminsdk-*.json"))

    cred = None
    for path in candidate_paths:
        if path and os.path.exists(path):
            cred = credentials.Certificate(path)
            print(f"   ✓ Using service account: {path}")
            break

    if cred:
        firebase_admin.initialize_app(cred)
    else:
        # Fall back to default credentials (gcloud / env)
        firebase_admin.initialize_app()
        print("   ⚠️  No service-account JSON found, falling back to default credentials")

    return firestore.client()


# -----------------------------------------------------------------------------
# Helper dataclasses
# -----------------------------------------------------------------------------

@dataclass
class TeamContext:
    id: str
    name: str
    logo: Optional[str]
    sport_type: str
    player_ids: List[str]
    players: List[Dict[str, str]]
    tournament_id: Optional[str] = None


# -----------------------------------------------------------------------------
# Seeder implementation
# -----------------------------------------------------------------------------

class SampleTournamentSeeder:
    def __init__(self, db: firestore.Client, tournament_name: str):
        self.db = db
        self.tournament_name = tournament_name
        self.now = datetime.utcnow()

    # --- public API ----------------------------------------------------------

    def run(self) -> Dict[str, str]:
        venue = self._pick_existing_venue()
        teams = self._pick_existing_teams(4, pending_tournament_id=None)

        sport_type = teams[0].sport_type if teams else "football"
        tournament_id = self._create_tournament(venue, teams, sport_type)
        if any(team.tournament_id is None for team in teams):
            teams = self._pick_existing_teams(4, pending_tournament_id=tournament_id)
        matches = self._create_matches(tournament_id, venue, teams, sport_type)

        summary = {
            "tournamentId": tournament_id,
            "tournamentName": self.tournament_name,
            "venueName": venue.get("title") or venue.get("name", "Venue"),
            "matchIds": ", ".join(match["id"] for match in matches),
        }

        self._print_summary(summary, matches)
        return summary

    # --- pick existing data --------------------------------------------------

    def _pick_existing_venue(self) -> Dict[str, Any]:
        snapshot = list(self.db.collection("venues").limit(5).stream())
        if not snapshot:
            raise RuntimeError("No existing venues were found in Firestore.")

        doc = random.choice(snapshot)
        data = doc.to_dict() or {}
        data["id"] = doc.id
        return data

    def _pick_existing_teams(self, count: int, pending_tournament_id: Optional[str]) -> List[TeamContext]:
        sources = ["tournament_teams", "teams"]
        candidates: List[TeamContext] = []

        for collection in sources:
            docs = list(self.db.collection(collection).limit(count * 3).stream())
            for doc in docs:
                data = doc.to_dict() or {}
                player_ids: List[str] = data.get("playerIds") or []
                sport_type = (data.get("sportType") or "football").lower()

                if len(player_ids) < 3:
                    continue

                players = self._fetch_players(player_ids[:5])
                if len(players) < 3:
                    continue

                candidates.append(
                    TeamContext(
                        id=doc.id,
                        name=data.get("name", "Team"),
                        logo=data.get("profileImageUrl")
                        or data.get("logoUrl")
                        or data.get("teamLogoUrl"),
                        sport_type=sport_type,
                        player_ids=player_ids,
                        players=players,
                    )
                )

            if len(candidates) >= count:
                break

        if len(candidates) < count:
            needed = count - len(candidates)
            print(
                f"   ⚠️  Only found {len(candidates)} rostered teams. "
                f"Bootstrapping {needed} teams from existing users..."
            )
            new_teams = self._bootstrap_teams(needed, pending_tournament_id)
            candidates.extend(new_teams)

        if len(candidates) < count:
            raise RuntimeError(
                "Unable to create enough tournament teams with rosters. "
                "Ensure the database has player profiles in the `users` collection."
            )

        return random.sample(candidates, count)

    def _fetch_players(self, player_ids: Sequence[str]) -> List[Dict[str, str]]:
        players: List[Dict[str, str]] = []
        users_collection = self.db.collection("users")
        for pid in player_ids:
            snap = users_collection.document(pid).get()
            if not snap.exists:
                continue
            data = snap.to_dict() or {}
            players.append(
                {
                    "uid": pid,
                    "fullName": data.get("fullName", "Player"),
                    "avatar": data.get("profilePictureUrl"),
                }
            )
        return players

    def _bootstrap_teams(self, needed: int, pending_tournament_id: Optional[str]) -> List[TeamContext]:
        users_snapshot = list(
            self.db.collection("users")
            .where("isProfileComplete", "==", True)
            .limit(needed * 10)
            .stream()
        )
        if len(users_snapshot) < needed * 5:
            raise RuntimeError(
                "Not enough player profiles to fabricate teams. Generate more users first."
            )

        players = []
        for doc in users_snapshot:
            data = doc.to_dict() or {}
            players.append(
                {
                    "uid": doc.id,
                    "fullName": data.get("fullName", "Player"),
                    "avatar": data.get("profilePictureUrl"),
                }
            )
        random.shuffle(players)

        created: List[TeamContext] = []
        teams_collection = self.db.collection("tournament_teams")

        for idx in range(needed):
            roster = players[idx * 6 : (idx + 1) * 6]
            if len(roster) < 4:
                break
            team_ref = teams_collection.document()
            sport = random.choice(["football", "futsal", "cricket"])
            name = f"Auto {sport.title()} Club {idx + 1}"
            payload = {
                "id": team_ref.id,
                "name": name,
                "tournamentId": pending_tournament_id or "",
                "sportType": sport,
                "coachName": roster[0]["fullName"],
                "playerIds": [p["uid"] for p in roster],
                "playerNames": [p["fullName"] for p in roster],
                "createdAt": self.now,
                "isActive": True,
            }
            team_ref.set(payload)

            created.append(
                TeamContext(
                    id=team_ref.id,
                    name=name,
                    logo=None,
                    sport_type=sport,
                    player_ids=payload["playerIds"],
                    players=roster,
                    tournament_id=pending_tournament_id,
                )
            )

        return created

    # --- data creation -------------------------------------------------------

    def _create_tournament(self, venue, teams, sport_type: str) -> str:
        tournament_ref = self.db.collection("tournaments").document()
        start_date = self.now - timedelta(days=3)
        end_date = self.now + timedelta(days=14)
        organizer = teams[0].players[0]

        tournament_payload = {
            "id": tournament_ref.id,
            "name": self.tournament_name,
            "description": "High-visibility invitational showcasing app features.",
            "sportType": sport_type,
            "format": "league",
            "status": "ongoing",
            "organizerId": organizer["uid"],
            "organizerName": organizer["fullName"],
            "registrationStartDate": self.now - timedelta(days=30),
            "registrationEndDate": self.now - timedelta(days=10),
            "startDate": start_date,
            "endDate": end_date,
            "maxTeams": len(teams),
            "minTeams": 2,
            "currentTeamsCount": len(teams),
            "location": venue.get("location", "Pakistan"),
            "venueId": venue.get("id"),
            "venueName": venue.get("title") or venue.get("name"),
            "imageUrl": (venue.get("images") or [None])[0],
            "rules": [
                "FIFA regulation timing",
                "Max 5 substitutes per match",
                "Yellow card accumulation rules apply",
            ],
            "prizes": {
                "champion": "PKR 200,000",
                "runnerUp": "PKR 75,000",
                "mvp": "Flagship kit + cash bonus",
            },
            "isPublic": True,
            "createdAt": self.now,
            "updatedAt": self.now,
            "entryFee": 5000.0,
            "winningPrize": 200000.0,
            "teamPoints": {},
            "allowTeamEditing": False,
            "metadata": {
                "sampleTournament": True,
                "venueSnapshot": {
                    "id": venue.get("id"),
                    "title": venue.get("title") or venue.get("name"),
                    "imageUrl": (venue.get("images") or [None])[0],
                },
            },
        }

        tournament_ref.set(tournament_payload)
        return tournament_ref.id

    def _create_matches(self, tournament_id, venue, teams, sport_type):
        base_schedule = self.now.replace(minute=0, second=0, microsecond=0)
        match_specs = [
            {
                "status": "completed",
                "scheduled_time": base_schedule - timedelta(days=2, hours=2),
                "actual_offset": (timedelta(hours=-2), timedelta(hours=-0.3)),
                "teams": (teams[0], teams[1]),
                "score": (3, 2),
                "round": "Group Stage",
            },
            {
                "status": "live",
                "scheduled_time": base_schedule,
                "actual_offset": (timedelta(minutes=-40), None),
                "teams": (teams[2], teams[3]),
                "score": (1, 1),
                "round": "Group Stage",
            },
            {
                "status": "scheduled",
                "scheduled_time": base_schedule + timedelta(days=1, hours=3),
                "actual_offset": (None, None),
                "teams": (teams[0], teams[2]),
                "score": (0, 0),
                "round": "Semi Final",
            },
        ]

        matches = []
        for index, spec in enumerate(match_specs, start=1):
            match_info = self._write_match(
                match_number=f"Match {index}",
                tournament_id=tournament_id,
                venue=venue,
                teams=spec["teams"],
                scheduled_time=spec["scheduled_time"],
                score=spec["score"],
                status=spec["status"],
                round_name=spec["round"],
                sport_type=sport_type,
                actual_offsets=spec["actual_offset"],
            )
            matches.append(match_info)

        return matches

    def _write_match(
        self,
        match_number: str,
        tournament_id: str,
        venue: Dict[str, Any],
        teams: Sequence[TeamContext],
        scheduled_time: datetime,
        score: Sequence[int],
        status: str,
        round_name: str,
        sport_type: str,
        actual_offsets: Sequence[Optional[timedelta]],
    ):
        team1_ctx, team2_ctx = teams
        team1_score, team2_score = score
        actual_start = (
            scheduled_time + actual_offsets[0] if actual_offsets[0] else None
        )
        actual_end = (
            scheduled_time + actual_offsets[1] if actual_offsets[1] else None
        )

        team1_payload = self._build_team_score(team1_ctx, team1_score)
        team2_payload = self._build_team_score(team2_ctx, team2_score)

        match_ref = self.db.collection("tournament_matches").document()
        commentary = self._build_commentary(match_ref.id, scheduled_time, team1_ctx, team2_ctx)
        player_stats = self._build_player_stats(team1_ctx, team2_ctx, status)

        match_payload = {
            "id": match_ref.id,
            "tournamentId": tournament_id,
            "tournamentName": self.tournament_name,
            "sportType": sport_type,
            "team1": team1_payload,
            "team2": team2_payload,
            "matchNumber": match_number,
            "round": round_name,
            "scheduledTime": scheduled_time,
            "actualStartTime": actual_start,
            "actualEndTime": actual_end,
            "status": status,
            "commentary": commentary,
            "team1PlayerStats": player_stats[team1_ctx.id],
            "team2PlayerStats": player_stats[team2_ctx.id],
            "result": self._describe_result(team1_ctx, team2_ctx, team1_score, team2_score),
            "winnerTeamId": self._winner_id(team1_ctx, team2_ctx, team1_score, team2_score),
            "venueId": venue.get("id"),
            "venueName": venue.get("title") or venue.get("name"),
            "createdAt": self.now,
            "updatedAt": self.now,
            "metadata": {
                "matchStats": {
                    "possession": {team1_ctx.id: 52, team2_ctx.id: 48},
                    "totalShots": {team1_ctx.id: 11, team2_ctx.id: 9},
                    "fouls": {team1_ctx.id: 12, team2_ctx.id: 10},
                },
                "sampleMatch": True,
            },
        }

        match_ref.set(match_payload)
        self._seed_reactions(match_ref.id, team1_ctx, team2_ctx, status)

        return {
            "id": match_ref.id,
            "status": status,
            "matchNumber": match_number,
            "scheduledTime": scheduled_time.isoformat(),
        }

    def _build_team_score(self, team: TeamContext, score: int) -> Dict[str, Any]:
        return {
            "teamId": team.id,
            "teamName": team.name,
            "teamLogoUrl": team.logo,
            "score": score,
            "playerIds": team.player_ids[:10],
            "sportSpecificData": {
                "attempts": random.randint(6, 15),
                "cards": random.randint(0, 3),
                "corners": random.randint(2, 8),
            },
        }

    def _build_player_stats(self, team1: TeamContext, team2: TeamContext, status: str):
        def make_stats(player, intensity=1.0):
            base = {
                "playerId": player["uid"],
                "playerName": player["fullName"],
                "playerImageUrl": player.get("avatar"),
                "goals": int(random.random() * 3 * intensity),
                "assists": int(random.random() * 2 * intensity),
                "yellowCards": int(random.random() * 1.2 * intensity),
                "redCards": 0,
                "runs": random.randint(20, 45),
                "balls": random.randint(25, 60),
                "wickets": 0,
                "catches": random.randint(0, 3),
                "points": random.randint(10, 25),
                "rebounds": random.randint(1, 6),
                "steals": random.randint(0, 3),
                "fouls": random.randint(0, 4),
                "saves": random.randint(0, 5),
                "customStats": {
                    "keyPasses": random.randint(1, 5),
                    "heatMapZone": random.choice(["Left Wing", "Right Wing", "Central"]),
                    "distanceKm": round(random.uniform(4.5, 10.2), 1),
                },
            }
            if status == "scheduled":
                base.update({"goals": 0, "assists": 0})
                base["customStats"] = {"readiness": "Awaiting kickoff"}
            return base

        stats = {
            team1.id: [make_stats(p, 1.2) for p in team1.players[:5]],
            team2.id: [make_stats(p, 1.0) for p in team2.players[:5]],
        }
        return stats

    def _build_commentary(self, match_id: str, scheduled_time: datetime, team1: TeamContext, team2: TeamContext):
        entries = []
        moments = [
            f"{team1.name} warms up confidently.",
            f"{team2.name} responds with an aggressive press.",
            f"{team1.name} opens the scoring with a low drive.",
            "Halftime team talks are heated.",
            f"{team2.name} equalizes from a set piece.",
            f"{team1.name} restores the lead with a curling effort.",
        ]
        current_time = scheduled_time

        for minute, text in enumerate(moments, start=3):
            current_time += timedelta(minutes=random.randint(3, 7))
            entries.append(
                {
                    "id": f"c_{match_id[:4]}_{minute}",
                    "text": text,
                    "timestamp": current_time.isoformat(),
                    "minute": str(minute),
                    "eventType": "highlight",
                }
            )
        return entries

    def _seed_reactions(self, match_id: str, team1: TeamContext, team2: TeamContext, status: str):
        reactions_ref = (
            self.db.collection("matches").document(match_id).collection("reactions")
        )
        parent_doc = self.db.collection("matches").document(match_id)
        parent_doc.set(
            {
                "matchId": match_id,
                "tournamentName": self.tournament_name,
                "status": status,
                "createdAt": self.now,
            },
            merge=True,
        )

        sample_users = (team1.players + team2.players)[:5]
        emojis = ["👏", "🔥", "💪", "⚽", "🙌"]
        seed_time = self.now - timedelta(days=1)

        for idx, user in enumerate(sample_users):
            reactions_ref.add(
                {
                    "userId": user["uid"],
                    "userName": user["fullName"],
                    "emoji": emojis[idx % len(emojis)],
                    "createdAt": seed_time + timedelta(minutes=idx * 8),
                }
            )

    def _winner_id(self, team1, team2, score1, score2):
        if score1 > score2:
            return team1.id
        if score2 > score1:
            return team2.id
        return None

    def _describe_result(self, team1, team2, score1, score2):
        if score1 == score2:
            return f"{team1.name} drew {team2.name} ({score1}-{score2})"
        winner = team1.name if score1 > score2 else team2.name
        return f"{winner} won {score1}-{score2}"

    # --- output --------------------------------------------------------------

    def _print_summary(self, summary: Dict[str, str], matches: List[Dict[str, str]]):
        print("\n╔════════════════════════════════════════════════════════════╗")
        print("║        ✅ Sample tournament seeded successfully            ║")
        print("╚════════════════════════════════════════════════════════════╝")
        print(f"• Tournament Name : {summary['tournamentName']}")
        print(f"• Tournament ID   : {summary['tournamentId']}")
        print(f"• Venue           : {summary['venueName']}")
        print("• Matches:")
        for match in matches:
            print(
                f"   - {match['matchNumber']} ({match['status']}) → {match['id']}"
            )
        print("\nYou can now open this tournament in both the admin panel and the")
        print("public detail view to verify synced data, commentary, reactions,")
        print("and player stats.")


# -----------------------------------------------------------------------------
# CLI
# -----------------------------------------------------------------------------

def parse_args():
    parser = argparse.ArgumentParser(
        description="Create a showcase tournament using existing Firestore data."
    )
    parser.add_argument(
        "--service-account",
        help="Path to the Firebase Admin SDK JSON key (optional if already configured).",
    )
    parser.add_argument(
        "--tournament-name",
        default="Aurora Clash Invitational",
        help="Name to assign to the generated tournament.",
    )
    return parser.parse_args()


def main():
    args = parse_args()
    print("🔥 Connecting to Firebase...")
    db = initialize_firebase(args.service_account)
    print("✅ Firebase initialized\n")

    seeder = SampleTournamentSeeder(db, args.tournament_name)
    seeder.run()


if __name__ == "__main__":
    main()


