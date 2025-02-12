// src/routes/productRoutes.js
const express = require('express');
const router = express.Router();
const { getProducts, getProductById, createProduct, updateProduct } = require('../controllers/productController');
const authMiddleware = require('../middlewares/authMiddleware');
const adminMiddleware = require('../middlewares/adminMiddleware');
const upload = require('../middlewares/upload');
const { updateProductStock } = require('../controllers/productController');

router.get('/', getProducts);
router.get('/:id', getProductById);
router.post('/', authMiddleware, adminMiddleware, upload.single('image'), createProduct);  // Bisa dilindungi: router.post('/', authMiddleware, adminMiddleware, createProduct);
router.put('/:id', authMiddleware, adminMiddleware,upload.single('image'), updateProduct); // Sama, tambahkan middleware jika diperlukan
router.patch('/:id/stock', authMiddleware, adminMiddleware, updateProductStock);

module.exports = router;
