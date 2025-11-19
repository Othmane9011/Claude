/*
  Warnings:

  - A unique constraint covering the columns `[providerId,weekday,startMin,endMin]` on the table `ProviderAvailability` will be added. If there are existing duplicate values, this will fail.

*/
-- DropForeignKey
ALTER TABLE "ProviderAvailability" DROP CONSTRAINT "ProviderAvailability_providerId_fkey";

-- DropForeignKey
ALTER TABLE "ProviderTimeOff" DROP CONSTRAINT "ProviderTimeOff_providerId_fkey";

-- DropIndex
DROP INDEX "ProviderTimeOff_providerId_startsAt_endsAt_idx";

-- AlterTable
ALTER TABLE "ProviderTimeOff" ADD COLUMN     "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;

-- CreateIndex
CREATE UNIQUE INDEX "ProviderAvailability_providerId_weekday_startMin_endMin_key" ON "ProviderAvailability"("providerId", "weekday", "startMin", "endMin");

-- CreateIndex
CREATE INDEX "ProviderTimeOff_providerId_startsAt_idx" ON "ProviderTimeOff"("providerId", "startsAt");

-- CreateIndex
CREATE INDEX "Service_providerId_createdAt_idx" ON "Service"("providerId", "createdAt");

-- AddForeignKey
ALTER TABLE "ProviderAvailability" ADD CONSTRAINT "ProviderAvailability_providerId_fkey" FOREIGN KEY ("providerId") REFERENCES "ProviderProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ProviderTimeOff" ADD CONSTRAINT "ProviderTimeOff_providerId_fkey" FOREIGN KEY ("providerId") REFERENCES "ProviderProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;
