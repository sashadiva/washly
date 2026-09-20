import { prisma } from '../src/config/prisma.js';
import { Role, PricingUnit } from '@prisma/client';

async function main() {
  console.log('--- Starting Washly Database Seeding ---');

  // 1. Clean existing records in reverse relation order
  await prisma.order.deleteMany();
  await prisma.review.deleteMany();
  await prisma.laundryService.deleteMany();
  await prisma.laundromatsOnTags.deleteMany();
  await prisma.laundromat.deleteMany();
  await prisma.tag.deleteMany();
  await prisma.user.deleteMany();

  console.log('Cleared existing database entries.');

  // 2. Create Default Demo Customer (id: 1 used across app tests)
  const demoCustomer = await prisma.user.create({
    data: {
      name: 'Demo Customer',
      email: 'customer@washly.com',
      phone: '081234567890',
      passwordHash: 'hashed_password_demo',
      role: Role.CUSTOMER,
    },
  });
  console.log(`Created demo customer: ${demoCustomer.email} (ID: ${demoCustomer.id})`);

  // 3. Create Tags for Marketplace Discovery
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
    const tag = await prisma.tag.create({
      data: { name },
    });
    createdTags[name] = tag.id;
  }
  console.log(`Created ${tagNames.length} marketplace tags.`);

  // 4. Partner Laundromats Data with Custom Services & Reviews
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
        latitude: -6.2615,
        longitude: 106.8153,
        imageUrl: 'https://images.unsplash.com/photo-1545173168-9f1947eebb7f?w=800&auto=format&fit=crop&q=80',
        rating: 4.8,
        reviewCount: 3,
        isOpen: true,
      },
      tags: ['express', 'kiloan', 'ironing', 'dry clean'],
      services: [
        {
          name: 'Standard Kiloan (Wash & Fold)',
          description: 'Everyday laundry washed with hypoallergenic detergent, tumble dried, and neatly packed.',
          price: 9000,
          unit: PricingUnit.PER_KG,
          imageUrl: 'https://images.unsplash.com/photo-1517677208171-0bc6725a3e60?w=400&auto=format&fit=crop&q=80',
        },
        {
          name: 'Express 6-Hour Kiloan',
          description: 'Priority queue same-day washing, spin drying, and packaging within 6 hours.',
          price: 16000,
          unit: PricingUnit.PER_KG,
          imageUrl: 'https://images.unsplash.com/photo-1545173168-9f1947eebb7f?w=400&auto=format&fit=crop&q=80',
        },
        {
          name: 'Steam Ironing Only',
          description: 'High-temperature industrial steam press for shirts, trousers, and skirts.',
          price: 7000,
          unit: PricingUnit.PER_KG,
          imageUrl: 'https://images.unsplash.com/photo-1489274495757-95c7c837b101?w=400&auto=format&fit=crop&q=80',
        },
        {
          name: 'Bedcover & Blanket Wash',
          description: 'Large drum deep cleansing for king and queen comforters.',
          price: 25000,
          unit: PricingUnit.PER_ITEM,
          imageUrl: 'https://images.unsplash.com/photo-1582735689369-4fe89db7114c?w=400&auto=format&fit=crop&q=80',
        },
      ],
      reviews: [
        {
          rating: 5,
          comment: 'Super fast express pickup! Clothes arrived warm, dry, and fragrant.',
        },
        {
          rating: 5,
          comment: 'Very neat folding and reasonable price for Kemang area.',
        },
        {
          rating: 4,
          comment: 'Good service, but delivery had a slight 15-minute delay due to rain.',
        },
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
        latitude: -6.2312,
        longitude: 106.8115,
        imageUrl: 'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?w=800&auto=format&fit=crop&q=80',
        rating: 4.9,
        reviewCount: 2,
        isOpen: true,
      },
      tags: ['shoes', 'bags', 'dry clean'],
      services: [
        {
          name: 'Sneaker Deep Clean & Unyellowing',
          description: 'Midsole de-oxidation, delicate suede scrubbing, insole UV sterilization, and relacing.',
          price: 45000,
          unit: PricingUnit.PER_ITEM,
          imageUrl: 'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=400&auto=format&fit=crop&q=80',
        },
        {
          name: 'Luxury Leather Bag Spa',
          description: 'Color-safe micro-cleanse, botanical hydration treatment, and beeswax buffing.',
          price: 85000,
          unit: PricingUnit.PER_ITEM,
          imageUrl: 'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=400&auto=format&fit=crop&q=80',
        },
        {
          name: 'Canvas Backpack & Duffel Care',
          description: 'Heavy stains spot cleaning followed by water-repellent coating spray.',
          price: 35000,
          unit: PricingUnit.PER_ITEM,
          imageUrl: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400&auto=format&fit=crop&q=80',
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
    {
      partner: {
        name: 'Costume & Plushie Care Lab',
        email: 'partner.cosplaycare@washly.com',
        phone: '08119876003',
      },
      store: {
        name: 'Costume & Plushie Care Lab',
        description: 'Specialized fabric treatment for cosplay outfits, theater costumes, wigs, and stuffed toys.',
        address: 'Jl. Tanjung Duren Barat No. 8, Grogol Petamburan, West Jakarta',
        latitude: -6.1754,
        longitude: 106.7825,
        imageUrl: 'https://images.unsplash.com/photo-1582735689369-4fe89db7114c?w=800&auto=format&fit=crop&q=80',
        rating: 4.7,
        reviewCount: 2,
        isOpen: true,
      },
      tags: ['dolls', 'costumes', 'dry clean'],
      services: [
        {
          name: 'Giant Plushie Sterilization',
          description: 'Deep anti-mite wash, mild disinfectant rinse, slow warm fluff drying, and brush finish.',
          price: 30000,
          unit: PricingUnit.PER_ITEM,
          imageUrl: 'https://images.unsplash.com/photo-1559454403-b8fb88521f11?w=400&auto=format&fit=crop&q=80',
        },
        {
          name: 'Cosplay & Stage Costume Spa',
          description: 'Gentle hand wash for satin, velvet, faux leather, sequins, and props.',
          price: 65000,
          unit: PricingUnit.PER_ITEM,
          imageUrl: 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=400&auto=format&fit=crop&q=80',
        },
      ],
      reviews: [
        {
          rating: 5,
          comment: 'Cleaned a massive 1.5-meter stuffed bear completely through without flattening the cotton!',
        },
        {
          rating: 4,
          comment: 'Careful with delicate fabrics and trims. Great niche laundry option.',
        },
      ],
    },
    {
      partner: {
        name: 'EcoWash Coin & Drop-off Laundry',
        email: 'partner.ecowash@washly.com',
        phone: '08119876004',
      },
      store: {
        name: 'EcoWash Coin & Drop-off Laundry',
        description: 'Budget-friendly community laundry using eco-friendly ozone sterilization and quick wash cycles.',
        address: 'Jl. Rawa Belong No. 21, Palmerah, West Jakarta',
        latitude: -6.2018,
        longitude: 106.7821,
        imageUrl: 'https://images.unsplash.com/photo-1517677208171-0bc6725a3e60?w=800&auto=format&fit=crop&q=80',
        rating: 4.4,
        reviewCount: 2,
        isOpen: true,
      },
      tags: ['kiloan', 'express'],
      services: [
        {
          name: 'Budget Kiloan Clean',
          description: 'Basic 24-hour detergent wash and fold for t-shirts, jeans, and socks.',
          price: 7000,
          unit: PricingUnit.PER_KG,
          imageUrl: 'https://images.unsplash.com/photo-1517677208171-0bc6725a3e60?w=400&auto=format&fit=crop&q=80',
        },
        {
          name: 'Dry Only (Tumble Spin)',
          description: '30-minute high-heat anti-bacterial tumble drying.',
          price: 5000,
          unit: PricingUnit.PER_KG,
          imageUrl: 'https://images.unsplash.com/photo-1545173168-9f1947eebb7f?w=400&auto=format&fit=crop&q=80',
        },
      ],
      reviews: [
        {
          rating: 4,
          comment: 'Very cheap and dependable for college dorm laundry.',
        },
        {
          rating: 5,
          comment: 'Clean machines and quick turnaround.',
        },
      ],
    },
  ];

  // 5. Seed Each Laundromat, Services, Tags, and Reviews
  for (const item of laundromatsData) {
    const owner = await prisma.user.create({
      data: {
        name: item.partner.name,
        email: item.partner.email,
        phone: item.partner.phone,
        passwordHash: 'dummy_partner_hash',
        role: Role.PARTNER,
      },
    });

    const laundromat = await prisma.laundromat.create({
      data: {
        ...item.store,
        ownerId: owner.id,
      },
    });

    // Attach Tag Join Records
    for (const tagName of item.tags) {
      const tagId = createdTags[tagName];
      if (tagId) {
        await prisma.laundromatsOnTags.create({
          data: {
            laundromatId: laundromat.id,
            tagId,
          },
        });
      }
    }

    // Attach Dynamic Services
    for (const service of item.services) {
      await prisma.laundryService.create({
        data: {
          ...service,
          laundromatId: laundromat.id,
        },
      });
    }

    // Attach Reviews
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

    console.log(`Seeded: ${laundromat.name} (${item.services.length} services, ${item.reviews.length} reviews)`);
  }

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