-- CreateEnum
CREATE TYPE "PricingUnit" AS ENUM ('PER_KG', 'PER_ITEM');

-- CreateTable
CREATE TABLE "LaundryService" (
    "id" SERIAL NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "price" DOUBLE PRECISION NOT NULL,
    "unit" "PricingUnit" NOT NULL DEFAULT 'PER_ITEM',
    "imageUrl" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "laundromatId" INTEGER NOT NULL,

    CONSTRAINT "LaundryService_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "LaundryService" ADD CONSTRAINT "LaundryService_laundromatId_fkey" FOREIGN KEY ("laundromatId") REFERENCES "Laundromat"("id") ON DELETE CASCADE ON UPDATE CASCADE;
