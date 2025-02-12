// src/controllers/productController.js
const prisma = require('../utils/prisma');

exports.getProducts = async (req, res, next) => {
  try {
    const { search, category, minPrice, maxPrice, sortBy, order, page, limit } = req.query;

    // Buat filter
    let filters = {};
    if (search) {
      filters.title = { contains: search, mode: 'insensitive' };
    }
    if (category) {
      filters.category = category;
    }
    if (minPrice || maxPrice) {
      filters.price = {};
      if (minPrice) filters.price.gte = parseFloat(minPrice);
      if (maxPrice) filters.price.lte = parseFloat(maxPrice);
    }

    let orderBy = {};
    if (sortBy) {
      orderBy[sortBy] = order === 'desc' ? 'desc' : 'asc';
    }

    // Pagination
    const pageNumber = parseInt(page) || 1;
    const pageSize   = parseInt(limit) || 10;
    const skip       = (pageNumber - 1) * pageSize;

    // Ambil produk
    const products = await prisma.product.findMany({
      where: filters,
      orderBy: Object.keys(orderBy).length ? orderBy : undefined,
      skip,
      take: pageSize,
      include: {
        reviews: { select: { rating: true } }
      }
    });

    // Gunakan groupBy untuk menghitung rata-rata rating tiap produk
    const ratings = await prisma.review.groupBy({
      by: ['productId'],
      _avg: { rating: true }
    });

    const ratingMap = {};
    ratings.forEach(r => {
      ratingMap[r.productId] = r._avg.rating || 0;
    });

    const productsWithRating = products.map(product => ({
      ...product,
      rating: parseFloat((ratingMap[product.id] || 0).toFixed(1))
    }));

    res.status(200).json(productsWithRating);
  } catch (error) {
    next(error);
  }
};

exports.getProductById = async (req, res, next) => {
  try {
    const productId = parseInt(req.params.id);
    const product = await prisma.product.findUnique({
      where: { id: productId }
    });
    if (!product) return res.status(404).json({ error: 'Product not found' });
    res.status(200).json(product);
  } catch (error) {
    next(error);
  }
};

// Fungsi update stok produk (bisa dipanggil dari dashboard admin)
exports.updateProductStock = async (req, res, next) => {
  try {
    const productId = parseInt(req.params.id);
    const { stock } = req.body; // pastikan stock dikirim sebagai angka
    const product = await prisma.product.update({
      where: { id: productId },
      data: { stock: parseInt(stock) }
    });
    res.status(200).json({ message: 'Product stock updated', product });
  } catch (error) {
    next(error);
  }
};

exports.createProduct = async (req, res, next) => {
  try {
    const { title, description, price, category } = req.body;
    // Jika file diupload, ambil path-nya; jika tidak, biarkan null
    const image = req.file ? `/uploads/${req.file.filename}` : null;
    const product = await prisma.product.create({
      data: {
        title,
        description,
        price: parseFloat(price),
        image,
        category
      }
    });
    res.status(201).json({ message: 'Product created', product });
  } catch (error) {
    next(error);
  }
};

exports.updateProduct = async (req, res, next) => {
  try {
    const productId = parseInt(req.params.id);
    const { title, description, price, category } = req.body;
    
    // Persiapkan data update
    const updateData = {
      title,
      description,
      price: parseFloat(price),
      category
    };

    // Jika ada file baru yang diupload, update field image
    if (req.file) {
      updateData.image = `/uploads/${req.file.filename}`;
    }
    
    const product = await prisma.product.update({
      where: { id: productId },
      data: updateData
    });
    res.status(200).json({ message: 'Product updated', product });
  } catch (error) {
    next(error);
  }
};