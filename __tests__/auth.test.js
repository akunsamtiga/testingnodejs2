const request = require('supertest');
const app = require('../server');

describe('🛠️ Auth API Tests', () => {
  test('✅ Register User', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({ name: "User Baru", email: "userbaru@example.com", password: "password123" });

    expect(res.statusCode).toBe(201);
  });

  test('✅ Login User', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: "userbaru@example.com", password: "password123" });

    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty("accessToken");
  });
});
