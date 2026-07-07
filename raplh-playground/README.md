# raplh-playground

An in-memory Todos REST API built with Express 5. Created as a learning/demo project.

## API

| Method   | Endpoint       | Description                |
|----------|----------------|----------------------------|
| `GET`    | `/todos`       | List all todos             |
| `GET`    | `/todos/:id`   | Get a todo by ID           |
| `POST`   | `/todos`       | Create a todo (body: `{ title }`) |
| `PUT`    | `/todos/:id`   | Update a todo (body: `{ title?, completed? }`) |
| `DELETE` | `/todos/:id`   | Delete a todo              |

## Usage

```js
const { app } = require('./src/index');
// Mount app in your own server or test with supertest
```

The app does not call `app.listen()` — it exports `{ app, reset }` for testing.

## Tests

```bash
npm test
```

Uses Mocha + Supertest. The `reset()` function clears state between tests.
