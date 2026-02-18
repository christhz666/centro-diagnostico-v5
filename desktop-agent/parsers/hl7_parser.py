"""
HL7 Parser - Parsea mensajes HL7 v2.5 de equipos de laboratorio
"""

import re
from datetime import datetime


class HL7Parser:
    """Parser para mensajes HL7 v2.5."""
    
    @staticmethod
    def parse(message):
        """
        Parsea un mensaje HL7 y extrae información relevante.
        
        Args:
            message: String con el mensaje HL7
            
        Returns:
            Dict con los datos parseados
        """
        try:
            # Limpiar el mensaje de caracteres de control
            message = message.replace('\x0B', '').replace('\x1C', '').replace('\x0D', '')
            
            # Separar en líneas (segmentos)
            segments = [line for line in message.split('\n') if line.strip()]
            
            # Inicializar resultado
            result = {
                'patient_id': None,
                'patient_name': None,
                'order_id': None,
                'test_results': [],
                'timestamp': None
            }
            
            # Procesar cada segmento
            for segment in segments:
                if not segment:
                    continue
                
                # Dividir segmento en campos
                fields = segment.split('|')
                segment_type = fields[0] if fields else ''
                
                # Segmento MSH (Message Header)
                if segment_type == 'MSH':
                    result['timestamp'] = HL7Parser._parse_timestamp(fields[6] if len(fields) > 6 else '')
                
                # Segmento PID (Patient Identification)
                elif segment_type == 'PID':
                    result['patient_id'] = HL7Parser._parse_patient_id(fields)
                    result['patient_name'] = HL7Parser._parse_patient_name(fields)
                
                # Segmento OBR (Observation Request)
                elif segment_type == 'OBR':
                    result['order_id'] = fields[2] if len(fields) > 2 else None
                
                # Segmento OBX (Observation/Result)
                elif segment_type == 'OBX':
                    test_result = HL7Parser._parse_obx(fields)
                    if test_result:
                        result['test_results'].append(test_result)
            
            return result
            
        except Exception as e:
            raise Exception(f"Error parseando mensaje HL7: {e}")
    
    @staticmethod
    def _parse_patient_id(fields):
        """Extrae el Patient ID del segmento PID."""
        # PID-3: Patient Identifier List
        if len(fields) > 3:
            pid_field = fields[3]
            # El ID puede estar en formato: ID^ID_TYPE^ID_SYSTEM
            components = pid_field.split('^')
            return components[0] if components else None
        return None
    
    @staticmethod
    def _parse_patient_name(fields):
        """Extrae el nombre del paciente del segmento PID."""
        # PID-5: Patient Name (Formato: Apellido^Nombre^SegundoNombre)
        if len(fields) > 5:
            name_field = fields[5]
            components = name_field.split('^')
            if len(components) >= 2:
                return f"{components[1]} {components[0]}"
            elif len(components) == 1:
                return components[0]
        return None
    
    @staticmethod
    def _parse_obx(fields):
        """
        Parsea un segmento OBX (Observation/Result).
        
        OBX structure:
        0: OBX
        1: Set ID
        2: Value Type (NM=numeric, ST=string, etc.)
        3: Observation Identifier (código^nombre^sistema)
        4: Observation Sub-ID
        5: Observation Value
        6: Units
        7: Reference Range
        8: Abnormal Flags (N=normal, H=high, L=low, etc.)
        """
        if len(fields) < 6:
            return None
        
        try:
            # Extraer código y nombre del test
            identifier = fields[3].split('^')
            test_code = identifier[0] if len(identifier) > 0 else ''
            test_name = identifier[1] if len(identifier) > 1 else test_code
            
            # Valor del resultado
            value = fields[5]
            
            # Unidades
            units = fields[6] if len(fields) > 6 else ''
            
            # Rango de referencia
            reference_range = fields[7] if len(fields) > 7 else ''
            
            # Flags (normal, alto, bajo, crítico)
            abnormal_flag = fields[8] if len(fields) > 8 else ''
            status = HL7Parser._interpret_flag(abnormal_flag)
            
            return {
                'test_code': test_code,
                'test_name': test_name,
                'value': value,
                'units': units,
                'reference_range': reference_range,
                'status': status
            }
            
        except Exception as e:
            return None
    
    @staticmethod
    def _interpret_flag(flag):
        """
        Interpreta el flag de anormalidad.
        
        Flags comunes:
        N = Normal
        H = High
        L = Low
        HH = Critically high
        LL = Critically low
        """
        flag = flag.upper().strip()
        
        if flag in ['N', '']:
            return 'normal'
        elif flag in ['H', 'HH', '>']:
            return 'alto'
        elif flag in ['L', 'LL', '<']:
            return 'bajo'
        elif flag in ['HH', 'LL', 'AA']:
            return 'critico'
        else:
            return 'normal'
    
    @staticmethod
    def _parse_timestamp(timestamp_str):
        """
        Parsea un timestamp HL7 (formato: YYYYMMDDHHMMSS).
        
        Args:
            timestamp_str: String con el timestamp
            
        Returns:
            ISO timestamp string
        """
        try:
            if not timestamp_str or len(timestamp_str) < 8:
                return datetime.now().isoformat()
            
            # Formato típico: YYYYMMDDHHMMSS o YYYYMMDD
            timestamp_str = timestamp_str[:14].ljust(14, '0')
            
            year = int(timestamp_str[0:4])
            month = int(timestamp_str[4:6])
            day = int(timestamp_str[6:8])
            hour = int(timestamp_str[8:10])
            minute = int(timestamp_str[10:12])
            second = int(timestamp_str[12:14])
            
            dt = datetime(year, month, day, hour, minute, second)
            return dt.isoformat()
            
        except:
            return datetime.now().isoformat()
