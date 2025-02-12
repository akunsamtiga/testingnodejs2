const request = require('supertest');
const app = require('../server');

describe('🛠️ Wishlist API Tests', () => {
  let accessToken = "";

  beforeAll(async () => {
    const loginRes = await request(app)
      .post('/api/auth/login')
      .send({ email: "userbaru@example.com", password: "password123" });

    accessToken = loginRes.body.accessToken;
  });

  test('✅ Get Wishlist', async () => {
    const res = await request(app)
      .get('/api/wishlist')
      .set('Authorization', `Bearer ${accessToken}`);

    expect(res.statusCode).toBe(200);
  });
});
