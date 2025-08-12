PRAGMA foreign_keys=ON;

CREATE TABLE IF NOT EXISTS influencers (
  id TEXT PRIMARY KEY,
  name TEXT,
  platform TEXT,
  handle TEXT,
  channel_url TEXT,
  followers INTEGER
);

CREATE TABLE IF NOT EXISTS routines (
  id TEXT PRIMARY KEY,
  title TEXT,
  categories TEXT,
  cost_krw INTEGER,
  time_min INTEGER,
  difficulty INTEGER,
  influencer_id TEXT,
  popularity_score INTEGER DEFAULT 50,
  video_url TEXT,
  thumbnail_url TEXT,
  provider TEXT,
  embed_html TEXT,
  tags TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  FOREIGN KEY (influencer_id) REFERENCES influencers(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS routine_elements (
  routine_id TEXT,
  eid TEXT,
  type TEXT,
  name TEXT,
  qty REAL,
  unit TEXT,
  note TEXT,
  PRIMARY KEY (routine_id, eid),
  FOREIGN KEY (routine_id) REFERENCES routines(id) ON DELETE CASCADE
);
