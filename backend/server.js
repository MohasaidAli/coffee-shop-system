const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const db = require('./db');
const authRoutes = require('./routes/auth');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(bodyParser.json());
app.use('/uploads', express.static('uploads')); // Serve images

// Routes
app.use('/api/auth', authRoutes);


app.get('/', (req, res) => {
    res.send('Coffee Shop API is running');
});

app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});
