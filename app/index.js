const express = require('express');
const { Pool } = require('pg');
const os = require('os');

const app = express();
const PORT = process.env.PORT || 3000;

// PostgreSQL connection pool
const pool = new Pool({
    host:     process.env.DB_HOST,
    port:     process.env.DB_PORT || 5432,
    database: process.env.DB_NAME,
    user:     process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    ssl:      { rejectUnauthorized: false }
});

// Create table if it doesn't exist
async function initDb() {
    try {
        await pool.query(`
      CREATE TABLE IF NOT EXISTS visits (
        id         SERIAL PRIMARY KEY,
        host       TEXT,
        visited_at TIMESTAMP DEFAULT NOW()
      )
    `);
        console.log('Database initialized');
    } catch (err) {
        if (err.code === '23505' || err.code === '42P07') {
            console.log('Table already exists, continuing...');
        } else {
            throw err;
        }
    }
}

app.get('/', async (req, res) => {
    try {
        // Record this visit
        await pool.query(
            'INSERT INTO visits (host) VALUES ($1)',
            [os.hostname()]
        );

        // Get total visit count
        const result = await pool.query('SELECT COUNT(*) FROM visits');
        const count = parseInt(result.rows[0].count);

        res.json({
            message:     'Hello from the whale!',
            host:        os.hostname(),
            total_visits: count
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Database error', detail: err.message });
    }
});

app.get('/health', (req, res) => res.json({ status: 'ok' }));

app.get('/visits', async (req, res) => {
    try {
        const result = await pool.query(
            'SELECT * FROM visits ORDER BY visited_at DESC LIMIT 20'
        );
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get("/products", async (req, res) => {
    try {
        const result = await pool.query(
            "SELECT id, name, price FROM products ORDER BY id"
        );

        res.json({
            count: result.rows.length,
            products: result.rows
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "DB error" });
    }
});

initDb()
    .then(() => app.listen(PORT, '0.0.0.0', () => {
        console.log(`Server running on port ${PORT}`);
    }))
    .catch(err => {
        console.error('Failed to initialize database:', err);
        process.exit(1);
    });