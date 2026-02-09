"""
G01 X3 B48 CAFD Database with Human-Readable Names
Maps CAFD IDs to ECU modules and functions
"""

# Complete G01 X3 B48 CAFD mapping
G01_CAFD_DATABASE = {
    # Engine Control Module (DME) - B48 Engine
    "0000000f": {
        "name": "DME - Engine Control (B48)",
        "ecu": "DME",
        "ecu_address": 0x12,
        "functions": [
            "Engine mapping",
            "Fuel injection",
            "Ignition timing",
            "Turbo boost control",
            "Exhaust flaps",
            "Launch control",
            "Rev limiter"
        ],
        "common_mods": [
            "Exhaust flaps always open",
            "Rev limiter increase",
            "Launch control activation"
        ]
    },
    
    # Front Electronic Module
    "000000b5": {
        "name": "FEM - Front Electronic Module",
        "ecu": "FEM",
        "ecu_address": 0xB0,
        "functions": [
            "Remote engine start (SCR1)",
            "Angel eyes brightness",
            "DRL control",
            "Welcome lights",
            "Puddle lights",
            "Interior lighting"
        ],
        "common_mods": [
            "SCR1 Remote Start Enable",
            "Angel eyes 100% brightness",
            "Welcome light duration"
        ]
    },
    
    # Body Domain Controller
    "000000b6": {
        "name": "BDC - Body Domain Controller",
        "ecu": "BDC",
        "ecu_address": 0xF1,
        "functions": [
            "Central locking",
            "Alarm system",
            "Comfort access",
            "Power windows",
            "Seat memory"
        ],
        "common_mods": [
            "Auto lock/unlock",
            "Windows via remote"
        ]
    },
    
    # Instrument Cluster
    "0000003f": {
        "name": "KOMBI - Instrument Cluster",
        "ecu": "KOMBI",
        "ecu_address": 0x61,
        "functions": [
            "Gauge display",
            "Warning lights",
            "Trip computer",
            "Speed display",
            "Needle sweep"
        ],
        "common_mods": [
            "Needle sweep enable",
            "Digital speed display",
            "Extended menu"
        ]
    },
    
    # Head Unit
    "00000a07": {
        "name": "HU - Head Unit (iDrive)",
        "ecu": "HU",
        "ecu_address": 0x63,
        "functions": [
            "Video in motion",
            "DVD region",
            "USB video",
            "CarPlay settings",
            "Display settings"
        ],
        "common_mods": [
            "Video in motion",
            "DVD region free",
            "USB video playback"
        ]
    },
    
    # Climate Control
    "00000160": {
        "name": "IHKA - Automatic Climate Control",
        "ecu": "IHKA",
        "ecu_address": 0x9B,
        "functions": [
            "Temperature control",
            "Fan speed",
            "Auto mode",
            "Seat heating",
            "Steering wheel heat"
        ],
        "common_mods": [
            "Max heat/cool on startup"
        ]
    },
    
    # Transmission
    "00000f9b": {
        "name": "TCU - Transmission Control",
        "ecu": "TCU",
        "ecu_address": 0x18,
        "functions": [
            "Shift points",
            "Sport mode",
            "Comfort mode",
            "Manual mode"
        ],
        "common_mods": [
            "Faster shifts",
            "Sport mode default"
        ]
    }
}

# Function-based search index
FUNCTION_SEARCH_INDEX = {
    "remote start": ["000000b5"],
    "scr1": ["000000b5"],
    "engine start": ["000000b5"],
    "angel eyes": ["000000b5"],
    "drl": ["000000b5"],
    "lights": ["000000b5", "0000003f"],
    "exhaust": ["0000000f"],
    "exhaust flaps": ["0000000f"],
    "launch control": ["0000000f"],
    "rev limiter": ["0000000f"],
    "video": ["00000a07"],
    "video in motion": ["00000a07"],
    "dvd": ["00000a07"],
    "needle sweep": ["0000003f"],
    "gauge": ["0000003f"],
    "cluster": ["0000003f"],
    "shift": ["00000f9b"],
    "transmission": ["00000f9b"],
    "dme": ["0000000f"],
    "engine": ["0000000f"],
}

def search_cafd_by_function(query: str):
    """Search CAFD by function name"""
    query_lower = query.lower()
    results = []
    
    # Direct match in index
    for key, cafd_ids in FUNCTION_SEARCH_INDEX.items():
        if query_lower in key:
            for cafd_id in cafd_ids:
                if cafd_id in G01_CAFD_DATABASE:
                    results.append({
                        "cafd_id": cafd_id,
                        **G01_CAFD_DATABASE[cafd_id]
                    })
    
    # Search in CAFD details
    for cafd_id, info in G01_CAFD_DATABASE.items():
        if query_lower in info["name"].lower():
            results.append({"cafd_id": cafd_id, **info})
        else:
            for func in info["functions"]:
                if query_lower in func.lower():
                    results.append({"cafd_id": cafd_id, **info})
                    break
    
    # Remove duplicates
    seen = set()
    unique_results = []
    for r in results:
        if r["cafd_id"] not in seen:
            seen.add(r["cafd_id"])
            unique_results.append(r)
    
    return unique_results

def get_cafd_info(cafd_id: str):
    """Get CAFD information by ID"""
    return G01_CAFD_DATABASE.get(cafd_id)
