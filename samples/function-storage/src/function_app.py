import azure.functions as func
import logging
import json
import os
from datetime import datetime
from azure.storage.blob import BlobServiceClient
from azure.storage.queue import QueueServiceClient
from azure.data.tables import TableServiceClient

app = func.FunctionApp()

# Initialize storage clients
def get_blob_service_client():
    """Get blob service client using managed identity"""
    account_url = f"https://{os.environ.get('STORAGE_ACCOUNT_NAME', 'defaultstorage')}.blob.core.windows.net"
    return BlobServiceClient(account_url=account_url, credential=None)

def get_queue_service_client():
    """Get queue service client using managed identity"""
    account_url = f"https://{os.environ.get('STORAGE_ACCOUNT_NAME', 'defaultstorage')}.queue.core.windows.net"
    return QueueServiceClient(account_url=account_url, credential=None)

def get_table_service_client():
    """Get table service client using managed identity"""
    account_url = f"https://{os.environ.get('STORAGE_ACCOUNT_NAME', 'defaultstorage')}.table.core.windows.net"
    return TableServiceClient(endpoint=account_url, credential=None)

@app.function_name(name="HttpTrigger")
@app.route(route="hello", auth_level=func.AuthLevel.ANONYMOUS)
def http_trigger(req: func.HttpRequest) -> func.HttpResponse:
    """HTTP trigger function - main entry point"""
    logging.info('Python HTTP trigger function processed a request.')

    try:
        # Get name from query params or request body
        name = req.params.get('name')
        if not name:
            try:
                req_body = req.get_json()
                if req_body:
                    name = req_body.get('name')
            except ValueError:
                pass

        if name:
            # Store message in blob storage
            try:
                blob_client = get_blob_service_client()
                container_name = "messages"
                blob_name = f"message-{datetime.now().strftime('%Y%m%d-%H%M%S')}.json"
                
                # Create container if it doesn't exist
                try:
                    blob_client.create_container(container_name)
                except Exception:
                    pass  # Container might already exist
                
                # Upload message to blob
                message_data = {
                    "name": name,
                    "message": f"Hello, {name}!",
                    "timestamp": datetime.now().isoformat(),
                    "function": "HttpTrigger"
                }
                
                blob_client.get_blob_client(
                    container=container_name, 
                    blob=blob_name
                ).upload_blob(
                    json.dumps(message_data, indent=2), 
                    overwrite=True
                )
                
                logging.info(f'Message stored in blob: {blob_name}')
                
                return func.HttpResponse(
                    json.dumps({
                        "message": f"Hello, {name}! Your greeting has been stored in Azure Storage.",
                        "timestamp": datetime.now().isoformat(),
                        "storage_info": {
                            "blob_name": blob_name,
                            "container": container_name
                        }
                    }),
                    status_code=200,
                    headers={"Content-Type": "application/json"}
                )
                
            except Exception as e:
                logging.error(f'Error storing message: {str(e)}')
                return func.HttpResponse(
                    json.dumps({
                        "message": f"Hello, {name}! (Note: Storage unavailable)",
                        "error": "Storage connection failed",
                        "timestamp": datetime.now().isoformat()
                    }),
                    status_code=200,
                    headers={"Content-Type": "application/json"}
                )
        else:
            return func.HttpResponse(
                json.dumps({
                    "message": "Hello, Azure Functions! Please pass a name in the query string or request body.",
                    "usage": "Add ?name=YourName to the URL or send JSON with 'name' field",
                    "timestamp": datetime.now().isoformat()
                }),
                status_code=200,
                headers={"Content-Type": "application/json"}
            )
            
    except Exception as e:
        logging.error(f'Unexpected error: {str(e)}')
        return func.HttpResponse(
            json.dumps({
                "error": "Internal server error",
                "timestamp": datetime.now().isoformat()
            }),
            status_code=500,
            headers={"Content-Type": "application/json"}
        )

@app.function_name(name="QueueTrigger")
@app.queue_trigger(arg_name="msg", queue_name="messages", connection="AzureWebJobsStorage")
def queue_trigger(msg: func.QueueMessage) -> None:
    """Queue trigger function - processes messages from storage queue"""
    logging.info('Python queue trigger function processed a queue item: %s',
                msg.get_body().decode('utf-8'))
    
    try:
        # Parse the queue message
        message_data = json.loads(msg.get_body().decode('utf-8'))
        
        # Store processed message in table storage
        table_client = get_table_service_client()
        table_name = "processedmessages"
        
        # Create table if it doesn't exist
        try:
            table_client.create_table(table_name)
        except Exception:
            pass  # Table might already exist
        
        # Insert entity into table
        entity = {
            "PartitionKey": "processed",
            "RowKey": f"msg-{datetime.now().strftime('%Y%m%d-%H%M%S-%f')}",
            "OriginalMessage": json.dumps(message_data),
            "ProcessedAt": datetime.now().isoformat(),
            "Status": "Completed"
        }
        
        table_client.get_table_client(table_name).create_entity(entity)
        logging.info(f'Message processed and stored in table: {entity["RowKey"]}')
        
    except Exception as e:
        logging.error(f'Error processing queue message: {str(e)}')

@app.function_name(name="BlobTrigger")
@app.blob_trigger(arg_name="myblob", path="uploads/{name}", connection="AzureWebJobsStorage")
def blob_trigger(myblob: func.InputStream) -> None:
    """Blob trigger function - processes new blobs in the uploads container"""
    logging.info(f"Python blob trigger function processed blob \n"
                f"Name: {myblob.name}\n"
                f"Blob Size: {myblob.length} bytes")
    
    try:
        # Read blob content
        blob_content = myblob.read()
        
        # Send message to queue for further processing
        queue_client = get_queue_service_client()
        queue_name = "messages"
        
        # Create queue if it doesn't exist
        try:
            queue_client.create_queue(queue_name)
        except Exception:
            pass  # Queue might already exist
        
        # Send message to queue
        message_data = {
            "type": "blob_uploaded",
            "blob_name": myblob.name,
            "blob_size": myblob.length,
            "processed_at": datetime.now().isoformat(),
            "content_preview": blob_content[:100].decode('utf-8', errors='ignore') if blob_content else "No content"
        }
        
        queue_client.get_queue_client(queue_name).send_message(
            json.dumps(message_data)
        )
        
        logging.info(f'Blob processing message sent to queue: {myblob.name}')
        
    except Exception as e:
        logging.error(f'Error processing blob: {str(e)}')

@app.function_name(name="TimerTrigger")
@app.timer_trigger(schedule="0 */5 * * * *", arg_name="myTimer")
def timer_trigger(myTimer: func.TimerRequest) -> None:
    """Timer trigger function - runs every 5 minutes"""
    utc_timestamp = datetime.utcnow().replace(
        tzinfo=datetime.timezone.utc).isoformat()

    if myTimer.past_due:
        logging.info('The timer is past due!')

    logging.info('Python timer trigger function ran at %s', utc_timestamp)
    
    try:
        # Create a heartbeat message in blob storage
        blob_client = get_blob_service_client()
        container_name = "heartbeat"
        blob_name = f"heartbeat-{datetime.now().strftime('%Y%m%d')}.json"
        
        # Create container if it doesn't exist
        try:
            blob_client.create_container(container_name)
        except Exception:
            pass
        
        # Update heartbeat data
        heartbeat_data = {
            "timestamp": utc_timestamp,
            "status": "healthy",
            "past_due": myTimer.past_due,
            "function": "TimerTrigger"
        }
        
        blob_client.get_blob_client(
            container=container_name, 
            blob=blob_name
        ).upload_blob(
            json.dumps(heartbeat_data, indent=2), 
            overwrite=True
        )
        
        logging.info(f'Heartbeat updated: {blob_name}')
        
    except Exception as e:
        logging.error(f'Error updating heartbeat: {str(e)}')

@app.function_name(name="HealthCheck")
@app.route(route="health", auth_level=func.AuthLevel.ANONYMOUS)
def health_check(req: func.HttpRequest) -> func.HttpResponse:
    """Health check endpoint"""
    try:
        # Test storage connectivity
        storage_status = {}
        
        try:
            blob_client = get_blob_service_client()
            blob_client.list_containers(max_results=1)
            storage_status["blob"] = "healthy"
        except Exception as e:
            storage_status["blob"] = f"error: {str(e)}"
        
        try:
            queue_client = get_queue_service_client()
            queue_client.list_queues(max_results=1)
            storage_status["queue"] = "healthy"
        except Exception as e:
            storage_status["queue"] = f"error: {str(e)}"
        
        try:
            table_client = get_table_service_client()
            table_client.list_tables(max_results=1)
            storage_status["table"] = "healthy"
        except Exception as e:
            storage_status["table"] = f"error: {str(e)}"
        
        health_data = {
            "status": "healthy",
            "timestamp": datetime.now().isoformat(),
            "storage": storage_status,
            "environment": {
                "storage_account": os.environ.get('STORAGE_ACCOUNT_NAME', 'not_configured'),
                "python_version": os.sys.version
            }
        }
        
        return func.HttpResponse(
            json.dumps(health_data, indent=2),
            status_code=200,
            headers={"Content-Type": "application/json"}
        )
        
    except Exception as e:
        logging.error(f'Health check failed: {str(e)}')
        return func.HttpResponse(
            json.dumps({
                "status": "unhealthy",
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }),
            status_code=503,
            headers={"Content-Type": "application/json"}
        )
