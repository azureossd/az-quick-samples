const express = require('express');
const redis = require('redis');
const path = require('path');
const app = express();

// Middleware
app.use(express.json());
app.use(express.static('public'));

// Redis configuration
const redisConfig = {
    host: process.env.REDIS_HOST || 'localhost',
    port: process.env.REDIS_PORT || 6379,
    password: process.env.REDIS_PASSWORD,
    tls: process.env.REDIS_SSL === 'true' ? {} : undefined,
    retry_strategy: (options) => {
        if (options.error && options.error.code === 'ECONNREFUSED') {
            console.error('Redis connection refused');
            return new Error('Redis connection refused');
        }
        if (options.total_retry_time > 1000 * 60 * 60) {
            return new Error('Retry time exhausted');
        }
        if (options.attempt > 10) {
            return undefined;
        }
        return Math.min(options.attempt * 100, 3000);
    }
};

// Create Redis client
let redisClient = null;
let redisConnected = false;

async function connectRedis() {
    try {
        redisClient = redis.createClient(redisConfig);
        
        redisClient.on('error', (err) => {
            console.error('Redis Client Error:', err);
            redisConnected = false;
        });
        
        redisClient.on('connect', () => {
            console.log('Connected to Redis');
            redisConnected = true;
        });
        
        redisClient.on('disconnect', () => {
            console.log('Disconnected from Redis');
            redisConnected = false;
        });
        
        await redisClient.connect();
    } catch (error) {
        console.error('Failed to connect to Redis:', error);
        redisConnected = false;
    }
}

// Initialize Redis connection
connectRedis();

// In-memory storage as fallback
const memoryStore = new Map();
let requestCount = 0;
let cacheHits = 0;
let cacheMisses = 0;

// Utility functions
async function getFromCache(key) {
    try {
        if (redisConnected && redisClient) {
            const value = await redisClient.get(key);
            return value ? JSON.parse(value) : null;
        } else {
            return memoryStore.get(key) || null;
        }
    } catch (error) {
        console.error('Cache get error:', error);
        return memoryStore.get(key) || null;
    }
}

async function setInCache(key, value, ttl = 300) {
    try {
        if (redisConnected && redisClient) {
            await redisClient.setEx(key, ttl, JSON.stringify(value));
        } else {
            memoryStore.set(key, value);
            // Simple TTL for memory store
            setTimeout(() => memoryStore.delete(key), ttl * 1000);
        }
    } catch (error) {
        console.error('Cache set error:', error);
        memoryStore.set(key, value);
    }
}

async function deleteFromCache(key) {
    try {
        if (redisConnected && redisClient) {
            await redisClient.del(key);
        } else {
            memoryStore.delete(key);
        }
    } catch (error) {
        console.error('Cache delete error:', error);
        memoryStore.delete(key);
    }
}

// Logging middleware
app.use((req, res, next) => {
    requestCount++;
    console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
    next();
});

// Routes
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// GET /api/data/:id - Get data with caching
app.get('/api/data/:id', async (req, res) => {
    const { id } = req.params;
    const cacheKey = `data:${id}`;
    
    try {
        // Try to get from cache first
        const cachedData = await getFromCache(cacheKey);
        
        if (cachedData) {
            cacheHits++;
            console.log(`Cache HIT for key: ${cacheKey}`);
            return res.json({
                ...cachedData,
                cached: true,
                timestamp: new Date().toISOString()
            });
        }
        
        // Cache miss - simulate data fetching
        cacheMisses++;
        console.log(`Cache MISS for key: ${cacheKey}`);
        
        // Simulate slow data fetching
        await new Promise(resolve => setTimeout(resolve, 500));
        
        const data = {
            id: id,
            title: `Sample Data Item ${id}`,
            description: `This is a sample data entry with ID ${id}. In a real application, this would come from a database.`,
            value: Math.floor(Math.random() * 1000),
            category: ['Technology', 'Business', 'Science', 'Arts'][Math.floor(Math.random() * 4)],
            createdAt: new Date().toISOString(),
            tags: ['sample', 'api', 'cache', 'demo']
        };
        
        // Store in cache for 5 minutes
        await setInCache(cacheKey, data, 300);
        
        res.json({
            ...data,
            cached: false,
            timestamp: new Date().toISOString()
        });
        
    } catch (error) {
        console.error('Error in GET /api/data/:id:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// POST /api/data - Create new data entry
app.post('/api/data', async (req, res) => {
    try {
        const { title, description, category } = req.body;
        
        if (!title || !description) {
            return res.status(400).json({ error: 'Title and description are required' });
        }
        
        const id = Date.now().toString();
        const data = {
            id,
            title,
            description,
            category: category || 'General',
            value: Math.floor(Math.random() * 1000),
            createdAt: new Date().toISOString(),
            tags: ['user-created', 'api', 'demo']
        };
        
        // Store in cache
        const cacheKey = `data:${id}`;
        await setInCache(cacheKey, data, 300);
        
        console.log(`Created new data entry: ${id}`);
        res.status(201).json(data);
        
    } catch (error) {
        console.error('Error in POST /api/data:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// PUT /api/data/:id - Update data entry
app.put('/api/data/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { title, description, category } = req.body;
        const cacheKey = `data:${id}`;
        
        // Get existing data
        let existingData = await getFromCache(cacheKey);
        
        if (!existingData) {
            return res.status(404).json({ error: 'Data not found' });
        }
        
        // Update data
        const updatedData = {
            ...existingData,
            title: title || existingData.title,
            description: description || existingData.description,
            category: category || existingData.category,
            updatedAt: new Date().toISOString()
        };
        
        // Update cache
        await setInCache(cacheKey, updatedData, 300);
        
        console.log(`Updated data entry: ${id}`);
        res.json(updatedData);
        
    } catch (error) {
        console.error('Error in PUT /api/data/:id:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// DELETE /api/data/:id - Delete data entry
app.delete('/api/data/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const cacheKey = `data:${id}`;
        
        // Check if data exists
        const existingData = await getFromCache(cacheKey);
        
        if (!existingData) {
            return res.status(404).json({ error: 'Data not found' });
        }
        
        // Delete from cache
        await deleteFromCache(cacheKey);
        
        console.log(`Deleted data entry: ${id}`);
        res.json({ success: true, message: 'Data deleted successfully' });
        
    } catch (error) {
        console.error('Error in DELETE /api/data/:id:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// GET /api/cache/stats - Get cache statistics
app.get('/api/cache/stats', async (req, res) => {
    try {
        let redisInfo = {};
        
        if (redisConnected && redisClient) {
            try {
                const info = await redisClient.info('memory');
                const lines = info.split('\r\n');
                lines.forEach(line => {
                    if (line.includes(':')) {
                        const [key, value] = line.split(':');
                        redisInfo[key] = value;
                    }
                });
            } catch (error) {
                redisInfo = { error: 'Failed to get Redis info' };
            }
        }
        
        const stats = {
            cacheType: redisConnected ? 'Redis' : 'Memory',
            redisConnected,
            totalRequests: requestCount,
            cacheHits,
            cacheMisses,
            hitRate: requestCount > 0 ? (cacheHits / (cacheHits + cacheMisses) * 100).toFixed(2) + '%' : '0%',
            memoryStoreSize: memoryStore.size,
            redisInfo: redisConnected ? redisInfo : null,
            timestamp: new Date().toISOString()
        };
        
        res.json(stats);
        
    } catch (error) {
        console.error('Error in GET /api/cache/stats:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// POST /api/cache/clear - Clear cache
app.post('/api/cache/clear', async (req, res) => {
    try {
        if (redisConnected && redisClient) {
            await redisClient.flushDb();
        }
        memoryStore.clear();
        
        // Reset stats
        cacheHits = 0;
        cacheMisses = 0;
        
        console.log('Cache cleared');
        res.json({ success: true, message: 'Cache cleared successfully' });
        
    } catch (error) {
        console.error('Error in POST /api/cache/clear:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Health check endpoint
app.get('/health', async (req, res) => {
    try {
        let redisStatus = 'disconnected';
        
        if (redisClient && redisConnected) {
            try {
                await redisClient.ping();
                redisStatus = 'connected';
            } catch (error) {
                redisStatus = 'error';
            }
        }
        
        const health = {
            status: 'healthy',
            timestamp: new Date().toISOString(),
            uptime: process.uptime(),
            redis: redisStatus,
            memory: {
                used: process.memoryUsage().heapUsed / 1024 / 1024,
                total: process.memoryUsage().heapTotal / 1024 / 1024
            },
            requests: requestCount
        };
        
        res.json(health);
        
    } catch (error) {
        console.error('Health check failed:', error);
        res.status(503).json({
            status: 'unhealthy',
            error: error.message,
            timestamp: new Date().toISOString()
        });
    }
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error('Unhandled error:', err);
    res.status(500).json({ error: 'Internal server error' });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({ error: 'Not found' });
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 API with Cache Sample running on port ${PORT}`);
    console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`Redis Host: ${redisConfig.host}:${redisConfig.port}`);
    console.log(`Redis SSL: ${redisConfig.tls ? 'enabled' : 'disabled'}`);
});
