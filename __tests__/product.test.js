const request = require('supertest');
const app = require('../server');

describe('🛠️ Product API Tests', () => {
  test('✅ Get All Products', async () => {
    const res = await request(app).get('/api/products');
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBeTruthy();
  });

  test('✅ Get Product by ID', async () => {
    const res = await request(app).get('/api/products/1');
    expect(res.statusCode).toBe(200);
  });
});
