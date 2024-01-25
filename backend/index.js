const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

// Connect to MongoDB
mongoose.connect('mongodb+srv://nokia_labs:nokia_labs@cluster0.5iqfe.mongodb.net/todo2?retryWrites=true&w=majority', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});
const db = mongoose.connection;

// Define the item schema
const itemSchema = new mongoose.Schema({
  item: String,
  value: String,
});

// Define the item model
const Item = mongoose.model('Item', itemSchema, 'items');

// Create the Express app
const app = express();

// Middleware to parse JSON request bodies
app.use(express.json());

// Enable CORS for all routes
app.use(cors());

// Route to add a new item
app.post('/addItem', async (req, res) => {
  const { item } = req.body;
  try {
    const newItem = new Item({ item });
    await newItem.save();
    res.status(201).json(newItem);
  } catch (error) {
    res.status(500).json({ message: 'Error adding item' });
  }
});

// Route to get all items
app.get('/getItems', async (req, res) => {
  try {
    const items = await Item.find();
    res.json(items);
  } catch (error) {
    res.status(500).json({ message: 'Error retrieving items' });
  }
});

// Start the server
app.listen(3000, () => {
  console.log('Server started on port 3000');
});