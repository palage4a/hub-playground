const express = require('express');

const app = express();
app.use(express.json());

let todos = [];
let nextId = 1;

app.get('/todos', (req, res) => {
  res.json(todos);
});

app.get('/todos/:id', (req, res) => {
  const todo = todos.find(t => t.id === parseInt(req.params.id));
  if (!todo) return res.status(404).json({ error: 'Todo not found' });
  res.json(todo);
});

app.post('/todos', (req, res) => {
  const { title } = req.body;
  if (!title || typeof title !== 'string') {
    return res.status(400).json({ error: 'Title is required and must be a string' });
  }
  const todo = { id: nextId++, title, completed: false };
  todos.push(todo);
  res.status(201).json(todo);
});

app.put('/todos/:id', (req, res) => {
  const todo = todos.find(t => t.id === parseInt(req.params.id));
  if (!todo) return res.status(404).json({ error: 'Todo not found' });
  const { title, completed } = req.body;
  if (title !== undefined) {
    if (typeof title !== 'string') return res.status(400).json({ error: 'Title must be a string' });
    todo.title = title;
  }
  if (completed !== undefined) {
    if (typeof completed !== 'boolean') return res.status(400).json({ error: 'Completed must be a boolean' });
    todo.completed = completed;
  }
  res.json(todo);
});

app.delete('/todos/:id', (req, res) => {
  const index = todos.findIndex(t => t.id === parseInt(req.params.id));
  if (index === -1) return res.status(404).json({ error: 'Todo not found' });
  todos.splice(index, 1);
  res.status(204).end();
});

function reset() {
  todos = [];
  nextId = 1;
}

module.exports = { app, reset };
