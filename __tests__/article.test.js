const request = require('supertest');
const app = require('../server');

describe('🛠️ Article API Tests', () => {
  test('✅ Get All Articles', async () => {
    const res = await request(app).get('/api/articles');
    expect(res.statusCode).toBe(200);
  });

  test('✅ Get Article by ID', async () => {
    const res = await request(app).get('/api/articles/1');
    expect(res.statusCode).toBe(200);
  });
});
