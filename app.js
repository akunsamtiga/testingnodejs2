// app.js
const dotenv = require('dotenv-safe');
dotenv.config({
  allowEmptyValues: false,
  example: '.env.example'
});

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const path = require('path');
const rateLimit = require('express-rate-limit');
const errorHandler = require('./src/middlewares/errorHandler');
const morgan = require('morgan');

const app = express();

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Gunakan `morgan` hanya di development mode
if (process.env.NODE_ENV !== 'test') {
  app.use(morgan('combined'));
}

// Konfigurasi rate limiter: maksimal 100 request per IP dalam 15 menit.
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 menit
  max: 100, // Maksimal 100 request per IP per windowMs
  message: {
    error: 'Terlalu banyak permintaan dari IP ini. Silakan coba lagi setelah 15 menit.'
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// Terapkan rate limiter secara global
app.use(limiter);

// Sediakan folder uploads sebagai static agar file dapat diakses
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Route dasar
app.get('/', (req, res) => {
  res.send('E-commerce Backend is running.');
});

// Mount routes
const authRoutes = require('./src/routes/authRoutes');
const userRoutes = require('./src/routes/userRoutes');
const adminRoutes = require('./src/routes/adminRoutes');
const productRoutes = require('./src/routes/productRoutes');
const reviewRoutes = require('./src/routes/reviewRoutes');
const wishlistRoutes = require('./src/routes/wishlistRoutes');
const heroImageRoutes = require('./src/routes/heroImageRoutes');
const articleRoutes = require('./src/routes/articleRoutes');

app.use('/api/auth', authRoutes);
app.use('/api/products', productRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/api/users', userRoutes);
app.use('/api/wishlist', wishlistRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/hero-images', heroImageRoutes);
app.use('/api/articles', articleRoutes);

// Global error handler
app.use(errorHandler);

module.exports = app; // Jangan jalankan app.listen() di sini
