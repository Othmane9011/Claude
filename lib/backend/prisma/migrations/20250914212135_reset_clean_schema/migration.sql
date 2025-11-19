-- DropIndex
DROP INDEX "RefreshToken_userId_idx";

-- CreateIndex
CREATE INDEX "ProviderProfile_userId_idx" ON "ProviderProfile"("userId");

-- CreateIndex
CREATE INDEX "ProviderProfile_lat_lng_idx" ON "ProviderProfile"("lat", "lng");

-- CreateIndex
CREATE INDEX "RefreshToken_userId_expiresAt_idx" ON "RefreshToken"("userId", "expiresAt");

-- CreateIndex
CREATE INDEX "Service_providerId_title_idx" ON "Service"("providerId", "title");
