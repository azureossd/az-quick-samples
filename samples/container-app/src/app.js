const express = require('express');
const path = require('path');
const app = express();

// Middleware
app.use(express.json());
app.use(express.static('public'));

// Basic logging middleware
app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
    next();
});

// In-memory storage for demo (in production, use a database)
let messages = [
    { id: 1, message: 'Welcome to the Container App Sample!', timestamp: new Date().toISOString() },
    { id: 2, message: 'This app is running in Azure Container Apps', timestamp: new Date().toISOString() }
];
let nextId = 3;

// Routes
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.get('/api/messages', (req, res) => {
    res.json(messages.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp)));
});

app.post('/api/messages', (req, res) => {
    const { message } = req.body;
    
    if (!message || message.trim() === '') {
        return res.status(400).json({ error: 'Message is required' });
    }
    
    const newMessage = {
        id: nextId++,
        message: message.trim(),
        timestamp: new Date().toISOString()
    };
    
    messages.push(newMessage);
    console.log(`New message added: ${newMessage.message}`);
    res.status(201).json(newMessage);
});

app.delete('/api/messages/:id', (req, res) => {
    const id = parseInt(req.params.id);
    const messageIndex = messages.findIndex(m => m.id === id);
    
    if (messageIndex === -1) {
        return res.status(404).json({ error: 'Message not found' });
    }
    
    const deletedMessage = messages.splice(messageIndex, 1)[0];
    console.log(`Message deleted: ${deletedMessage.message}`);
    res.json({ success: true });
});

app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        environment: process.env.NODE_ENV || 'development',
        version: process.env.npm_package_version || '1.0.0'
    });
});

app.get('/api/info', (req, res) => {
    res.json({
        app: 'Container App Sample',
        description: 'A simple Node.js app running in Azure Container Apps',
        environment: process.env.NODE_ENV || 'development',
        nodeVersion: process.version,
        timestamp: new Date().toISOString(),
        containerInfo: {
            hostname: require('os').hostname(),
            platform: process.platform,
            arch: process.arch
        }
    });
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
    console.log(`🚀 Container App Sample running on port ${PORT}`);
    console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`Node version: ${process.version}`);
    console.log(`Container hostname: ${require('os').hostname()}`);
});
