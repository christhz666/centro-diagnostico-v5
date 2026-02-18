"""
DICOM Parser - Extrae metadatos de archivos DICOM
"""

from datetime import datetime


class DicomParser:
    """Parser para archivos DICOM."""
    
    @staticmethod
    def parse(file_path):
        """
        Parsea un archivo DICOM y extrae metadatos relevantes.
        
        Args:
            file_path: Ruta al archivo DICOM
            
        Returns:
            Dict con los metadatos extraídos
        """
        try:
            import pydicom
            
            # Leer archivo DICOM
            ds = pydicom.dcmread(file_path)
            
            # Extraer metadatos
            result = {
                'patient_id': DicomParser._get_tag(ds, 'PatientID'),
                'patient_name': DicomParser._get_tag(ds, 'PatientName'),
                'patient_birth_date': DicomParser._parse_date(DicomParser._get_tag(ds, 'PatientBirthDate')),
                'patient_sex': DicomParser._get_tag(ds, 'PatientSex'),
                'study_instance_uid': DicomParser._get_tag(ds, 'StudyInstanceUID'),
                'study_date': DicomParser._parse_date(DicomParser._get_tag(ds, 'StudyDate')),
                'study_time': DicomParser._parse_time(DicomParser._get_tag(ds, 'StudyTime')),
                'study_description': DicomParser._get_tag(ds, 'StudyDescription'),
                'series_instance_uid': DicomParser._get_tag(ds, 'SeriesInstanceUID'),
                'series_number': DicomParser._get_tag(ds, 'SeriesNumber'),
                'series_description': DicomParser._get_tag(ds, 'SeriesDescription'),
                'modality': DicomParser._get_tag(ds, 'Modality'),
                'sop_instance_uid': DicomParser._get_tag(ds, 'SOPInstanceUID'),
                'institution_name': DicomParser._get_tag(ds, 'InstitutionName'),
                'manufacturer': DicomParser._get_tag(ds, 'Manufacturer'),
                'manufacturer_model': DicomParser._get_tag(ds, 'ManufacturerModelName'),
                'rows': DicomParser._get_tag(ds, 'Rows'),
                'columns': DicomParser._get_tag(ds, 'Columns'),
                'timestamp': datetime.now().isoformat()
            }
            
            return result
            
        except ImportError:
            raise Exception("pydicom no está instalado. Instalar con: pip install pydicom")
        except Exception as e:
            raise Exception(f"Error parseando archivo DICOM: {e}")
    
    @staticmethod
    def _get_tag(ds, tag_name):
        """
        Obtiene el valor de un tag DICOM de forma segura.
        
        Args:
            ds: Dataset de pydicom
            tag_name: Nombre del tag
            
        Returns:
            Valor del tag o None si no existe
        """
        try:
            value = getattr(ds, tag_name, None)
            if value is not None:
                return str(value)
            return None
        except:
            return None
    
    @staticmethod
    def _parse_date(date_str):
        """
        Parsea una fecha DICOM (formato: YYYYMMDD).
        
        Args:
            date_str: String con la fecha
            
        Returns:
            Fecha en formato ISO (YYYY-MM-DD) o None
        """
        if not date_str or len(date_str) < 8:
            return None
        
        try:
            year = date_str[0:4]
            month = date_str[4:6]
            day = date_str[6:8]
            return f"{year}-{month}-{day}"
        except:
            return None
    
    @staticmethod
    def _parse_time(time_str):
        """
        Parsea una hora DICOM (formato: HHMMSS.FFFFFF).
        
        Args:
            time_str: String con la hora
            
        Returns:
            Hora en formato ISO (HH:MM:SS) o None
        """
        if not time_str or len(time_str) < 6:
            return None
        
        try:
            hour = time_str[0:2]
            minute = time_str[2:4]
            second = time_str[4:6]
            return f"{hour}:{minute}:{second}"
        except:
            return None
