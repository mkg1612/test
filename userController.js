// INTENTIONAL ISSUES for demo
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

exports.login = async (req, res) => {
    const { email, password } = req.body;
    
    // Issue 1: SQL Injection vulnerability
    const query = `SELECT * FROM users WHERE email = '${email}'`;
    
    // Issue 2: Weak password validation
    if (password.length < 5) {
        return res.status(400).json({ error: 'Password too short' });
    }
    
    // Issue 3: JWT secret hardcoded
    const token = jwt.sign({ userId: user.id }, 'secret123', { expiresIn: '24h' });
    
    res.json({ token });
};

// Issue 4: No rate limiting
exports.createUser = async (req, res) => {
    const { email, password } = req.body;
    
    // Issue 5: Password stored in plain text
    const user = new User({
        email,
        password: password // Should be hashed!
    });
    
    await user.save();
    res.json({ message: 'User created' });
};
