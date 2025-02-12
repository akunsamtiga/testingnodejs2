const request = require('supertest');
const app = require('../server');

describe('🛠️ Review API Tests', () => {
  test('✅ Get Reviews by Product ID', async () => {
    const res = await request(app).get('/api/reviews/product/1');
    expect(res.statusCode).toBe(200);
  });
});
