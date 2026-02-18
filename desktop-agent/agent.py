#!/usr/bin/env python3
"""
Desktop Agent - Integración de Equipos Médicos
Centro Diagnóstico v5

Este agente se ejecuta en PCs de laboratorio y recolecta datos de equipos médicos
para enviarlos automáticamente al servidor central.
"""

import json
import logging
import os
import sys
import time
import threading
from queue import Queue
from pathlib import Path

# Importar collectors
from collectors.serial_collector import SerialCollector
from collectors.file_watcher import FileWatcherCollector
from collectors.dicom_listener import DicomListener

# Importar uploader
from uploader import ResultUploader


class DesktopAgent:
    """Agente principal que coordina los collectors y el uploader."""
    
    def __init__(self, config_path='config.json'):
        """
        Inicializa el agente.
        
        Args:
            config_path: Ruta al archivo de configuración
        """
        self.config_path = config_path
        self.config = self._load_config()
        self.queue = Queue()
        self.collectors = []
        self.uploader = None
        self.running = False
        
        # Configurar logging
        self._setup_logging()
        
        self.logger.info("=" * 60)
        self.logger.info("Desktop Agent - Centro Diagnóstico v5")
        self.logger.info("=" * 60)
        self.logger.info(f"Estación: {self.config['station_name']}")
        self.logger.info(f"Servidor: {self.config['server_url']}")
        
    def _load_config(self):
        """Carga la configuración desde el archivo JSON."""
        if not os.path.exists(self.config_path):
            print(f"ERROR: No se encontró el archivo de configuración: {self.config_path}")
            print("Copia config.example.json a config.json y edítalo según tu configuración.")
            sys.exit(1)
            
        try:
            with open(self.config_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception as e:
            print(f"ERROR al cargar configuración: {e}")
            sys.exit(1)
    
    def _setup_logging(self):
        """Configura el sistema de logging."""
        log_level = getattr(logging, self.config.get('log_level', 'INFO'))
        log_file = self.config.get('log_file', 'agent.log')
        
        # Configurar formato
        log_format = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        
        # Configurar handlers
        handlers = [
            logging.FileHandler(log_file, encoding='utf-8'),
            logging.StreamHandler(sys.stdout)
        ]
        
        logging.basicConfig(
            level=log_level,
            format=log_format,
            handlers=handlers
        )
        
        self.logger = logging.getLogger('DesktopAgent')
    
    def _initialize_collectors(self):
        """Inicializa los collectors habilitados según la configuración."""
        collectors_config = self.config.get('collectors', {})
        
        # Serial Collector
        if collectors_config.get('serial', {}).get('enabled', False):
            self.logger.info("Inicializando Serial Collector...")
            try:
                serial_config = collectors_config['serial']
                collector = SerialCollector(
                    ports_config=serial_config.get('ports', []),
                    queue=self.queue,
                    logger=self.logger
                )
                self.collectors.append(collector)
                self.logger.info(f"Serial Collector inicializado con {len(serial_config.get('ports', []))} puertos")
            except Exception as e:
                self.logger.error(f"Error inicializando Serial Collector: {e}")
        
        # File Watcher Collector
        if collectors_config.get('file_watcher', {}).get('enabled', False):
            self.logger.info("Inicializando File Watcher Collector...")
            try:
                fw_config = collectors_config['file_watcher']
                collector = FileWatcherCollector(
                    watch_dirs=fw_config.get('watch_dirs', []),
                    queue=self.queue,
                    logger=self.logger
                )
                self.collectors.append(collector)
                self.logger.info(f"File Watcher inicializado con {len(fw_config.get('watch_dirs', []))} directorios")
            except Exception as e:
                self.logger.error(f"Error inicializando File Watcher: {e}")
        
        # DICOM Listener
        if collectors_config.get('dicom_listener', {}).get('enabled', False):
            self.logger.info("Inicializando DICOM Listener...")
            try:
                dicom_config = collectors_config['dicom_listener']
                collector = DicomListener(
                    ae_title=dicom_config.get('ae_title', 'CENTRO_DIAG'),
                    port=dicom_config.get('port', 11112),
                    store_path=dicom_config.get('store_path', './dicom_received'),
                    queue=self.queue,
                    logger=self.logger
                )
                self.collectors.append(collector)
                self.logger.info(f"DICOM Listener inicializado en puerto {dicom_config.get('port', 11112)}")
            except Exception as e:
                self.logger.error(f"Error inicializando DICOM Listener: {e}")
        
        if not self.collectors:
            self.logger.warning("No hay collectors habilitados. Revisa la configuración.")
    
    def _initialize_uploader(self):
        """Inicializa el uploader."""
        self.logger.info("Inicializando Uploader...")
        try:
            self.uploader = ResultUploader(
                server_url=self.config['server_url'],
                station_name=self.config['station_name'],
                api_key=self.config.get('api_key', ''),
                queue=self.queue,
                upload_interval=self.config.get('upload_interval_seconds', 10),
                retry_on_failure=self.config.get('retry_on_failure', True),
                max_retries=self.config.get('max_retries', 3),
                logger=self.logger
            )
            self.logger.info("Uploader inicializado")
        except Exception as e:
            self.logger.error(f"Error inicializando Uploader: {e}")
            raise
    
    def start(self):
        """Inicia el agente y todos sus componentes."""
        self.logger.info("Iniciando Desktop Agent...")
        
        # Inicializar componentes
        self._initialize_collectors()
        self._initialize_uploader()
        
        if not self.collectors and not self.uploader:
            self.logger.error("No hay componentes para iniciar. Saliendo...")
            return
        
        self.running = True
        
        # Iniciar collectors en threads separados
        for collector in self.collectors:
            thread = threading.Thread(
                target=collector.start,
                daemon=True,
                name=f"Collector-{collector.__class__.__name__}"
            )
            thread.start()
            self.logger.info(f"Thread iniciado: {thread.name}")
        
        # Iniciar uploader en thread separado
        if self.uploader:
            thread = threading.Thread(
                target=self.uploader.start,
                daemon=True,
                name="Uploader"
            )
            thread.start()
            self.logger.info(f"Thread iniciado: {thread.name}")
        
        self.logger.info("=" * 60)
        self.logger.info("Desktop Agent ejecutándose correctamente")
        self.logger.info("Presiona Ctrl+C para detener")
        self.logger.info("=" * 60)
        
        # Mantener el programa en ejecución
        try:
            while self.running:
                time.sleep(1)
        except KeyboardInterrupt:
            self.logger.info("Recibida señal de interrupción...")
            self.stop()
    
    def stop(self):
        """Detiene el agente y todos sus componentes."""
        self.logger.info("Deteniendo Desktop Agent...")
        self.running = False
        
        # Detener collectors
        for collector in self.collectors:
            try:
                collector.stop()
                self.logger.info(f"Collector detenido: {collector.__class__.__name__}")
            except Exception as e:
                self.logger.error(f"Error deteniendo collector: {e}")
        
        # Detener uploader
        if self.uploader:
            try:
                self.uploader.stop()
                self.logger.info("Uploader detenido")
            except Exception as e:
                self.logger.error(f"Error deteniendo uploader: {e}")
        
        self.logger.info("Desktop Agent detenido correctamente")


def main():
    """Función principal."""
    # Buscar archivo de configuración
    config_path = 'config.json'
    if len(sys.argv) > 1:
        config_path = sys.argv[1]
    
    # Crear y ejecutar el agente
    agent = DesktopAgent(config_path)
    agent.start()


if __name__ == '__main__':
    main()
