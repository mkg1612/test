// INTENTIONAL ISSUES for demo
exports.getProducts = async (req, res) => {
    try {
        // Issue 1: N+1 query problem
        const products = await Product.findAll();
        for (let product of products) {
            product.reviews = await Review.findAll({ where: { productId: product.id } });
            product.category = await Category.findById(product.categoryId);
        }
        
        // Issue 2: No pagination
        // Issue 3: No caching
        // Issue 4: Exposing sensitive data
        res.json(products);
        
    } catch (error) {
        // Issue 5: Poor error handling
        console.log(error);
        res.status(500).json({ error: 'Something went wrong' });
    }
};

// Issue 6: Synchronous file operations
const fs = require('fs');
exports.uploadImage = (req, res) => {
    const data = fs.readFileSync(req.file.path); // Blocks event loop
    // Process image...
};

// Issue 7: Memory leak potential
let cache = {};
exports.cacheProduct = (req, res) => {
    cache[req.params.id] = req.body; // Never cleaned up
};
