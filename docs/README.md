# DPP Documentation

Welcome to the DPP (Digital Product Passport) documentation!

## 📚 Documentation Index

### Getting Started

- **[Quick Mode Reference](DUAL_MODE_QUICK.md)** ⭐ - Start here! One-page quick start guide
- **[Dual Setup Guide](DUAL_SETUP_GUIDE.md)** - Complete guide for running in SQLite or PostgreSQL mode
- **[Local Development Setup](LOCAL_DEV.md)** - Detailed local development instructions

### Architecture & Design

- **[Architecture Overview](LOCAL_DEV_ARCHITECTURE.md)** - System architecture and design decisions
- **[Local Dev Setup Summary](LOCAL_DEV_SETUP_SUMMARY.md)** - Summary of local dev configuration

### Reference

- **[Quick Reference](QUICK_REFERENCE.md)** - Common commands and patterns
- **[Dual Setup Summary](DUAL_SETUP_SUMMARY.md)** - Summary of dual mode capabilities
- **[Changes Summary](CHANGES_SUMMARY.md)** - Recent changes and updates

---

## 🎯 Common Tasks

### I want to...

| Task | Documentation |
|------|---------------|
| **Start quickly for a demo** | [Quick Mode Reference](DUAL_MODE_QUICK.md) |
| **Run without Docker** | [Dual Setup Guide](DUAL_SETUP_GUIDE.md) → Local Development Mode |
| **Deploy for production** | [Dual Setup Guide](DUAL_SETUP_GUIDE.md) → Docker Production Mode |
| **Understand the architecture** | [Architecture Overview](LOCAL_DEV_ARCHITECTURE.md) |
| **Look up a command** | [Quick Reference](QUICK_REFERENCE.md) |
| **Set up my dev environment** | [Local Development Setup](LOCAL_DEV.md) |

---

## 🚀 Quick Start

### For Demos (No Docker)
```powershell
cd api
.\run-local-dev.ps1
```
→ See [DUAL_MODE_QUICK.md](DUAL_MODE_QUICK.md)

### For Production (Docker)
```powershell
docker compose up
```
→ See [DUAL_SETUP_GUIDE.md](DUAL_SETUP_GUIDE.md)

---

## 📖 Reading Order

If you're new to the project, we recommend reading in this order:

1. **[Quick Mode Reference](DUAL_MODE_QUICK.md)** - Get started in 30 seconds
2. **[Dual Setup Guide](DUAL_SETUP_GUIDE.md)** - Understand both deployment modes
3. **[Local Development Setup](LOCAL_DEV.md)** - Set up your environment
4. **[Architecture Overview](LOCAL_DEV_ARCHITECTURE.md)** - Deep dive into design
5. **[Quick Reference](QUICK_REFERENCE.md)** - Bookmark for daily use

---

## 🔗 External Resources

- **Main README**: [../Readme.md](../Readme.md)
- **API Source**: [../api/](../api/)
- **Portal Source**: [../portal/](../portal/)
- **Seed Data**: [../seed/](../seed/)

---

Last updated: October 31, 2025
