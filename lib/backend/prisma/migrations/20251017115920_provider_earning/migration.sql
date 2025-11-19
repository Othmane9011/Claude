-- CreateTable
CREATE TABLE "ProviderEarning" (
    "id" TEXT NOT NULL,
    "providerId" TEXT NOT NULL,
    "bookingId" TEXT NOT NULL,
    "serviceId" TEXT NOT NULL,
    "grossPriceDa" INTEGER NOT NULL,
    "commissionDa" INTEGER NOT NULL,
    "netToProviderDa" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "paidAt" TIMESTAMP(3),

    CONSTRAINT "ProviderEarning_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "ProviderEarning_bookingId_key" ON "ProviderEarning"("bookingId");

-- CreateIndex
CREATE INDEX "ProviderEarning_providerId_createdAt_idx" ON "ProviderEarning"("providerId", "createdAt");

-- AddForeignKey
ALTER TABLE "ProviderEarning" ADD CONSTRAINT "ProviderEarning_providerId_fkey" FOREIGN KEY ("providerId") REFERENCES "ProviderProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ProviderEarning" ADD CONSTRAINT "ProviderEarning_bookingId_fkey" FOREIGN KEY ("bookingId") REFERENCES "Booking"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ProviderEarning" ADD CONSTRAINT "ProviderEarning_serviceId_fkey" FOREIGN KEY ("serviceId") REFERENCES "Service"("id") ON DELETE CASCADE ON UPDATE CASCADE;
