-- Top 2 Customers by Spending
WITH CustomerSpending AS (
    SELECT
        c.customer_id,
        c.name,
        SUM(o.total_amount) AS total_spent
    FROM Customer c
    JOIN Orders o ON c.customer_id = o.customer_id
    WHERE o.status <> 'cancelled'
    GROUP BY c.customer_id, c.name
),
RankedSpending AS (
    SELECT
        cs.*,
        RANK() OVER (ORDER BY total_spent DESC) AS ranking
    FROM CustomerSpending cs
)
SELECT customer_id, name, total_spent, ranking
FROM RankedSpending
WHERE ranking <= 2;

-- Restaurants Performing Above Average Revenue
WITH RestaurantRevenue AS (
    SELECT
        restaurant_id,
        SUM(total_amount) AS revenue
    FROM Orders
    WHERE status <> 'cancelled'
    GROUP BY restaurant_id
)
SELECT
    r.restaurant_name,
    rr.revenue
FROM RestaurantRevenue rr
JOIN Restaurant r ON r.restaurant_id = rr.restaurant_id
WHERE rr.revenue > (SELECT AVG(revenue) FROM RestaurantRevenue)
ORDER BY rr.revenue DESC;

-- Most Popular Item per Restaurant
WITH ItemSales AS (
    SELECT
        r.restaurant_id,
        r.restaurant_name,
        mi.menu_item_id,
        mi.name AS item_name,
        SUM(oi.quantity) AS total_sold
    FROM Orders o
    JOIN Restaurant r ON o.restaurant_id = r.restaurant_id
    JOIN OrderItem oi ON o.order_id = oi.order_id
    JOIN MenuItem mi ON oi.menu_item_id = mi.menu_item_id
    GROUP BY r.restaurant_id, r.restaurant_name, mi.menu_item_id, mi.name
),
RankedItems AS (
    SELECT
        ItemSales.*,
        RANK() OVER (PARTITION BY restaurant_id ORDER BY total_sold DESC) AS rnk
    FROM ItemSales
)
SELECT restaurant_name, item_name, total_sold
FROM RankedItems
WHERE rnk = 1
ORDER BY restaurant_name;

-- Revenue Contribution Percentage per Customer
WITH CustomerTotals AS (
    SELECT
        c.customer_id,
        c.name,
        SUM(o.total_amount) AS total_spent,
        SUM(SUM(o.total_amount)) OVER () AS grand_total
    FROM Customer c
    JOIN Orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.name
)
SELECT
    name,
    total_spent,
    ROUND(total_spent / grand_total * 100, 2) AS percentage_contribution
FROM CustomerTotals
ORDER BY percentage_contribution DESC;

-- Customer Retention
WITH CustomerOrders AS (
    SELECT
        customer_id,
        COUNT(order_id) AS order_count
    FROM Orders
    GROUP BY customer_id
)
SELECT
    SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) AS repeat_customers,
    SUM(CASE WHEN order_count = 1 THEN 1 ELSE 0 END) AS one_time_customers,
    ROUND(
        SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) / COUNT(*) * 100,
        2
    ) AS retention_rate_pct
FROM CustomerOrders;

-- Running Total Revenue Per Restaurant
SELECT
    r.restaurant_name,
    o.order_date,
    o.total_amount AS order_amount,
    SUM(o.total_amount) OVER (
        PARTITION BY r.restaurant_id
        ORDER BY o.order_date, o.order_id
    ) AS running_revenue
FROM Orders o
JOIN Restaurant r ON o.restaurant_id = r.restaurant_id
ORDER BY r.restaurant_name, o.order_date, o.order_id;

-- Menu Items Never Ordered
SELECT
    r.restaurant_name,
    mi.name AS item_name,
    mi.price
FROM MenuItem mi
JOIN Menu m ON mi.menu_id = m.menu_id
JOIN Restaurant r ON m.restaurant_id = r.restaurant_id
LEFT JOIN OrderItem oi ON mi.menu_item_id = oi.menu_item_id
WHERE oi.order_item_id IS NULL
ORDER BY r.restaurant_name, mi.name;

-- Worst-Rated Menu Items (caveat: each feedback rating is attributed to every item in that order)
WITH ItemRatings AS (
    SELECT
        mi.menu_item_id,
        mi.name AS item_name,
        r.restaurant_name,
        AVG(f.rating) AS avg_rating,
        COUNT(f.feedback_id) AS review_count
    FROM MenuItem mi
    JOIN OrderItem oi ON mi.menu_item_id = oi.menu_item_id
    JOIN Orders o ON oi.order_id = o.order_id
    JOIN Restaurant r ON o.restaurant_id = r.restaurant_id
    JOIN Feedback f ON o.order_id = f.order_id
    GROUP BY mi.menu_item_id, mi.name, r.restaurant_name
)
SELECT
    restaurant_name,
    item_name,
    ROUND(avg_rating, 2) AS avg_rating,
    review_count
FROM ItemRatings
ORDER BY avg_rating ASC, review_count DESC
LIMIT 10;

-- Monthly Revenue Trend per Restaurant
SELECT
    DATE_FORMAT(o.order_date, '%Y-%m') AS month,
    r.restaurant_name,
    SUM(o.total_amount) AS monthly_revenue,
    COUNT(o.order_id) AS order_count
FROM Orders o
JOIN Restaurant r ON o.restaurant_id = r.restaurant_id
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m'), r.restaurant_id, r.restaurant_name
ORDER BY month, r.restaurant_name;

-- Employee Hours Worked
SELECT
    e.name,
    r.restaurant_name,
    e.position,
    COUNT(s.shift_id) AS shifts_worked,
    ROUND(SUM(TIMESTAMPDIFF(MINUTE, s.start_time, s.end_time)) / 60.0, 2) AS hours_worked
FROM Employee e
JOIN Restaurant r ON e.restaurant_id = r.restaurant_id
LEFT JOIN Shift s ON e.employee_id = s.employee_id
GROUP BY e.employee_id, e.name, r.restaurant_name, e.position
ORDER BY hours_worked DESC;

-- Loyalty Points Activity (per customer earn/redeem breakdown)
SELECT
    c.name,
    SUM(CASE WHEN lt.points_delta > 0 THEN lt.points_delta ELSE 0 END) AS points_earned,
    SUM(CASE WHEN lt.points_delta < 0 THEN -lt.points_delta ELSE 0 END) AS points_redeemed,
    SUM(lt.points_delta) AS current_balance
FROM Customer c
JOIN LoyaltyProgram lp ON lp.customer_id = c.customer_id
LEFT JOIN LoyaltyTransaction lt ON lt.customer_id = c.customer_id
GROUP BY c.customer_id, c.name
ORDER BY current_balance DESC;

-- Recipe Cost Estimate (cheapest supplier per ingredient × recipe quantity)
WITH CheapestSupplier AS (
    SELECT
        ingredient_id,
        MIN(price_per_unit) AS unit_cost
    FROM SupplierIngredient
    WHERE price_per_unit IS NOT NULL
    GROUP BY ingredient_id
)
SELECT
    mi.name AS menu_item,
    mi.price AS sale_price,
    ROUND(SUM(mii.quantity * cs.unit_cost), 2) AS recipe_cost,
    ROUND(mi.price - SUM(mii.quantity * cs.unit_cost), 2) AS estimated_margin
FROM MenuItem mi
JOIN MenuItemIngredient mii ON mii.menu_item_id = mi.menu_item_id
JOIN CheapestSupplier cs ON cs.ingredient_id = mii.ingredient_id
GROUP BY mi.menu_item_id, mi.name, mi.price
ORDER BY estimated_margin ASC;

-- Reservation No-Show Rate per Restaurant
SELECT
    r.restaurant_name,
    COUNT(*) AS total_reservations,
    SUM(CASE WHEN res.status = 'no_show' THEN 1 ELSE 0 END) AS no_shows,
    ROUND(
        SUM(CASE WHEN res.status = 'no_show' THEN 1 ELSE 0 END) / COUNT(*) * 100,
        2
    ) AS no_show_rate_pct
FROM Reservation res
JOIN Restaurant r ON res.restaurant_id = r.restaurant_id
GROUP BY r.restaurant_id, r.restaurant_name
ORDER BY no_show_rate_pct DESC;

-- Delivery Punctuality (avg minutes late vs scheduled)
SELECT
    e.name AS driver,
    COUNT(d.delivery_id) AS deliveries,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, d.scheduled_time, d.actual_delivery_time)), 1) AS avg_minutes_late
FROM Delivery d
JOIN Employee e ON d.employee_id = e.employee_id
WHERE d.actual_delivery_time IS NOT NULL
GROUP BY e.employee_id, e.name
ORDER BY avg_minutes_late;
