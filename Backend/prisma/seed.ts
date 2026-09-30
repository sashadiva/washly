import { prisma } from '../src/config/prisma.js';
import { Role, PricingUnit, DriverAvailability } from '@prisma/client';
import { hashPassword } from '../src/services/passwordService.js';

// Shared demo password for every seeded account (customer, partners, drivers).
const DEMO_PASSWORD = 'password123';

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
    });
    console.log(`Created driver: ${user.email} (${driver.profile.plateNumber})`);
  }

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
