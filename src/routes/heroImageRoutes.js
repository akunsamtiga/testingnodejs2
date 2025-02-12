// src/routes/heroImageRoutes.js
const express = require('express');
const router = express.Router();
const upload = require('../middlewares/upload'); // Middleware upload gambar
const heroImageController = require('../controllers/heroImageController');

router.post('/', upload.single('heroImage'), heroImageController.createHeroImage);
router.get('/', heroImageController.getHeroImages);
router.delete('/:id', heroImageController.deleteHeroImage);

module.exports = router;
