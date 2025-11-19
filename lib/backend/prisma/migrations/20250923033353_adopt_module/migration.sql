-- CreateEnum
CREATE TYPE "Sex" AS ENUM ('M', 'F', 'U');

-- CreateTable
CREATE TABLE "AdoptListing" (
    "id" TEXT NOT NULL,
    "ownerId" TEXT NOT NULL,
    "petName" TEXT NOT NULL,
    "species" TEXT NOT NULL,
    "sex" "Sex" NOT NULL DEFAULT 'U',
    "age" TEXT,
    "city" TEXT NOT NULL,
    "desc" TEXT,
    "photos" TEXT[],
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "AdoptListing_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AdoptLike" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "listingId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AdoptLike_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "AdoptListing_ownerId_idx" ON "AdoptListing"("ownerId");

-- CreateIndex
CREATE INDEX "AdoptListing_city_idx" ON "AdoptListing"("city");

-- CreateIndex
CREATE INDEX "AdoptLike_listingId_idx" ON "AdoptLike"("listingId");

-- CreateIndex
CREATE UNIQUE INDEX "AdoptLike_userId_listingId_key" ON "AdoptLike"("userId", "listingId");

-- AddForeignKey
ALTER TABLE "AdoptListing" ADD CONSTRAINT "AdoptListing_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AdoptLike" ADD CONSTRAINT "AdoptLike_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AdoptLike" ADD CONSTRAINT "AdoptLike_listingId_fkey" FOREIGN KEY ("listingId") REFERENCES "AdoptListing"("id") ON DELETE CASCADE ON UPDATE CASCADE;
