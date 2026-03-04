const express = require('express');
const router = express.Router();
const { Order, LineOrder, Article } = require('../models');

// Create order
router.post('/', async (req, res) => {
  try {
    const { client, lineOrder } = req.body;

    const total = lineOrder.reduce((acc, item) => acc + item.totalPrice, 0);

    const newOrder = await Order.create({
      client,
      total,
      status: 'Not processed',
    });

    // Create line items
    for (const item of lineOrder) {
      await LineOrder.create({
        orderId: newOrder.id,
        articleId: item.articleId,
        quantity: item.quantity,
        totalPrice: item.totalPrice,
      });
    }

    const orderWithLines = await Order.findByPk(newOrder.id, {
      include: [{ model: LineOrder, as: 'lineOrder' }],
    });

    res.status(201).json({ message: 'Order created successfully', order: orderWithLines });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Get all orders
router.get('/', async (req, res) => {
  try {
    const orders = await Order.findAll({
      include: [
        {
          model: LineOrder,
          as: 'lineOrder',
          include: [{ model: Article, as: 'article' }],
        },
      ],
      order: [['id', 'DESC']],
    });
    res.status(200).json(orders);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Update order status
router.put('/:id', async (req, res) => {
  try {
    const { status } = req.body;
    const validStatuses = ['Not processed', 'Processing', 'Shipped', 'Delivered', 'Cancelled'];

    if (!validStatuses.includes(status)) {
      return res.status(400).json({ message: 'Invalid status value' });
    }

    const order = await Order.findByPk(req.params.id);
    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }

    await order.update({ status });
    res.status(200).json(order);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Delete order
router.delete('/:id', async (req, res) => {
  try {
    const order = await Order.findByPk(req.params.id);
    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }
    await order.destroy();
    res.status(200).json({ message: 'Order deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;