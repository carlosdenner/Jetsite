#!/usr/bin/env node

/**
 * Jetsite Agent - Self-hosted automation daemon
 * 
 * This agent polls for repository creation requests and automates
 * the entire Jetsite workflow including:
 * - Repository creation from templates
 * - Local cloning and setup
 * - VS Code launching
 * - Post-creation command execution
 * 
 * @author Jetsite Project
 * @version 1.0.0
 */

const express = require('express');
const cron = require('node-cron');
const axios = require('axios');
const { spawn, exec } = require('child_process');
const fs = require('fs-extra');
const path = require('path');
const winston = require('winston');
const bodyParser = require('body-parser');
const cors = require('cors');
const helmet = require('helmet');
const { v4: uuidv4 } = require('uuid');

require('dotenv').config();

// ============================================================================
// COMMAND LINE INTERFACE
// ============================================================================

const PACKAGE_VERSION = '1.0.0';

function showHelp() {
    console.log(`
Jetsite Agent - Node.js Implementation v${PACKAGE_VERSION}

DESCRIPTION:
   Self-hosted automation daemon for Jetsite repository creation.
   Provides REST API and optional external queue polling.

USAGE:
   node agent.js [options]

OPTIONS:
   --help, -h           Show this help message
   --version, -v        Show version information
   --port <number>      API server port (default: 3000)
   --work-dir <path>    Work directory (default: ./workspace)
   --poll-interval <cron> Cron pattern for polling (default: */30 * * * * *)
   --no-poll           Disable external queue polling
   --quiet             Reduce log output

ENVIRONMENT VARIABLES:
   PORT                 API server port
   HOST                 API server host (default: localhost)
   WORK_DIR            Work directory path
   JETSITE_SCRIPT      Path to Jetsite PowerShell script
   GITHUB_TOKEN        GitHub personal access token
   API_KEY             API authentication key
   QUEUE_URL           External queue endpoint URL
   POLL_INTERVAL       Cron pattern for queue polling

EXAMPLES:
   node agent.js                           # Start with defaults
   node agent.js --port 8080              # Start on port 8080
   node agent.js --no-poll --quiet        # API only, quiet mode
   
API ENDPOINTS:
   GET  /health                           # Health check
   GET  /status                           # Agent status
   POST /create-repository                # Create repository
   GET  /task/:id                         # Get task status

For more information, visit: https://github.com/your-username/jetsite
`);
}

function showVersion() {
    console.log(`Jetsite Agent v${PACKAGE_VERSION}`);
}

// Parse command line arguments
const args = process.argv.slice(2);
let config_overrides = {};

for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    
    switch (arg) {
        case '--help':
        case '-h':
            showHelp();
            process.exit(0);
            break;
            
        case '--version':
        case '-v':
            showVersion();
            process.exit(0);
            break;
            
        case '--port':
            if (i + 1 < args.length) {
                config_overrides.PORT = parseInt(args[++i]);
            } else {
                console.error('Error: --port requires a value');
                process.exit(1);
            }
            break;
            
        case '--work-dir':
            if (i + 1 < args.length) {
                config_overrides.WORK_DIR = args[++i];
            } else {
                console.error('Error: --work-dir requires a value');
                process.exit(1);
            }
            break;
            
        case '--poll-interval':
            if (i + 1 < args.length) {
                config_overrides.POLL_INTERVAL = args[++i];
            } else {
                console.error('Error: --poll-interval requires a value');
                process.exit(1);
            }
            break;
            
        case '--no-poll':
            config_overrides.QUEUE_URL = null;
            config_overrides.POLL_INTERVAL = null;
            break;
            
        case '--quiet':
            config_overrides.LOG_LEVEL = 'warn';
            break;
            
        default:
            if (arg.startsWith('-')) {
                console.error(`Error: Unknown option ${arg}`);
                console.error('Use --help for usage information');
                process.exit(1);
            }
            break;
    }
}

// ============================================================================
// CONFIGURATION
// ============================================================================

const CONFIG = {
    // Server configuration
    PORT: config_overrides.PORT || process.env.PORT || 3000,
    HOST: process.env.HOST || 'localhost',
      // Agent configuration
    POLL_INTERVAL: config_overrides.POLL_INTERVAL || process.env.POLL_INTERVAL || '*/30 * * * * *', // Every 30 seconds
    QUEUE_URL: config_overrides.QUEUE_URL !== undefined ? config_overrides.QUEUE_URL : process.env.QUEUE_URL || null, // External queue endpoint
    WORK_DIR: config_overrides.WORK_DIR || process.env.WORK_DIR || path.join(__dirname, 'workspace'),
      // Jetsite configuration
    JETSITE_SCRIPT: process.env.JETSITE_SCRIPT || path.join(__dirname, '..', 'fork_template_repo_simple.ps1'),
    AUTO_OPEN_VSCODE: process.env.AUTO_OPEN_VSCODE !== 'false',
    
    // GitHub configuration
    GITHUB_TOKEN: process.env.GITHUB_TOKEN,
      // Security
    API_KEY: process.env.API_KEY || 'your-secret-api-key',
    
    // Logging
    LOG_LEVEL: config_overrides.LOG_LEVEL || process.env.LOG_LEVEL || 'info'
};

// ============================================================================
// LOGGING SETUP
// ============================================================================

const logger = winston.createLogger({
    level: CONFIG.LOG_LEVEL,
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.errors({ stack: true }),
        winston.format.json()
    ),
    defaultMeta: { service: 'jetsite-agent' },
    transports: [
        new winston.transports.File({ filename: 'agent-error.log', level: 'error' }),
        new winston.transports.File({ filename: 'agent.log' }),
        new winston.transports.Console({
            format: winston.format.combine(
                winston.format.colorize(),
                winston.format.simple()
            )
        })
    ]
});

// ============================================================================
// TASK QUEUE
// ============================================================================

class TaskQueue {
    constructor() {
        this.tasks = [];
        this.processing = false;
    }

    add(task) {
        const taskWithId = {
            id: uuidv4(),
            createdAt: new Date(),
            status: 'pending',
            ...task
        };
        
        this.tasks.push(taskWithId);
        logger.info(`Task added: ${taskWithId.id}`, taskWithId);
        return taskWithId.id;
    }

    getNext() {
        return this.tasks.find(task => task.status === 'pending');
    }

    updateStatus(taskId, status, result = null, error = null) {
        const task = this.tasks.find(t => t.id === taskId);
        if (task) {
            task.status = status;
            task.updatedAt = new Date();
            if (result) task.result = result;
            if (error) task.error = error;
            logger.info(`Task ${taskId} status updated: ${status}`);
        }
    }

    getTask(taskId) {
        return this.tasks.find(t => t.id === taskId);
    }

    getAllTasks() {
        return this.tasks;
    }

    cleanup() {
        // Remove completed tasks older than 24 hours
        const cutoff = new Date(Date.now() - 24 * 60 * 60 * 1000);
        this.tasks = this.tasks.filter(task => 
            task.status === 'pending' || 
            task.status === 'processing' || 
            new Date(task.updatedAt || task.createdAt) > cutoff
        );
    }
}

const taskQueue = new TaskQueue();

// ============================================================================
// JETSITE AUTOMATION
// ============================================================================

class JetsiteAutomator {
    constructor() {
        this.ensureWorkDir();
    }

    async ensureWorkDir() {
        try {
            await fs.ensureDir(CONFIG.WORK_DIR);
            logger.info(`Work directory ensured: ${CONFIG.WORK_DIR}`);
        } catch (error) {
            logger.error('Failed to create work directory:', error);
        }
    }

    async checkDependencies() {
        const checks = {
            gh: await this.checkCommand('gh --version'),
            git: await this.checkCommand('git --version'),
            powershell: process.platform === 'win32' ? await this.checkCommand('powershell -Command "Write-Host OK"') : true,
            vscode: CONFIG.AUTO_OPEN_VSCODE ? await this.checkCommand('code --version') : true
        };

        logger.info('Dependency check:', checks);
        return checks;
    }

    async checkCommand(command) {
        return new Promise(resolve => {
            exec(command, (error) => {
                resolve(!error);
            });
        });
    }

    async executeTask(task) {
        logger.info(`Executing task: ${task.id}`, task);
        
        try {
            // Validate required parameters
            if (!task.template || !task.name) {
                throw new Error('Missing required parameters: template and name');
            }

            // Check dependencies
            const deps = await this.checkDependencies();
            if (!deps.gh || !deps.git) {
                throw new Error('Missing required dependencies: GitHub CLI or Git');
            }

            // Prepare command arguments
            const args = [
                '-template', task.template,
                '-name', task.name,
                '-quiet'
            ];

            if (task.visibility) {
                args.push('-visibility', task.visibility);
            }

            if (!CONFIG.AUTO_OPEN_VSCODE || task.noVSCode) {
                args.push('-noVSCode');
            }

            if (task.postCommands) {
                args.push('-postCommands', task.postCommands);
            }

            // Execute Jetsite script
            const result = await this.runJetsiteScript(args, task);
            
            // Run additional post-processing if specified
            if (task.postProcessing) {
                await this.runPostProcessing(task);
            }

            return {
                success: true,
                repositoryName: task.name,
                workingDirectory: path.join(CONFIG.WORK_DIR, task.name),
                ...result
            };

        } catch (error) {
            logger.error(`Task execution failed: ${task.id}`, error);
            throw error;
        }
    }    async runJetsiteScript(args, task) {
        return new Promise(async (resolve, reject) => {
            const scriptPath = CONFIG.JETSITE_SCRIPT;
            
            // Get GitHub token
            const githubToken = await getGitHubToken();
            if (!githubToken) {
                reject(new Error('GitHub authentication required. Please run: gh auth login'));
                return;
            }
            
            // Change to work directory and set up environment with GitHub auth
            const options = {
                cwd: CONFIG.WORK_DIR,
                stdio: ['pipe', 'pipe', 'pipe'],
                env: {
                    ...process.env,
                    GITHUB_TOKEN: githubToken,
                    GH_TOKEN: githubToken,
                    PATH: process.env.PATH
                }
            };

            let command, scriptArgs;
            
            if (process.platform === 'win32') {
                command = 'powershell';
                scriptArgs = ['-ExecutionPolicy', 'Bypass', '-File', scriptPath, ...args];
            } else {
                // For Linux/macOS, use the bash script
                const bashScript = scriptPath.replace('.ps1', '.sh');
                command = 'bash';
                scriptArgs = [bashScript, ...args];
            }            logger.info(`Running command: ${command} ${scriptArgs.join(' ')}`);
            
            const childProcess = spawn(command, scriptArgs, options);
            
            let stdout = '';
            let stderr = '';
            
            childProcess.stdout.on('data', (data) => {
                stdout += data.toString();
                logger.info(`[${task.id}] ${data.toString().trim()}`);
            });
            
            childProcess.stderr.on('data', (data) => {
                stderr += data.toString();
                logger.warn(`[${task.id}] ${data.toString().trim()}`);
            });
            
            childProcess.on('close', (code) => {
                if (code === 0) {
                    resolve({
                        exitCode: code,
                        stdout: stdout,
                        stderr: stderr
                    });
                } else {
                    reject(new Error(`Script exited with code ${code}\\n${stderr}`));
                }
            });
            
            childProcess.on('error', (error) => {
                reject(error);
            });
        });
    }

    async runPostProcessing(task) {
        if (task.postProcessing.startServer) {
            await this.startDevelopmentServer(task);
        }
        
        if (task.postProcessing.customCommands) {
            await this.runCustomCommands(task.postProcessing.customCommands, task);
        }
    }

    async startDevelopmentServer(task) {
        const projectPath = path.join(CONFIG.WORK_DIR, task.name);
        
        // Detect project type and start appropriate server
        if (await fs.pathExists(path.join(projectPath, 'package.json'))) {
            await this.runCommand('npm install && npm run dev', projectPath);
        } else if (await fs.pathExists(path.join(projectPath, 'requirements.txt'))) {
            await this.runCommand('pip install -r requirements.txt && python manage.py runserver', projectPath);
        }
    }

    async runCustomCommands(commands, task) {
        const projectPath = path.join(CONFIG.WORK_DIR, task.name);
        
        for (const command of commands) {
            try {
                await this.runCommand(command, projectPath);
                logger.info(`Custom command completed: ${command}`);
            } catch (error) {
                logger.warn(`Custom command failed: ${command}`, error);
            }
        }
    }

    async runCommand(command, cwd) {
        return new Promise((resolve, reject) => {
            exec(command, { cwd }, (error, stdout, stderr) => {
                if (error) {
                    reject(error);
                } else {
                    resolve({ stdout, stderr });
                }
            });
        });
    }
}

const automator = new JetsiteAutomator();

// ============================================================================
// TASK PROCESSOR
// ============================================================================

async function processNextTask() {
    if (taskQueue.processing) return;
    
    const task = taskQueue.getNext();
    if (!task) return;
    
    taskQueue.processing = true;
    taskQueue.updateStatus(task.id, 'processing');
    
    try {
        const result = await automator.executeTask(task);
        taskQueue.updateStatus(task.id, 'completed', result);
        logger.info(`Task completed successfully: ${task.id}`);
    } catch (error) {
        taskQueue.updateStatus(task.id, 'failed', null, error.message);
        logger.error(`Task failed: ${task.id}`, error);
    } finally {
        taskQueue.processing = false;
    }
}

// ============================================================================
// WEB API
// ============================================================================

const app = express();

// Middleware
app.use(helmet());
app.use(cors());
app.use(bodyParser.json());

// Authentication middleware (disabled for local development)
const authenticate = (req, res, next) => {
    // Skip authentication if API_KEY is default/development value
    if (CONFIG.API_KEY === 'your-secret-api-key' || CONFIG.API_KEY === 'dev-mode') {
        return next();
    }
    
    const apiKey = req.headers['x-api-key'] || req.query.apiKey;
    if (apiKey !== CONFIG.API_KEY) {
        return res.status(401).json({ error: 'Invalid API key' });
    }
    next();
};

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        version: '1.0.0'
    });
});

// Status endpoint
app.get('/status', authenticate, (req, res) => {
    res.json({
        tasks: {
            pending: taskQueue.tasks.filter(t => t.status === 'pending').length,
            processing: taskQueue.tasks.filter(t => t.status === 'processing').length,
            completed: taskQueue.tasks.filter(t => t.status === 'completed').length,
            failed: taskQueue.tasks.filter(t => t.status === 'failed').length,
            total: taskQueue.tasks.length
        },
        agent: {
            processing: taskQueue.processing,
            workDir: CONFIG.WORK_DIR,
            lastCleanup: new Date().toISOString()
        }
    });
});

// Create repository endpoint
app.post('/create-repository', authenticate, (req, res) => {
    try {
        const { template, name, visibility, noVSCode, postCommands, postProcessing } = req.body;
        
        if (!template || !name) {
            return res.status(400).json({ 
                error: 'Missing required fields: template and name' 
            });
        }
        
        const taskId = taskQueue.add({
            template,
            name,
            visibility: visibility || 'public',
            noVSCode: noVSCode || false,
            postCommands,
            postProcessing
        });
        
        res.json({
            taskId,
            status: 'queued',
            message: 'Repository creation task queued successfully'
        });
        
    } catch (error) {
        logger.error('Error creating task:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Get task status endpoint
app.get('/task/:taskId', authenticate, (req, res) => {
    const task = taskQueue.getTask(req.params.taskId);
    
    if (!task) {
        return res.status(404).json({ error: 'Task not found' });
    }
    
    res.json(task);
});

// List all tasks endpoint
app.get('/tasks', authenticate, (req, res) => {
    const { status, limit = 50 } = req.query;
    
    let tasks = taskQueue.getAllTasks();
    
    if (status) {
        tasks = tasks.filter(t => t.status === status);
    }
    
    tasks = tasks.slice(0, parseInt(limit));
    
    res.json({
        tasks,
        total: taskQueue.getAllTasks().length
    });
});

// ============================================================================
// EXTERNAL QUEUE POLLING (Optional)
// ============================================================================

async function pollExternalQueue() {
    if (!CONFIG.QUEUE_URL) return;
    
    try {
        const response = await axios.get(CONFIG.QUEUE_URL, {
            headers: {
                'Authorization': `Bearer ${CONFIG.GITHUB_TOKEN}`,
                'X-API-Key': CONFIG.API_KEY
            }
        });
        
        if (response.data && response.data.tasks) {
            for (const task of response.data.tasks) {
                taskQueue.add(task);
                
                // Acknowledge task received
                if (task.id) {
                    await axios.post(`${CONFIG.QUEUE_URL}/ack/${task.id}`, {}, {
                        headers: { 'X-API-Key': CONFIG.API_KEY }
                    });
                }
            }
        }
    } catch (error) {
        logger.warn('Failed to poll external queue:', error.message);
    }
}

// ============================================================================
// GITHUB AUTHENTICATION HELPER
// ============================================================================

async function getGitHubToken() {
    // First try environment variables
    if (process.env.GITHUB_TOKEN) {
        return process.env.GITHUB_TOKEN;
    }
    
    if (process.env.GH_TOKEN) {
        return process.env.GH_TOKEN;
    }
    
    // Try to get token from GitHub CLI
    try {
        const { exec } = require('child_process');
        const { promisify } = require('util');
        const execAsync = promisify(exec);
        
        const { stdout } = await execAsync('gh auth token', { encoding: 'utf8' });
        const token = stdout.trim();
        
        if (token && token.startsWith('gho_')) {
            logger.info('GitHub token obtained from CLI');
            return token;
        }
    } catch (error) {
        logger.warn('Could not get GitHub token from CLI:', error.message);
    }
    
    return null;
}

async function verifyGitHubAuth() {
    const token = await getGitHubToken();
    
    if (!token) {
        logger.error('No GitHub token found. Please run: gh auth login');
        return false;
    }
    
    try {
        const https = require('https');
        const options = {
            hostname: 'api.github.com',
            path: '/user',
            method: 'GET',
            headers: {
                'Authorization': `token ${token}`,
                'User-Agent': 'jetsite-agent'
            }
        };
        
        return new Promise((resolve) => {
            const req = https.request(options, (res) => {
                if (res.statusCode === 200) {
                    logger.info('GitHub authentication verified');
                    resolve(true);
                } else {
                    logger.error(`GitHub auth failed: ${res.statusCode}`);
                    resolve(false);
                }
            });
            
            req.on('error', (error) => {
                logger.error('GitHub auth error:', error.message);
                resolve(false);
            });
            
            req.end();
        });
    } catch (error) {
        logger.error('GitHub auth verification failed:', error.message);
        return false;
    }
}

// ============================================================================
// STARTUP & CLEANUP
// ============================================================================

// Scheduled task processing
cron.schedule(CONFIG.POLL_INTERVAL, processNextTask);

// Cleanup old tasks every hour
cron.schedule('0 * * * *', () => {
    taskQueue.cleanup();
    logger.info('Task queue cleanup completed');
});

// External queue polling (if configured)
if (CONFIG.QUEUE_URL) {
    cron.schedule('*/10 * * * * *', pollExternalQueue); // Every 10 seconds
    logger.info(`External queue polling enabled: ${CONFIG.QUEUE_URL}`);
}

// Start the server
app.listen(CONFIG.PORT, CONFIG.HOST, async () => {
    logger.info(`🚀 Jetsite Agent started on http://${CONFIG.HOST}:${CONFIG.PORT}`);
    logger.info(`📁 Work directory: ${CONFIG.WORK_DIR}`);
    logger.info(`⚙️  Script path: ${CONFIG.JETSITE_SCRIPT}`);
    logger.info(`🔄 Poll interval: ${CONFIG.POLL_INTERVAL}`);
    
    // Verify GitHub authentication
    const isAuthValid = await verifyGitHubAuth();
    if (isAuthValid) {
        logger.info(`✅ GitHub authentication verified`);
    } else {
        logger.error(`❌ GitHub authentication failed - repository creation will fail`);
        logger.error(`   Please run: gh auth login`);
    }
});

// Graceful shutdown
process.on('SIGTERM', () => {
    logger.info('Received SIGTERM, shutting down gracefully');
    process.exit(0);
});

process.on('SIGINT', () => {
    logger.info('Received SIGINT, shutting down gracefully');
    process.exit(0);
});

module.exports = app;
