/*
  Warnings:

  - You are about to drop the column `photoUrl` on the `Pet` table. All the data in the column will be lost.
  - You are about to drop the column `city` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `lat` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `lng` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `phone` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `photoUrl` on the `User` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "Pet" DROP COLUMN "photoUrl";

-- AlterTable
ALTER TABLE "User" DROP COLUMN "city",
DROP COLUMN "lat",
DROP COLUMN "lng",
DROP COLUMN "phone",
DROP COLUMN "photoUrl";
