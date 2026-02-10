const express = require('express');
const db = require('../db');
const router = express.Router();

// Get orders for a user
router.get('/:userId', (req, res) => {
    const sql = 'SELECT * FROM orders WHERE user_id = ? ORDER BY order_date DESC';
    db.query(sql, [req.params.userId], (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(results);
    });
});

// Place an order (from cart)
router.post('/', (req, res) => {
    const { userId, totalAmount, items, location, contact, note } = req.body;
    // items should be [{ coffee_id, quantity, price }]

    db.beginTransaction(err => {
        if (err) return res.status(500).json({ error: err.message });

        const orderSql = 'INSERT INTO orders (user_id, total_amount, location, contact, note) VALUES (?, ?, ?, ?, ?)';
        db.query(orderSql, [userId, totalAmount, location, contact, note], (err, result) => {
            if (err) {
                return db.rollback(() => res.status(500).json({ error: err.message }));
            }

            const orderId = result.insertId;

            if (!items || items.length === 0) {
                return db.rollback(() => res.status(400).json({ message: 'No items in order' }));
            }

            const itemValues = items.map(item => [orderId, item.coffee_id, item.quantity, item.price]);
            const itemSql = 'INSERT INTO order_items (order_id, coffee_id, quantity, price) VALUES ?';

            db.query(itemSql, [itemValues], (err, result) => {
                if (err) {
                    return db.rollback(() => res.status(500).json({ error: err.message }));
                }

                // Decrease Stock
                const updateStockQueries = items.map(item => {
                    return new Promise((resolve, reject) => {
                        db.query('UPDATE coffees SET stock = stock - ? WHERE id = ?', [item.quantity, item.coffee_id], (err) => {
                            if (err) reject(err);
                            else resolve();
                        });
                    });
                });

                Promise.all(updateStockQueries)
                    .then(() => {
                        db.commit(err => {
                            if (err) {
                                return db.rollback(() => res.status(500).json({ error: err.message }));
                            }
                            res.status(201).json({ message: 'Order placed successfully', orderId });
                        });
                    })
                    .catch(err => {
                        return db.rollback(() => res.status(500).json({ error: 'Failed to update stock' }));
                    });
            });
        });
    });
});

// Admin: Get revenue stats
router.get('/admin/revenue', (req, res) => {
    const sql = `
        SELECT
            SUM(CASE WHEN status = 'Completed' THEN total_amount ELSE 0 END) as totalRevenue,
            SUM(CASE WHEN status NOT IN ('Completed', 'Canceled') THEN total_amount ELSE 0 END) as potentialRevenue
        FROM orders
    `;
    db.query(sql, (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(results[0]);
    });
});

// Update order status
router.patch('/:orderId/status', (req, res) => {
    const { status } = req.body;

    // First, check if the order is canceled by customer
    db.query('SELECT status, canceled_by FROM orders WHERE id = ?', [req.params.orderId], (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        if (results.length === 0) return res.status(404).json({ message: 'Order not found' });

        const order = results[0];
        if (order.status === 'Canceled' && order.canceled_by === 'customer') {
            return res.status(403).json({ message: 'Cannot update status of an order canceled by customer. Only user can reactivate it.' });
        }

        const sql = 'UPDATE orders SET status = ? WHERE id = ?';
        db.query(sql, [status, req.params.orderId], (err, result) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json({ message: 'Status updated successfully' });
        });
    });
});

// Cancel order
router.patch('/:orderId/cancel', (req, res) => {
    const { reason, canceledBy } = req.body;
    const sql = 'UPDATE orders SET status = "Canceled", cancel_reason = ?, canceled_by = ? WHERE id = ?';
    db.query(sql, [reason, canceledBy, req.params.orderId], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ message: 'Order canceled successfully' });
    });
});

// Reactivate order
router.patch('/:orderId/reactivate', (req, res) => {
    // Only allows reactivation if canceled by customer
    db.query('SELECT canceled_by FROM orders WHERE id = ?', [req.params.orderId], (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        if (results.length === 0) return res.status(404).json({ message: 'Order not found' });

        if (results[0].canceled_by !== 'customer') {
            return res.status(403).json({ message: 'Only orders canceled by customer can be reactivated by them.' });
        }

        const sql = 'UPDATE orders SET status = "Pending", cancel_reason = NULL, canceled_by = NULL WHERE id = ?';
        db.query(sql, [req.params.orderId], (err, result) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json({ message: 'Order reactivated successfully' });
        });
    });
});

// Admin: Get all orders
router.get('/admin/all', (req, res) => {
    const sql = `
        SELECT o.*, u.name as customer_name
        FROM orders o
        JOIN users u ON o.user_id = u.id
        ORDER BY o.order_date DESC
    `;
    db.query(sql, (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(results);
    });
});

module.exports = router;
