"""
Serial Collector - Recolecta datos de equipos conectados por puerto serial (RS-232/USB)
"""

import serial
import threading
import time
from datetime import datetime


class SerialCollector:
    """Recolecta datos de puertos seriales."""
    
    # Delimitadores estándar HL7
    VT = b'\x0B'  # Vertical Tab - inicio de mensaje
    FS = b'\x1C'  # File Separator - fin de mensaje
    CR = b'\x0D'  # Carriage Return
    
    def __init__(self, ports_config, queue, logger):
        """
        Inicializa el Serial Collector.
        
        Args:
            ports_config: Lista de configuraciones de puertos
            queue: Cola para poner los datos recolectados
            logger: Logger para mensajes
        """
        self.ports_config = ports_config
        self.queue = queue
        self.logger = logger
        self.running = False
        self.connections = []
    
    def start(self):
        """Inicia la recolección de datos de todos los puertos configurados."""
        self.running = True
        self.logger.info(f"Serial Collector: Iniciando con {len(self.ports_config)} puertos")
        
        # Crear un thread por cada puerto
        for port_config in self.ports_config:
            thread = threading.Thread(
                target=self._read_port,
                args=(port_config,),
                daemon=True,
                name=f"Serial-{port_config['port']}"
            )
            thread.start()
            self.logger.info(f"Thread iniciado para puerto {port_config['port']}")
    
    def _read_port(self, port_config):
        """
        Lee datos continuamente de un puerto serial.
        
        Args:
            port_config: Configuración del puerto
        """
        port_name = port_config['port']
        baud_rate = port_config.get('baud_rate', 9600)
        data_bits = port_config.get('data_bits', 8)
        stop_bits = port_config.get('stop_bits', 1)
        parity = port_config.get('parity', 'N')
        equipment_type = port_config.get('equipment_type', 'unknown')
        equipment_name = port_config.get('equipment_name', 'Unknown Equipment')
        
        ser = None
        buffer = b''
        
        while self.running:
            try:
                # Intentar abrir el puerto si no está abierto
                if ser is None or not ser.is_open:
                    self.logger.info(f"Conectando a {port_name} ({baud_rate} baud)...")
                    ser = serial.Serial(
                        port=port_name,
                        baudrate=baud_rate,
                        bytesize=data_bits,
                        stopbits=stop_bits,
                        parity=parity,
                        timeout=1
                    )
                    self.connections.append(ser)
                    self.logger.info(f"Conectado a {port_name}")
                
                # Leer datos
                if ser.in_waiting > 0:
                    data = ser.read(ser.in_waiting)
                    buffer += data
                    
                    # Buscar mensajes completos en el buffer
                    messages = self._extract_messages(buffer)
                    
                    for message in messages:
                        # Remover el mensaje del buffer
                        buffer = buffer.replace(message, b'', 1)
                        
                        # Procesar el mensaje
                        self._process_message(message, equipment_type, equipment_name, port_name)
                
                # Pequeña pausa para no saturar la CPU
                time.sleep(0.1)
                
            except serial.SerialException as e:
                self.logger.error(f"Error en puerto {port_name}: {e}")
                if ser:
                    try:
                        ser.close()
                    except:
                        pass
                    ser = None
                # Esperar antes de reintentar
                time.sleep(5)
                
            except Exception as e:
                self.logger.error(f"Error inesperado en {port_name}: {e}")
                time.sleep(5)
        
        # Cleanup al salir
        if ser and ser.is_open:
            ser.close()
            self.logger.info(f"Puerto {port_name} cerrado")
    
    def _extract_messages(self, buffer):
        """
        Extrae mensajes completos del buffer.
        
        Los mensajes HL7 están delimitados por:
        VT (0x0B) al inicio, FS (0x1C) al final, seguido de CR (0x0D)
        
        Args:
            buffer: Buffer de bytes
            
        Returns:
            Lista de mensajes completos
        """
        messages = []
        
        # Buscar patrón VT...FS+CR
        start = 0
        while True:
            # Buscar inicio de mensaje
            vt_pos = buffer.find(self.VT, start)
            if vt_pos == -1:
                break
            
            # Buscar fin de mensaje
            fs_pos = buffer.find(self.FS, vt_pos)
            if fs_pos == -1:
                break
            
            # Verificar CR después de FS
            if fs_pos + 1 < len(buffer) and buffer[fs_pos + 1:fs_pos + 2] == self.CR:
                # Mensaje completo encontrado
                message = buffer[vt_pos:fs_pos + 2]
                messages.append(message)
                start = fs_pos + 2
            else:
                start = fs_pos + 1
        
        return messages
    
    def _process_message(self, message, equipment_type, equipment_name, port_name):
        """
        Procesa un mensaje recibido y lo pone en la cola.
        
        Args:
            message: Mensaje en bytes
            equipment_type: Tipo de equipo
            equipment_name: Nombre del equipo
            port_name: Nombre del puerto
        """
        try:
            # Decodificar mensaje
            message_str = message.decode('utf-8', errors='replace')
            
            self.logger.info(f"Mensaje recibido de {equipment_name} ({port_name})")
            self.logger.debug(f"Contenido: {message_str[:200]}...")  # Log primeros 200 chars
            
            # Crear objeto de datos para la cola
            data = {
                'source': 'serial',
                'equipment_type': equipment_type,
                'equipment_name': equipment_name,
                'port': port_name,
                'data_type': 'hl7',
                'raw_data': message_str,
                'timestamp': datetime.now().isoformat()
            }
            
            # Poner en la cola para procesamiento
            self.queue.put(data)
            self.logger.info(f"Mensaje puesto en cola: {equipment_name}")
            
        except Exception as e:
            self.logger.error(f"Error procesando mensaje de {port_name}: {e}")
    
    def stop(self):
        """Detiene la recolección de datos."""
        self.logger.info("Deteniendo Serial Collector...")
        self.running = False
        
        # Cerrar todas las conexiones
        for ser in self.connections:
            try:
                if ser.is_open:
                    ser.close()
            except:
                pass
