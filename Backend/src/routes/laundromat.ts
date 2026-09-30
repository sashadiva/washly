import { Router, Request, Response } from 'express';
import { prisma } from '../config/prisma.js';
import { toCustomerLaundromat } from '../services/laundromatMapper.js';

const router = Router();

interface LaundromatQuery {
  tags?: string;
  sort?: 'rating' | 'distance';
  userLat?: string;
  userLng?: string;
}

// ---------------------------------------------------------------------------
// GET /api/laundromats (Discovery Feed with Tag Filters & Distance/Rating Sort)
//
// Customer-facing: responses omit exact address and raw lat/lng (Requirement
// 3.4). Only distanceKm (computed server-side) and a coarse areaLabel are
// exposed. When customer coords are absent, the list still returns but without
// distance, and distance sorting is skipped.
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

    const lat = userLat ? parseFloat(userLat) : null;
    const lng = userLng ? parseFloat(userLng) : null;
    const hasCoords = lat != null && lng != null && Number.isFinite(lat) && Number.isFinite(lng);

    let results = laundromats.map((shop) =>
      toCustomerLaundromat(
        {
          id: shop.id,
          name: shop.name,
          areaLabel: shop.areaLabel,
          latitude: shop.latitude,
          longitude: shop.longitude,
          imageUrl: shop.imageUrl,
          rating: shop.rating,
          reviewCount: shop.reviewCount,
          tags: shop.tags ? shop.tags.map((t) => t.tag.name) : [],
        },
        lat,
        lng
      )
    );

    if (sort === 'rating') {
      results.sort((a, b) => b.rating - a.rating);
    } else if (sort === 'distance' && hasCoords) {
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
//
// Customer-facing: no exact address or coords (Requirement 3.4). Distance is
// included when the caller supplies userLat/userLng.
// ---------------------------------------------------------------------------
router.get('/:id', async (req: Request<{ id: string }, {}, {}, LaundromatQuery>, res: Response) => {
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

    const { userLat, userLng } = req.query;
    const lat = userLat ? parseFloat(userLat) : null;
    const lng = userLng ? parseFloat(userLng) : null;

    const payload = toCustomerLaundromat(
      {
        id: store.id,
        name: store.name,
        description: store.description,
        areaLabel: store.areaLabel,
        latitude: store.latitude,
        longitude: store.longitude,
        imageUrl: store.imageUrl,
        rating: store.rating,
        reviewCount: store.reviewCount,
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
      },
      lat,
      lng
    );

    res.json(payload);
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
