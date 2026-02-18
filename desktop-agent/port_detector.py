"""
Port Detector - Auto-detección de puertos COM y equipos médicos
"""

import serial
import serial.tools.list_ports
import json
import os
import time
from pathlib import Path


class PortDetector:
    """Detecta automáticamente puertos COM y los equipos conectados."""
    
    # Patrones conocidos para identificar equipos
    EQUIPMENT_PATTERNS = {
        'sysmex': {
            'patterns': [b'Sysmex', b'XN-', b'XT-', b'XS-'],
            'type': 'hematologia',
            'name': 'Sysmex Hematology Analyzer'
        },
        'roche': {
            'patterns': [b'Roche', b'Cobas', b'c311', b'c501'],
            'type': 'quimica',
            'name': 'Roche Chemistry Analyzer'
        },
        'abbott': {
            'patterns': [b'Abbott', b'Architect', b'CELL-DYN'],
            'type': 'quimica',
            'name': 'Abbott Analyzer'
        },
        'beckman': {
            'patterns': [b'Beckman', b'Coulter', b'DxH'],
            'type': 'hematologia',
            'name': 'Beckman Coulter Analyzer'
        },
        'mindray': {
            'patterns': [b'Mindray', b'BC-'],
            'type': 'hematologia',
            'name': 'Mindray Hematology Analyzer'
        },
        'generic_hl7': {
            'patterns': [b'MSH|', b'\x0BMSH|'],
            'type': 'unknown',
            'name': 'Generic HL7 Device'
        }
    }
    
    # Configuraciones comunes de puertos para probar
    COMMON_BAUDS = [9600, 19200, 38400, 57600, 115200]
    
    def __init__(self, cache_file='ports_cache.json', logger=None):
        """
        Inicializa el detector de puertos.
        
        Args:
            cache_file: Archivo para guardar el mapeo de puertos
            logger: Logger para mensajes
        """
        self.cache_file = cache_file
        self.logger = logger
        self.detected_ports = {}
        
    def _log(self, message, level='info'):
        """Helper para logging."""
        if self.logger:
            getattr(self.logger, level)(message)
        else:
            print(f"[{level.upper()}] {message}")
    
    def list_available_ports(self):
        """
        Lista todos los puertos COM/serial disponibles en el sistema.
        
        Returns:
            Lista de puertos disponibles
        """
        ports = serial.tools.list_ports.comports()
        available = []
        
        for port in ports:
            available.append({
                'port': port.device,
                'description': port.description,
                'hwid': port.hwid,
                'manufacturer': port.manufacturer if hasattr(port, 'manufacturer') else None
            })
        
        return available
    
    def probe_port(self, port_name, timeout=3, read_attempts=5):
        """
        Sondea un puerto para detectar qué tipo de equipo está conectado.
        
        Args:
            port_name: Nombre del puerto (ej: COM3)
            timeout: Timeout en segundos para lectura
            read_attempts: Número de intentos de lectura
            
        Returns:
            Diccionario con información del equipo o None si no se detecta
        """
        for baud_rate in self.COMMON_BAUDS:
            try:
                self._log(f"Probando {port_name} a {baud_rate} baud...")
                
                ser = serial.Serial(
                    port=port_name,
                    baudrate=baud_rate,
                    timeout=timeout / read_attempts
                )
                
                # Leer datos durante varios intentos
                buffer = b''
                for attempt in range(read_attempts):
                    if ser.in_waiting > 0:
                        data = ser.read(ser.in_waiting)
                        buffer += data
                        self._log(f"  Recibidos {len(data)} bytes...", 'debug')
                    time.sleep(timeout / read_attempts)
                
                ser.close()
                
                # Si recibimos datos, intentar identificar el equipo
                if buffer:
                    equipment = self._identify_equipment(buffer)
                    if equipment:
                        equipment['port'] = port_name
                        equipment['baud_rate'] = baud_rate
                        equipment['data_bits'] = 8
                        equipment['stop_bits'] = 1
                        equipment['parity'] = 'N'
                        self._log(f"✓ Equipo detectado en {port_name}: {equipment['equipment_name']}")
                        return equipment
                
            except serial.SerialException as e:
                self._log(f"Error probando {port_name} a {baud_rate}: {e}", 'debug')
                continue
            except Exception as e:
                self._log(f"Error inesperado en {port_name}: {e}", 'error')
                continue
        
        self._log(f"✗ No se detectó equipo en {port_name}")
        return None
    
    def _identify_equipment(self, data):
        """
        Identifica el tipo de equipo basado en los datos recibidos.
        
        Args:
            data: Datos en bytes recibidos del puerto
            
        Returns:
            Diccionario con información del equipo o None
        """
        for eq_id, eq_info in self.EQUIPMENT_PATTERNS.items():
            for pattern in eq_info['patterns']:
                if pattern in data:
                    return {
                        'equipment_type': eq_info['type'],
                        'equipment_name': eq_info['name'],
                        'pattern_matched': eq_id
                    }
        
        # Si recibimos datos pero no coinciden con patrones conocidos
        if len(data) > 10:
            return {
                'equipment_type': 'unknown',
                'equipment_name': 'Unknown Medical Device',
                'pattern_matched': None
            }
        
        return None
    
    def scan_all_ports(self):
        """
        Escanea todos los puertos COM disponibles e intenta detectar equipos.
        
        Returns:
            Diccionario con puertos detectados y sus equipos
        """
        self._log("=" * 60)
        self._log("Iniciando escaneo automático de puertos...")
        self._log("=" * 60)
        
        available_ports = self.list_available_ports()
        self._log(f"Puertos COM disponibles: {len(available_ports)}")
        
        for port_info in available_ports:
            self._log(f"\nEscaneando {port_info['port']} ({port_info['description']})...")
            equipment = self.probe_port(port_info['port'])
            
            if equipment:
                self.detected_ports[port_info['port']] = {
                    **equipment,
                    'description': port_info['description'],
                    'hwid': port_info['hwid']
                }
        
        self._log("=" * 60)
        self._log(f"Escaneo completado. Equipos detectados: {len(self.detected_ports)}")
        self._log("=" * 60)
        
        return self.detected_ports
    
    def save_cache(self):
        """Guarda el mapeo de puertos en un archivo cache."""
        try:
            with open(self.cache_file, 'w', encoding='utf-8') as f:
                json.dump(self.detected_ports, f, indent=2)
            self._log(f"Cache guardado en {self.cache_file}")
        except Exception as e:
            self._log(f"Error guardando cache: {e}", 'error')
    
    def load_cache(self):
        """
        Carga el mapeo de puertos desde el archivo cache.
        
        Returns:
            Diccionario con puertos cacheados o dict vacío si no existe
        """
        if not os.path.exists(self.cache_file):
            return {}
        
        try:
            with open(self.cache_file, 'r', encoding='utf-8') as f:
                self.detected_ports = json.load(f)
            self._log(f"Cache cargado desde {self.cache_file}")
            return self.detected_ports
        except Exception as e:
            self._log(f"Error cargando cache: {e}", 'error')
            return {}
    
    def verify_cached_ports(self):
        """
        Verifica que los puertos cacheados siguen siendo válidos.
        
        Returns:
            Lista de puertos que ya no son válidos
        """
        invalid_ports = []
        available = [p['port'] for p in self.list_available_ports()]
        
        for port in list(self.detected_ports.keys()):
            if port not in available:
                self._log(f"Puerto {port} ya no está disponible")
                invalid_ports.append(port)
                del self.detected_ports[port]
        
        if invalid_ports:
            self.save_cache()
        
        return invalid_ports
    
    def get_ports_config(self):
        """
        Convierte los puertos detectados al formato esperado por SerialCollector.
        
        Returns:
            Lista de configuraciones de puertos
        """
        config = []
        
        for port_name, port_info in self.detected_ports.items():
            config.append({
                'port': port_name,
                'baud_rate': port_info.get('baud_rate', 9600),
                'data_bits': port_info.get('data_bits', 8),
                'stop_bits': port_info.get('stop_bits', 1),
                'parity': port_info.get('parity', 'N'),
                'equipment_type': port_info.get('equipment_type', 'unknown'),
                'equipment_name': port_info.get('equipment_name', 'Unknown Equipment')
            })
        
        return config
