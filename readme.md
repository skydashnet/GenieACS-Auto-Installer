# 🚀 GenieACS Auto Installer


**Automated GenieACS installation scripts for Linux distributions**

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/skydashnet/GenieACS-Auto-Installer.svg)](https://github.com/skydashnet/GenieACS-Auto-Installer/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/skydashnet/GenieACS-Auto-Installer.svg)](https://github.com/skydashnet/GenieACS-Auto-Installer/network)
[![Issues](https://img.shields.io/github/issues/skydashnet/GenieACS-Auto-Installer.svg)](https://github.com/skydashnet/GenieACS-Auto-Installer/issues)

---

## ✨ Features

- 🎯 **One-click installation** - Simple curl command to get started
- 🛡️ **Auto database setup** - MongoDB or Redis/Valkey fallback
- 🔥 **Firewall configuration** - UFW rules automatically configured
- ⚙️ **Service management** - SystemD services with auto-restart
- 🎨 **Custom port support** - Configure your preferred UI port
- 📊 **Status verification** - Real-time service health checks
- 🔧 **Clean output** - Minimal noise, maximum clarity

## 🖥️ Supported Systems

| Distribution | Status | Script |
|-------------|--------|---------|
| **Arch Linux** | ✅ Supported | `genieacs-arch.sh` |
| **EndeavourOS** | ✅ Supported | `genieacs-arch.sh` |
| **Ubuntu 20.04** | ✅ Supported | `genieacs-ubuntu.sh` |
| **Ubuntu 22.04** | ✅ Supported | `genieacs-ubuntu.sh` |
| **Ubuntu 24.04** | ✅ Supported | `genieacs-ubuntu.sh` |
| **Debian** | ⚠️ Experimental | `genieacs-ubuntu.sh` |

---

## 🚀 Quick Start

### For Arch Linux / EndeavourOS

```bash
# Download and run the installer
curl -fsSL https://raw.githubusercontent.com/skydashnet/GenieACS-Auto-Installer/main/install.sh | sudo bash
```

### For Ubuntu / Debian

```bash
# Download and run the installer
curl -fsSL https://raw.githubusercontent.com/skydashnet/GenieACS-Auto-Installer/main/install-ubuntu.sh | sudo bash
```

---

## 🛠️ Manual Installation

If you prefer to download and inspect the script first:

### Arch Linux / EndeavourOS

```bash
# Download the script
wget https://raw.githubusercontent.com/skydashnet/GenieACS-Auto-Installer/main/install.sh

# Make it executable
chmod +x install.sh

# Run with sudo
sudo ./install.sh
```

### Ubuntu / Debian

```bash
# Download the script
wget https://raw.githubusercontent.com/skydashnet/GenieACS-Auto-Installer/main/install-ubuntu.sh

# Make it executable
chmod +x install-ubuntu.sh

# Run with sudo
sudo ./install-ubuntu.sh
```

---

## 📋 What Gets Installed?

The installer automatically sets up:

### 🗄️ Database Layer
- **MongoDB 6.0** (preferred) with official repositories
- **Redis/Valkey** as fallback for compatibility

### 🌐 GenieACS Components
- **GenieACS v1.2.13** via npm
- **CWMP Server** (Port 7547)
- **NBI API** (Port 7557) 
- **File Server** (Port 7567)
- **Web UI** (Port 3000 or custom)

### 🔧 System Configuration
- Dedicated `genieacs` system user
- SystemD service files with auto-restart
- UFW firewall rules
- Log rotation and directory structure

---

## 🎛️ Configuration

### Default Credentials
```
Username: admin
Password: admin
```

### Default Ports
- **Web UI**: 3000 (customizable during install)
- **CWMP**: 7547
- **NBI**: 7557  
- **File Server**: 7567

### Service Management

```bash
# Check all services
sudo systemctl status genieacs-{cwmp,nbi,fs,ui}

# View real-time logs
sudo journalctl -u genieacs-ui -f

# Restart a service
sudo systemctl restart genieacs-ui

# Stop all services
sudo systemctl stop genieacs-{cwmp,nbi,fs,ui}

# Start all services
sudo systemctl start genieacs-{cwmp,nbi,fs,ui}
```

---

## 🔍 Troubleshooting

### Service Won't Start?
```bash
# Check service status
sudo systemctl status genieacs-ui

# Check detailed logs
sudo journalctl -u genieacs-ui --no-pager

# Check configuration
cat /opt/genieacs/genieacs.env
```

### Can't Access Web UI?
```bash
# Check if port is open
sudo ufw status

# Verify service is listening
sudo netstat -tlnp | grep :3000

# Check firewall rules
sudo iptables -L
```

### Database Connection Issues?
```bash
# For MongoDB
sudo systemctl status mongod
mongosh --eval "db.runCommand({connectionStatus: 1})"

# For Redis
sudo systemctl status redis-server
redis-cli ping
```

---

## 🎨 Customization

### Change UI Port After Installation

1. Edit the environment file:
```bash
sudo nano /opt/genieacs/genieacs.env
```

2. Update the port:
```bash
GENIEACS_UI_PORT=8080
```

3. Update firewall and restart:
```bash
sudo ufw allow 8080/tcp
sudo systemctl restart genieacs-ui
```

### Custom Extensions

Place your custom extensions in:
```bash
/opt/genieacs/ext/
```

---

## 🔐 Security Considerations

- Change default admin credentials after first login
- Consider setting up SSL/TLS for production use
- Review firewall rules for your network requirements
- Regularly update GenieACS and system packages

---

## 📊 Performance Tuning

For high-traffic deployments, consider:

- Increasing Node.js memory limits
- Database optimization (indexes, memory allocation)
- Load balancing multiple GenieACS instances
- SSD storage for database operations

---

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Quick Contribution Guide

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes and test thoroughly
4. Submit a pull request with a clear description

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [GenieACS Project](https://genieacs.com/) for the excellent TR-069 ACS
- The open-source community for continuous improvements
- Contributors who help maintain and enhance these scripts

---

<div align="center">

If this helped you, please ⭐ star the repository!

</div>
