const mysql = require('mysql2/promise');
require('dotenv').config();

async function createDatabase() {
  let connection;
  try {
    connection = await mysql.createConnection({
      host: process.env.DB_HOST || 'localhost',
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || '',
    });

    await connection.execute(`CREATE DATABASE IF NOT EXISTS ${process.env.DB_NAME || 'ecommerce_db'}`);
    console.log(`✓ Database '${process.env.DB_NAME || 'ecommerce_db'}' created successfully!`);
    
  } catch (error) {
    console.error('Error creating database:', error.message);
    process.exit(1);
  } finally {
    if (connection) await connection.end();
  }
}

createDatabase();
