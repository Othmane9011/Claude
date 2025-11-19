-- prisma/migrations/20251113043652_add_admin_collection/migration.sql

CREATE TABLE "AdminCollection" (
  "id"          TEXT        NOT NULL,
  "providerId"  TEXT        NOT NULL,
  "month"       TEXT        NOT NULL, -- 'YYYY-MM'
  "amountDa"    INTEGER     NOT NULL,
  "collectedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "note"        TEXT,

  CONSTRAINT "AdminCollection_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "AdminCollection_providerId_month_key"
  ON "AdminCollection"("providerId","month");

CREATE INDEX "AdminCollection_providerId_month_idx"
  ON "AdminCollection"("providerId","month");

ALTER TABLE "AdminCollection"
  ADD CONSTRAINT "AdminCollection_providerId_fkey"
  FOREIGN KEY ("providerId") REFERENCES "ProviderProfile"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;
