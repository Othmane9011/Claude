-- AlterTable
ALTER TABLE "Service" ADD COLUMN     "archivedAt" TIMESTAMP(3);

-- CreateIndex
CREATE INDEX "Service_providerId_archivedAt_idx" ON "Service"("providerId", "archivedAt");
