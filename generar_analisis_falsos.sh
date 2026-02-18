#!/bin/bash

echo "+--------------------------------------------------------+"
echo "¦   GENERADOR DE ANÁLISIS MÉDICOS FALSOS                ¦"
echo "+--------------------------------------------------------+"

PGPASSWORD='Centro2024Pass!' psql -U centro_user -d centro_diagnostico -h localhost << 'EOSQL'

DO $$
DECLARE
    v_paciente_id INTEGER;
    v_orden_id INTEGER;
    v_orden_detalle_id INTEGER;
    v_estudio_id INTEGER;
    v_precio NUMERIC(10,2);
    v_contador INTEGER := 0;
BEGIN
    -- Para cada paciente (primeros 5)
    FOR v_paciente_id IN (SELECT id FROM pacientes ORDER BY id LIMIT 5) LOOP
        
        -- Crear orden
        INSERT INTO ordenes (
            paciente_id,
            numero_orden,
            fecha_orden,
            medico_referente,
            estado,
            created_at
        ) VALUES (
            v_paciente_id,
            'ORD-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD((RANDOM() * 1000)::INTEGER::TEXT, 4, '0'),
            CURRENT_DATE - (RANDOM() * 30)::INTEGER,
            CASE (RANDOM() * 4)::INTEGER
                WHEN 0 THEN 'Dr. Carlos Méndez'
                WHEN 1 THEN 'Dra. María García'
                WHEN 2 THEN 'Dr. José Rodríguez'
                ELSE 'Dra. Ana Martínez'
            END,
            'completada',
            NOW() - (RANDOM() * 30 || ' days')::INTERVAL
        ) RETURNING id INTO v_orden_id;
        
        -- Crear 2-3 detalles por orden
        FOR i IN 1..(2 + (RANDOM())::INTEGER) LOOP
            
            SELECT id INTO v_estudio_id FROM estudios ORDER BY RANDOM() LIMIT 1;
            v_precio := (100 + RANDOM() * 400)::NUMERIC(10,2);
            
            INSERT INTO orden_detalles (
                orden_id,
                estudio_id,
                precio,
                descuento,
                precio_final,
                estado,
                created_at
            ) VALUES (
                v_orden_id,
                v_estudio_id,
                v_precio,
                0.00,
                v_precio,  -- precio_final = precio - descuento
                'completado',
                NOW() - (RANDOM() * 25 || ' days')::INTERVAL
            ) RETURNING id INTO v_orden_detalle_id;
            
            v_contador := v_contador + 1;
            
            -- Crear resultado
            INSERT INTO resultados (
                orden_detalle_id,
                tipo_archivo,
                nombre_archivo,
                ruta_archivo,
                tamano_bytes,
                hash_archivo,
                datos_dicom,
                interpretacion,
                valores_referencia,
                estado_validacion,
                fecha_importacion,
                created_at
            ) VALUES (
                v_orden_detalle_id,
                'pdf',
                'analisis_' || v_contador || '_' || TO_CHAR(NOW(), 'YYYYMMDD') || '.pdf',
                '/uploads/resultados/' || v_orden_id || '/',
                (50000 + RANDOM() * 500000)::BIGINT,
                MD5(RANDOM()::TEXT),
                jsonb_build_object(
                    'hemoglobina', jsonb_build_object(
                        'valor', (12 + RANDOM() * 6)::NUMERIC(4,2),
                        'unidad', 'g/dL',
                        'referencia', '12-16 g/dL',
                        'estado', CASE WHEN RANDOM() < 0.8 THEN 'normal' ELSE 'bajo' END
                    ),
                    'glucosa', jsonb_build_object(
                        'valor', (70 + RANDOM() * 60)::NUMERIC(5,2),
                        'unidad', 'mg/dL',
                        'referencia', '70-110 mg/dL',
                        'estado', CASE WHEN RANDOM() < 0.7 THEN 'normal' ELSE 'elevado' END
                    ),
                    'colesterol_total', jsonb_build_object(
                        'valor', (150 + RANDOM() * 100)::NUMERIC(5,2),
                        'unidad', 'mg/dL',
                        'referencia', '<200 mg/dL',
                        'estado', CASE WHEN RANDOM() < 0.6 THEN 'normal' ELSE 'elevado' END
                    ),
                    'trigliceridos', jsonb_build_object(
                        'valor', (50 + RANDOM() * 200)::NUMERIC(5,2),
                        'unidad', 'mg/dL',
                        'referencia', '<150 mg/dL',
                        'estado', CASE WHEN RANDOM() < 0.7 THEN 'normal' ELSE 'elevado' END
                    ),
                    'leucocitos', jsonb_build_object(
                        'valor', (4000 + RANDOM() * 7000)::INTEGER,
                        'unidad', 'cel/µL',
                        'referencia', '4000-11000 cel/µL',
                        'estado', CASE WHEN RANDOM() < 0.85 THEN 'normal' ELSE 'anormal' END
                    )
                ),
                CASE (RANDOM() * 3)::INTEGER
                    WHEN 0 THEN 'Todos los valores dentro de parámetros normales. Seguimiento rutinario.'
                    WHEN 1 THEN 'Leve elevación en algunos valores. Se recomienda dieta balanceada y control en 3 meses.'
                    ELSE 'Valores ligeramente alterados. Consultar con médico para evaluación.'
                END,
                'Ver rangos de referencia en cada parámetro',
                CASE WHEN RANDOM() < 0.7 THEN 'validado' ELSE 'pendiente' END,
                NOW() - (RANDOM() * 20 || ' days')::INTERVAL,
                NOW() - (RANDOM() * 20 || ' days')::INTERVAL
            );
            
        END LOOP;
    END LOOP;
    
    RAISE NOTICE '? Creados % nuevos análisis médicos', v_contador;
END $$;

-- Mostrar resumen
SELECT 
    COUNT(*) as total_resultados,
    COUNT(*) FILTER (WHERE estado_validacion = 'validado') as validados,
    COUNT(*) FILTER (WHERE estado_validacion = 'pendiente') as pendientes,
    COUNT(*) FILTER (WHERE tipo_archivo = 'pdf') as pdfs
FROM resultados;

EOSQL

echo ""
echo "? Generación completada"
