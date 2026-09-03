CREATE TABLE view_events (
  id            BIGSERIAL PRIMARY KEY,
  handle        TEXT NOT NULL,
  deck          TEXT NOT NULL,
  slide         INT  NOT NULL,
  seconds       REAL NOT NULL,
  playback_rate REAL NOT NULL DEFAULT 1.0,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX view_events_handle_deck_idx ON view_events (handle, deck);

CREATE VIEW deck_progress AS
  SELECT handle, deck,
         COUNT(DISTINCT slide) AS slides_touched,
         SUM(seconds)          AS seconds_listened,
         MIN(created_at)       AS first_seen,
         MAX(created_at)       AS last_seen
  FROM view_events GROUP BY handle, deck;
