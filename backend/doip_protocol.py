"""
BMW DoIP Protocol Implementation
Using ZGM gateway at 169.254.0.8:13400
"""

import socket
import struct
import asyncio
from typing import Optional, Tuple
import logging

logger = logging.getLogger(__name__)

class DoIPConnection:
    """BMW DoIP (Diagnostics over IP) Protocol Handler"""
    
    def __init__(self, zgm_ip: str = "169.254.0.8", port: int = 13400):
        self.zgm_ip = zgm_ip
        self.port = port
        self.socket: Optional[socket.socket] = None
        self.connected = False
        self.source_address = 0x0E00  # Tester address
        
    async def connect(self) -> bool:
        """Connect to BMW ZGM (Central Gateway Module)"""
        try:
            self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.socket.settimeout(10)
            
            await asyncio.get_event_loop().run_in_executor(
                None, self.socket.connect, (self.zgm_ip, self.port)
            )
            
            logger.info(f"Socket connected to {self.zgm_ip}:{self.port}")
            
            # Send routing activation
            success = await self.send_routing_activation()
            self.connected = success
            
            return success
            
        except Exception as e:
            logger.error(f"DoIP connection failed: {e}")
            return False
    
    async def send_routing_activation(self) -> bool:
        """Send DoIP Routing Activation Request"""
        # DoIP Header: Protocol Version (0x02) + Inverse (0xFD) + Payload Type (0x0005) + Length (0x00000007)
        header = struct.pack('>BBHII', 0x02, 0xFD, 0x0005, 0x00000007)
        
        # Payload: Source Address (0x0E00) + Activation Type (0x00) + Reserved (0x00000000)
        payload = struct.pack('>HBI', self.source_address, 0x00, 0x00000000)
        
        packet = header + payload
        
        try:
            await asyncio.get_event_loop().run_in_executor(
                None, self.socket.send, packet
            )
            
            # Receive response
            response = await asyncio.get_event_loop().run_in_executor(
                None, self.socket.recv, 4096
            )
            
            if len(response) < 8:
                return False
            
            # Parse response
            payload_type = struct.unpack('>H', response[2:4])[0]
            
            if payload_type == 0x0006:  # Routing Activation Response
                response_code = response[13] if len(response) > 13 else 0
                success = response_code == 0x10  # Success code
                logger.info(f"Routing activation: {'SUCCESS' if success else 'FAILED'} (code: {response_code:02X})")
                return success
            
            return False
            
        except Exception as e:
            logger.error(f"Routing activation failed: {e}")
            return False
    
    async def send_diagnostic_request(self, target_ecu: int, uds_data: bytes) -> Optional[bytes]:
        """
        Send UDS diagnostic request via DoIP
        
        Args:
            target_ecu: ECU address (e.g., 0x0012 for DME)
            uds_data: UDS request data (e.g., [0x22, 0xF1, 0x90] for VIN)
        
        Returns:
            UDS response data (without DoIP wrapper)
        """
        if not self.connected:
            logger.error("Not connected to ZGM")
            return None
        
        # Build DoIP Diagnostic Message (0x8001)
        payload_length = 4 + len(uds_data)  # SA(2) + TA(2) + UDS data
        
        # DoIP Header
        header = struct.pack('>BBHI', 0x02, 0xFD, 0x8001, payload_length)
        
        # Source and Target addresses
        addresses = struct.pack('>HH', self.source_address, target_ecu)
        
        # Complete packet
        packet = header + addresses + uds_data
        
        try:
            # Send request
            await asyncio.get_event_loop().run_in_executor(
                None, self.socket.send, packet
            )
            
            # Receive response
            response = await asyncio.get_event_loop().run_in_executor(
                None, self.socket.recv, 4096
            )
            
            if len(response) < 12:
                logger.error("Response too short")
                return None
            
            # Verify DoIP response type (0x8001)
            resp_type = struct.unpack('>H', response[2:4])[0]
            if resp_type != 0x8001:
                logger.error(f"Unexpected response type: {resp_type:04X}")
                return None
            
            # Extract UDS data (skip DoIP header + SA + TA)
            uds_response = response[12:]
            
            return uds_response
            
        except Exception as e:
            logger.error(f"Diagnostic request failed: {e}")
            return None
    
    async def read_vin(self) -> Optional[str]:
        """Read VIN using UDS Service 0x22 (Read Data By Identifier)"""
        # UDS: Service 0x22 + DID 0xF190 (VIN)
        uds_request = bytes([0x22, 0xF1, 0x90])
        
        response = await self.send_diagnostic_request(0x0012, uds_request)  # DME address
        
        if not response or len(response) < 20:
            logger.error("Invalid VIN response")
            return None
        
        # Check for positive response (0x62)
        if response[0] == 0x62:
            # VIN is at bytes 3-19 (17 bytes)
            vin_bytes = response[3:20]
            vin = vin_bytes.decode('ascii', errors='ignore').strip()
            logger.info(f"VIN read: {vin}")
            return vin
        else:
            # Negative response (0x7F)
            if response[0] == 0x7F:
                nrc = response[2] if len(response) > 2 else 0
                logger.error(f"VIN read failed - NRC: {nrc:02X}")
            return None
    
    async def request_seed(self, ecu_address: int, security_level: int = 0x01) -> Optional[bytes]:
        """Request security seed from ECU"""
        uds_request = bytes([0x27, security_level])
        
        response = await self.send_diagnostic_request(ecu_address, uds_request)
        
        if not response or response[0] != 0x67:
            logger.error("Seed request failed")
            return None
        
        # Seed is typically 4 bytes
        seed = response[2:6]
        logger.info(f"Seed received: {seed.hex()}")
        return seed
    
    async def send_key(self, ecu_address: int, security_level: int, key: bytes) -> bool:
        """Send security key to unlock ECU"""
        uds_request = bytes([0x27, security_level + 1]) + key
        
        response = await self.send_diagnostic_request(ecu_address, uds_request)
        
        if not response or response[0] != 0x67:
            logger.error("Key rejected by ECU")
            return False
        
        logger.info("ECU unlocked successfully")
        return True
    
    async def read_parameter(self, ecu_address: int, did: int) -> Optional[bytes]:
        """Read parameter using UDS Service 0x22"""
        uds_request = struct.pack('>BH', 0x22, did)
        
        response = await self.send_diagnostic_request(ecu_address, uds_request)
        
        if not response or response[0] != 0x62:
            return None
        
        # Return data (skip service ID and DID echo)
        return response[3:]
    
    async def write_parameter(self, ecu_address: int, did: int, data: bytes) -> bool:
        """Write parameter using UDS Service 0x2E"""
        uds_request = struct.pack('>BH', 0x2E, did) + data
        
        response = await self.send_diagnostic_request(ecu_address, uds_request)
        
        return response and response[0] == 0x6E
    
    def disconnect(self):
        """Close connection"""
        if self.socket:
            self.socket.close()
            self.connected = False
            logger.info("DoIP connection closed")

# Export
__all__ = ['DoIPConnection']
