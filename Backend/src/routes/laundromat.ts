import { Router, Request, Response } from 'express';
import { prisma } from '../config/prisma.js';

const router = Router();

// Haversine formula to compute great-circle distance in kilometers
function getDistanceKm(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371;
  const dLat = (lat2 - lat1) * (Math.PI / 180);
  const dLon = (lon2 - lon1) * (Math.PI / 180);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * (Math.PI / 180)) *
      Math.cos(lat2 * (Math.PI / 180)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

interface LaundromatQuery {
  tags?: string;
  sort?: 'rating' | 'distance';
  userLat?: string;
  userLng?: string;
}

// ---------------------------------------------------------------------------
// GET /api/laundromats (Discovery Feed with Tag Filters & Distance/Rating Sort)
// ---------------------------------------------------------------------------
router.get('/', async (req: Request<{}, {}, {}, LaundromatQuery>, res: Response) => {
  try {
    const { tags, sort, userLat, userLng } = req.query;

    const whereClause: any = { isOpen: true };

    if (tags && tags.trim().length > 0) {
      const tagList = tags
        .split(',')
        .map((t) => t.trim().toLowerCase())
        .filter((t) => t.length > 0);

      if (tagList.length > 0) {
        whereClause.tags = {
          some: {
            tag: {
              name: { in: tagList },
            },
          },
        };
      }
    }

    const laundromats = await prisma.laundromat.findMany({
      where: whereClause,
      include: {
        tags: {
          include: { tag: true },
        },
      },
    });

    let results = laundromats.map((shop) => {
      const flattenedTags = shop.tags ? shop.tags.map((t) => t.tag.name) : [];
      let distanceKm: number | null = null;

      if (userLat && userLng) {
        distanceKm = getDistanceKm(
          parseFloat(userLat),
          parseFloat(userLng),
          shop.latitude,
          shop.longitude
        );
      }

      return {
        id: shop.id,
        name: shop.name,
        address: shop.address,
        rating: shop.rating,
        reviewCount: shop.reviewCount,
        imageUrl: shop.imageUrl,
        tags: flattenedTags,
        distanceKm: distanceKm ? parseFloat(distanceKm.toFixed(1)) : null,
      };
    });

    if (sort === 'rating') {
      results.sort((a, b) => b.rating - a.rating);
    } else if (sort === 'distance' && userLat && userLng) {
      results.sort((a, b) => (a.distanceKm ?? 0) - (b.distanceKm ?? 0));
    }

    res.json(results);
  } catch (error: any) {
    console.error('Error fetching laundromats:', error);
    res.status(500).json({ error: error.message });
  }
});

// ---------------------------------------------------------------------------
// GET /api/laundromats/:id (Store Details with Dynamic Services & Reviews)
// ---------------------------------------------------------------------------
router.get('/:id', async (req: Request<{ id: string }>, res: Response) => {
  try {
    const storeId = parseInt(req.params.id, 10);
    if (isNaN(storeId)) {
      return res.status(400).json({ error: 'Invalid laundromat ID' });
    }

    const store = await prisma.laundromat.findUnique({
      where: { id: storeId },
      include: {
        tags: {
          include: { tag: true },
        },
        services: {
          orderBy: { price: 'asc' },
        },
        reviews: {
          include: {
            user: {
              select: { id: true, name: true },
            },
          },
          orderBy: { createdAt: 'desc' },
        },
      },
    });

    if (!store) {
      return res.status(404).json({ error: 'Laundromat not found' });
    }

    res.json({
      id: store.id,
      name: store.name,
      description: store.description,
      address: store.address,
      rating: store.rating,
      reviewCount: store.reviewCount,
      imageUrl: store.imageUrl,
      tags: store.tags.map((t) => t.tag.name),
      services: store.services.map((s) => ({
        id: s.id,
        name: s.name,
        description: s.description,
        price: s.price,
        unit: s.unit,
        imageUrl: s.imageUrl,
      })),
      reviews: store.reviews.map((r) => ({
        id: r.id,
        rating: r.rating,
        comment: r.comment,
        userName: r.user.name,
        createdAt: r.createdAt,
      })),
    });
  } catch (error: any) {
    console.error('Error fetching laundromat detail:', error);
    res.status(500).json({ error: error.message });
  }
});

// ---------------------------------------------------------------------------
// POST /api/laundromats/:id/reviews (Add Review & Recalculate Rating)
// ---------------------------------------------------------------------------
router.post('/:id/reviews', async (req: Request<{ id: string }>, res: Response) => {
  try {
    const laundromatId = parseInt(req.params.id, 10);
    const { rating, comment, userId } = req.body;

    const parsedRating = parseInt(String(rating), 10);
    const parsedUserId = parseInt(String(userId), 10);

    if (isNaN(laundromatId) || isNaN(parsedRating) || isNaN(parsedUserId)) {
      return res.status(400).json({ error: 'Missing or invalid parameters' });
    }

    if (parsedRating < 1 || parsedRating > 5) {
      return res.status(400).json({ error: 'Rating must be between 1 and 5' });
    }

    const newReview = await prisma.review.create({
      data: {
        rating: parsedRating,
        comment: comment || null,
        userId: parsedUserId,
        laundromatId,
      },
    });

    const stats = await prisma.review.aggregate({
      where: { laundromatId },
      _avg: { rating: true },
      _count: { rating: true },
    });

    await prisma.laundromat.update({
      where: { id: laundromatId },
      data: {
        rating: stats._avg.rating ? parseFloat(stats._avg.rating.toFixed(1)) : 0.0,
        reviewCount: stats._count.rating || 0,
      },
    });

    res.status(201).json(newReview);
  } catch (error: any) {
    console.error('Error creating review:', error);
    res.status(500).json({ error: error.message });
  }
});

export default router;