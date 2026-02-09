# BMW G01 X3 Coding Tool - Local Deployment

## Run Backend Locally on Your Device

### Requirements:
- Python 3.11+
- Your device connected to same network as ENET (169.254.x.x)

### Step 1: Install Backend on Your Computer

```bash
# Download these files to your computer:
/app/backend/server.py
/app/backend/g01_x3_b48_module.py
/app/backend/g01_cafd_database.py
/app/backend/requirements.txt
/app/backend/.env
```

### Step 2: Install Dependencies

```bash
cd backend
pip install -r requirements.txt
```

### Step 3: Configure ENET IP

Edit `server.py` or run with environment variable:
```bash
export ENET_IP="169.254.250.250"
```

### Step 4: Run Backend

```bash
python server.py
```

Backend will run on: `http://localhost:8001`

### Step 5: Update Mobile App

In your phone, update backend URL to your computer's local IP:
- Find your computer IP: `ifconfig` (Mac/Linux) or `ipconfig` (Windows)
- Update app to connect to: `http://YOUR_COMPUTER_IP:8001`

### Step 6: Connect ENET

1. Plug ENET into X3 OBD port
2. Turn ignition ON
3. Connect your phone to ENET network (169.254.x.x range)
4. Your computer must also be on same network
5. Open app → Connection Manager → ENET → Connect

### Connection Flow:
```
Phone (App) → Computer (Backend on 169.254.x.x) → ENET → X3 ECU
```

### Alternative: Run Backend on Phone

If you can run Python on your phone (Termux, etc.):
1. Copy backend folder to phone
2. Run `python server.py` on phone
3. App connects to `http://localhost:8001`
4. Phone connects directly to ENET

This eliminates the need for a separate computer.

---

## Quick Start Commands:

```bash
# On your computer (connected to ENET network):
cd backend
pip install -r requirements.txt
python server.py

# App will connect to: http://YOUR_COMPUTER_IP:8001/api
```

---

## Files Needed:

All files are in `/app/backend/` directory. Copy this entire folder to your device.

Key files:
- `server.py` - Main backend
- `g01_x3_b48_module.py` - G01 X3 specific logic
- `g01_cafd_database.py` - CAFD database
- `requirements.txt` - Python dependencies
- `.env` - Configuration

---

## Test Connection:

```bash
# From your computer on ENET network:
curl http://169.254.250.250:6801

# Should get response or connection if ENET is reachable
```
