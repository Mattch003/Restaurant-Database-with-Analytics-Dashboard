import express from 'express';
import mysql from 'mysql2/promise';
import 'dotenv/config';

const app = express();
const port = process.env.PORT || 3000;

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT) || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'RestaurantOrderingSystemDB',
  waitForConnections: true,
  connectionLimit: 10,
});

app.use(express.static('public'));
app.use(express.json());

const wrap = (handler) => async (req, res) => {
  try {
    await handler(req, res);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
};

// Dashboard stats
app.get('/api/stats', wrap(async (req, res) => {
  const [[stats]] = await pool.query(`
    SELECT
      (SELECT COUNT(*) FROM Orders) AS order_count,
      (SELECT COALESCE(SUM(total_amount), 0) FROM Orders) AS total_revenue,
      (SELECT ROUND(AVG(rating), 2) FROM Feedback) AS avg_rating,
      (SELECT COUNT(*) FROM Customer) AS customer_count,
      (SELECT COUNT(*) FROM Restaurant) AS restaurant_count,
      (SELECT COUNT(*) FROM MenuItem) AS menu_item_count
  `);
  res.json(stats);
}));

// Restaurants with revenue summary
app.get('/api/restaurants', wrap(async (req, res) => {
  const [rows] = await pool.query(`
    SELECT
      r.restaurant_id,
      r.restaurant_name,
      r.address,
      r.phone_number,
      COALESCE(SUM(CASE WHEN o.status <> 'cancelled' THEN o.total_amount END), 0) AS total_revenue,
      COUNT(DISTINCT o.order_id) AS order_count
    FROM Restaurant r
    LEFT JOIN Orders o ON r.restaurant_id = o.restaurant_id
    GROUP BY r.restaurant_id, r.restaurant_name, r.address, r.phone_number
    ORDER BY total_revenue DESC
  `);
  res.json(rows);
}));

// Hours for a restaurant (0=Sun .. 6=Sat)
app.get('/api/restaurants/:id/hours', wrap(async (req, res) => {
  const [rows] = await pool.query(`
    SELECT day_of_week, open_time, close_time
    FROM RestaurantHours
    WHERE restaurant_id = ?
    ORDER BY day_of_week
  `, [req.params.id]);
  res.json(rows);
}));

// Menu for a specific restaurant
app.get('/api/restaurants/:id/menu', wrap(async (req, res) => {
  const [rows] = await pool.query(`
    SELECT
      mi.menu_item_id,
      mi.name,
      mi.price,
      mi.description,
      cat.name AS category_name,
      m.menu_type
    FROM MenuItem mi
    JOIN Menu m ON mi.menu_id = m.menu_id
    JOIN Category cat ON mi.category_id = cat.category_id
    WHERE m.restaurant_id = ?
    ORDER BY m.menu_type, cat.name, mi.name
  `, [req.params.id]);
  res.json(rows);
}));

// Recent orders
app.get('/api/orders', wrap(async (req, res) => {
  const [rows] = await pool.query(`
    SELECT
      o.order_id,
      o.order_date,
      o.total_amount,
      o.status,
      c.name AS customer_name,
      r.restaurant_name
    FROM Orders o
    JOIN Customer c ON o.customer_id = c.customer_id
    JOIN Restaurant r ON o.restaurant_id = r.restaurant_id
    ORDER BY o.order_date DESC, o.order_id DESC
    LIMIT 50
  `);
  res.json(rows);
}));

// Line items for a single order
app.get('/api/orders/:id/items', wrap(async (req, res) => {
  const [rows] = await pool.query(`
    SELECT
      oi.order_item_id,
      oi.quantity,
      oi.price,
      mi.name AS menu_item,
      (oi.quantity * oi.price) AS line_total
    FROM OrderItem oi
    JOIN MenuItem mi ON oi.menu_item_id = mi.menu_item_id
    WHERE oi.order_id = ?
    ORDER BY oi.order_item_id
  `, [req.params.id]);
  res.json(rows);
}));

// Orders grouped by date (for line chart)
app.get('/api/stats/orders-over-time', wrap(async (req, res) => {
  const [rows] = await pool.query(`
    SELECT
      order_date,
      COUNT(*) AS order_count,
      COALESCE(SUM(CASE WHEN status <> 'cancelled' THEN total_amount END), 0) AS revenue
    FROM Orders
    GROUP BY order_date
    ORDER BY order_date
  `);
  res.json(rows);
}));

// Top 10 best sellers
app.get('/api/best-sellers', wrap(async (req, res) => {
  const [rows] = await pool.query(`
    SELECT
      mi.name,
      mi.price,
      SUM(oi.quantity) AS total_sold
    FROM OrderItem oi
    JOIN MenuItem mi ON oi.menu_item_id = mi.menu_item_id
    GROUP BY mi.menu_item_id, mi.name, mi.price
    ORDER BY total_sold DESC
    LIMIT 10
  `);
  res.json(rows);
}));

// All promotions (flags active ones based on today)
app.get('/api/promotions', wrap(async (req, res) => {
  const [rows] = await pool.query(`
    SELECT
      p.promotion_id,
      p.name AS promotion_name,
      p.start_date,
      p.end_date,
      p.discount_type,
      p.discount_value,
      mi.name AS menu_item,
      CASE WHEN CURDATE() BETWEEN p.start_date AND p.end_date THEN 1 ELSE 0 END AS is_active
    FROM Promotions p
    JOIN MenuItem mi ON p.menu_item_id = mi.menu_item_id
    ORDER BY is_active DESC, p.start_date DESC
  `);
  res.json(rows);
}));

// Loyalty leaderboard (current balance from transaction ledger)
app.get('/api/loyalty', wrap(async (req, res) => {
  const [rows] = await pool.query(`
    SELECT
      c.name,
      COALESCE(SUM(lt.points_delta), 0) AS reward_points
    FROM Customer c
    JOIN LoyaltyProgram lp ON lp.customer_id = c.customer_id
    LEFT JOIN LoyaltyTransaction lt ON lt.customer_id = c.customer_id
    GROUP BY c.customer_id, c.name
    ORDER BY reward_points DESC
    LIMIT 10
  `);
  res.json(rows);
}));

app.listen(port, () => {
  console.log(`Restaurant dashboard running at http://localhost:${port}`);
});
