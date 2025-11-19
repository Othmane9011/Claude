-- CreateEnum
CREATE TYPE "Gender" AS ENUM ('MALE', 'FEMALE', 'UNKNOWN');

-- AlterTable
ALTER TABLE "ProviderProfile" ADD COLUMN     "timezone" TEXT;

-- CreateTable
CREATE TABLE "ProviderAvailability" (
    "id" TEXT NOT NULL,
    "providerId" TEXT NOT NULL,
    "weekday" INTEGER NOT NULL,
    "startMin" INTEGER NOT NULL,
    "endMin" INTEGER NOT NULL,
    "timezone" TEXT NOT NULL DEFAULT 'UTC',

    CONSTRAINT "ProviderAvailability_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ProviderTimeOff" (
    "id" TEXT NOT NULL,
    "providerId" TEXT NOT NULL,
    "startsAt" TIMESTAMP(3) NOT NULL,
    "endsAt" TIMESTAMP(3) NOT NULL,
    "reason" TEXT,

    CONSTRAINT "ProviderTimeOff_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Pet" (
    "id" TEXT NOT NULL,
    "ownerId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "gender" "Gender" NOT NULL DEFAULT 'UNKNOWN',
    "weightKg" DECIMAL(5,2),
    "color" TEXT,
    "country" TEXT,
    "idNumber" TEXT,
    "breed" TEXT,
    "neuteredAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Pet_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "ProviderAvailability_providerId_weekday_idx" ON "ProviderAvailability"("providerId", "weekday");

-- CreateIndex
CREATE INDEX "ProviderTimeOff_providerId_startsAt_endsAt_idx" ON "ProviderTimeOff"("providerId", "startsAt", "endsAt");

-- CreateIndex
CREATE INDEX "Pet_ownerId_idx" ON "Pet"("ownerId");

-- CreateIndex
CREATE INDEX "Booking_providerId_scheduledAt_idx" ON "Booking"("providerId", "scheduledAt");

-- CreateIndex
CREATE INDEX "Booking_userId_scheduledAt_idx" ON "Booking"("userId", "scheduledAt");

-- AddForeignKey
ALTER TABLE "ProviderAvailability" ADD CONSTRAINT "ProviderAvailability_providerId_fkey" FOREIGN KEY ("providerId") REFERENCES "ProviderProfile"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ProviderTimeOff" ADD CONSTRAINT "ProviderTimeOff_providerId_fkey" FOREIGN KEY ("providerId") REFERENCES "ProviderProfile"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Pet" ADD CONSTRAINT "Pet_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
