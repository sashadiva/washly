-- CreateEnum
CREATE TYPE "OrderStatus" AS ENUM ('PICKUP_REQUESTED', 'PICKED_UP', 'WASHING', 'OUT_FOR_DELIVERY', 'COMPLETED', 'CANCELLED');

-- CreateTable
CREATE TABLE "Order" (
    "id" SERIAL NOT NULL,
    "pickupAddress" TEXT NOT NULL,
    "deliveryAddress" TEXT NOT NULL,
    "serviceType" TEXT NOT NULL,
    "notes" TEXT,
    "estimatedKg" DOUBLE PRECISION,
    "totalPrice" DOUBLE PRECISION,
    "status" "OrderStatus" NOT NULL DEFAULT 'PICKUP_REQUESTED',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "customerId" INTEGER NOT NULL,
    "laundromatId" INTEGER NOT NULL,

    CONSTRAINT "Order_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "Order" ADD CONSTRAINT "Order_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Order" ADD CONSTRAINT "Order_laundromatId_fkey" FOREIGN KEY ("laundromatId") REFERENCES "Laundromat"("id") ON DELETE CASCADE ON UPDATE CASCADE;
