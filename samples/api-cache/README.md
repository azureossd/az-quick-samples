# REST API with Redis Cache Sample

This sample demonstrates how to create a REST API with Redis Cache for improved performance using Azure Developer CLI (azd).

## Architecture

This sample creates:
- **App Service**: Hosts the REST API application
- **Azure Cache for Redis**: Provides high-performance caching
- **App Service Plan**: Compute resources for the web application

## Prerequisites

Before deploying this sample, ensure you have:

1. **Azure CLI** installed and logged in
2. **Azure Developer CLI (azd)** installed
3. An **Azure subscription** with appropriate permissions
4. **Node.js 18+** (for local development)

## Deployment

### Quick Deploy with azd

1. Navigate to this sample directory:
   ```cmd
   cd samples\api-cache
   ```

2. Initialize azd (if not already done):
   ```cmd
   azd init
   ```

3. Deploy the infrastructure and application:
   ```cmd
   azd up
   ```

### Manual Steps

If you prefer to deploy manually:

1. **Provision Infrastructure**:
   ```cmd
   azd provision
   ```

2. **Deploy Application**:
   ```cmd
   azd deploy
   ```

## Configuration

The application uses these environment variables (automatically configured during deployment):

- `REDIS_HOST`: Redis cache hostname
- `REDIS_PORT`: Redis cache port (6380 for SSL)
- `REDIS_PASSWORD`: Redis cache access key
- `REDIS_SSL`: Enable SSL connection (true)

## Customization

### Redis Cache Configuration

You can customize the Redis cache by modifying `infra/main.parameters.json`:

```json
{
  "redisCacheSku": {
    "value": "Premium"
  },
  "redisCacheFamily": {
    "value": "P"
  },
  "redisCacheCapacity": {
    "value": 1
  }
}
```

### App Service Plan

Change the App Service Plan SKU in `infra/main.parameters.json`:

```json
{
  "appServicePlanSku": {
    "value": "S1"
  }
}
```

Available SKUs: B1, B2, B3, S1, S2, S3, P1V2, P2V2, P3V2

## Application Structure

```
api-cache/
├── azure.yaml           # Azure Developer CLI configuration
├── infra/              # Infrastructure as Code (Bicep)
│   ├── main.bicep      # Main infrastructure template
│   └── main.parameters.json # Parameters file
├── src/                # Application source code
│   ├── app.js         # Express.js API application
│   ├── package.json   # Node.js dependencies
│   ├── routes/        # API route handlers
│   └── middleware/    # Custom middleware (caching, etc.)
└── README.md          # This file
```

## API Endpoints

The sample API provides these endpoints:

- `GET /api/data/:id` - Get data by ID (with caching)
- `POST /api/data` - Create new data entry
- `PUT /api/data/:id` - Update data entry
- `DELETE /api/data/:id` - Delete data entry
- `GET /api/cache/stats` - Get cache statistics
- `POST /api/cache/clear` - Clear cache

## Local Development

1. **Install dependencies**:
   ```cmd
   cd src
   npm install
   ```

2. **Set environment variables**:
   ```cmd
   set REDIS_HOST=your-redis-host.redis.cache.windows.net
   set REDIS_PORT=6380
   set REDIS_PASSWORD=your-redis-key
   set REDIS_SSL=true
   set PORT=3000
   ```

3. **Run the application**:
   ```cmd
   npm start
   ```

4. **Test API endpoints** using curl or Postman:
   ```cmd
   curl http://localhost:3000/api/data/123
   ```

## Features

- **REST API**: Full CRUD operations with Express.js
- **Redis Caching**: Automatic caching for improved performance
- **Cache Strategies**: Implements cache-aside pattern
- **Error Handling**: Graceful handling of cache and API errors
- **Health Checks**: Built-in health check endpoints
- **Logging**: Structured logging for monitoring

## Monitoring and Troubleshooting

### View Application Logs

```cmd
azd logs
```

### Monitor Redis Cache

Check your Redis cache metrics in the Azure portal:
1. Navigate to your Redis Cache resource
2. Go to "Metrics" to view cache hits, misses, and performance
3. Use "Console" for direct Redis commands

### Common Issues

1. **Redis Connection**: Ensure firewall rules allow your App Service to connect
2. **SSL Configuration**: Redis requires SSL connections by default
3. **Memory Usage**: Monitor Redis memory usage and configure eviction policies

## Performance Benefits

With Redis caching, you can expect:
- **Reduced Database Load**: Cache frequently accessed data
- **Faster Response Times**: Sub-millisecond data retrieval
- **Better Scalability**: Handle more concurrent requests
- **Cost Optimization**: Reduce expensive database queries

## Cache Strategies

The sample implements several caching patterns:

1. **Cache-Aside**: Load data on cache miss
2. **Write-Through**: Update cache when data is written
3. **Time-based Expiration**: Automatic cache invalidation
4. **Cache Warming**: Pre-populate cache with common data

## Cost Considerations

- **App Service**: Charges based on the selected SKU
- **Redis Cache**: Pricing varies by tier (Basic, Standard, Premium)
- **Data Transfer**: Charges for data transfer between services

Estimated monthly cost for B1 App Service + Basic Redis: $20-40

## Security

- **SSL/TLS**: All Redis connections use encryption
- **Access Keys**: Redis protected with access keys
- **Network Security**: Optional VNet integration for Premium tier
- **Authentication**: Support for Redis AUTH

## Scaling

### Redis Cache Scaling
- **Basic**: Single node, no SLA
- **Standard**: Two nodes with SLA
- **Premium**: Clustering, persistence, VNet support

### App Service Scaling
- **Scale Up**: Increase VM size for more CPU/memory
- **Scale Out**: Add more instances for higher throughput

## Next Steps

- Implement distributed caching across multiple regions
- Add cache warming strategies for cold start optimization
- Integrate with Azure Monitor for detailed analytics
- Implement custom eviction policies based on business logic
- Add support for Redis Streams for real-time data processing

## Resources

- [Azure Cache for Redis Documentation](https://docs.microsoft.com/azure/azure-cache-for-redis/)
- [Azure Developer CLI Documentation](https://docs.microsoft.com/azure/developer-cli/)
- [Express.js Documentation](https://expressjs.com/)
- [Redis Documentation](https://redis.io/documentation)
