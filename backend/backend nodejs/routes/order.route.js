const express = require('express');
const router = express.Router();
const { Order, LineOrder, Article } = require('../models');

// Create order
router.post('/', async (req, res) => {
  try {
    const { client, lineOrder } = req.body;

    if (!client || !Array.isArray(lineOrder) || lineOrder.length === 0) {
      return res.status(400).json({ message: 'Client et lineOrder sont requis' });
    }

    const orderWithLines = await Order.sequelize.transaction(async (transaction) => {
      const sanitizedLines = [];

      for (const item of lineOrder) {
        const articleId = Number(item.articleId);
        const quantity = Number(item.quantity);

        if (!Number.isInteger(articleId) || articleId <= 0) {
          throw new Error(`articleId invalide: ${item.articleId}`);
        }

        if (!Number.isInteger(quantity) || quantity <= 0) {
          throw new Error(`quantité invalide pour article ${articleId}`);
        }

        const article = await Article.findByPk(articleId, {
          attributes: ['id', 'prix'],
          transaction,
        });

        if (!article) {
          throw new Error(`Article introuvable: ${articleId}`);
        }

        const unitPrice = Number(article.prix ?? 0);
        if (!Number.isFinite(unitPrice) || unitPrice < 0) {
          throw new Error(`Prix invalide pour article ${articleId}`);
        }

        const totalPrice = Number((unitPrice * quantity).toFixed(2));

        sanitizedLines.push({
          articleId,
          quantity,
          totalPrice,
        });
      }

      const total = Number(
        sanitizedLines
          .reduce((acc, item) => acc + item.totalPrice, 0)
          .toFixed(2)
      );

      const newOrder = await Order.create(
        {
          client,
          total,
          status: 'Not processed',
        },
        { transaction }
      );

      for (const item of sanitizedLines) {
        await LineOrder.create(
          {
            orderId: newOrder.id,
            articleId: item.articleId,
            quantity: item.quantity,
            totalPrice: item.totalPrice,
          },
          { transaction }
        );
      }

      return Order.findByPk(newOrder.id, {
        include: [{ model: LineOrder, as: 'lineOrder' }],
        transaction,
      });
    });

    res.status(201).json({ message: 'Order created successfully', order: orderWithLines });
  } catch (error) {
    if (
      error.message?.includes('invalide') ||
      error.message?.includes('introuvable')
    ) {
      return res.status(400).json({ message: error.message });
    }

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