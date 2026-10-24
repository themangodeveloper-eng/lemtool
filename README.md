# 🍋 lemtool
Multi-distribution toolchain manager (Debian & Ubuntu) for deploying Lemon-OS developer environments on Termux with integrated `lli` and `sli` utilities.

## Quick Start
```bash
git clone [https://github.com/YOUR_USERNAME/lemtool.git](https://github.com/YOUR_USERNAME/lemtool.git)
cd lemtool
./lemon-tool.sh debian
proot-distro login debian
### Step 3: Add a `.gitignore`
Keep sensitive local configuration keys out of version control:
```bash
cat << 'EOF' > .gitignore
.config/
*.key
*.tar.gz
