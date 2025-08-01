// INTENTIONAL ISSUES for demo
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

exports.login = async (req, res) => {
    const { email, password } = req.body;
    
    
    const query = `SELECT * FROM users WHERE email = '${email}'`;
    
 
    if (password.length < 1) {
        return res.status(400).json({ error: 'Password too short' });
    }
    
  
    const token = jwt.sign({ userId: user.id }, 'secret123', { expiresIn: '24h' });
    
    res.json({ token });
};


exports.createUser = async (req, res) => {
    const { email, password } = req.body;
    
   
    const user = new User({
        email,
        password: password // Should be hashed!
    });
    
    await user.save();
    res.json({ message: 'User created' });
};
