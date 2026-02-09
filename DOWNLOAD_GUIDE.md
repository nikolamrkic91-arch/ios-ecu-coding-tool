# BMW G01 X3 ECU Coding Tool - Complete Project Files

## 📦 Archive Contents

**Archive:** `bmw-g01-x3-coding-tool.tar.gz` (40KB)

### Native iOS DoIP Module
```
frontend/ios/
├── BMWDoIPModule.swift    (400 lines) - Complete DoIP implementation
└── BMWDoIPModule.m         (30 lines)  - React Native bridge
```

### Frontend (React Native/Expo)
```
frontend/app/
├── index.tsx              - Welcome screen
├── home.tsx               - Main menu
├── vehicle-select.tsx     - G01 X3 selection
├── connection.tsx         - Connection manager
├── coding.tsx             - ECU coding interface
├── cheat-sheets.tsx       - Pre-configured mods
├── flash.tsx              - ECU flashing
└── history.tsx            - Transaction history

frontend/store/
├── vehicleStore.ts        - Vehicle state management
└── connectionStore.ts     - Connection state

frontend/utils/
└── BMWDoIP.ts             - TypeScript wrapper for native module

frontend/
├── package.json           - Dependencies
├── app.json               - Expo configuration
└── tsconfig.json          - TypeScript config
```

### Backend (Python/FastAPI)
```
backend/
├── server.py              - Main API server
├── doip_protocol.py       - BMW DoIP protocol implementation
├── g01_x3_b48_module.py   - G01 X3 specific logic
├── g01_cafd_database.py   - CAFD mapping with human names
├── requirements.txt       - Python dependencies
└── .env                   - Configuration
```

### Documentation
```
NATIVE_DOIP_GUIDE.md       - Complete setup instructions
G01_X3_B48_STATUS.md       - G01 X3 implementation status
PROJECT_STATUS.md          - Overall project status
LOCAL_DEPLOYMENT.md        - Run backend locally
README.md                  - General readme
```

## 📥 How to Download

**Option 1: Direct Download from Deployment**

The file is located at:
```
/app/bmw-g01-x3-coding-tool.tar.gz
```

You can access it through the deployment interface or request a download link.

**Option 2: Extract Here and Upload to Drive**

If you have access to the deployment terminal or can download from there, extract and view contents:

```bash
tar -xzf bmw-g01-x3-coding-tool.tar.gz
ls -la
```

## 🚀 Setup After Download

### 1. Extract Archive
```bash
tar -xzf bmw-g01-x3-coding-tool.tar.gz
cd bmw-g01-x3-coding-tool
```

### 2. Backend Setup
```bash
cd backend
pip install -r requirements.txt
python server.py
```

### 3. Frontend Setup
```bash
cd frontend
yarn install
yarn ios  # or yarn android
```

### 4. Add Native Module to Xcode
1. Open `frontend/ios/YourApp.xcworkspace`
2. Add `BMWDoIPModule.swift` and `BMWDoIPModule.m`
3. Configure Info.plist permissions (see NATIVE_DOIP_GUIDE.md)
4. Build on physical iPhone

### 5. Test with Your G01 X3
1. Connect ENET cable to car
2. Configure iPhone network:
   - IP: 169.254.250.250
   - Subnet: 255.255.0.0
   - Router: 169.254.0.8
3. Run app and test connection

## 📋 Key Features

### Implemented ✅
- Native iOS DoIP protocol
- Direct TCP connection to BMW ZGM
- VIN reading
- Parameter read/write
- Security access (seed/key)
- ECU unlocking
- G01 X3 B48 specific configuration
- CAFD database with human-readable names
- Cheat sheets for popular mods
- Transaction history
- Beautiful mobile UI

### Backend APIs
- Seed-to-key calculation
- CAFD search by function
- DME read/write operations
- Transaction logging
- Connection management

## 🔐 Important Files

### Native Module (iOS)
- `frontend/ios/BMWDoIPModule.swift` - **CRITICAL** - DoIP implementation
- `frontend/utils/BMWDoIP.ts` - TypeScript API wrapper

### Backend
- `backend/doip_protocol.py` - DoIP protocol reference
- `backend/g01_cafd_database.py` - CAFD mappings for G01 X3

### Documentation
- `NATIVE_DOIP_GUIDE.md` - **START HERE** - Setup instructions
- `G01_X3_B48_STATUS.md` - What works, what needs testing

## 📞 Support

For setup issues, refer to:
1. **NATIVE_DOIP_GUIDE.md** - Complete setup walkthrough
2. **G01_X3_B48_STATUS.md** - Implementation details
3. **LOCAL_DEPLOYMENT.md** - Run backend locally

## ⚠️ Note

- **CAFD files NOT included** (13k files, 5.6GB) - Too large for archive
- Your CAFD files are at: `/app/backend/psdz_data/cafd/` on deployment server
- Download separately if needed
- App works without them using mock data for testing

## 📦 What's NOT Included

Due to size constraints:
- ❌ node_modules (run `yarn install`)
- ❌ CAFD database files (5.6GB - available on server)
- ❌ Build artifacts
- ❌ Logs

## 🎯 Ready to Build

This archive contains everything needed to:
1. Build native iOS app with DoIP support
2. Run backend API server
3. Test with real G01 X3 B48

**Start with NATIVE_DOIP_GUIDE.md after extracting.**

---

**Archive created:** February 8, 2026
**Size:** 40KB (compressed)
**Files:** 25+ source files + documentation
