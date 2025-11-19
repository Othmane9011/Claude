/*
  Warnings:

  - You are about to drop the `AdoptInterest` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `AdoptListing` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE "AdoptInterest" DROP CONSTRAINT "AdoptInterest_listingId_fkey";

-- DropForeignKey
ALTER TABLE "AdoptInterest" DROP CONSTRAINT "AdoptInterest_userId_fkey";

-- DropForeignKey
ALTER TABLE "AdoptListing" DROP CONSTRAINT "AdoptListing_ownerId_fkey";

-- DropTable
DROP TABLE "AdoptInterest";

-- DropTable
DROP TABLE "AdoptListing";
