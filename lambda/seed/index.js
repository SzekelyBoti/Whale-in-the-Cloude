const { Client } = require('pg');

exports.handler = async (event) => {
    const client = new Client({
        host:     process.env.DB_HOST,
        port:     process.env.DB_PORT || 5432,
        database: process.env.DB_NAME,
        user:     process.env.DB_USER,
        password: process.env.DB_PASSWORD,
        ssl:      { rejectUnauthorized: false }
    });

    try {
        await client.connect();
        console.log('Connected to database');

        await client.query(`
      CREATE TABLE IF NOT EXISTS products (
        id          SERIAL PRIMARY KEY,
        name        TEXT NOT NULL,
        description TEXT,
        price       NUMERIC(10,2),
        created_at  TIMESTAMP DEFAULT NOW()
      )
    `);

        await client.query('TRUNCATE TABLE products RESTART IDENTITY');

        const products = [
            ['Blue Whale Plushie',    'A giant soft toy',          29.99],
            ['Humpback Hoodie',       'Warm whale-themed hoodie',  49.99],
            ['Orca Coffee Mug',       'Start your day right',       9.99],
            ['Narwhal Night Light',   'Glows in the dark',         19.99],
            ['Beluga Bean Bag',       'Extra comfy seating',       89.99],
            ['Dolphin Desk Lamp',     'Brighten your workspace',   34.99],
            ['Sperm Whale Backpack',  'Holds all your stuff',      59.99],
            ['Manatee Mouse Pad',     'Smooth sailing for clicks',  7.99],
        ];

        for (const [name, description, price] of products) {
            await client.query(
                'INSERT INTO products (name, description, price) VALUES ($1, $2, $3)',
                [name, description, price]
            );
        }

        const result = await client.query('SELECT COUNT(*) FROM products');
        const count = parseInt(result.rows[0].count);

        console.log(`Seeded ${count} products`);
        return {
            statusCode: 200,
            body: JSON.stringify({ message: `Successfully seeded ${count} products` })
        };

    } catch (err) {
        console.error('Error:', err);
        return {
            statusCode: 500,
            body: JSON.stringify({ error: err.message })
        };
    } finally {
        await client.end();
    }
};