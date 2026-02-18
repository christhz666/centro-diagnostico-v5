"""
DICOM Listener - Actúa como servidor DICOM para recibir imágenes médicas
"""

import os
import time
from datetime import datetime
from pathlib import Path


class DicomListener:
    """
    Escucha conexiones DICOM para recibir imágenes de sonografía/rayos X.
    
    NOTA: Esta es una implementación básica. Para producción, considerar usar
    pynetdicom para un servidor DICOM completo con soporte de C-STORE.
    """
    
    def __init__(self, ae_title, port, store_path, queue, logger):
        """
        Inicializa el DICOM Listener.
        
        Args:
            ae_title: Application Entity Title
            port: Puerto de escucha
            store_path: Carpeta donde guardar archivos recibidos
            queue: Cola para poner los datos
            logger: Logger para mensajes
        """
        self.ae_title = ae_title
        self.port = port
        self.store_path = store_path
        self.queue = queue
        self.logger = logger
        self.running = False
        
        # Crear directorio de almacenamiento
        Path(store_path).mkdir(parents=True, exist_ok=True)
    
    def start(self):
        """Inicia el listener DICOM."""
        self.running = True
        self.logger.info(f"DICOM Listener: Iniciando en puerto {self.port}")
        self.logger.info(f"AE Title: {self.ae_title}")
        self.logger.info(f"Almacenamiento: {self.store_path}")
        
        try:
            # Importar pynetdicom aquí para que sea opcional
            from pynetdicom import AE, evt, StoragePresentationContexts
            from pynetdicom.sop_class import Verification
            
            # Crear Application Entity
            ae = AE(ae_title=self.ae_title)
            
            # Agregar contextos de presentación para Storage
            ae.supported_contexts = StoragePresentationContexts
            
            # Agregar soporte para C-ECHO (verificación)
            ae.add_supported_context(Verification)
            
            # Configurar handlers
            handlers = [
                (evt.EVT_C_STORE, self._handle_store),
                (evt.EVT_CONN_OPEN, self._handle_conn_open),
                (evt.EVT_CONN_CLOSE, self._handle_conn_close)
            ]
            
            # Iniciar servidor
            self.logger.info("Servidor DICOM iniciado y escuchando...")
            ae.start_server(
                ('', self.port),
                block=True,
                evt_handlers=handlers
            )
            
        except ImportError:
            self.logger.error("pynetdicom no está instalado. DICOM Listener no disponible.")
            self.logger.error("Instalar con: pip install pynetdicom")
            
        except Exception as e:
            self.logger.error(f"Error en DICOM Listener: {e}")
    
    def _handle_conn_open(self, event):
        """Handler para nueva conexión."""
        addr = event.address
        self.logger.info(f"Conexión DICOM abierta desde {addr[0]}:{addr[1]}")
    
    def _handle_conn_close(self, event):
        """Handler para cierre de conexión."""
        self.logger.info("Conexión DICOM cerrada")
    
    def _handle_store(self, event):
        """
        Handler para recepción de imagen DICOM (C-STORE).
        
        Args:
            event: Evento de pynetdicom
            
        Returns:
            Status code (0x0000 = success)
        """
        try:
            # Obtener dataset
            ds = event.dataset
            
            # Extraer información del paciente
            patient_id = getattr(ds, 'PatientID', 'UNKNOWN')
            patient_name = str(getattr(ds, 'PatientName', 'UNKNOWN'))
            study_date = getattr(ds, 'StudyDate', '')
            study_time = getattr(ds, 'StudyTime', '')
            modality = getattr(ds, 'Modality', 'UNKNOWN')
            series_description = getattr(ds, 'SeriesDescription', '')
            
            self.logger.info(f"Imagen DICOM recibida:")
            self.logger.info(f"  Paciente: {patient_name} ({patient_id})")
            self.logger.info(f"  Modalidad: {modality}")
            self.logger.info(f"  Fecha: {study_date}")
            
            # Generar nombre de archivo único
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            filename = f"{patient_id}_{modality}_{timestamp}.dcm"
            filepath = os.path.join(self.store_path, filename)
            
            # Guardar archivo DICOM
            ds.save_as(filepath, write_like_original=False)
            self.logger.info(f"Archivo guardado: {filename}")
            
            # Crear objeto de datos para la cola
            data = {
                'source': 'dicom_listener',
                'equipment_type': modality.lower(),
                'equipment_name': f"DICOM {modality}",
                'data_type': 'dicom',
                'file_name': filename,
                'file_path': filepath,
                'patient_id': patient_id,
                'patient_name': patient_name,
                'study_date': study_date,
                'study_time': study_time,
                'modality': modality,
                'series_description': series_description,
                'timestamp': datetime.now().isoformat()
            }
            
            # Poner en la cola
            self.queue.put(data)
            self.logger.info("Imagen DICOM puesta en cola")
            
            # Retornar éxito
            return 0x0000
            
        except Exception as e:
            self.logger.error(f"Error procesando imagen DICOM: {e}")
            # Retornar error
            return 0xC000
    
    def stop(self):
        """Detiene el listener DICOM."""
        self.logger.info("Deteniendo DICOM Listener...")
        self.running = False
