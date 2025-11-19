-- AlterTable
ALTER TABLE "Pet" ADD COLUMN     "photoUrl" TEXT;

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "city" TEXT,
ADD COLUMN     "lat" DOUBLE PRECISION,
ADD COLUMN     "lng" DOUBLE PRECISION,
ADD COLUMN     "phone" TEXT,
ADD COLUMN     "photoUrl" TEXT;

-- CreateIndex
CREATE INDEX "User_email_idx" ON "User"("email");

-- CreateIndex
CREATE INDEX "User_city_idx" ON "User"("city");

-- CreateIndex
CREATE INDEX "User_lat_lng_idx" ON "User"("lat", "lng");
