from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import os
import logging
from datetime import datetime
from typing import List, Optional

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# FastAPI app instance
app = FastAPI(
    title="FastAPI Web App Sample",
    description="A sample FastAPI application running on Azure App Service Linux",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure as needed for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Pydantic models for request/response
class Item(BaseModel):
    id: Optional[int] = None
    name: str
    description: Optional[str] = None
    price: float
    created_at: Optional[datetime] = None

class ItemCreate(BaseModel):
    name: str
    description: Optional[str] = None
    price: float

# In-memory storage for demo purposes
items_db: List[Item] = [
    Item(id=1, name="Sample Item 1", description="This is a sample item", price=29.99, created_at=datetime.now()),
    Item(id=2, name="Sample Item 2", description="Another sample item", price=49.99, created_at=datetime.now())
]

# Health check endpoint
@app.get("/health", status_code=status.HTTP_200_OK)
async def health_check():
    """Health check endpoint for Azure App Service health monitoring."""
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}

# Root endpoint
@app.get("/", response_model=dict)
async def root():
    """Root endpoint with basic information about the API."""
    environment = os.getenv("ENVIRONMENT", "development")
    return {
        "message": "Welcome to FastAPI on Azure App Service!",
        "environment": environment,
        "docs_url": "/docs",
        "health_check": "/health",
        "api_endpoints": {
            "items": "/items",
            "create_item": "/items (POST)",
            "get_item": "/items/{item_id}"
        }
    }

# Get all items
@app.get("/items", response_model=List[Item])
async def get_items():
    """Get all items from the database."""
    logger.info(f"Retrieved {len(items_db)} items")
    return items_db

# Get item by ID
@app.get("/items/{item_id}", response_model=Item)
async def get_item(item_id: int):
    """Get a specific item by ID."""
    item = next((item for item in items_db if item.id == item_id), None)
    if item is None:
        logger.warning(f"Item with ID {item_id} not found")
        raise HTTPException(status_code=404, detail="Item not found")
    
    logger.info(f"Retrieved item with ID {item_id}")
    return item

# Create a new item
@app.post("/items", response_model=Item, status_code=status.HTTP_201_CREATED)
async def create_item(item: ItemCreate):
    """Create a new item."""
    # Generate new ID
    new_id = max([item.id for item in items_db], default=0) + 1
    
    # Create new item
    new_item = Item(
        id=new_id,
        name=item.name,
        description=item.description,
        price=item.price,
        created_at=datetime.now()
    )
    
    items_db.append(new_item)
    logger.info(f"Created new item with ID {new_id}")
    
    return new_item

# Update an item
@app.put("/items/{item_id}", response_model=Item)
async def update_item(item_id: int, item_update: ItemCreate):
    """Update an existing item."""
    item_index = next((index for index, item in enumerate(items_db) if item.id == item_id), None)
    if item_index is None:
        logger.warning(f"Item with ID {item_id} not found for update")
        raise HTTPException(status_code=404, detail="Item not found")
    
    # Update the item
    items_db[item_index].name = item_update.name
    items_db[item_index].description = item_update.description
    items_db[item_index].price = item_update.price
    
    logger.info(f"Updated item with ID {item_id}")
    return items_db[item_index]

# Delete an item
@app.delete("/items/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_item(item_id: int):
    """Delete an item by ID."""
    item_index = next((index for index, item in enumerate(items_db) if item.id == item_id), None)
    if item_index is None:
        logger.warning(f"Item with ID {item_id} not found for deletion")
        raise HTTPException(status_code=404, detail="Item not found")
    
    items_db.pop(item_index)
    logger.info(f"Deleted item with ID {item_id}")

# Get app info
@app.get("/info", response_model=dict)
async def get_app_info():
    """Get application information and environment details."""
    return {
        "app_name": "FastAPI Web App Sample",
        "version": "1.0.0",
        "environment": os.getenv("ENVIRONMENT", "development"),
        "python_version": os.getenv("PYTHON_VERSION", "Unknown"),
        "total_items": len(items_db),
        "timestamp": datetime.now().isoformat()
    }

# Exception handler
@app.exception_handler(Exception)
async def general_exception_handler(request, exc):
    """General exception handler for unhandled exceptions."""
    logger.error(f"Unhandled exception: {exc}")
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error"}
    )

# Startup event
@app.on_event("startup")
async def startup_event():
    """Application startup event."""
    logger.info("FastAPI application started successfully")
    logger.info(f"Environment: {os.getenv('ENVIRONMENT', 'development')}")
    logger.info(f"Total items in database: {len(items_db)}")

# Shutdown event
@app.on_event("shutdown")
async def shutdown_event():
    """Application shutdown event."""
    logger.info("FastAPI application shutting down")

# For Azure App Service
if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    uvicorn.run("main:app", host="0.0.0.0", port=port, log_level="info")
