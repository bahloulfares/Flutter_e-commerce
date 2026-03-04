const express = require('express');
const router = express.Router();
const { User } = require('../models');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');

// Register
router.post('/register', async (req, res) => {
  try {
    const { name, email, password, role = 'user', avatar = '' } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ success: false, message: "All fields are required" });
    }

    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) {
      return res.status(409).json({ success: false, message: "Account already exists" });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    const newUser = await User.create({
      name,
      email,
      password: hashedPassword,
      role,
      avatar,
    });

    return res.status(201).json({ 
      success: true, 
      message: "Account created successfully", 
      user: {
        id: newUser.id,
        name: newUser.name,
        email: newUser.email,
        role: newUser.role,
      }
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Generate Token
const generateToken = (user) => {
  return jwt.sign({ user: { id: user.id, email: user.email, name: user.name } }, process.env.TOKEN, { expiresIn: '15m' });
};

// Login
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ success: false, message: "All fields are required" });
    }

    const user = await User.findOne({ where: { email } });

    if (!user) {
      return res.status(404).json({ success: false, message: "Account doesn't exist" });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ success: false, message: "Invalid credentials" });
    }

    const token = generateToken(user);
    const refreshToken = generateRefreshToken(user);

    res.status(200).json({
      success: true,
      token,
      refreshToken,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
      },
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Generate Refresh Token
function generateRefreshToken(user) {
  return jwt.sign({ user: { id: user.id, email: user.email } }, process.env.REFRESH_TOKEN, { expiresIn: '1y' });
}

// Refresh Token Route
router.post('/refreshToken', async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json({ success: false, message: "Token not provided" });
    }

    jwt.verify(refreshToken, process.env.REFRESH_TOKEN, (err, decoded) => {
      if (err) {
        return res.status(401).json({ success: false, message: "Invalid or expired token" });
      }

      const user = { id: decoded.user.id, email: decoded.user.email };
      const token = generateToken(user);
      const newRefreshToken = generateRefreshToken(user);

      res.status(200).json({
        token,
        refreshToken: newRefreshToken,
      });
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
