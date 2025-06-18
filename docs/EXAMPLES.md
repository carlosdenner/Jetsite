# Examples

This document provides practical examples of using the Jetsite script with different types of GitHub template repositories.

## Basic Usage Examples

### Example 1: Creating a React App

```bash
$ ./fork_template_repo.sh
📋 Please provide the template repository information:
Template repo (owner/repo) [owner/template-repo]: facebook/create-react-app
📝 Enter the name for your new repository:
New repository name: my-awesome-react-app

🚀 Creating repository 'my-awesome-react-app' from template 'facebook/create-react-app'...
✅ Template-based repository created successfully.

📥 Cloning repository to local machine...
   Repository URL: https://github.com/yourusername/my-awesome-react-app.git
Cloning into 'my-awesome-react-app'...

🎨 Opening project in VS Code...
✅ Project opened in VS Code successfully.

🎉 Setup complete! Your new project is ready.
   📁 Project directory: /current/path/my-awesome-react-app
   🌐 GitHub repository: https://github.com/yourusername/my-awesome-react-app

Happy coding! 🚀
```

### Example 2: Node.js Express Template

```bash
$ ./fork_template_repo.sh
📋 Please provide the template repository information:
Template repo (owner/repo) [owner/template-repo]: expressjs/express-generator
📝 Enter the name for your new repository:
New repository name: my-express-api

🚀 Creating repository 'my-express-api' from template 'expressjs/express-generator'...
✅ Template-based repository created successfully.
```

### Example 3: Python Flask Template

```bash
$ ./fork_template_repo.sh
📋 Please provide the template repository information:
Template repo (owner/repo) [owner/template-repo]: pallets/flask
📝 Enter the name for your new repository:
New repository name: my-flask-web-app

🚀 Creating repository 'my-flask-web-app' from template 'pallets/flask'...
✅ Template-based repository created successfully.
```

## Fallback Scenario Example

When the template creation method fails, the script automatically falls back to forking:

```bash
$ ./fork_template_repo.sh
📋 Please provide the template repository information:
Template repo (owner/repo) [owner/template-repo]: some-org/special-repo
📝 Enter the name for your new repository:
New repository name: my-special-project

🚀 Creating repository 'my-special-project' from template 'some-org/special-repo'...
⚠️  Template creation failed; falling back to forking method...
🔄 Renaming forked repository 'special-repo' to 'my-special-project'...
✅ Repository forked and renamed successfully.

📥 Cloning repository to local machine...
```

## Popular Template Repositories

Here are some popular GitHub template repositories you can use:

### Web Development
- `vercel/next.js` - Next.js React framework
- `vitejs/vite` - Modern frontend build tool
- `sveltejs/template` - Svelte application template
- `angular/angular-cli` - Angular CLI templates

### Backend Development
- `expressjs/express-generator` - Express.js web framework
- `nestjs/nest` - Node.js framework
- `spring-projects/spring-boot` - Spring Boot Java framework
- `django/django` - Django Python framework

### Mobile Development
- `facebook/react-native` - React Native mobile apps
- `flutter/flutter` - Flutter mobile development
- `ionic-team/ionic-framework` - Ionic hybrid apps

### Desktop Applications
- `electron/electron` - Electron desktop apps
- `tauri-apps/tauri` - Rust-based desktop apps

### Documentation
- `docsify-js/docsify` - Documentation sites
- `facebook/docusaurus` - Documentation platform
- `mkdocs/mkdocs` - Python documentation generator

## Error Scenarios

### GitHub CLI Not Installed
```bash
$ ./fork_template_repo.sh
❌ Error: GitHub CLI (gh) is not installed.
   Please install it from https://cli.github.com/
   After installation, run 'gh auth login' to authenticate.
```

### Empty Repository Name
```bash
$ ./fork_template_repo.sh
📋 Please provide the template repository information:
Template repo (owner/repo) [owner/template-repo]: facebook/react
📝 Enter the name for your new repository:
New repository name: 
❌ Error: New repository name cannot be empty.
```

### VS Code Not Available
```bash
🎨 Opening project in VS Code...
⚠️  VS Code not found in PATH. You can manually open the project:
   cd my-project && code .
```

## Advanced Usage Tips

### 1. Using with Different Default Templates

You can modify the `default_template_repo` variable in the script to set your most commonly used template:

```bash
# Change this line in the script
default_template_repo="your-org/your-favorite-template"
```

### 2. Batch Processing

For creating multiple projects, you can run the script multiple times or create a wrapper script:

```bash
#!/bin/bash
# batch_create.sh
projects=("project1" "project2" "project3")
template="your-org/template"

for project in "${projects[@]}"; do
    echo "$template" | echo "$project" | ./fork_template_repo.sh
done
```

### 3. Integration with Project Initialization

After the script completes, you might want to run additional setup commands:

```bash
$ ./fork_template_repo.sh
# After completion:
$ cd my-new-project
$ npm install
$ npm run dev
```

## Troubleshooting Common Issues

### Repository Already Exists
If you get an error that the repository already exists, either:
- Choose a different name
- Delete the existing repository from GitHub
- Use the existing repository

### Network Connectivity Issues
Ensure you have:
- Active internet connection
- GitHub access (not blocked by firewall)
- Valid GitHub authentication

### Permission Issues
Make sure:
- You're authenticated with GitHub CLI (`gh auth status`)
- You have permission to create repositories
- The template repository is accessible to you
