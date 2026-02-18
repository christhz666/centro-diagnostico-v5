"""
File Watcher Collector - Monitorea carpetas para archivos nuevos (HL7, DICOM, PDF)
"""

import os
import shutil
import time
from datetime import datetime
from pathlib import Path
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler


class FileHandler(FileSystemEventHandler):
    """Handler para eventos de archivos."""
    
    def __init__(self, collector, dir_config):
        """
        Inicializa el handler.
        
        Args:
            collector: Instancia del FileWatcherCollector
            dir_config: Configuración del directorio
        """
        self.collector = collector
        self.dir_config = dir_config
    
    def on_created(self, event):
        """Se ejecuta cuando se crea un archivo nuevo."""
        if event.is_directory:
            return
        
        # Esperar un poco para asegurar que el archivo esté completo
        time.sleep(0.5)
        
        # Procesar el archivo
        self.collector.process_file(event.src_path, self.dir_config)


class FileWatcherCollector:
    """Monitorea carpetas para detectar archivos nuevos."""
    
    def __init__(self, watch_dirs, queue, logger):
        """
        Inicializa el File Watcher.
        
        Args:
            watch_dirs: Lista de configuraciones de directorios a monitorear
            queue: Cola para poner los datos recolectados
            logger: Logger para mensajes
        """
        self.watch_dirs = watch_dirs
        self.queue = queue
        self.logger = logger
        self.observers = []
        self.running = False
    
    def start(self):
        """Inicia el monitoreo de todas las carpetas configuradas."""
        self.running = True
        self.logger.info(f"File Watcher: Iniciando con {len(self.watch_dirs)} directorios")
        
        for dir_config in self.watch_dirs:
            path = dir_config['path']
            
            # Crear el directorio si no existe
            Path(path).mkdir(parents=True, exist_ok=True)
            
            # Crear directorio para archivos procesados
            processed_path = os.path.join(path, 'procesados')
            Path(processed_path).mkdir(exist_ok=True)
            
            # Crear observer
            event_handler = FileHandler(self, dir_config)
            observer = Observer()
            observer.schedule(event_handler, path, recursive=False)
            observer.start()
            
            self.observers.append(observer)
            self.logger.info(f"Monitoreando: {path} ({dir_config.get('file_type', 'unknown')})")
        
        # Mantener el thread vivo
        try:
            while self.running:
                time.sleep(1)
        except Exception as e:
            self.logger.error(f"Error en File Watcher: {e}")
    
    def process_file(self, file_path, dir_config):
        """
        Procesa un archivo nuevo.
        
        Args:
            file_path: Ruta del archivo
            dir_config: Configuración del directorio
        """
        try:
            # Verificar que el archivo existe y no está vacío
            if not os.path.exists(file_path):
                return
            
            file_size = os.path.getsize(file_path)
            if file_size == 0:
                self.logger.warning(f"Archivo vacío ignorado: {file_path}")
                return
            
            file_name = os.path.basename(file_path)
            file_type = dir_config.get('file_type', 'unknown')
            equipment_type = dir_config.get('equipment_type', 'unknown')
            equipment_name = dir_config.get('equipment_name', 'Unknown Equipment')
            
            self.logger.info(f"Archivo detectado: {file_name} ({file_type})")
            
            # Leer el contenido del archivo
            with open(file_path, 'rb') as f:
                raw_data = f.read()
            
            # Determinar si es texto o binario
            is_text = file_type in ['hl7', 'txt', 'csv']
            
            if is_text:
                try:
                    content = raw_data.decode('utf-8', errors='replace')
                except:
                    content = raw_data.decode('latin-1', errors='replace')
            else:
                # Para archivos binarios (DICOM, PDF), guardar como bytes
                content = raw_data
            
            # Crear objeto de datos para la cola
            data = {
                'source': 'file_watcher',
                'equipment_type': equipment_type,
                'equipment_name': equipment_name,
                'data_type': file_type,
                'file_name': file_name,
                'file_path': file_path,
                'raw_data': content,
                'file_size': file_size,
                'timestamp': datetime.now().isoformat()
            }
            
            # Poner en la cola
            self.queue.put(data)
            self.logger.info(f"Archivo puesto en cola: {file_name}")
            
            # Mover el archivo a la carpeta de procesados
            processed_dir = os.path.join(dir_config['path'], 'procesados')
            processed_path = os.path.join(processed_dir, file_name)
            
            # Si ya existe un archivo con ese nombre, agregar timestamp
            if os.path.exists(processed_path):
                timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
                name, ext = os.path.splitext(file_name)
                processed_path = os.path.join(processed_dir, f"{name}_{timestamp}{ext}")
            
            shutil.move(file_path, processed_path)
            self.logger.info(f"Archivo movido a: {processed_path}")
            
        except Exception as e:
            self.logger.error(f"Error procesando archivo {file_path}: {e}")
    
    def stop(self):
        """Detiene el monitoreo de carpetas."""
        self.logger.info("Deteniendo File Watcher...")
        self.running = False
        
        for observer in self.observers:
            observer.stop()
            observer.join()
