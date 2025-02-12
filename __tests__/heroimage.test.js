const request = require('supertest');
const app = require('../server');

describe('🛠️ Hero Image API Tests', () => {
  test('✅ Get All Hero Images', async () => {
    const res = await request(app).get('/api/hero-images');
    expect(res.statusCode).toBe(200);
  });
});
