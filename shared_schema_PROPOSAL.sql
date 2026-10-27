-- LOST//SIGNAL shared database schema PROPOSAL v1.0 (PostgreSQL)
-- Team rule: SAME structure, SEPARATE physical databases per team / stage.
-- Run this schema in each team's own database. Agree together before freezing names/types.
-- Cross-database foreign keys are NOT used.
CREATE TABLE IF NOT EXISTS player_profiles (
  player_id UUID PRIMARY KEY,
  display_name TEXT NOT NULL DEFAULT 'PLAYER',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS missions (
  mission_id VARCHAR(3) PRIMARY KEY,             -- W01 ... W40
  stage_id SMALLINT NOT NULL CHECK(stage_id BETWEEN 1 AND 4),
  problem_no SMALLINT NOT NULL CHECK(problem_no BETWEEN 1 AND 40),
  difficulty TEXT NOT NULL CHECK(difficulty IN ('easy','normal','hard','very_hard')),
  title TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  is_available BOOLEAN NOT NULL DEFAULT TRUE,
  UNIQUE(problem_no)
);
CREATE TABLE IF NOT EXISTS mission_progress (
  player_id UUID NOT NULL REFERENCES player_profiles(player_id) ON DELETE CASCADE,
  mission_id VARCHAR(3) NOT NULL REFERENCES missions(mission_id),
  status TEXT NOT NULL DEFAULT 'available' CHECK(status IN ('available','solved')),
  attempts INTEGER NOT NULL DEFAULT 0 CHECK(attempts>=0),
  solved_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (player_id,mission_id)
);
CREATE TABLE IF NOT EXISTS player_state (
  player_id UUID PRIMARY KEY REFERENCES player_profiles(player_id) ON DELETE CASCADE,
  region_id TEXT NOT NULL DEFAULT 'stage1_abandoned_city',
  position_x DOUBLE PRECISION NOT NULL DEFAULT 300,
  position_y DOUBLE PRECISION NOT NULL DEFAULT 640,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS clue_inventory (
  player_id UUID NOT NULL REFERENCES player_profiles(player_id) ON DELETE CASCADE,
  clue_id TEXT NOT NULL,
  source_mission_id VARCHAR(3),
  obtained_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY(player_id,clue_id)
);
CREATE TABLE IF NOT EXISTS skill_unlocks (
  player_id UUID NOT NULL REFERENCES player_profiles(player_id) ON DELETE CASCADE,
  skill_id TEXT NOT NULL,
  source_mission_id VARCHAR(3) NOT NULL,
  unlocked_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY(player_id,skill_id),
  -- Only stage-3 mission IDs W21 through W30 are permitted in this contract.
  CONSTRAINT only_stage3_skill_sources CHECK(source_mission_id IN
    ('W21','W22','W23','W24','W25','W26','W27','W28','W29','W30'))
);
CREATE INDEX IF NOT EXISTS idx_mission_progress_solved ON mission_progress(player_id, status, solved_at);
-- IMPORTANT: Apply server-side authorization/RLS. Never use browser-supplied player_id as identity.
-- Do NOT distribute the database URL, service credentials or flag answers in the frontend.