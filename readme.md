# GPS [Git Profile Switcher] 

A comprehensive tool to easily switch between different git user profiles for work, personal projects, or different clients.

## 🚀 Quick Start

The git profile switcher has been automatically set up with your existing configurations:

**Available Profiles:** For me currently 🙈
- **work**: `sai-vishnu-****` / `****.kiriti@razorpay.com` (Work profile)
- **personal**: `arvind3417` / `****iarvindss@gmail.com` (Personal profile)



## 🔧 Installation - Skip underlying commands and jump in 

To use GPS from anywhere on your system:

```bash
./install-gps.sh
```

After installation, you can use `gps` instead of `./gps.sh`:

```bash
gps list
gps current
gps switch work
gps switch personal local
```

## 🆘 Help

For full command reference:
```bash
./gps.sh help
```

## 📋 Basic Commands

### View Current Configuration
```bash
./gps.sh current
```

### List All Profiles
```bash
./gps.sh list
```

### Switch Profiles

**Switch globally (affects all new repositories):**
```bash
./gps.sh switch work      # Switch to work profile globally
./gps.sh switch personal  # Switch to personal profile globally
```

**Switch locally (affects only current repository):**
```bash
./gps.sh switch work local      # Switch to work profile for this repo only
./gps.sh switch personal local  # Switch to personal profile for this repo only
```

## 🛠️ Management Commands - WIP

### Add New Profile
```bash
./gps.sh add client "John Doe" john@client.com "Client project profile"
```

### Remove Profile
```bash
./gps.sh remove client
```

### Edit Profiles Configuration
```bash
./gps.sh edit
```



## 💡 Usage Examples

### Typical Workflow

1. **Check current profile:**
   ```bash
   ./gps.sh current
   ```

2. **Switch to work profile for a work project:**
   ```bash
   ./gps.sh switch work local
   ```

3. **Switch globally to personal for personal projects:**
   ```bash
   ./gps.sh switch personal
   ```

4. **Add a client profile:**
   ```bash
   ./gps.sh add client "Your Name" your.email@client.com "Client XYZ projects"
   ```

### Best Practices

- **Use global switching** when you're primarily working on one type of project
- **Use local switching** when working on a specific repository that needs a different profile
- **Keep work and personal profiles separate** to maintain proper attribution
- **Add descriptive names** to profiles for easy identification

## 🎯 Common Scenarios

### Scenario 1: Starting a Work Project
```bash
cd /path/to/work-project
./gps.sh switch work local
git init
# Your commits will now use your work profile
```

### Scenario 2: Contributing to Open Source
```bash
cd /path/to/opensource-project
./gps.sh switch personal local
# Your commits will use your personal profile
```

### Scenario 3: Client Work
```bash
# First, add client profile (one time setup)
./gps.sh add client "Your Name" your.name@client.com "Client ABC"

# Then use for client projects
cd /path/to/client-project
./gps.sh switch client local
```

## 📂 File Locations

- **Profiles Configuration**: `~/.git-profiles/profiles.conf`
- **Script Location**: `./gps.sh`
- **Installation Script**: `./install-gps.sh`



