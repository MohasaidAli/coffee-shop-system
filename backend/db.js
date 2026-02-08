const mysql = require('mysql2');
const dotenv = require('dotenv');
dotenv.config();
const db = mysql.createConnection({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  multipleStatements: true
});

db.connect((err) => {
  if (err) {
    console.error('Error connecting to MySQL:', err);
    // Create database if it doesn't exist
    if (err.code === 'ER_BAD_DB_ERROR') {
      const adminDb = mysql.createConnection({
        host: process.env.DB_HOST,
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD
      });
      adminDb.query('CREATE DATABASE ' + process.env.DB_NAME, (err) => {
        if (err) console.log('Database created');
        else console.log('Database ' + process.env.DB_NAME + ' created');
        adminDb.end();
        // Reconnect logic could be added here but for simplicity we assume next run works
      });
    }
    return;
  }
  console.log('Connected to MySQL database');
  initializeTables();
});

function initializeTables() {
  const usersTable = `
    CREATE TABLE IF NOT EXISTS users (
      id INT AUTO_INCREMENT PRIMARY KEY,
      name VARCHAR(100),
      email VARCHAR(100) UNIQUE,
      password VARCHAR(255),
      role ENUM('admin', 'customer') DEFAULT 'customer',
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `;

  db.query(usersTable, (err) => { if (err) console.error(err); });
  
}


module.exports = db;
