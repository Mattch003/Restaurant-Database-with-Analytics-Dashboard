-- =========================
-- BUSINESS QUERIES
-- =========================

-- Customer Order History
SELECT
    c.name AS customer_name,
    o.order_id,
    o.order_date,
    o.total_amount,
    o.status
FROM Orders o
JOIN Customer c ON o.customer_id = c.customer_id
ORDER BY o.order_date;

-- Total Revenue Per Restaurant (includes restaurants with zero orders, excludes cancelled)
SELECT
    r.restaurant_name,
    COALESCE(SUM(CASE WHEN o.status <> 'cancelled' THEN o.total_amount END), 0) AS total_revenue
FROM Restaurant r
LEFT JOIN Orders o ON r.restaurant_id = o.restaurant_id
GROUP BY r.restaurant_id, r.restaurant_name
ORDER BY total_revenue DESC;

-- Top 10 Best Sellers
SELECT
    mi.name,
    SUM(oi.quantity) AS total_sold
FROM OrderItem oi
JOIN MenuItem mi ON oi.menu_item_id = mi.menu_item_id
GROUP BY mi.menu_item_id, mi.name
ORDER BY total_sold DESC
LIMIT 10;

-- Average Customer Rating
SELECT AVG(rating) AS avg_rating
FROM Feedback;

-- Rating Distribution (1-5)
SELECT
    rating,
    COUNT(*) AS feedback_count
FROM Feedback
GROUP BY rating
ORDER BY rating;

-- Payment Method Breakdown
SELECT
    payment_type,
    COUNT(*) AS payment_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Payment), 2) AS percentage
FROM Payment
GROUP BY payment_type
ORDER BY payment_count DESC;

-- Loyalty Leaderboard (Top 10) — current balance from transaction ledger
SELECT
    c.name,
    COALESCE(SUM(lt.points_delta), 0) AS reward_points
FROM Customer c
JOIN LoyaltyProgram lp ON lp.customer_id = c.customer_id
LEFT JOIN LoyaltyTransaction lt ON lt.customer_id = c.customer_id
GROUP BY c.customer_id, c.name
ORDER BY reward_points DESC
LIMIT 10;

-- Active Promotions Today (with discount info)
SELECT
    p.name AS promotion_name,
    mi.name AS menu_item,
    p.discount_type,
    p.discount_value,
    p.start_date,
    p.end_date
FROM Promotions p
JOIN MenuItem mi ON p.menu_item_id = mi.menu_item_id
WHERE CURDATE() BETWEEN p.start_date AND p.end_date
ORDER BY p.start_date;

-- Restaurant Open Now (joins schedule against current weekday/time)
SELECT
    r.restaurant_name,
    rh.open_time,
    rh.close_time
FROM Restaurant r
JOIN RestaurantHours rh ON rh.restaurant_id = r.restaurant_id
WHERE rh.day_of_week = WEEKDAY(CURDATE())  -- WEEKDAY: 0=Mon..6=Sun
  AND CURTIME() BETWEEN rh.open_time AND rh.close_time
ORDER BY r.restaurant_name;

-- Orders with Full Details
SELECT
    o.order_id,
    c.name AS customer_name,
    r.restaurant_name,
    mi.name AS item,
    oi.quantity,
    oi.price
FROM Orders o
JOIN Customer c ON o.customer_id = c.customer_id
JOIN Restaurant r ON o.restaurant_id = r.restaurant_id
JOIN OrderItem oi ON o.order_id = oi.order_id
JOIN MenuItem mi ON oi.menu_item_id = mi.menu_item_id
ORDER BY o.order_id, oi.order_item_id;

-- Order Total Drift Check (catches any order whose stored total != line-item sum)
SELECT
    o.order_id,
    o.total_amount AS stored_total,
    ROUND(SUM(oi.quantity * oi.price), 2) AS computed_total
FROM Orders o
JOIN OrderItem oi ON oi.order_id = o.order_id
GROUP BY o.order_id, o.total_amount
HAVING stored_total <> computed_total;
