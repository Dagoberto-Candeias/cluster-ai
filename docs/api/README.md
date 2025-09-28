# Cluster AI Dashboard API Documentation

## Overview

The Cluster AI Dashboard API provides REST endpoints and WebSocket connections for monitoring and managing the distributed AI cluster. Built with FastAPI, it offers real-time monitoring, worker management, authentication, and system metrics.

## Base URL
```
http://localhost:8000
```

## Authentication

All API endpoints (except `/`, `/health`, and `/auth/login`) require JWT authentication.

### Login
```http
POST /auth/login
Content-Type: application/json

{
  "username": "admin",
  "password": "admin123"
}
```

Response:
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "token_type": "bearer"
}
```

Use the token in Authorization header:
```
Authorization: Bearer <access_token>
```

## Endpoints

### Health & Status

#### GET /health
Health check endpoint.

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00"
}
```

#### GET /auth/me
Get current user information.

**Response:**
```json
{
  "username": "admin",
  "email": "admin@cluster-ai.local",
  "full_name": "Administrator",
  "disabled": false
}
```

### Cluster Management

#### GET /cluster/status
Get comprehensive cluster status including services, workers, and performance metrics.

**Response:**
```json
{
  "total_workers": 3,
  "active_workers": 2,
  "total_cpu": 127.5,
  "total_memory": 234.8,
  "status": "healthy",
  "ollama_running": true,
  "dask_running": true,
  "webui_running": true,
  "dask_tasks_completed": 150,
  "dask_tasks_failed": 2,
  "dask_tasks_pending": 5,
  "dask_tasks_processing": 3,
  "dask_task_throughput": 2.5,
  "dask_avg_task_time": 45.2
}
```

### Workers Management

#### GET /workers
Get information about all workers.

**Query Parameters:**
- `limit` (optional): Maximum number of workers to return

**Response:**
```json
[
  {
    "id": "worker-001",
    "name": "Worker Node 1",
    "status": "active",
    "ip_address": "192.168.1.101",
    "cpu_usage": 45.2,
    "memory_usage": 67.8,
    "last_seen": "2024-01-15T10:25:00"
  }
]
```

#### GET /workers/{worker_id}
Get information about a specific worker.

**Response:** Same as individual worker object above.

#### POST /workers/{worker_id}/start
Start a specific worker.

**Response:**
```json
{
  "message": "Worker worker-001 started successfully"
}
```

#### POST /workers/{worker_id}/stop
Stop a specific worker.

**Response:**
```json
{
  "message": "Worker worker-001 stopped successfully"
}
```

#### POST /workers/{worker_id}/restart
Restart a specific worker.

**Response:**
```json
{
  "message": "Worker worker-001 restart initiated successfully"
}
```

### Metrics & Monitoring

#### GET /metrics/system
Get system metrics history.

**Query Parameters:**
- `limit` (optional, default: 100): Number of data points to return

**Response:**
```json
[
  {
    "timestamp": "2024-01-15T10:30:00",
    "cpu_percent": 45.2,
    "memory_percent": 67.8,
    "disk_percent": 25.4,
    "network_rx": 1250000.0,
    "network_tx": 980000.0
  }
]
```

#### GET /alerts
Get recent system alerts.

**Query Parameters:**
- `limit` (optional, default: 50): Number of alerts to return

**Response:**
```json
[
  {
    "timestamp": "2024-01-15T10:25:00",
    "severity": "WARNING",
    "component": "CPU",
    "message": "CPU usage above 80%"
  }
]
```

#### GET /monitoring/status
Get overall monitoring system status.

**Response:**
```json
{
  "monitoring_active": true,
  "last_update": "2024-01-15T10:30:00",
  "alerts_summary": {
    "critical": 0,
    "warning": 2,
    "info": 5,
    "total": 7
  },
  "services_status": {
    "ollama": true,
    "dask": true,
    "webui": true
  },
  "cluster_health": "healthy"
}
```

### Logs

#### GET /logs
Get system logs with optional filtering.

**Query Parameters:**
- `limit` (optional, default: 100): Number of log entries to return
- `level` (optional): Filter by log level (ERROR, WARNING, INFO, DEBUG)
- `component` (optional): Filter by component (SYSTEM, DASK, OLLAMA, etc.)

**Response:**
```json
[
  {
    "timestamp": "2024-01-15T10:25:00",
    "level": "INFO",
    "component": "SYSTEM",
    "message": "Worker worker-001 connected",
    "raw": "[2024-01-15 10:25:00] [INFO] [SYSTEM] Worker worker-001 connected"
  }
]
```

### Settings

#### GET /settings
Get current system settings.

**Response:**
```json
{
  "monitoring_enabled": true,
  "update_interval": 5,
  "alert_threshold_cpu": 80,
  "alert_threshold_memory": 80,
  "alert_threshold_disk": 90,
  "email_notifications": false,
  "slack_notifications": false,
  "notification_email": "",
  "session_timeout": 30,
  "max_login_attempts": 5,
  "log_level": "INFO",
  "backup_enabled": true,
  "backup_interval": 24
}
```

#### POST /settings
Update system settings.

**Request Body:** Partial or complete settings object

**Response:**
```json
{
  "message": "Settings updated successfully",
  "settings": { ... }
}
```

### WebSocket Connections

#### GET /ws/connections
Get information about active WebSocket connections.

**Response:**
```json
{
  "active_connections": 3,
  "clients": [
    {
      "client_id": "dashboard-001",
      "connected_at": "2024-01-15T10:20:00"
    }
  ]
}
```

## WebSocket API

### Connection
```
ws://localhost:8000/ws/{client_id}
```

### Real-time Updates
The server broadcasts real-time updates every 3 seconds:

```json
{
  "type": "realtime_update",
  "timestamp": "2024-01-15T10:30:00",
  "data": {
    "system_metrics": {
      "cpu_percent": 45.2,
      "memory_percent": 67.8,
      "disk_percent": 25.4,
      "network_rx": 1250000.0,
      "network_tx": 980000.0
    },
    "cluster_status": {
      "total_workers": 3,
      "active_workers": 2,
      "status": "healthy"
    },
    "alerts_count": 7,
    "workers_count": 3,
    "active_workers": 2
  }
}
```

### Client Messages
Clients can send messages to the server:

```json
{
  "type": "ping",
  "data": "Hello server"
}
```

Server responds with acknowledgment:
```json
{
  "type": "ack",
  "message": "Message received",
  "timestamp": "2024-01-15T10:30:00"
}
```

## Error Responses

All endpoints return standard HTTP status codes:

- `200`: Success
- `400`: Bad Request
- `401`: Unauthorized
- `404`: Not Found
- `500`: Internal Server Error

Error response format:
```json
{
  "detail": "Error description"
}
```

## Rate Limiting

API endpoints are protected with rate limiting:
- Authenticated requests: 100 requests per minute
- Unauthenticated requests: 10 requests per minute

## Caching

Several endpoints implement intelligent caching:
- `/cluster/status`: 30 seconds
- `/workers`: 20 seconds
- `/metrics/system`: 15 seconds
- `/alerts`: 10 seconds

## Performance

- **Response Compression**: GZip compression for responses > 1KB
- **Connection Pooling**: Efficient database connections
- **Async Operations**: Non-blocking I/O operations
- **Background Tasks**: Real-time updates run in background

## Development

### Running Locally
```bash
cd web-dashboard/backend
python main_fixed.py
```

### Testing API
```bash
# Get health status
curl http://localhost:8000/health

# Login
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "admin123"}'

# Get cluster status (with token)
curl -H "Authorization: Bearer <token>" \
  http://localhost:8000/cluster/status
```

## Troubleshooting

### Common Issues

1. **401 Unauthorized**
   - Check if JWT token is valid and not expired
   - Verify token format: `Bearer <token>`

2. **500 Internal Server Error**
   - Check server logs for detailed error information
   - Verify all required services are running (Dask, Ollama, etc.)

3. **WebSocket Connection Failed**
   - Ensure server is running on port 8000
   - Check firewall settings
   - Verify client_id is provided in URL

4. **Slow Responses**
   - Check system resources (CPU, memory)
   - Verify cache is working (check response headers)
   - Monitor active connections

### Monitoring

- **Health Checks**: Regular health checks every 30 seconds
- **Metrics Collection**: System metrics collected every 5 seconds
- **Log Rotation**: Automatic log rotation to prevent disk space issues
- **Connection Monitoring**: Track active WebSocket connections

## Security Considerations

- JWT tokens expire after 30 minutes
- All sensitive operations require authentication
- Input validation on all endpoints
- CORS configured for frontend domains only
- Rate limiting prevents abuse
- Audit logging for all operations

## Future Enhancements

- GraphQL API support
- API versioning
- Bulk operations
- Advanced filtering and pagination
- Webhook notifications
- API key authentication
