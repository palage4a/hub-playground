const request = require('supertest');
const { app, reset } = require('../src/index');
const assert = require('assert');

describe('Todos API', () => {
  beforeEach(() => {
    reset();
  });

  it('POST /todos - should create a todo', async () => {
    const res = await request(app)
      .post('/todos')
      .send({ title: 'Buy milk' });
    assert.strictEqual(res.status, 201);
    assert.strictEqual(res.body.title, 'Buy milk');
    assert.strictEqual(res.body.completed, false);
    assert.ok(res.body.id);
  });

  it('POST /todos - should reject request without title', async () => {
    const res = await request(app)
      .post('/todos')
      .send({});
    assert.strictEqual(res.status, 400);
  });

  it('GET /todos - should list all todos', async () => {
    await request(app).post('/todos').send({ title: 'Task 1' });
    const res = await request(app).get('/todos');
    assert.strictEqual(res.status, 200);
    assert.strictEqual(Array.isArray(res.body), true);
    assert.strictEqual(res.body.length, 1);
  });

  it('GET /todos/:id - should return a specific todo', async () => {
    const createRes = await request(app)
      .post('/todos')
      .send({ title: 'Find me' });
    const res = await request(app).get(`/todos/${createRes.body.id}`);
    assert.strictEqual(res.status, 200);
    assert.strictEqual(res.body.title, 'Find me');
  });

  it('GET /todos/:id - should return 404 for unknown id', async () => {
    const res = await request(app).get('/todos/999');
    assert.strictEqual(res.status, 404);
  });

  it('PUT /todos/:id - should update a todo', async () => {
    const createRes = await request(app)
      .post('/todos')
      .send({ title: 'Update me' });
    const res = await request(app)
      .put(`/todos/${createRes.body.id}`)
      .send({ title: 'Updated', completed: true });
    assert.strictEqual(res.status, 200);
    assert.strictEqual(res.body.title, 'Updated');
    assert.strictEqual(res.body.completed, true);
  });

  it('PUT /todos/:id - should return 404 for unknown id', async () => {
    const res = await request(app)
      .put('/todos/999')
      .send({ title: 'Nope' });
    assert.strictEqual(res.status, 404);
  });

  it('DELETE /todos/:id - should delete a todo', async () => {
    const createRes = await request(app)
      .post('/todos')
      .send({ title: 'Delete me' });
    const res = await request(app).delete(`/todos/${createRes.body.id}`);
    assert.strictEqual(res.status, 204);
    const getRes = await request(app).get(`/todos/${createRes.body.id}`);
    assert.strictEqual(getRes.status, 404);
  });

  it('DELETE /todos/:id - should return 404 for unknown id', async () => {
    const res = await request(app).delete('/todos/999');
    assert.strictEqual(res.status, 404);
  });
});
