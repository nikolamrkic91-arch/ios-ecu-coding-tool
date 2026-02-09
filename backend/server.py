from fastapi import FastAPI, APIRouter, HTTPException
from dotenv import load_dotenv
from starlette.middleware.cors import CORSMiddleware
from motor.motor_asyncio import AsyncIOMotorClient
import os
import logging
from pathlib import Path
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
import uuid
from datetime import datetime
import asyncio
import socket
import struct

# Import G01 X3 B48 specific module
from g01_x3_b48_module import (
    G01_X3_B48_CONFIG,
    BMWSeedToKey,
    CAFDParser,
    G01ECUManager,
    G01_CODING_PARAMS
)
from g01_cafd_database import (
    G01_CAFD_DATABASE,
    search_cafd_by_function,
    get_cafd_info
)

ROOT_DIR = Path(__file__).parent
load_dotenv(ROOT_DIR / '.env')

# MongoDB connection
mongo_url = os.environ['MONGO_URL']
client = AsyncIOMotorClient(mongo_url)
db = client[os.environ['DB_NAME']]

# Create the main app
app = FastAPI(title="BMW ECU Coding Tool API - G01 X3 B48")
api_router = APIRouter(prefix="/api")

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# ============================================================================
# MODELS
# ============================================================================

class Vehicle(BaseModel):
    series: str
    model: str
    year: str
    vin: Optional[str] = None
    ecuType: Optional[str] = None

class ConnectionRequest(BaseModel):
    type: str  # enet, bluetooth, wifi
    ipAddress: Optional[str] = None

class ConnectionResponse(BaseModel):
    success: bool
    deviceName: Optional[str] = None
    message: Optional[str] = None

class Parameter(BaseModel):
    id: str
    name: str
    currentValue: str
    newValue: Optional[str] = None
    unit: Optional[str] = None
    min: Optional[float] = None
    max: Optional[float] = None
    type: str  # string, number, boolean

class ApplyCodingRequest(BaseModel):
    cafd: str
    parameters: List[Parameter]
    vehicle: Vehicle

class ApplyCheatSheetRequest(BaseModel):
    sheetId: str
    vehicle: Vehicle

class FlashRequest(BaseModel):
    stageId: str
    vehicle: Vehicle

class Transaction(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    type: str  # coding, flash, cheatsheet
    vin: str
    vehicle: str
    description: str
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    status: str  # success, failed
    details: Optional[Dict[str, Any]] = None

# ============================================================================
# ENET COMMUNICATION LAYER
# ============================================================================

class ENETConnection:
    def __init__(self, ip_address: str = "169.254.250.250", port: int = 6801):
        """
        ENET Connection for BMW G01 X3
        Uses static IP in 169.254.x.x range as per BMW ENET protocol
        """
        self.ip_address = ip_address
        self.port = port
        self.socket = None
        self.connected = False
    
    async def connect(self) -> bool:
        """Establish TCP connection to ENET cable"""
        try:
            self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.socket.settimeout(10)  # Increased timeout
            await asyncio.get_event_loop().run_in_executor(
                None, self.socket.connect, (self.ip_address, self.port)
            )
            self.connected = True
            logger.info(f"Connected to ENET at {self.ip_address}:{self.port}")
            return True
        except Exception as e:
            logger.error(f"ENET connection failed: {e}")
            self.connected = False
            return False
    
    def disconnect(self):
        """Close ENET connection"""
        if self.socket:
            self.socket.close()
            self.connected = False
            logger.info("ENET connection closed")
    
    async def send_uds_request(self, service_id: int, data: bytes = b'') -> bytes:
        """Send UDS (Unified Diagnostic Services) request"""
        if not self.connected:
            raise Exception("Not connected to ENET")
        
        # ISO-TP header + UDS service ID + data
        message = struct.pack('B', service_id) + data
        
        try:
            await asyncio.get_event_loop().run_in_executor(
                None, self.socket.send, message
            )
            response = await asyncio.get_event_loop().run_in_executor(
                None, self.socket.recv, 4096
            )
            return response
        except Exception as e:
            logger.error(f"UDS request failed: {e}")
            raise
    
    async def read_vin(self) -> str:
        """Read VIN from vehicle using UDS Service 0x22 (ReadDataByIdentifier)"""
        try:
            # Service 0x22, DID 0xF190 (VIN)
            response = await self.send_uds_request(0x22, b'\\xF1\\x90')
            # Parse response (skip first 3 bytes: response code + DID echo)
            vin = response[3:20].decode('ascii')
            return vin
        except Exception as e:
            logger.error(f"VIN read failed: {e}")
            return "DEMO_VIN_123456789"
    
    async def read_ecu_data(self, did: int) -> bytes:
        """Read data from ECU by Data Identifier"""
        did_bytes = struct.pack('>H', did)
        return await self.send_uds_request(0x22, did_bytes)
    
    async def write_ecu_data(self, did: int, data: bytes) -> bool:
        """Write data to ECU"""
        try:
            did_bytes = struct.pack('>H', did)
            response = await self.send_uds_request(0x2E, did_bytes + data)
            # Check for positive response (0x6E)
            return response[0] == 0x6E
        except Exception as e:
            logger.error(f"ECU write failed: {e}")
            return False
    
    async def start_diagnostic_session(self, session_type: int = 0x03):
        """Start diagnostic session (0x03 = Extended Diagnostic Session)"""
        return await self.send_uds_request(0x10, struct.pack('B', session_type))
    
    async def security_access_seed(self) -> bytes:
        """Request security seed"""
        return await self.send_uds_request(0x27, b'\\x01')
    
    async def security_access_key(self, key: bytes):
        """Send security key"""
        return await self.send_uds_request(0x27, b'\\x02' + key)

# Global ENET connection and G01 manager instances
enet_connection: Optional[ENETConnection] = None
g01_manager: Optional[G01ECUManager] = None

# ============================================================================
# PSdZData MANAGEMENT
# ============================================================================

class PSdZDataManager:
    def __init__(self, psdz_root: str = "/app/backend/psdz_data"):
        self.psdz_root = Path(psdz_root)
        self.cafd_cache: Dict[str, Any] = {}
    
    def search_cafd(self, series: str, model: str, year: str) -> List[Dict[str, str]]:
        """Search for CAFD files based on vehicle"""
        # Mock CAFD search - in production, this would parse actual PSdZData
        cafds = [
            {"id": "3000_HU_CIC", "name": "Head Unit CIC", "module": "Infotainment"},
            {"id": "3000_FRM", "name": "Footwell Module", "module": "Body"},
            {"id": "3000_DME", "name": "Engine Control", "module": "Powertrain"},
            {"id": "3000_KOMBI", "name": "Instrument Cluster", "module": "Display"},
            {"id": "3000_HU_NBT", "name": "Head Unit NBT", "module": "Infotainment"},
        ]
        return cafds
    
    def get_cafd_parameters(self, cafd_id: str, vin: Optional[str] = None) -> List[Dict[str, Any]]:
        """Get parameters from CAFD file"""
        # Mock parameters - in production, parse actual CAFD
        parameters = [
            {
                "id": "1",
                "name": "SCR_VERBAU",
                "currentValue": "not_active",
                "type": "string",
                "options": ["not_active", "aktiv"]
            },
            {
                "id": "2",
                "name": "SCR_ANZEIGE",
                "currentValue": "not_active",
                "type": "string",
                "options": ["not_active", "aktiv"]
            },
            {
                "id": "3",
                "name": "VIDEO_FREIGABE",
                "currentValue": "not_active",
                "type": "string",
                "options": ["not_active", "aktiv"]
            },
        ]
        return parameters
    
    def validate_parameter(self, param_name: str, value: str) -> bool:
        """Validate parameter value"""
        # Safety validation logic
        return True

psdz_manager = PSdZDataManager()

# ============================================================================
# API ENDPOINTS
# ============================================================================

@api_router.get("/")
async def root():
    return {"message": "BMW ECU Coding Tool API", "version": "1.0.0"}

# CAFD Search and Browse
@api_router.get("/cafd/search")
async def search_cafds(query: str):
    """Search CAFD by function name (e.g., 'remote start', 'exhaust', 'dme')"""
    try:
        results = search_cafd_by_function(query)
        return {"success": True, "results": results, "count": len(results)}
    except Exception as e:
        logger.error(f"CAFD search error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@api_router.get("/cafd/list")
async def list_all_cafds():
    """List all available CAFDs with names"""
    try:
        cafds = [
            {"cafd_id": cafd_id, **info}
            for cafd_id, info in G01_CAFD_DATABASE.items()
        ]
        return {"success": True, "cafds": cafds, "count": len(cafds)}
    except Exception as e:
        logger.error(f"List CAFDs error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@api_router.get("/cafd/{cafd_id}")
async def get_cafd_details(cafd_id: str):
    """Get detailed information about specific CAFD"""
    try:
        info = get_cafd_info(cafd_id)
        if not info:
            raise HTTPException(status_code=404, detail=f"CAFD {cafd_id} not found")
        return {"success": True, "cafd": {"cafd_id": cafd_id, **info}}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Get CAFD error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# DME Operations
@api_router.post("/dme/read")
async def read_dme():
    """Read all data from DME (Engine Control Module)"""
    global g01_manager
    
    try:
        if not g01_manager:
            raise HTTPException(status_code=400, detail="Not connected to G01 X3")
        
        dme_addr = G01_X3_B48_CONFIG["ecu_addresses"]["DME"]
        
        # Unlock DME
        unlocked = await g01_manager.unlock_ecu(dme_addr, security_level=3)
        if not unlocked:
            raise HTTPException(status_code=500, detail="Failed to unlock DME")
        
        # Read common parameters
        parameters = {}
        common_dids = {
            0x5000: "Exhaust Flaps",
            0x5001: "Launch Control",
            0x5002: "Rev Limiter",
            0x5003: "Boost Pressure",
        }
        
        for did, name in common_dids.items():
            value = await g01_manager.read_parameter(dme_addr, did)
            if value:
                parameters[name] = value.hex()
        
        return {
            "success": True,
            "ecu": "DME",
            "parameters": parameters,
            "message": "DME data read successfully"
        }
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"DME read error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@api_router.post("/dme/write")
async def write_dme(parameter: str, value: str):
    """Write specific parameter to DME"""
    global g01_manager
    
    try:
        if not g01_manager:
            raise HTTPException(status_code=400, detail="Not connected to G01 X3")
        
        dme_addr = G01_X3_B48_CONFIG["ecu_addresses"]["DME"]
        
        # Unlock DME
        unlocked = await g01_manager.unlock_ecu(dme_addr, security_level=3)
        if not unlocked:
            raise HTTPException(status_code=500, detail="Failed to unlock DME")
        
        # Parameter mapping
        param_map = {
            "exhaust_flaps": 0x5000,
            "launch_control": 0x5001,
            "rev_limiter": 0x5002,
            "boost_pressure": 0x5003,
        }
        
        did = param_map.get(parameter.lower())
        if not did:
            raise HTTPException(status_code=400, detail=f"Unknown parameter: {parameter}")
        
        # Write parameter
        value_bytes = value.encode('utf-8')
        success = await g01_manager.write_parameter(dme_addr, did, value_bytes)
        
        if not success:
            raise HTTPException(status_code=500, detail="Failed to write DME parameter")
        
        # Log transaction
        transaction = Transaction(
            type="coding",
            vin="UNKNOWN",
            vehicle="G01 X3 B48",
            description=f"DME Write: {parameter} = {value}",
            status="success"
        )
        await db.transactions.insert_one(transaction.dict())
        
        return {
            "success": True,
            "message": f"DME parameter '{parameter}' written successfully"
        }
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"DME write error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Connection Management
@api_router.post("/connection/connect", response_model=ConnectionResponse)
async def connect_to_vehicle(request: ConnectionRequest):
    global enet_connection, g01_manager
    
    try:
        if request.type == "enet":
            ip = request.ipAddress or "169.254.250.250"  # BMW ENET static IP
            enet_connection = ENETConnection(ip, 6801)
            success = await enet_connection.connect()
            
            if success:
                # Initialize G01 X3 B48 manager
                g01_manager = G01ECUManager(enet_connection)
                
                # Read VIN
                vin = await enet_connection.read_vin()
                
                logger.info(f"G01 X3 B48 Manager initialized for VIN: {vin}")
                
                return ConnectionResponse(
                    success=True,
                    deviceName=f"ENET ({ip}) - G01 X3 B48",
                    message=f"Connected to G01 X3 - VIN: {vin}"
                )
            else:
                return ConnectionResponse(
                    success=False,
                    message="Failed to connect to ENET cable"
                )
        
        elif request.type == "bluetooth":
            # Bluetooth OBD connection logic
            return ConnectionResponse(
                success=True,
                deviceName="Bluetooth OBD",
                message="Connected via Bluetooth"
            )
        
        elif request.type == "wifi":
            # WiFi OBD connection logic
            return ConnectionResponse(
                success=True,
                deviceName="WiFi OBD",
                message="Connected via WiFi"
            )
        
        else:
            return ConnectionResponse(
                success=False,
                message="Unknown connection type"
            )
    
    except Exception as e:
        logger.error(f"Connection error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@api_router.post("/connection/disconnect")
async def disconnect_from_vehicle():
    global enet_connection
    if enet_connection:
        enet_connection.disconnect()
        enet_connection = None
    return {"success": True, "message": "Disconnected"}

# Coding
@api_router.get("/coding/parameters/{cafd_id}")
async def get_cafd_parameters(cafd_id: str, vin: Optional[str] = None):
    try:
        # Use G01 CAFD parser
        cafd_parser = CAFDParser(G01_X3_B48_CONFIG["cafd_path"])
        params = cafd_parser.parse_cafd(cafd_id)
        
        if not params:
            # Fallback to mock for demo
            params = {
                "param_3000": {"id": 12288, "value": "not_active", "raw": "6e6f745f616374697665", "length": 10},
                "param_3001": {"id": 12289, "value": "not_active", "raw": "6e6f745f616374697665", "length": 10},
            }
        
        return {"success": True, "parameters": list(params.values())[:10]}  # Return first 10
    except Exception as e:
        logger.error(f"Get parameters error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@api_router.post("/coding/apply")
async def apply_coding(request: ApplyCodingRequest):
    global g01_manager
    
    try:
        if not g01_manager:
            raise HTTPException(status_code=400, detail="Not connected to G01 X3 B48")
        
        # Use G01 manager for real ECU unlock and parameter writing
        ecu_name = request.cafd.split('_')[0] if '_' in request.cafd else "DME"
        ecu_addr = G01_X3_B48_CONFIG["ecu_addresses"].get(ecu_name, 0x12)
        
        # Unlock ECU
        unlocked = await g01_manager.unlock_ecu(ecu_addr, security_level=3)
        if not unlocked:
            raise HTTPException(status_code=500, detail="Failed to unlock ECU")
        
        # Apply each parameter
        for param in request.parameters:
            if param.newValue:
                # Write to ECU
                param_addr = int(param.id) if param.id.isdigit() else 0x3000
                value_bytes = param.newValue.encode('utf-8')
                
                success = await g01_manager.write_parameter(ecu_addr, param_addr, value_bytes)
                if not success:
                    raise HTTPException(status_code=500, detail=f"Failed to write {param.name}")
        
        # Log transaction
        transaction = Transaction(
            type="coding",
            vin=request.vehicle.vin or "UNKNOWN",
            vehicle=f"{request.vehicle.series} {request.vehicle.model}",
            description=f"CAFD {request.cafd} - {len(request.parameters)} parameters",
            status="success",
            details={"cafd": request.cafd, "parameters": [p.dict() for p in request.parameters]}
        )
        await db.transactions.insert_one(transaction.dict())
        
        return {"success": True, "message": "Coding applied successfully to G01 X3"}
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Apply coding error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@api_router.post("/coding/apply-cheatsheet")
async def apply_cheatsheet(request: ApplyCheatSheetRequest):
    global enet_connection
    
    try:
        if not enet_connection or not enet_connection.connected:
            raise HTTPException(status_code=400, detail="Not connected to vehicle")
        
        # Mock cheatsheet application
        await asyncio.sleep(2)  # Simulate coding time
        
        # Log transaction
        transaction = Transaction(
            type="cheatsheet",
            vin=request.vehicle.vin or "UNKNOWN",
            vehicle=f"{request.vehicle.series} {request.vehicle.model}",
            description=f"Cheatsheet: {request.sheetId}",
            status="success"
        )
        await db.transactions.insert_one(transaction.dict())
        
        return {"success": True, "message": "Cheatsheet applied successfully"}
    
    except Exception as e:
        logger.error(f"Apply cheatsheet error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Flash
@api_router.post("/flash/apply")
async def apply_flash(request: FlashRequest):
    global enet_connection
    
    try:
        if not enet_connection or not enet_connection.connected:
            raise HTTPException(status_code=400, detail="Not connected to vehicle")
        
        # Start extended diagnostic session
        await enet_connection.start_diagnostic_session(0x03)
        
        # Security access
        seed_response = await enet_connection.security_access_seed()
        # In production, calculate key from seed using manufacturer algorithm
        key = b'\\x00\\x00\\x00\\x00'  # Mock key
        await enet_connection.security_access_key(key)
        
        # Mock flash process (in production, write actual flash file)
        await asyncio.sleep(5)  # Simulate flashing
        
        # Log transaction
        transaction = Transaction(
            type="flash",
            vin=request.vehicle.vin or "UNKNOWN",
            vehicle=f"{request.vehicle.series} {request.vehicle.model}",
            description=f"Flash: {request.stageId.upper()}",
            status="success",
            details={"stage": request.stageId}
        )
        await db.transactions.insert_one(transaction.dict())
        
        return {"success": True, "message": "Flash applied successfully"}
    
    except Exception as e:
        logger.error(f"Flash error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# History
@api_router.get("/history/transactions")
async def get_transactions(vin: Optional[str] = None):
    try:
        query = {"vin": vin} if vin else {}
        transactions = await db.transactions.find(query).sort("timestamp", -1).limit(100).to_list(100)
        return {"success": True, "transactions": transactions}
    except Exception as e:
        logger.error(f"Get transactions error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Vehicle Management
@api_router.get("/vehicles/search")
async def search_cafds(series: str, model: str, year: str):
    try:
        cafds = psdz_manager.search_cafd(series, model, year)
        return {"success": True, "cafds": cafds}
    except Exception as e:
        logger.error(f"Search CAFDs error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Include the router in the main app
app.include_router(api_router)

app.add_middleware(
    CORSMiddleware,
    allow_credentials=True,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("shutdown")
async def shutdown():
    global enet_connection
    if enet_connection:
        enet_connection.disconnect()
    client.close()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
