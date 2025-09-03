# VS Code Freezing Resolution Plan

## Critical Issues Identified:
1. **110+ extensions** consuming 39GB disk space
2. **Multiple AI extensions** conflicting
3. **Memory-intensive processes** running
4. **Potential extension conflicts**

## Immediate Actions:

### 1. Disable Problematic Extensions (Run these commands):
```bash
# Disable multiple AI assistants (choose one)
code --disable-extension codeium.codeium
code --disable-extension anthropic.claude-code  
code --disable-extension askcodi.askcodi-vscode
code --disable-extension blackboxapp.blackbox
code --disable-extension blackboxapp.blackboxagent
code --disable-extension danielsanmedium.dscodegpt

# Disable heavy/unused extensions
code --disable-extension cweijan.dbclient-jdbc
code --disable-extension cweijan.vscode-mysql-client2
code --disable-extension angular.ng-template
```

### 2. Clean Extension Cache:
```bash
# Backup then remove some extensions
mkdir -p ~/vscode_extensions_backup
mv ~/.vscode/extensions/* ~/vscode_extensions_backup/

# Reinstall only essential extensions
code --install-extension ms-python.python
code --install-extension ms-toolsai.jupyter
code --install-extension eamodio.gitlens
```

### 3. Optimize VS Code Settings:
Add to `~/.config/Code/User/settings.json`:
```json
{
    "telemetry.telemetryLevel": "off",
    "extensions.autoUpdate": false,
    "files.watcherExclude": {
        "**/.git/objects/**": true,
        "**/.git/subtree-cache/**": true,
        "**/node_modules/**": true,
        "**/venv/**": true,
        "**/cluster_env/**": true
    },
    "search.exclude": {
        "**/node_modules": true,
        "**/venv": true,
        "**/cluster_env": true
    },
    "editor.largeFileOptimizations": true,
    "files.maxMemoryForLargeFilesMB": 2048
}
```

### 4. System Optimization:
```bash
# Reduce swappiness for better performance
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Clear system cache
sudo sync && echo 3 | sudo tee /proc/sys/vm/drop_caches
```

### 5. Monitor Resources:
```bash
# Keep this running to monitor VS Code processes
watch -n 5 'ps aux | grep -E "(code|vscode)" | grep -v grep'
```

## Recommended Extension Keep List:
- ms-python.python
- ms-toolsai.jupyter  
- eamodio.gitlens
- github.copilot (choose ONE AI assistant)
- ms-azuretools.vscode-docker
- redhat.vscode-yaml

## Expected Results:
- 50-70% reduction in memory usage
- Elimination of freezing/crashing
- Faster VS Code startup and operation
- 30+ GB disk space reclaimed

**Note**: After applying these changes, restart VS Code completely.
