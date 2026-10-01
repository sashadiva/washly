import { prisma } from '../src/config/prisma.js';
import {
  Role,
  PricingUnit,
  DriverAvailability,
  OrderStatus,
  PaymentStatus,
  OfferStatus,
} from '@prisma/client';
import { hashPassword } from '../src/services/passwordService.js';

// Shared demo password for every seeded account (customer, partners, drivers).
const DEMO_PASSWORD = 'password123';

// Declared-item thumbnails reuse the exact Unsplash photos used by the product
// services above (known-good URLs that already render in the app), so seeded
// declared items show a real, relevant image. Real customer declared items
// carry their own uploaded photo.
const DECLARED_PHOTOS = {
  // Garment photo (same image as the "Standard Kiloan (Wash & Fold)" service).
  denimJacket:
    'https://images.unsplash.com/photo-1517677208171-0bc6725a3e60?w=400&auto=format&fit=crop&q=80',
  // Bedding photo (same image as the "Bedcover & Blanket Wash" service).
  bedsheet:
    'https://images.unsplash.com/photo-1582735689369-4fe89db7114c?w=400&auto=format&fit=crop&q=80',
  // Sneaker photo (same image as the "Sneaker Deep Clean & Unyellowing" service).
  whiteSneaker:
    'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=400&auto=format&fit=crop&q=80',
};

async function main() {
  console.log('--- Starting Washly Database Seeding ---');

  // 1. Clean existing records in reverse relation order.
  await prisma.warrantyClaim.deleteMany();
  await prisma.declaredItem.deleteMany();
  await prisma.pointsTransaction.deleteMany();
  await prisma.payment.deleteMany();
  await prisma.deliveryOffer.deleteMany();
  await prisma.orderItem.deleteMany();
  await prisma.order.deleteMany();
  await prisma.voucher.deleteMany();
  await prisma.review.deleteMany();
  await prisma.laundryService.deleteMany();
  await prisma.laundromatsOnTags.deleteMany();
  await prisma.laundromat.deleteMany();
  await prisma.tag.deleteMany();
  await prisma.driverProfile.deleteMany();
  await prisma.user.deleteMany();

  console.log('Cleared existing database entries.');

  const passwordHash = await hashPassword(DEMO_PASSWORD);

  // 2. Default demo customer.
  const demoCustomer = await prisma.user.create({
    data: {
      name: 'Demo Customer',
      email: 'customer@washly.com',
      phone: '081234567890',
      passwordHash,
      role: Role.CUSTOMER,
    },
  });
  console.log(`Created demo customer: ${demoCustomer.email} (ID: ${demoCustomer.id})`);

  // 3. Marketplace discovery tags.
  const tagNames = [
    'shoes',
    'bags',
    'dolls',
    'costumes',
    'express',
    'ironing',
    'kiloan',
    'dry clean',
  ];

  const createdTags: Record<string, number> = {};
  for (const name of tagNames) {
    const tag = await prisma.tag.create({ data: { name } });
    createdTags[name] = tag.id;
  }
  console.log(`Created ${tagNames.length} marketplace tags.`);

  // 4. Two partner laundromats (one kiloan-focused, one per-item specialist).
  const laundromatsData = [
    {
      partner: {
        name: 'CleanWave Express Laundry',
        email: 'partner.cleanwave@washly.com',
        phone: '08119876001',
      },
      store: {
        name: 'CleanWave Express Laundry',
        description: 'Premium daily wash, fast fold, and specialized steam pressing in Kemang.',
        address: 'Jl. Kemang Raya No. 12, Bangka, Mampang Prapatan, South Jakarta',
        areaLabel: 'Kemang, South Jakarta',
        latitude: -6.2615,
        longitude: 106.8153,
        imageUrl:
          'https://images.unsplash.com/photo-1545173168-9f1947eebb7f?w=800&auto=format&fit=crop&q=80',
        rating: 4.8,
        reviewCount: 3,
        isOpen: true,
      },
      tags: ['express', 'kiloan', 'ironing', 'dry clean'],
      services: [
        {
          name: 'Standard Kiloan (Wash & Fold)',
          description:
            'Everyday laundry washed with hypoallergenic detergent, tumble dried, and neatly packed.',
          price: 9000,
          unit: PricingUnit.PER_KG,
          imageUrl:
            'https://images.unsplash.com/photo-1517677208171-0bc6725a3e60?w=400&auto=format&fit=crop&q=80',
        },
        {
          name: 'Express 6-Hour Kiloan',
          description: 'Priority queue same-day washing, spin drying, and packaging within 6 hours.',
          price: 16000,
          unit: PricingUnit.PER_KG,
          imageUrl:
            'https://images.unsplash.com/photo-1545173168-9f1947eebb7f?w=400&auto=format&fit=crop&q=80',
        },
        {
          name: 'Bedcover & Blanket Wash',
          description: 'Large drum deep cleansing for king and queen comforters.',
          price: 25000,
          unit: PricingUnit.PER_ITEM,
          imageUrl:
            'https://images.unsplash.com/photo-1582735689369-4fe89db7114c?w=400&auto=format&fit=crop&q=80',
        },
      ],
      reviews: [
        { rating: 5, comment: 'Super fast express pickup! Clothes arrived warm, dry, and fragrant.' },
        { rating: 5, comment: 'Very neat folding and reasonable price for Kemang area.' },
        { rating: 4, comment: 'Good service, but delivery had a slight 15-minute delay due to rain.' },
      ],
    },
    {
      partner: {
        name: 'The Sneaker & Bag Spa',
        email: 'partner.sneakerspa@washly.com',
        phone: '08119876002',
      },
      store: {
        name: 'The Sneaker & Bag Spa',
        description: 'Master care for designer footwear, leather goods, and luxury travel bags.',
        address: 'Jl. Senopati No. 45, Kebayoran Baru, South Jakarta',
        areaLabel: 'Senopati, South Jakarta',
        latitude: -6.2312,
        longitude: 106.8115,
        imageUrl:
          'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?w=800&auto=format&fit=crop&q=80',
        rating: 4.9,
        reviewCount: 2,
        isOpen: true,
      },
      tags: ['shoes', 'bags', 'dry clean'],
      services: [
        {
          name: 'Sneaker Deep Clean & Unyellowing',
          description:
            'Midsole de-oxidation, delicate suede scrubbing, insole UV sterilization, and relacing.',
          price: 45000,
          unit: PricingUnit.PER_ITEM,
          imageUrl:
            'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=400&auto=format&fit=crop&q=80',
        },
        {
          name: 'Luxury Leather Bag Spa',
          description: 'Color-safe micro-cleanse, botanical hydration treatment, and beeswax buffing.',
          price: 85000,
          unit: PricingUnit.PER_ITEM,
          imageUrl:
            'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=400&auto=format&fit=crop&q=80',
        },
        {
          name: 'Canvas Backpack & Duffel Care',
          description: 'Heavy stains spot cleaning followed by water-repellent coating spray.',
          price: 35000,
          unit: PricingUnit.PER_ITEM,
          imageUrl:
            'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400&auto=format&fit=crop&q=80',
        },
      ],
      reviews: [
        {
          rating: 5,
          comment: 'Restored my yellowed Air Force 1s to brand-new condition. Absolutely worth the price!',
        },
        {
          rating: 5,
          comment: 'Handled my vintage leather bag with immense care and no color bleeding.',
        },
      ],
    },
  ];

  // 5. Seed each laundromat with its services, tag links, and reviews.
  const createdLaundromats: { id: number; name: string; address: string }[] = [];
  for (const item of laundromatsData) {
    const owner = await prisma.user.create({
      data: {
        name: item.partner.name,
        email: item.partner.email,
        phone: item.partner.phone,
        passwordHash,
        role: Role.PARTNER,
      },
    });

    const laundromat = await prisma.laundromat.create({
      data: {
        ...item.store,
        ownerId: owner.id,
      },
    });

    for (const tagName of item.tags) {
      const tagId = createdTags[tagName];
      if (tagId) {
        await prisma.laundromatsOnTags.create({
          data: { laundromatId: laundromat.id, tagId },
        });
      }
    }

    for (const service of item.services) {
      await prisma.laundryService.create({
        data: { ...service, laundromatId: laundromat.id },
      });
    }

    for (const review of item.reviews) {
      await prisma.review.create({
        data: {
          rating: review.rating,
          comment: review.comment,
          userId: demoCustomer.id,
          laundromatId: laundromat.id,
        },
      });
    }

    createdLaundromats.push({
      id: laundromat.id,
      name: laundromat.name,
      address: laundromat.address,
    });

    console.log(
      `Seeded: ${laundromat.name} (${item.services.length} services, ${item.reviews.length} reviews)`
    );
  }

  // 6. Two demo drivers with profiles (available, positioned near the partners).
  const driversData = [
    {
      name: 'Andi Driver',
      email: 'driver.andi@washly.com',
      phone: '08123400001',
      profile: {
        vehicleType: 'Motorcycle',
        plateNumber: 'B 1234 AND',
        availability: DriverAvailability.AVAILABLE,
        latitude: -6.2585,
        longitude: 106.8131,
      },
    },
    {
      name: 'Budi Driver',
      email: 'driver.budi@washly.com',
      phone: '08123400002',
      profile: {
        vehicleType: 'Motorcycle',
        plateNumber: 'B 5678 BUD',
        availability: DriverAvailability.AVAILABLE,
        latitude: -6.2350,
        longitude: 106.8100,
      },
    },
  ];

  const createdDrivers: Record<string, { userId: number; profileId: number }> = {};
  for (const driver of driversData) {
    const user = await prisma.user.create({
      data: {
        name: driver.name,
        email: driver.email,
        phone: driver.phone,
        passwordHash,
        role: Role.DRIVER,
        driverProfile: {
          create: driver.profile,
        },
      },
      include: { driverProfile: true },
    });
    createdDrivers[driver.email] = {
      userId: user.id,
      profileId: user.driverProfile!.id,
    };
    console.log(`Created driver: ${user.email} (${driver.profile.plateNumber})`);
  }

  // 7. Demo orders so the driver screens (Offers / Active / History) and the
  //    tracking map are populated. Uses the demo customer + seeded stores.
  const cleanWave = createdLaundromats[0];
  const sneakerSpa = createdLaundromats[1];
  const andi = createdDrivers['driver.andi@washly.com'];
  const budi = createdDrivers['driver.budi@washly.com'];
  const customerAddress = 'Jl. Wijaya IX No. 3, Melawai, Kebayoran Baru, South Jakarta';
  const customerLat = -6.2447;
  const customerLng = 106.7995;

  // 7a. Andi — an ACTIVE delivery (OUT_FOR_DELIVERY). Powers the Active tab and
  //     the tracking map (laundromat marker + Andi's location marker).
  const activeOrder = await prisma.order.create({
    data: {
      status: OrderStatus.OUT_FOR_DELIVERY,
      pricingModel: PricingUnit.PER_ITEM,
      pickupAddress: customerAddress,
      deliveryAddress: customerAddress,
      customerLat,
      customerLng,
      distanceKm: 2.1,
      deliveryFee: 8000,
      itemsSubtotal: 90000,
      finalTotal: 98000,
      customerId: demoCustomer.id,
      laundromatId: sneakerSpa.id,
      driverId: andi.profileId,
      items: {
        create: [
          {
            serviceId: 0,
            serviceName: 'Sneaker Deep Clean & Unyellowing',
            unit: PricingUnit.PER_ITEM,
            unitPrice: 45000,
            quantity: 2,
            lineTotal: 90000,
          },
        ],
      },
      payments: {
        create: {
          amount: 98000,
          status: PaymentStatus.SETTLED,
          midtransOrderId: 'SEED-ANDI-ACTIVE-0001',
        },
      },
      offers: {
        create: {
          driverId: andi.profileId,
          phase: 'DELIVERY',
          status: OfferStatus.ACCEPTED,
          respondedAt: new Date(),
        },
      },
    },
  });
  console.log(`Seeded active delivery for Andi (order #${activeOrder.id}).`);

  // 7b. Andi — a COMPLETED order for the History tab.
  const completedOrder = await prisma.order.create({
    data: {
      status: OrderStatus.COMPLETED,
      pricingModel: PricingUnit.PER_KG,
      pickupAddress: customerAddress,
      deliveryAddress: customerAddress,
      customerLat,
      customerLng,
      distanceKm: 1.4,
      deliveryFee: 6000,
      weighedKg: 4,
      itemsSubtotal: 36000,
      finalTotal: 42000,
      customerId: demoCustomer.id,
      laundromatId: cleanWave.id,
      driverId: andi.profileId,
      items: {
        create: [
          {
            serviceId: 0,
            serviceName: 'Standard Kiloan (Wash & Fold)',
            unit: PricingUnit.PER_KG,
            unitPrice: 9000,
            quantity: 4,
            lineTotal: 36000,
          },
        ],
      },
      payments: {
        create: {
          amount: 42000,
          status: PaymentStatus.SETTLED,
          midtransOrderId: 'SEED-ANDI-DONE-0001',
        },
      },
    },
  });
  console.log(`Seeded completed order for Andi (order #${completedOrder.id}).`);

  // 7c. Budi — a pending DELIVERY offer (order READY_FOR_DELIVERY, unassigned).
  //     Powers the Offers tab.
  const offeredOrder = await prisma.order.create({
    data: {
      status: OrderStatus.READY_FOR_DELIVERY,
      pricingModel: PricingUnit.PER_ITEM,
      pickupAddress: customerAddress,
      deliveryAddress: customerAddress,
      customerLat,
      customerLng,
      distanceKm: 3.0,
      deliveryFee: 9000,
      itemsSubtotal: 85000,
      finalTotal: 94000,
      customerId: demoCustomer.id,
      laundromatId: sneakerSpa.id,
      items: {
        create: [
          {
            serviceId: 0,
            serviceName: 'Luxury Leather Bag Spa',
            unit: PricingUnit.PER_ITEM,
            unitPrice: 85000,
            quantity: 1,
            lineTotal: 85000,
          },
        ],
      },
      payments: {
        create: {
          amount: 94000,
          status: PaymentStatus.SETTLED,
          midtransOrderId: 'SEED-BUDI-OFFER-0001',
        },
      },
      offers: {
        create: {
          driverId: budi.profileId,
          phase: 'DELIVERY',
          status: OfferStatus.OFFERED,
        },
      },
    },
  });
  console.log(`Seeded pending delivery offer for Budi (order #${offeredOrder.id}).`);

  // 7d. Budi — a second pending DELIVERY offer (kiloan from CleanWave) so the
  //     Offers area shows more than one card.
  const offeredOrder2 = await prisma.order.create({
    data: {
      status: OrderStatus.READY_FOR_DELIVERY,
      pricingModel: PricingUnit.PER_KG,
      pickupAddress: customerAddress,
      deliveryAddress: 'Jl. Gandaria I No. 10, Kramat Pela, Kebayoran Baru, South Jakarta',
      customerLat: -6.2439,
      customerLng: 106.7845,
      distanceKm: 2.4,
      deliveryFee: 8000,
      weighedKg: 5,
      itemsSubtotal: 45000,
      finalTotal: 53000,
      customerId: demoCustomer.id,
      laundromatId: cleanWave.id,
      items: {
        create: [
          {
            serviceId: 0,
            serviceName: 'Standard Kiloan (Wash & Fold)',
            unit: PricingUnit.PER_KG,
            unitPrice: 9000,
            quantity: 5,
            lineTotal: 45000,
          },
        ],
      },
      payments: {
        create: {
          amount: 53000,
          status: PaymentStatus.SETTLED,
          midtransOrderId: 'SEED-BUDI-OFFER-0002',
        },
      },
      offers: {
        create: {
          driverId: budi.profileId,
          phase: 'DELIVERY',
          status: OfferStatus.OFFERED,
        },
      },
    },
  });
  console.log(`Seeded second pending delivery offer for Budi (order #${offeredOrder2.id}).`);

  // 7e. Andi — two pending DELIVERY offers too, so whichever demo driver you
  //     log in as has offers on the Home tab.
  const andiOffers = [
    {
      laundromatId: sneakerSpa.id,
      serviceName: 'Canvas Backpack & Duffel Care',
      unitPrice: 35000,
      deliveryAddress: 'Jl. Cipete Raya No. 8, Cipete Selatan, South Jakarta',
      lat: -6.2795,
      lng: 106.7980,
      fee: 7000,
      ref: 'SEED-ANDI-OFFER-0001',
    },
    {
      laundromatId: cleanWave.id,
      serviceName: 'Bedcover & Blanket Wash',
      unitPrice: 25000,
      deliveryAddress: 'Jl. Petogogan I No. 2, Pulo, Kebayoran Baru, South Jakarta',
      lat: -6.2460,
      lng: 106.8060,
      fee: 6000,
      ref: 'SEED-ANDI-OFFER-0002',
    },
  ];
  for (const o of andiOffers) {
    const order = await prisma.order.create({
      data: {
        status: OrderStatus.READY_FOR_DELIVERY,
        pricingModel: PricingUnit.PER_ITEM,
        pickupAddress: customerAddress,
        deliveryAddress: o.deliveryAddress,
        customerLat: o.lat,
        customerLng: o.lng,
        distanceKm: 2.0,
        deliveryFee: o.fee,
        itemsSubtotal: o.unitPrice,
        finalTotal: o.unitPrice + o.fee,
        customerId: demoCustomer.id,
        laundromatId: o.laundromatId,
        items: {
          create: [
            {
              serviceId: 0,
              serviceName: o.serviceName,
              unit: PricingUnit.PER_ITEM,
              unitPrice: o.unitPrice,
              quantity: 1,
              lineTotal: o.unitPrice,
            },
          ],
        },
        payments: {
          create: {
            amount: o.unitPrice + o.fee,
            status: PaymentStatus.SETTLED,
            midtransOrderId: o.ref,
          },
        },
        offers: {
          create: {
            driverId: andi.profileId,
            phase: 'DELIVERY',
            status: OfferStatus.OFFERED,
          },
        },
      },
    });
    console.log(`Seeded pending delivery offer for Andi (order #${order.id}).`);
  }

  // 7f. PENDING_ACCEPTANCE orders so partners see the Accept/Reject buttons.
  //     CleanWave: per-kg (no up-front payment needed to accept).
  const pendingKg = await prisma.order.create({
    data: {
      status: OrderStatus.PENDING_ACCEPTANCE,
      pricingModel: PricingUnit.PER_KG,
      pickupAddress: customerAddress,
      deliveryAddress: customerAddress,
      customerLat,
      customerLng,
      distanceKm: 1.8,
      deliveryFee: 7000,
      itemsSubtotal: null,
      finalTotal: null,
      customerId: demoCustomer.id,
      laundromatId: cleanWave.id,
      items: {
        create: [
          {
            serviceId: 0,
            serviceName: 'Standard Kiloan (Wash & Fold)',
            unit: PricingUnit.PER_KG,
            unitPrice: 9000,
            quantity: 4,
          },
        ],
      },
      declaredItems: {
        create: [
          { label: 'Blue denim jacket', photoUrl: DECLARED_PHOTOS.denimJacket },
          { label: 'White bedsheet set', photoUrl: DECLARED_PHOTOS.bedsheet },
        ],
      },
    },
  });
  console.log(`Seeded pending-acceptance order for CleanWave (order #${pendingKg.id}).`);

  // SneakerSpa: per-item, already paid (per-item must be paid before accept).
  const pendingItem = await prisma.order.create({
    data: {
      status: OrderStatus.PENDING_ACCEPTANCE,
      pricingModel: PricingUnit.PER_ITEM,
      pickupAddress: customerAddress,
      deliveryAddress: customerAddress,
      customerLat,
      customerLng,
      distanceKm: 2.6,
      deliveryFee: 8000,
      itemsSubtotal: 45000,
      finalTotal: 53000,
      customerId: demoCustomer.id,
      laundromatId: sneakerSpa.id,
      items: {
        create: [
          {
            serviceId: 0,
            serviceName: 'Sneaker Deep Clean & Unyellowing',
            unit: PricingUnit.PER_ITEM,
            unitPrice: 45000,
            quantity: 1,
            lineTotal: 45000,
          },
        ],
      },
      declaredItems: {
        create: [
          {
            label: 'Nike Air Force 1 (white)',
            photoUrl: DECLARED_PHOTOS.whiteSneaker,
          },
        ],
      },
      payments: {
        create: {
          amount: 53000,
          status: PaymentStatus.SETTLED,
          midtransOrderId: 'SEED-SNEAKER-PENDING-0001',
        },
      },
    },
  });
  console.log(`Seeded pending-acceptance order for SneakerSpa (order #${pendingItem.id}).`);

  // 8. Per-kg order AT_LAUNDROMAT — the driver has dropped it at CleanWave and
  //    it is waiting for the partner to "Receive & weigh". Declared items are
  //    NOT yet confirmed, so the partner's intake checklist has work to do.
  const atLaundromat = await prisma.order.create({
    data: {
      status: OrderStatus.AT_LAUNDROMAT,
      pricingModel: PricingUnit.PER_KG,
      pickupAddress: customerAddress,
      deliveryAddress: customerAddress,
      customerLat,
      customerLng,
      distanceKm: 1.8,
      deliveryFee: 7000,
      declaredItemsFee: 2000,
      itemsSubtotal: null,
      finalTotal: null,
      customerId: demoCustomer.id,
      laundromatId: cleanWave.id,
      driverId: andi.profileId,
      items: {
        create: [
          {
            serviceId: 0,
            serviceName: 'Standard Kiloan (Wash & Fold)',
            unit: PricingUnit.PER_KG,
            unitPrice: 9000,
            quantity: 4,
          },
        ],
      },
      declaredItems: {
        create: [
          {
            label: 'Blue denim jacket',
            photoUrl: DECLARED_PHOTOS.denimJacket,
            confirmedReceived: false,
          },
          {
            label: 'White bedsheet set',
            photoUrl: DECLARED_PHOTOS.bedsheet,
            confirmedReceived: false,
          },
        ],
      },
      offers: {
        create: {
          driverId: andi.profileId,
          phase: 'PICKUP',
          status: OfferStatus.ACCEPTED,
        },
      },
    },
  });
  console.log(`Seeded AT_LAUNDROMAT per-kg order for CleanWave (order #${atLaundromat.id}).`);

  // 9. Per-kg order WEIGHED_AWAITING_CONFIRM — the partner already received &
  //    weighed it, declared items are confirmed, and the customer now sees the
  //    weight + price + warranty confirmation to approve.
  const awaitingConfirm = await prisma.order.create({
    data: {
      status: OrderStatus.WEIGHED_AWAITING_CONFIRM,
      pricingModel: PricingUnit.PER_KG,
      pickupAddress: customerAddress,
      deliveryAddress: customerAddress,
      customerLat,
      customerLng,
      distanceKm: 1.8,
      deliveryFee: 7000,
      declaredItemsFee: 2000,
      weighedKg: 4.5,
      itemsSubtotal: 40500,
      finalTotal: 49500, // 40500 + 7000 delivery + 2000 declared-items fee
      customerId: demoCustomer.id,
      laundromatId: cleanWave.id,
      driverId: andi.profileId,
      items: {
        create: [
          {
            serviceId: 0,
            serviceName: 'Standard Kiloan (Wash & Fold)',
            unit: PricingUnit.PER_KG,
            unitPrice: 9000,
            quantity: 4,
            lineTotal: 40500,
          },
        ],
      },
      declaredItems: {
        create: [
          {
            label: 'Blue denim jacket',
            photoUrl: DECLARED_PHOTOS.denimJacket,
            confirmedReceived: true,
          },
          {
            label: 'White bedsheet set',
            photoUrl: DECLARED_PHOTOS.bedsheet,
            confirmedReceived: true,
          },
        ],
      },
      offers: {
        create: {
          driverId: andi.profileId,
          phase: 'PICKUP',
          status: OfferStatus.ACCEPTED,
        },
      },
    },
  });
  console.log(
    `Seeded WEIGHED_AWAITING_CONFIRM per-kg order for CleanWave (order #${awaitingConfirm.id}).`
  );

  console.log(`\nAll demo accounts use password: ${DEMO_PASSWORD}`);
  console.log('--- Washly Database Seeding Completed Successfully! ---');
}

main()
  .catch((e) => {
    console.error('Seeding Error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
