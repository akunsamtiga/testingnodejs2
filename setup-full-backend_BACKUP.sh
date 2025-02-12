#!/bin/bash
set -e

echo "=========================================="
echo "Memulai setup lengkap backend e-commerce..."
echo "=========================================="

# 1. Membuat folder proyek backend dan seluruh struktur folder
BACKEND_DIR="backend"
mkdir -p $BACKEND_DIR/{prisma,src/{controllers,middlewares,routes,utils,logs},__tests__/{controllers,middlewares,utils}}

echo "Folder struktur telah dibuat."

# 2. Pindah ke direktori backend
cd $BACKEND_DIR

# 3. Membuat file .env
echo "Membuat file .env..."
cat > .env <<EOL
DATABASE_URL="postgresql://postgres:aryasatyaibnusani87@localhost:5432/ecommerce_db?schema=public"
JWT_SECRET="aryasatyaibnusani"
PORT=5000
EMAIL_USER="akunsamempat@gmail.com"
EMAIL_PASS="aryasatyaibnusani87"
EOL
echo ".env telah dibuat."

# 4. Membuat package.json
echo "Membuat package.json..."
cat > package.json <<'EOF'
{
  "name": "backend",
  "version": "1.0.0",
  "description": "Backend untuk aplikasi e-commerce (tanpa checkout)",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "test": "jest",
    "seed": "node prisma/seed.js"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "dependencies": {
    "bcrypt": "^5.1.0",
    "cors": "^2.8.5",
    "dotenv": "^16.0.3",
    "express": "^4.18.2",
    "express-validator": "^6.14.2",
    "helmet": "^6.0.1",
    "jsonwebtoken": "^9.0.0",
    "@prisma/client": "^4.13.0"
  },
  "devDependencies": {
    "jest": "^29.5.0",
    "nodemon": "^2.0.22",
    "prisma": "^4.13.0",
    "supertest": "^6.3.3"
  }
}
EOF
echo "package.json telah dibuat."

# 5. Membuat Dockerfile
echo "Membuat Dockerfile..."
cat > Dockerfile <<'EOF'
FROM node:16-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 5000
CMD ["npm", "run", "start"]
EOF
echo "Dockerfile telah dibuat."

# 6. Membuat file jest.config.js
echo "Membuat jest.config.js..."
cat > jest.config.js <<'EOF'
module.exports = {
  testEnvironment: 'node',
  testMatch: ['**/__tests__/**/*.test.js'],
  setupFiles: ["dotenv/config"]
};
EOF
echo "jest.config.js telah dibuat."

# 7. Membuat file Prisma schema (prisma/schema.prisma)
echo "Membuat prisma/schema.prisma..."
cat > prisma/schema.prisma <<'EOF'
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

generator client {
  provider = "prisma-client-js"
}

model User {
  id        Int      @id @default(autoincrement())
  name      String
  email     String   @unique
  password  String
  role      String   @default("USER")
  createdAt DateTime @default(now())
  reviews   Review[]
  wishlist  Wishlist[]
}

model Product {
  id          Int      @id @default(autoincrement())
  title       String
  description String
  price       Float
  image       String?
  category    String
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt
  reviews     Review[]
  wishlists   Wishlist[]
}

model Review {
  id        Int      @id @default(autoincrement())
  rating    Int
  comment   String?
  product   Product  @relation(fields: [productId], references: [id])
  productId Int
  user      User     @relation(fields: [userId], references: [id])
  userId    Int
  createdAt DateTime @default(now())
}

model Wishlist {
  id        Int      @id @default(autoincrement())
  user      User     @relation(fields: [userId], references: [id])
  userId    Int
  product   Product  @relation(fields: [productId], references: [id])
  productId Int
  createdAt DateTime @default(now())
}
EOF
echo "prisma/schema.prisma telah dibuat."

# 8. Membuat file seed (prisma/seed.js)
echo "Membuat prisma/seed.js..."
cat > prisma/seed.js <<'EOF'
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  // Hapus data lama (jika ada)
  await prisma.wishlist.deleteMany();
  await prisma.review.deleteMany();
  await prisma.product.deleteMany();
  await prisma.user.deleteMany();

  // Membuat user admin dan user biasa
  const admin = await prisma.user.create({
    data: {
      name: "Admin",
      email: "admin@example.com",
      password: "adminpassword", // sebaiknya di-hash pada saat registrasi (untuk seed, bisa plain)
      role: "ADMIN"
    }
  });

  const user = await prisma.user.create({
    data: {
      name: "Regular User",
      email: "user@example.com",
      password: "userpassword"
    }
  });

  // Membuat produk-produk contoh
  const product1 = await prisma.product.create({
    data: {
      title: "Produk Contoh 1",
      description: "Deskripsi produk contoh 1",
      price: 100.0,
      image: "https://via.placeholder.com/150",
      category: "Kategori 1"
    }
  });

  const product2 = await prisma.product.create({
    data: {
      title: "Produk Contoh 2",
      description: "Deskripsi produk contoh 2",
      price: 200.0,
      image: "https://via.placeholder.com/150",
      category: "Kategori 2"
    }
  });

  console.log("Seed data berhasil dibuat.");
}

main()
  .catch(e => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
EOF
echo "prisma/seed.js telah dibuat."

# 9. Membuat file server.js (entry point Express)
echo "Membuat file server.js..."
cat > server.js <<'EOF'
const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const helmet = require('helmet');
const errorHandler = require('./src/middlewares/errorHandler');

dotenv.config();

const app = express();

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Routing dasar
app.get('/', (req, res) => {
  res.send('E-commerce Backend is running.');
});

// Mount routes
const authRoutes = require('./src/routes/authRoutes');
const productRoutes = require('./src/routes/productRoutes');
const reviewRoutes = require('./src/routes/reviewRoutes');
const userRoutes = require('./src/routes/userRoutes');
const wishlistRoutes = require('./src/routes/wishlistRoutes');
const adminRoutes = require('./src/routes/adminRoutes');

app.use('/api/auth', authRoutes);
app.use('/api/products', productRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/api/users', userRoutes);
app.use('/api/wishlist', wishlistRoutes);
app.use('/api/admin', adminRoutes);

// Global error handler
app.use(errorHandler);

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
EOF
echo "server.js telah dibuat."

# 10. Membuat folder logs dan file log (opsional)
echo "Membuat folder logs..."
mkdir -p src/logs
touch src/logs/app.log
echo "Folder logs dan file app.log telah dibuat."

# 11. Membuat file-file di folder src/controllers

## authController.js
echo "Membuat src/controllers/authController.js..."
cat > src/controllers/authController.js <<'EOF'
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

exports.registerUser = async (req, res, next) => {
  try {
    const { name, email, password } = req.body;
    const hashedPassword = await bcrypt.hash(password, 10);
    const user = await prisma.user.create({
      data: { name, email, password: hashedPassword }
    });
    res.status(201).json({ message: 'User registered successfully', user });
  } catch (error) {
    next(error);
  }
};

exports.loginUser = async (req, res, next) => {
  try {
    const { email, password } = req.body;
    const user = await prisma.user.findUnique({ where: { email }});
    if (!user) return res.status(404).json({ error: 'User not found' });
    const isValid = await bcrypt.compare(password, user.password);
    if (!isValid) return res.status(401).json({ error: 'Invalid credentials' });
    const token = jwt.sign({ id: user.id, email: user.email, role: user.role }, process.env.JWT_SECRET, { expiresIn: '1d' });
    res.status(200).json({ message: 'Login successful', token });
  } catch (error) {
    next(error);
  }
};
EOF

## productController.js
echo "Membuat src/controllers/productController.js..."
cat > src/controllers/productController.js <<'EOF'
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

exports.getProducts = async (req, res, next) => {
  try {
    const products = await prisma.product.findMany();
    res.status(200).json(products);
  } catch (error) {
    next(error);
  }
};

exports.getProductById = async (req, res, next) => {
  try {
    const productId = parseInt(req.params.id);
    const product = await prisma.product.findUnique({ where: { id: productId }});
    if (!product) return res.status(404).json({ error: 'Product not found' });
    res.status(200).json(product);
  } catch (error) {
    next(error);
  }
};
EOF

## reviewController.js
echo "Membuat src/controllers/reviewController.js..."
cat > src/controllers/reviewController.js <<'EOF'
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

exports.createReview = async (req, res, next) => {
  try {
    const { rating, comment, productId, userId } = req.body;
    const review = await prisma.review.create({
      data: { rating, comment, productId, userId }
    });
    res.status(201).json({ message: 'Review added', review });
  } catch (error) {
    next(error);
  }
};

exports.getReviewsByProduct = async (req, res, next) => {
  try {
    const productId = parseInt(req.params.id);
    const reviews = await prisma.review.findMany({ where: { productId }});
    res.status(200).json(reviews);
  } catch (error) {
    next(error);
  }
};
EOF

## userController.js
echo "Membuat src/controllers/userController.js..."
cat > src/controllers/userController.js <<'EOF'
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

exports.getUserProfile = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const user = await prisma.user.findUnique({ where: { id: userId }});
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.status(200).json(user);
  } catch (error) {
    next(error);
  }
};

exports.updateUserProfile = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const data = req.body;
    const user = await prisma.user.update({ where: { id: userId }, data });
    res.status(200).json({ message: 'Profile updated', user });
  } catch (error) {
    next(error);
  }
};
EOF

## wishlistController.js
echo "Membuat src/controllers/wishlistController.js..."
cat > src/controllers/wishlistController.js <<'EOF'
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

exports.addToWishlist = async (req, res, next) => {
  try {
    const { productId } = req.body;
    const userId = req.user.id;
    const wishlistItem = await prisma.wishlist.create({ data: { userId, productId }});
    res.status(201).json({ message: 'Added to wishlist', wishlistItem });
  } catch (error) {
    next(error);
  }
};

exports.getWishlist = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const wishlist = await prisma.wishlist.findMany({ where: { userId }, include: { product: true }});
    res.status(200).json(wishlist);
  } catch (error) {
    next(error);
  }
};

exports.removeFromWishlist = async (req, res, next) => {
  try {
    const wishlistId = parseInt(req.params.id);
    await prisma.wishlist.delete({ where: { id: wishlistId }});
    res.status(200).json({ message: 'Removed from wishlist' });
  } catch (error) {
    next(error);
  }
};
EOF

## adminController.js
echo "Membuat src/controllers/adminController.js..."
cat > src/controllers/adminController.js <<'EOF'
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

exports.getDashboardStats = async (req, res, next) => {
  try {
    const userCount = await prisma.user.count();
    const productCount = await prisma.product.count();
    const reviewCount = await prisma.review.count();
    res.status(200).json({ userCount, productCount, reviewCount });
  } catch (error) {
    next(error);
  }
};

exports.deleteProduct = async (req, res, next) => {
  try {
    const productId = parseInt(req.params.id);
    await prisma.product.delete({ where: { id: productId }});
    res.status(200).json({ message: 'Product deleted' });
  } catch (error) {
    next(error);
  }
};
EOF

echo "Controller files telah dibuat."

# 12. Membuat file-file di folder src/middlewares

## authMiddleware.js
echo "Membuat src/middlewares/authMiddleware.js..."
cat > src/middlewares/authMiddleware.js <<'EOF'
const jwt = require('jsonwebtoken');

const authMiddleware = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader) return res.status(401).json({ error: 'No token provided' });
  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    res.status(401).json({ error: 'Invalid token' });
  }
};

module.exports = authMiddleware;
EOF

## adminMiddleware.js
echo "Membuat src/middlewares/adminMiddleware.js..."
cat > src/middlewares/adminMiddleware.js <<'EOF'
const adminMiddleware = (req, res, next) => {
  if (req.user && req.user.role === 'ADMIN') {
    return next();
  }
  return res.status(403).json({ error: 'Access denied' });
};

module.exports = adminMiddleware;
EOF

## errorHandler.js
echo "Membuat src/middlewares/errorHandler.js..."
cat > src/middlewares/errorHandler.js <<'EOF'
const errorHandler = (err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: err.message });
};

module.exports = errorHandler;
EOF

echo "Middleware files telah dibuat."

# 13. Membuat file-file di folder src/routes

## authRoutes.js
echo "Membuat src/routes/authRoutes.js..."
cat > src/routes/authRoutes.js <<'EOF'
const express = require('express');
const router = express.Router();
const { registerUser, loginUser } = require('../controllers/authController');

router.post('/register', registerUser);
router.post('/login', loginUser);

module.exports = router;
EOF

## productRoutes.js
echo "Membuat src/routes/productRoutes.js..."
cat > src/routes/productRoutes.js <<'EOF'
const express = require('express');
const router = express.Router();
const { getProducts, getProductById } = require('../controllers/productController');

router.get('/', getProducts);
router.get('/:id', getProductById);

module.exports = router;
EOF

## reviewRoutes.js
echo "Membuat src/routes/reviewRoutes.js..."
cat > src/routes/reviewRoutes.js <<'EOF'
const express = require('express');
const router = express.Router();
const { createReview, getReviewsByProduct } = require('../controllers/reviewController');

router.post('/', createReview);
router.get('/product/:id', getReviewsByProduct);

module.exports = router;
EOF

## userRoutes.js
echo "Membuat src/routes/userRoutes.js..."
cat > src/routes/userRoutes.js <<'EOF'
const express = require('express');
const router = express.Router();
const { getUserProfile, updateUserProfile } = require('../controllers/userController');
const authMiddleware = require('../middlewares/authMiddleware');

router.get('/profile', authMiddleware, getUserProfile);
router.put('/profile', authMiddleware, updateUserProfile);

module.exports = router;
EOF

## wishlistRoutes.js
echo "Membuat src/routes/wishlistRoutes.js..."
cat > src/routes/wishlistRoutes.js <<'EOF'
const express = require('express');
const router = express.Router();
const authMiddleware = require('../middlewares/authMiddleware');
const { addToWishlist, getWishlist, removeFromWishlist } = require('../controllers/wishlistController');

router.post('/', authMiddleware, addToWishlist);
router.get('/', authMiddleware, getWishlist);
router.delete('/:id', authMiddleware, removeFromWishlist);

module.exports = router;
EOF

## adminRoutes.js
echo "Membuat src/routes/adminRoutes.js..."
cat > src/routes/adminRoutes.js <<'EOF'
const express = require('express');
const router = express.Router();
const authMiddleware = require('../middlewares/authMiddleware');
const adminMiddleware = require('../middlewares/adminMiddleware');
const { getDashboardStats, deleteProduct } = require('../controllers/adminController');

router.use(authMiddleware, adminMiddleware);

router.get('/dashboard', getDashboardStats);
router.delete('/product/:id', deleteProduct);

module.exports = router;
EOF

echo "Route files telah dibuat."

# 14. Membuat file-file di folder src/utils

## generateToken.js
echo "Membuat src/utils/generateToken.js..."
cat > src/utils/generateToken.js <<'EOF'
const jwt = require('jsonwebtoken');

const generateToken = (payload) => {
  return jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '1d' });
};

module.exports = generateToken;
EOF

## emailService.js
echo "Membuat src/utils/emailService.js..."
cat > src/utils/emailService.js <<'EOF'
const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: 'smtp.example.com',
  port: 587,
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

const sendEmail = async (to, subject, html) => {
  const mailOptions = {
    from: process.env.EMAIL_USER,
    to,
    subject,
    html,
  };
  await transporter.sendMail(mailOptions);
};

module.exports = { sendEmail };
EOF

echo "Utility files telah dibuat."

# 15. Membuat file-file contoh testing di folder __tests__

## __tests__/controllers/authController.test.js
echo "Membuat __tests__/controllers/authController.test.js..."
cat > __tests__/controllers/authController.test.js <<'EOF'
const request = require('supertest');
const express = require('express');
const dotenv = require('dotenv');
dotenv.config();

const app = express();
app.use(express.json());
const authRoutes = require('../../src/routes/authRoutes');
app.use('/api/auth', authRoutes);

describe('Auth Controller', () => {
  it('should register a new user', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({ name: 'Test User', email: 'test@example.com', password: 'password' });
    expect(res.statusCode).toEqual(201);
    expect(res.body).toHaveProperty('message', 'User registered successfully');
  });

  it('should login an existing user', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: 'test@example.com', password: 'password' });
    expect(res.statusCode).toEqual(200);
    expect(res.body).toHaveProperty('token');
  });
});
EOF

## __tests__/controllers/productController.test.js
echo "Membuat __tests__/controllers/productController.test.js..."
cat > __tests__/controllers/productController.test.js <<'EOF'
const request = require('supertest');
const express = require('express');
const dotenv = require('dotenv');
dotenv.config();

const app = express();
app.use(express.json());
const productRoutes = require('../../src/routes/productRoutes');
app.use('/api/products', productRoutes);

describe('Product Controller', () => {
  it('should get list of products', async () => {
    const res = await request(app).get('/api/products');
    expect(res.statusCode).toEqual(200);
    expect(Array.isArray(res.body)).toBeTruthy();
  });
});
EOF

## __tests__/controllers/reviewController.test.js
echo "Membuat __tests__/controllers/reviewController.test.js..."
cat > __tests__/controllers/reviewController.test.js <<'EOF'
const request = require('supertest');
const express = require('express');
const dotenv = require('dotenv');
dotenv.config();

const app = express();
app.use(express.json());
const reviewRoutes = require('../../src/routes/reviewRoutes');
app.use('/api/reviews', reviewRoutes);

describe('Review Controller', () => {
  it('should create a review', async () => {
    const res = await request(app)
      .post('/api/reviews')
      .send({ rating: 5, comment: 'Great product!', productId: 1, userId: 1 });
    expect(res.statusCode).toEqual(201);
    expect(res.body).toHaveProperty('message', 'Review added');
  });
});
EOF

## __tests__/controllers/userController.test.js
echo "Membuat __tests__/controllers/userController.test.js..."
cat > __tests__/controllers/userController.test.js <<'EOF'
const request = require('supertest');
const express = require('express');
const dotenv = require('dotenv');
dotenv.config();

const app = express();
app.use(express.json());
const authRoutes = require('../../src/routes/authRoutes');
const userRoutes = require('../../src/routes/userRoutes');
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);

describe('User Controller', () => {
  let token;
  beforeAll(async () => {
    await request(app)
      .post('/api/auth/register')
      .send({ name: 'Profile User', email: 'profile@example.com', password: 'password' });
    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: 'profile@example.com', password: 'password' });
    token = res.body.token;
  });

  it('should get user profile', async () => {
    const res = await request(app)
      .get('/api/users/profile')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toEqual(200);
    expect(res.body).toHaveProperty('email');
  });
});
EOF

## __tests__/controllers/wishlistController.test.js
echo "Membuat __tests__/controllers/wishlistController.test.js..."
cat > __tests__/controllers/wishlistController.test.js <<'EOF'
const request = require('supertest');
const express = require('express');
const dotenv = require('dotenv');
dotenv.config();

const app = express();
app.use(express.json());
const authRoutes = require('../../src/routes/authRoutes');
const wishlistRoutes = require('../../src/routes/wishlistRoutes');
app.use('/api/auth', authRoutes);
app.use('/api/wishlist', wishlistRoutes);

describe('Wishlist Controller', () => {
  let token;
  beforeAll(async () => {
    await request(app)
      .post('/api/auth/register')
      .send({ name: 'Wishlist User', email: 'wishlist@example.com', password: 'password' });
    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: 'wishlist@example.com', password: 'password' });
    token = res.body.token;
  });

  it('should add a product to wishlist', async () => {
    const res = await request(app)
      .post('/api/wishlist')
      .set('Authorization', `Bearer ${token}`)
      .send({ productId: 1 });
    expect(res.statusCode).toEqual(201);
    expect(res.body).toHaveProperty('message', 'Added to wishlist');
  });
});
EOF

## __tests__/controllers/adminController.test.js
echo "Membuat __tests__/controllers/adminController.test.js..."
cat > __tests__/controllers/adminController.test.js <<'EOF'
const request = require('supertest');
const express = require('express');
const dotenv = require('dotenv');
dotenv.config();

const app = express();
app.use(express.json());
const authRoutes = require('../../src/routes/authRoutes');
const adminRoutes = require('../../src/routes/adminRoutes');
app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes);

describe('Admin Controller', () => {
  let token;
  beforeAll(async () => {
    await request(app)
      .post('/api/auth/register')
      .send({ name: 'Admin User', email: 'admin@example.com', password: 'adminpassword' });
    // Ubah role menjadi ADMIN melalui seed atau update langsung (di sini gunakan Prisma)
    const { PrismaClient } = require('@prisma/client');
    const prisma = new PrismaClient();
    await prisma.user.update({ where: { email: 'admin@example.com' }, data: { role: 'ADMIN' }});
    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: 'admin@example.com', password: 'adminpassword' });
    token = res.body.token;
  });

  it('should get dashboard stats', async () => {
    const res = await request(app)
      .get('/api/admin/dashboard')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toEqual(200);
    expect(res.body).toHaveProperty('userCount');
  });
});
EOF

## __tests__/middlewares/authMiddleware.test.js
echo "Membuat __tests__/middlewares/authMiddleware.test.js..."
cat > __tests__/middlewares/authMiddleware.test.js <<'EOF'
const jwt = require('jsonwebtoken');
const authMiddleware = require('../../src/middlewares/authMiddleware');

describe('Auth Middleware', () => {
  it('should call next() if valid token is provided', () => {
    const payload = { id: 1, email: 'test@example.com', role: 'USER' };
    const token = jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '1d' });
    const req = { headers: { authorization: `Bearer ${token}` } };
    const res = {};
    const next = jest.fn();
    authMiddleware(req, res, next);
    expect(next).toHaveBeenCalled();
  });

  it('should return error if no token is provided', () => {
    const req = { headers: {} };
    const res = { status: jest.fn().mockReturnThis(), json: jest.fn() };
    const next = jest.fn();
    authMiddleware(req, res, next);
    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith({ error: 'No token provided' });
  });
});
EOF

## __tests__/utils/generateToken.test.js
echo "Membuat __tests__/utils/generateToken.test.js..."
cat > __tests__/utils/generateToken.test.js <<'EOF'
const generateToken = require('../../src/utils/generateToken');
const jwt = require('jsonwebtoken');

describe('generateToken Utility', () => {
  it('should generate a valid JWT', () => {
    const payload = { id: 1, email: 'test@example.com' };
    const token = generateToken(payload);
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    expect(decoded).toHaveProperty('id', 1);
    expect(decoded).toHaveProperty('email', 'test@example.com');
  });
});
EOF

echo "Semua file test telah dibuat."

# 16. Menambahkan script "test" ke package.json (telah ditambahkan di package.json)
echo "Setup testing lengkap telah selesai!"

echo "=========================================="
echo "Setup backend e-commerce selesai!"
echo "Jalankan perintah berikut:"
echo "1. Untuk migrasi Prisma: npx prisma migrate dev --name init"
echo "2. Untuk seed database: npm run seed"
echo "3. Untuk memulai server (development): npm run dev"
echo "4. Untuk menjalankan test: npm run test"
echo "=========================================="
