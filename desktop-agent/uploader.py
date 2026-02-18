"""
Result Uploader - Envía resultados al servidor central vía API REST
"""

import json
import time
import requests
from datetime import datetime
from parsers.hl7_parser import HL7Parser
from parsers.dicom_parser import DicomParser


class ResultUploader:
    """Procesa la cola de datos y los envía al servidor."""
    
    def __init__(self, server_url, station_name, api_key, queue, 
                 upload_interval, retry_on_failure, max_retries, logger):
        """
        Inicializa el uploader.
        
        Args:
            server_url: URL base del servidor
            station_name: Nombre de la estación
            api_key: Clave de API para autenticación
            queue: Cola de datos a procesar
            upload_interval: Intervalo entre uploads en segundos
            retry_on_failure: Si reintentar en caso de fallo
            max_retries: Número máximo de reintentos
            logger: Logger para mensajes
        """
        self.server_url = server_url.rstrip('/')
        self.station_name = station_name
        self.api_key = api_key
        self.queue = queue
        self.upload_interval = upload_interval
        self.retry_on_failure = retry_on_failure
        self.max_retries = max_retries
        self.logger = logger
        self.running = False
        
        # Estadísticas
        self.stats = {
            'enviados': 0,
            'fallidos': 0,
            'ultimo_envio': None
        }
    
    def start(self):
        """Inicia el procesamiento y envío de datos."""
        self.running = True
        self.logger.info(f"Uploader: Iniciando (intervalo: {self.upload_interval}s)")
        
        while self.running:
            try:
                # Verificar si hay datos en la cola
                if not self.queue.empty():
                    data = self.queue.get()
                    self._process_and_upload(data)
                else:
                    # No hay datos, esperar
                    time.sleep(1)
                    
            except Exception as e:
                self.logger.error(f"Error en Uploader: {e}")
                time.sleep(5)
    
    def _process_and_upload(self, data):
        """
        Procesa un dato de la cola y lo envía al servidor.
        
        Args:
            data: Diccionario con los datos recolectados
        """
        try:
            self.logger.info(f"Procesando dato de {data.get('source')} ({data.get('equipment_name')})")
            
            # Parsear los datos según el tipo
            parsed_data = self._parse_data(data)
            
            if not parsed_data:
                self.logger.warning("No se pudo parsear el dato")
                return
            
            # Preparar payload para el servidor
            payload = self._prepare_payload(data, parsed_data)
            
            # Enviar al servidor
            success = self._send_to_server(payload)
            
            if success:
                self.stats['enviados'] += 1
                self.stats['ultimo_envio'] = datetime.now().isoformat()
                self.logger.info(f"✓ Dato enviado exitosamente (Total: {self.stats['enviados']})")
            else:
                self.stats['fallidos'] += 1
                self.logger.error(f"✗ Fallo al enviar dato (Total fallidos: {self.stats['fallidos']})")
            
        except Exception as e:
            self.logger.error(f"Error procesando dato: {e}")
            self.stats['fallidos'] += 1
    
    def _parse_data(self, data):
        """
        Parsea los datos según su tipo.
        
        Args:
            data: Datos crudos
            
        Returns:
            Datos parseados o None si hay error
        """
        try:
            data_type = data.get('data_type', '')
            
            if data_type == 'hl7':
                # Parsear mensaje HL7
                raw_data = data.get('raw_data', '')
                if isinstance(raw_data, bytes):
                    raw_data = raw_data.decode('utf-8', errors='replace')
                return HL7Parser.parse(raw_data)
                
            elif data_type == 'dicom':
                # Parsear archivo DICOM
                file_path = data.get('file_path')
                if file_path:
                    return DicomParser.parse(file_path)
                else:
                    # Si viene de DICOM listener, ya tiene metadatos
                    return {
                        'patient_id': data.get('patient_id'),
                        'patient_name': data.get('patient_name'),
                        'study_date': data.get('study_date'),
                        'modality': data.get('modality'),
                        'series_description': data.get('series_description')
                    }
            
            else:
                self.logger.warning(f"Tipo de dato no soportado: {data_type}")
                return None
                
        except Exception as e:
            self.logger.error(f"Error parseando dato: {e}")
            return None
    
    def _prepare_payload(self, raw_data, parsed_data):
        """
        Prepara el payload en el formato esperado por el servidor.
        
        Args:
            raw_data: Datos crudos del collector
            parsed_data: Datos parseados
            
        Returns:
            Dict con el payload para el servidor
        """
        # Formato base según la documentación del servidor
        payload = {
            'station_name': self.station_name,
            'equipment_type': raw_data.get('equipment_type'),
            'equipment_name': raw_data.get('equipment_name'),
            'timestamp': raw_data.get('timestamp', datetime.now().isoformat()),
        }
        
        # Agregar datos específicos según el tipo
        if raw_data.get('data_type') == 'hl7':
            # Formato para resultados de laboratorio
            payload['paciente_id'] = parsed_data.get('patient_id')
            payload['cedula'] = parsed_data.get('patient_id')  # Usar patient_id como cédula por ahora
            payload['orden_id'] = parsed_data.get('order_id')
            payload['tipo_estudio'] = raw_data.get('equipment_type')
            
            # Convertir resultados de tests a formato de valores
            valores = {}
            for test in parsed_data.get('test_results', []):
                valores[test['test_name']] = {
                    'valor': test['value'],
                    'unidad': test['units'],
                    'referencia': test['reference_range'],
                    'estado': test['status']
                }
            payload['valores'] = valores
            
        elif raw_data.get('data_type') == 'dicom':
            # Formato para imágenes DICOM
            payload['paciente_id'] = parsed_data.get('patient_id')
            payload['tipo_estudio'] = parsed_data.get('modality', '').lower()
            payload['study_date'] = parsed_data.get('study_date')
            payload['series_description'] = parsed_data.get('series_description')
            payload['file_path'] = raw_data.get('file_path')
        
        return payload
    
    def _send_to_server(self, payload):
        """
        Envía el payload al servidor.
        
        Args:
            payload: Dict con los datos a enviar
            
        Returns:
            True si se envió exitosamente, False en caso contrario
        """
        endpoint = f"{self.server_url}/equipos/recibir-json"
        
        headers = {
            'Content-Type': 'application/json'
        }
        
        # Agregar API key si está configurada
        if self.api_key:
            headers['Authorization'] = f'Bearer {self.api_key}'
        
        retries = 0
        
        while retries <= self.max_retries:
            try:
                self.logger.debug(f"Enviando a: {endpoint}")
                self.logger.debug(f"Payload: {json.dumps(payload, indent=2)}")
                
                response = requests.post(
                    endpoint,
                    json=payload,
                    headers=headers,
                    timeout=30
                )
                
                if response.status_code == 200:
                    response_data = response.json()
                    self.logger.info(f"Respuesta del servidor: {response_data}")
                    
                    # Si el servidor devuelve un código de muestra, loguearlo
                    if 'codigoMuestra' in response_data:
                        self.logger.info(f"Código de muestra generado: {response_data['codigoMuestra']}")
                    
                    return True
                    
                else:
                    self.logger.error(f"Error del servidor: {response.status_code} - {response.text}")
                    
                    if not self.retry_on_failure:
                        return False
                    
                    retries += 1
                    if retries <= self.max_retries:
                        wait_time = retries * 5  # Backoff exponencial
                        self.logger.warning(f"Reintentando en {wait_time}s... (intento {retries}/{self.max_retries})")
                        time.sleep(wait_time)
                    
            except requests.exceptions.Timeout:
                self.logger.error("Timeout al conectar con el servidor")
                retries += 1
                if retries <= self.max_retries and self.retry_on_failure:
                    time.sleep(retries * 5)
                else:
                    return False
                    
            except requests.exceptions.ConnectionError:
                self.logger.error("Error de conexión con el servidor")
                retries += 1
                if retries <= self.max_retries and self.retry_on_failure:
                    time.sleep(retries * 5)
                else:
                    return False
                    
            except Exception as e:
                self.logger.error(f"Error al enviar al servidor: {e}")
                return False
        
        return False
    
    def stop(self):
        """Detiene el uploader."""
        self.logger.info("Deteniendo Uploader...")
        self.running = False
        self.logger.info(f"Estadísticas finales: {self.stats}")
