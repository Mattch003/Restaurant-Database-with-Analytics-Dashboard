const content = document.getElementById('content');
const tabs = document.querySelectorAll('.tab');
const chartInstances = [];

function destroyCharts() {
  while (chartInstances.length) chartInstances.pop().destroy();
}

const views = {
  dashboard: renderDashboard,
  restaurants: renderRestaurants,
  orders: renderOrders,
  'best-sellers': renderBestSellers,
  promotions: renderPromotions,
  loyalty: renderLoyalty,
};

tabs.forEach((tab) => {
  tab.addEventListener('click', () => {
    tabs.forEach((t) => t.classList.remove('active'));
    tab.classList.add('active');
    const view = tab.dataset.view;
    destroyCharts();
    views[view]();
  });
});

async function fetchJSON(url) {
  const res = await fetch(url);
  if (!res.ok) {
    const body = await res.json().catch(() => ({ error: res.statusText }));
    throw new Error(body.error || `Request failed: ${res.status}`);
  }
  return res.json();
}

function showLoading() {
  content.innerHTML = '<p class="loading">Loading...</p>';
}

function showError(err) {
  content.innerHTML = `<div class="error"><strong>Error:</strong> ${escapeHtml(err.message)}<br><small>Is the MySQL server running and are your .env credentials correct?</small></div>`;
}

function escapeHtml(str) {
  return String(str ?? '').replace(/[&<>"']/g, (c) => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  }[c]));
}

function fmtMoney(n) {
  return `$${Number(n).toFixed(2)}`;
}

function fmtDate(d) {
  if (!d) return '';
  return new Date(d).toLocaleDateString();
}

// ---------------- VIEWS ----------------

async function renderDashboard() {
  showLoading();
  try {
    const [s, restaurants, timeline] = await Promise.all([
      fetchJSON('/api/stats'),
      fetchJSON('/api/restaurants'),
      fetchJSON('/api/stats/orders-over-time'),
    ]);
    content.innerHTML = `
      <h2>Overview</h2>
      <div class="stats-grid">
        <div class="stat-card">
          <div class="stat-label">Total Revenue</div>
          <div class="stat-value money">${fmtMoney(s.total_revenue)}</div>
        </div>
        <div class="stat-card">
          <div class="stat-label">Orders</div>
          <div class="stat-value">${s.order_count}</div>
        </div>
        <div class="stat-card">
          <div class="stat-label">Restaurants</div>
          <div class="stat-value">${s.restaurant_count}</div>
        </div>
        <div class="stat-card">
          <div class="stat-label">Menu Items</div>
          <div class="stat-value">${s.menu_item_count}</div>
        </div>
        <div class="stat-card">
          <div class="stat-label">Customers</div>
          <div class="stat-value">${s.customer_count}</div>
        </div>
        <div class="stat-card">
          <div class="stat-label">Avg Rating</div>
          <div class="stat-value">${s.avg_rating ?? '—'} / 5</div>
        </div>
      </div>
      <div class="charts-grid">
        <div class="chart-card">
          <div class="chart-title">Revenue by Restaurant</div>
          <canvas id="revenue-chart"></canvas>
        </div>
        <div class="chart-card">
          <div class="chart-title">Orders Over Time</div>
          <canvas id="orders-chart"></canvas>
        </div>
      </div>
    `;
    drawRevenueChart(restaurants);
    drawOrdersChart(timeline);
  } catch (err) {
    showError(err);
  }
}

function drawRevenueChart(restaurants) {
  const ctx = document.getElementById('revenue-chart');
  if (!ctx) return;
  const sorted = [...restaurants].sort((a, b) => b.total_revenue - a.total_revenue);
  chartInstances.push(new Chart(ctx, {
    type: 'bar',
    data: {
      labels: sorted.map((r) => r.restaurant_name),
      datasets: [{
        label: 'Revenue',
        data: sorted.map((r) => Number(r.total_revenue)),
        backgroundColor: '#1f6feb',
        borderRadius: 4,
      }],
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: { legend: { display: false } },
      scales: {
        x: { ticks: { color: '#8b949e' }, grid: { display: false } },
        y: {
          ticks: { color: '#8b949e', callback: (v) => '$' + v },
          grid: { color: '#21262d' },
        },
      },
    },
  }));
}

function drawOrdersChart(timeline) {
  const ctx = document.getElementById('orders-chart');
  if (!ctx) return;
  chartInstances.push(new Chart(ctx, {
    type: 'line',
    data: {
      labels: timeline.map((t) => fmtDate(t.order_date)),
      datasets: [{
        label: 'Orders',
        data: timeline.map((t) => t.order_count),
        borderColor: '#3fb950',
        backgroundColor: '#3fb95033',
        fill: true,
        tension: 0.3,
        pointRadius: 3,
      }],
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: { legend: { display: false } },
      scales: {
        x: { ticks: { color: '#8b949e' }, grid: { display: false } },
        y: {
          beginAtZero: true,
          ticks: { color: '#8b949e', precision: 0 },
          grid: { color: '#21262d' },
        },
      },
    },
  }));
}

async function renderRestaurants() {
  showLoading();
  try {
    const rows = await fetchJSON('/api/restaurants');
    if (!rows.length) {
      content.innerHTML = '<p class="empty">No restaurants found.</p>';
      return;
    }
    content.innerHTML = `
      <h2>Restaurants</h2>
      <div class="restaurant-list">
        ${rows.map((r) => `
          <div class="restaurant-card" data-id="${r.restaurant_id}">
            <h3>${escapeHtml(r.restaurant_name)}</h3>
            <div class="restaurant-meta">📍 ${escapeHtml(r.address)}</div>
            <div class="restaurant-meta">📞 ${escapeHtml(r.phone_number)}</div>
            <div class="restaurant-stats">
              <div>
                <div class="stat-label">Revenue</div>
                <div class="stat-value money">${fmtMoney(r.total_revenue)}</div>
              </div>
              <div>
                <div class="stat-label">Orders</div>
                <div class="stat-value">${r.order_count}</div>
              </div>
            </div>
          </div>
        `).join('')}
      </div>
    `;
    document.querySelectorAll('.restaurant-card').forEach((card) => {
      card.addEventListener('click', () => renderMenu(card.dataset.id, card.querySelector('h3').textContent));
    });
  } catch (err) {
    showError(err);
  }
}

async function renderMenu(restaurantId, restaurantName) {
  showLoading();
  try {
    const items = await fetchJSON(`/api/restaurants/${restaurantId}/menu`);
    if (!items.length) {
      content.innerHTML = `
        <div class="menu-view">
          <button class="back-button">← Back to Restaurants</button>
          <h2>${escapeHtml(restaurantName)}</h2>
          <p class="empty">No menu items.</p>
        </div>
      `;
    } else {
      const grouped = {};
      for (const it of items) {
        const key = `${it.menu_type} — ${it.category_name}`;
        (grouped[key] ||= []).push(it);
      }
      content.innerHTML = `
        <div class="menu-view">
          <button class="back-button">← Back to Restaurants</button>
          <h2>${escapeHtml(restaurantName)} — Menu</h2>
          ${Object.entries(grouped).map(([section, list]) => `
            <div class="menu-section">
              <h3>${escapeHtml(section)}</h3>
              ${list.map((it) => `
                <div class="menu-item">
                  <div class="menu-item-info">
                    <div class="menu-item-name">${escapeHtml(it.name)}</div>
                    <div class="menu-item-desc">${escapeHtml(it.description)}</div>
                  </div>
                  <div class="menu-item-price">${fmtMoney(it.price)}</div>
                </div>
              `).join('')}
            </div>
          `).join('')}
        </div>
      `;
    }
    document.querySelector('.back-button').addEventListener('click', renderRestaurants);
  } catch (err) {
    showError(err);
  }
}

async function renderOrders() {
  showLoading();
  try {
    const rows = await fetchJSON('/api/orders');
    if (!rows.length) {
      content.innerHTML = '<p class="empty">No orders.</p>';
      return;
    }
    content.innerHTML = `
      <h2>Recent Orders <span class="hint">(click a row to see line items)</span></h2>
      <table>
        <thead>
          <tr><th>#</th><th>Date</th><th>Customer</th><th>Restaurant</th><th>Status</th><th class="money">Total</th></tr>
        </thead>
        <tbody>
          ${rows.map((o) => `
            <tr class="order-row" data-id="${o.order_id}">
              <td><span class="expand-caret">▸</span> ${o.order_id}</td>
              <td>${fmtDate(o.order_date)}</td>
              <td>${escapeHtml(o.customer_name)}</td>
              <td>${escapeHtml(o.restaurant_name)}</td>
              <td><span class="badge badge-status badge-${o.status}">${o.status}</span></td>
              <td class="money">${fmtMoney(o.total_amount)}</td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    `;
    document.querySelectorAll('.order-row').forEach((row) => {
      row.addEventListener('click', () => toggleOrderItems(row));
    });
  } catch (err) {
    showError(err);
  }
}

async function toggleOrderItems(row) {
  const next = row.nextElementSibling;
  if (next && next.classList.contains('order-items-row')) {
    next.remove();
    row.classList.remove('expanded');
    return;
  }
  row.classList.add('expanded');
  const detailRow = document.createElement('tr');
  detailRow.className = 'order-items-row';
  detailRow.innerHTML = `<td colspan="6"><p class="loading-inline">Loading items...</p></td>`;
  row.parentNode.insertBefore(detailRow, row.nextSibling);
  try {
    const items = await fetchJSON(`/api/orders/${row.dataset.id}/items`);
    if (!items.length) {
      detailRow.querySelector('td').innerHTML = '<p class="empty-inline">No items on this order.</p>';
      return;
    }
    detailRow.querySelector('td').innerHTML = `
      <table class="nested-table">
        <thead>
          <tr><th>Item</th><th class="num">Qty</th><th class="money">Unit Price</th><th class="money">Line Total</th></tr>
        </thead>
        <tbody>
          ${items.map((it) => `
            <tr>
              <td>${escapeHtml(it.menu_item)}</td>
              <td class="num">${it.quantity}</td>
              <td class="money">${fmtMoney(it.price)}</td>
              <td class="money">${fmtMoney(it.line_total)}</td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    `;
  } catch (err) {
    detailRow.querySelector('td').innerHTML = `<div class="error">${escapeHtml(err.message)}</div>`;
  }
}

async function renderBestSellers() {
  showLoading();
  try {
    const rows = await fetchJSON('/api/best-sellers');
    if (!rows.length) {
      content.innerHTML = '<p class="empty">No sales data.</p>';
      return;
    }
    content.innerHTML = `
      <h2>Top 10 Best Sellers</h2>
      <table>
        <thead>
          <tr><th>Rank</th><th>Item</th><th class="money">Price</th><th class="num">Units Sold</th></tr>
        </thead>
        <tbody>
          ${rows.map((r, i) => `
            <tr>
              <td class="rank rank-${i + 1}">#${i + 1}</td>
              <td>${escapeHtml(r.name)}</td>
              <td class="money">${fmtMoney(r.price)}</td>
              <td class="num">${r.total_sold}</td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    `;
  } catch (err) {
    showError(err);
  }
}

async function renderPromotions() {
  showLoading();
  try {
    const rows = await fetchJSON('/api/promotions');
    if (!rows.length) {
      content.innerHTML = '<p class="empty">No promotions.</p>';
      return;
    }
    content.innerHTML = `
      <h2>Promotions</h2>
      <table>
        <thead>
          <tr><th>Status</th><th>Promotion</th><th>Menu Item</th><th>Start</th><th>End</th></tr>
        </thead>
        <tbody>
          ${rows.map((p) => `
            <tr>
              <td>
                <span class="badge ${p.is_active ? 'badge-active' : 'badge-expired'}">
                  ${p.is_active ? 'Active' : 'Expired'}
                </span>
              </td>
              <td>${escapeHtml(p.promotion_name)}</td>
              <td>${escapeHtml(p.menu_item)}</td>
              <td>${fmtDate(p.start_date)}</td>
              <td>${fmtDate(p.end_date)}</td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    `;
  } catch (err) {
    showError(err);
  }
}

async function renderLoyalty() {
  showLoading();
  try {
    const rows = await fetchJSON('/api/loyalty');
    if (!rows.length) {
      content.innerHTML = '<p class="empty">No loyalty members.</p>';
      return;
    }
    content.innerHTML = `
      <h2>Loyalty Leaderboard</h2>
      <table>
        <thead>
          <tr><th>Rank</th><th>Customer</th><th class="num">Reward Points</th></tr>
        </thead>
        <tbody>
          ${rows.map((c, i) => `
            <tr>
              <td class="rank rank-${i + 1}">#${i + 1}</td>
              <td>${escapeHtml(c.name)}</td>
              <td class="num">${c.reward_points}</td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    `;
  } catch (err) {
    showError(err);
  }
}

// Initial render
renderDashboard();
