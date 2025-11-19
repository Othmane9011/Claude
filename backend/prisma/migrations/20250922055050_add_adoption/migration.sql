-- CreateTable
CREATE TABLE "AdoptListing" (
    "id" TEXT NOT NULL,
    "ownerId" TEXT NOT NULL,
    "petName" TEXT NOT NULL,
    "species" TEXT NOT NULL,
    "sex" TEXT,
    "ageMonths" INTEGER,
    "city" TEXT,
    "description" TEXT,
    "photos" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "AdoptListing_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AdoptInterest" (
    "id" TEXT NOT NULL,
    "listingId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AdoptInterest_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "AdoptListing_ownerId_idx" ON "AdoptListing"("ownerId");

-- CreateIndex
CREATE INDEX "AdoptInterest_userId_idx" ON "AdoptInterest"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "AdoptInterest_listingId_userId_key" ON "AdoptInterest"("listingId", "userId");

-- AddForeignKey
ALTER TABLE "AdoptListing" ADD CONSTRAINT "AdoptListing_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AdoptInterest" ADD CONSTRAINT "AdoptInterest_listingId_fkey" FOREIGN KEY ("listingId") REFERENCES "AdoptListing"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AdoptInterest" ADD CONSTRAINT "AdoptInterest_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
