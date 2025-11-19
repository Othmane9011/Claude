-- AlterTable
ALTER TABLE "ProviderProfile" ADD COLUMN     "rejectedAt" TIMESTAMP(3),
ADD COLUMN     "rejectionReason" TEXT;
