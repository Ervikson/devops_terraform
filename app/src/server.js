import express from 'express';
import mysql from 'mysql2/promise';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 5,
  queueLimit: 0
});

app.get('/', async (_req, res) => {
  try {
    const [rows] = await pool.query('SELECT NOW() AS server_time');
    res.json({
      message: 'Final project sample app running in Yandex Cloud!',
      dbTime: rows[0]?.server_time ?? null,
      region: process.env.YC_REGION || 'unknown'
    });
  } catch (error) {
    console.error('DB query failed', error);
    res.status(500).json({ error: 'Database unavailable', details: error.message });
  }
});

app.listen(port, () => {
  /* eslint-disable no-console */
  console.log(`App listening on port ${port}`);
});
