# Covlant CLI

Generate tests and chat with AI about your code.

## Overview

Covlant CLI helps developers generate tests for their code and provides AI-powered insights about their codebase. Supporting Go, Python, TypeScript, and JavaScript, it seamlessly integrates with your development workflow.

## Key Features

- **AI Test Generation** - Create tests for your code with a single command
- **Code Chat** - Ask questions about your codebase and get intelligent answers
- **Multi-Language Support** - Works with Go, Python, TypeScript, and JavaScript

## Installation

### Option 1: Bash Installation Script

```bash
# On macOS and Linux.
https://install.covlant.ai/install.sh | bash
```
```powershell
# On Windows.
powershell -ExecutionPolicy ByPass -c "irm https://install.covlant.ai/install.ps1 | iex"
```

### Option 2: Manual Installation

#### Linux/macOS
```bash
# Download latest release (.tar.gz) from https://github.com/covlant/covlant-cli/releases

# Extract the archive
tar -xzf covlant-cli-*.tar.gz

# Make executable
chmod +x covlant

# Add to PATH
sudo mv covlant /usr/local/bin/
```

#### Windows
```powershell
# Download latest release (.zip) from https://github.com/covlant/covlant-cli/releases

# Extract the ZIP file

# Option A: Using PowerShell (Run as Administrator)
# Create a directory in Program Files
New-Item -ItemType Directory -Path "C:\Program Files\Covlant" -Force

# Move the executable to the created directory
Move-Item -Path "PATH\TO\EXTRACTED\covlant.exe" -Destination "C:\Program Files\Covlant"

# Add to PATH environment variable
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\Program Files\Covlant", "Machine")

# Option B: Manual Windows Installation
# 1. Create a folder: C:\Program Files\Covlant
# 2. Move the covlant.exe file to this folder
# 3. Add C:\Program Files\Covlant to your PATH:
#    - Right-click on 'This PC' > Properties > Advanced system settings
#    - Click 'Environment Variables'
#    - Under System variables, select 'Path' and click 'Edit'
#    - Click 'New' and add 'C:\Program Files\Covlant'
#    - Click 'OK' on all dialogs
```

## Quick Start

### Authentication

```bash
covlant login
```

### Add a Repository

```bash
covlant add-repo -r /path/to/your/repo
```

### Generate Tests

```bash
# For a file
covlant gen-test path/to/file.go

# For a specific function
covlant gen-test path/to/file.go:FunctionName
```

### Chat About Your Code

```bash
covlant chat
```

## Command Reference

| Command | Purpose |
|---------|---------|
| `login` | Authenticate with Covlant |
| `gen-test` | Generate tests for your code |
| `chat` | Ask questions about your codebase |
| `add-repo` | Register a repository |
| `update` | Update to latest version |
| `info` | Show repository details |
| `logout` | End your session |

## Support

Need help? Contact us at [support@covlant.ai](mailto:support@covlant.ai) or visit [https://support.covlant.ai](https://support.covlant.ai).

## License

Copyright © 2025 Covlant. All rights reserved.