# Jetsite Agent Documentation

The Jetsite Agent is a self-hosted automation system that enables programmatic creation of GitHub repositories from templates. It provides both REST API and queue-based interfaces for integration with CI/CD pipelines, web applications, and automation workflows.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [API Reference](#api-reference)
- [Deployment](#deployment)
- [Troubleshooting](#troubleshooting)

## Overview

The Jetsite Agent consists of multiple implementation options:

### 1. **Node.js Agent** (`agent.js`)
- Full-featured REST API server
- External queue polling support
- Comprehensive logging and monitoring
- Production-ready with PM2 support

### 2. **PowerShell Agent** (`jetsite-agent.ps1`)
- Native Windows PowerShell implementation
- Lightweight and easy to deploy
- Built-in HTTP server
- Perfect for Windows environments

## Features

✅ **Repository Automation**
- Create repositories from GitHub templates
- Clone repositories locally
- Automatic VS Code integration
- Post-creation command execution

✅ **Task Management**
- Concurrent task processing
- Task queue with status tracking
- Automatic retry and error handling
- Task cleanup and retention

✅ **API Integration**
- RESTful API endpoints
- Authentication and security
- Real-time task monitoring
- Health checks and status reporting

✅ **Enterprise Ready**
- External queue integration
- Logging and monitoring
- Scalable architecture
- Production deployment support

## Installation

### Node.js Agent

1. **Install Dependencies**
   ```bash
   cd agent
   npm install
   ```

2. **Configure Environment**
   ```bash
   cp .env.example .env
   # Edit .env with your settings
   ```

3. **Start the Agent**
   ```bash
   # Development
   npm run dev
   
   # Production
   npm start
   
   # As daemon with PM2
   npm run daemon
   ```

### PowerShell Agent

1. **Install the Agent**
   ```powershell
   .\jetsite-agent.ps1 -Install
   ```

2. **Start the Agent**
   ```powershell
   .\jetsite-agent.ps1 -Start
   ```

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | API server port | `3000` |
| `WORK_DIR` | Repository workspace directory | `./workspace` |
| `GITHUB_TOKEN` | GitHub personal access token | *required* |
| `API_KEY` | API authentication key | *required* |
| `AUTO_OPEN_VSCODE` | Auto-open VS Code | `true` |
| `POLL_INTERVAL` | Task polling interval | `*/30 * * * * *` |

### GitHub Token Setup

1. Go to GitHub Settings → Developer settings → Personal access tokens
2. Create a token with these scopes:
   - `repo` (full repository access)
   - `admin:org` (if working with organization templates)
3. Add the token to your `.env` file

## Usage

### Creating Repositories via API

**Basic Repository Creation:**
```bash
curl -X POST http://localhost:3000/create-repository \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-api-key" \
  -d '{
    "template": "facebook/react",
    "name": "my-awesome-app",
    "visibility": "public"
  }'
```

**Advanced Repository Creation:**
```bash
curl -X POST http://localhost:3000/create-repository \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-api-key" \
  -d '{
    "template": "vercel/next.js",
    "name": "my-next-app",
    "visibility": "private",
    "noVSCode": false,
    "postCommands": "npm install; npm run dev",
    "postProcessing": {
      "startServer": true,
      "customCommands": ["npm test", "npm run build"]
    }
  }'
```

### Task Management

**Check Task Status:**
```bash
curl -H "X-API-Key: your-api-key" \
  http://localhost:3000/task/abc123def
```

**List All Tasks:**
```bash
curl -H "X-API-Key: your-api-key" \
  http://localhost:3000/tasks?status=completed&limit=10
```

**Agent Status:**
```bash
curl -H "X-API-Key: your-api-key" \
  http://localhost:3000/status
```

### Integration Examples

#### CI/CD Pipeline Integration

**GitHub Actions Example:**
```yaml
name: Create Development Environment
on:
  workflow_dispatch:
    inputs:
      template:
        description: 'Template repository'
        required: true
        default: 'my-org/api-template'
      name:
        description: 'New repository name'
        required: true

jobs:
  create-repo:
    runs-on: ubuntu-latest
    steps:
      - name: Create Repository
        run: |
          curl -X POST ${{ secrets.JETSITE_AGENT_URL }}/create-repository \
            -H "Content-Type: application/json" \
            -H "X-API-Key: ${{ secrets.JETSITE_API_KEY }}" \
            -d '{
              "template": "${{ github.event.inputs.template }}",
              "name": "${{ github.event.inputs.name }}",
              "visibility": "private",
              "postCommands": "npm install && npm run setup"
            }'
```

#### Web Application Integration

**JavaScript Example:**
```javascript
class JetsiteClient {
  constructor(baseUrl, apiKey) {
    this.baseUrl = baseUrl;
    this.apiKey = apiKey;
  }

  async createRepository(options) {
    const response = await fetch(`${this.baseUrl}/create-repository`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-API-Key': this.apiKey
      },
      body: JSON.stringify(options)
    });
    
    return response.json();
  }

  async getTaskStatus(taskId) {
    const response = await fetch(`${this.baseUrl}/task/${taskId}`, {
      headers: { 'X-API-Key': this.apiKey }
    });
    
    return response.json();
  }
}

// Usage
const client = new JetsiteClient('http://localhost:3000', 'your-api-key');

const result = await client.createRepository({
  template: 'facebook/react',
  name: 'my-new-project',
  visibility: 'public'
});

console.log('Task created:', result.taskId);
```

#### PowerShell Integration

```powershell
# PowerShell client example
function New-JetsiteRepository {
    param(
        [string]$Template,
        [string]$Name,
        [string]$Visibility = "public",
        [string]$ApiUrl = "http://localhost:3001",
        [string]$ApiKey = "your-api-key"
    )
    
    $body = @{
        template = $Template
        name = $Name
        visibility = $Visibility
    } | ConvertTo-Json
    
    $headers = @{
        "Content-Type" = "application/json"
        "X-API-Key" = $ApiKey
    }
    
    $response = Invoke-RestMethod -Uri "$ApiUrl/create-repository" -Method POST -Body $body -Headers $headers
    
    return $response
}

# Usage
$result = New-JetsiteRepository -Template "microsoft/vscode-extension-samples" -Name "my-vscode-extension"
Write-Host "Task ID: $($result.taskId)"
```

## API Reference

### Endpoints

#### `GET /health`
Health check endpoint.

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-06-18T10:30:00.000Z",
  "uptime": 3600,
  "version": "1.0.0"
}
```

#### `GET /status`
Get agent status and statistics.

**Headers:**
- `X-API-Key`: Authentication key

**Response:**
```json
{
  "tasks": {
    "pending": 2,
    "processing": 1,
    "completed": 15,
    "failed": 0,
    "total": 18
  },
  "agent": {
    "processing": true,
    "workDir": "./workspace",
    "lastCleanup": "2025-06-18T10:00:00.000Z"
  }
}
```

#### `POST /create-repository`
Create a new repository from a template.

**Headers:**
- `X-API-Key`: Authentication key
- `Content-Type`: application/json

**Body:**
```json
{
  "template": "owner/repository-name",
  "name": "new-repository-name",
  "visibility": "public|private",
  "noVSCode": false,
  "postCommands": "npm install; npm start",
  "postProcessing": {
    "startServer": true,
    "customCommands": ["npm test"]
  }
}
```

**Response:**
```json
{
  "taskId": "abc123def",
  "status": "queued",
  "message": "Repository creation task queued successfully"
}
```

#### `GET /task/{taskId}`
Get task status and details.

**Headers:**
- `X-API-Key`: Authentication key

**Response:**
```json
{
  "id": "abc123def",
  "template": "facebook/react",
  "name": "my-app",
  "status": "completed",
  "createdAt": "2025-06-18T10:00:00.000Z",
  "startedAt": "2025-06-18T10:00:30.000Z",
  "completedAt": "2025-06-18T10:02:15.000Z",
  "result": {
    "success": true,
    "repositoryName": "my-app",
    "workingDirectory": "./workspace/my-app"
  }
}
```

#### `GET /tasks`
List tasks with optional filtering.

**Headers:**
- `X-API-Key`: Authentication key

**Query Parameters:**
- `status`: Filter by status (pending, processing, completed, failed)
- `limit`: Maximum number of results (default: 50)

**Response:**
```json
{
  "tasks": [...],
  "total": 25
}
```

## Deployment

### Production Deployment (Node.js)

1. **Install PM2**
   ```bash
   npm install -g pm2
   ```

2. **Configure Ecosystem**
   ```bash
   # ecosystem.config.js is included
   pm2 start ecosystem.config.js
   ```

3. **Setup Process Monitoring**
   ```bash
   pm2 startup
   pm2 save
   ```

### Docker Deployment

**Dockerfile:**
```dockerfile
FROM node:18-alpine

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 3000
CMD ["npm", "start"]
```

**Docker Compose:**
```yaml
version: '3.8'
services:
  jetsite-agent:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - GITHUB_TOKEN=${GITHUB_TOKEN}
      - API_KEY=${API_KEY}
    volumes:
      - ./workspace:/app/workspace
      - ./logs:/app/logs
    restart: unless-stopped
```

### Windows Service (PowerShell)

Use tools like NSSM to run the PowerShell agent as a Windows service:

```bash
nssm install JetsiteAgent
nssm set JetsiteAgent Application powershell.exe
nssm set JetsiteAgent AppParameters "-ExecutionPolicy Bypass -File C:\path\to\jetsite-agent.ps1 -Start"
nssm set JetsiteAgent AppDirectory C:\path\to\agent
nssm start JetsiteAgent
```

## Troubleshooting

### Common Issues

#### GitHub CLI Authentication
```bash
# Check authentication
gh auth status

# Re-authenticate if needed
gh auth login
```

#### Permission Issues
- Ensure the agent has write access to the work directory
- Verify GitHub token has required repository permissions
- Check file system permissions for cloned repositories

#### VS Code Integration
```bash
# Verify VS Code CLI is available
code --version

# Add VS Code to PATH if needed (Windows)
setx PATH "%PATH%;C:\Users\username\AppData\Local\Programs\Microsoft VS Code\bin"
```

#### Port Conflicts
```bash
# Check if port is in use
netstat -an | findstr :3000

# Kill process using port (Windows)
netstat -ano | findstr :3000
taskkill /PID <process_id> /F
```

### Logging and Debugging

#### Node.js Agent
```bash
# Enable debug logging
DEBUG=jetsite:* npm start

# View logs
tail -f agent.log
tail -f agent-error.log
```

#### PowerShell Agent
```powershell
# Enable verbose logging
.\jetsite-agent.ps1 -Start -LogLevel Debug

# View logs
Get-Content .\jetsite-agent-*.log -Wait
```

### Performance Tuning

#### Concurrent Tasks
Adjust `MAX_CONCURRENT_TASKS` based on system resources:
- **Low-end systems**: 1-2 concurrent tasks
- **Mid-range systems**: 3-5 concurrent tasks  
- **High-end systems**: 5-10 concurrent tasks

#### Memory Management
Monitor memory usage and adjust Node.js heap size if needed:
```bash
node --max-old-space-size=4096 agent.js
```

## Support

For additional support:
- 📖 Review the main [Jetsite documentation](../README.md)
- 🐛 Report issues on GitHub
- 💡 Check [examples](../docs/EXAMPLES.md) for common use cases
- 🤝 Contribute improvements via pull requests
