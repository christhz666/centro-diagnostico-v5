--
-- PostgreSQL database dump
--

\restrict SIK848qqJztzawh4OaZSxaOucnNVVZbgN5mWDWjKo9lOdfonOPuCQTFoZEK7vWX

-- Dumped from database version 13.23
-- Dumped by pg_dump version 13.23

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: generar_codigo_paciente(); Type: FUNCTION; Schema: public; Owner: centro_user
--

CREATE FUNCTION public.generar_codigo_paciente() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.codigo_paciente IS NULL THEN
        NEW.codigo_paciente := 'PAC-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || 
                               LPAD(nextval('pacientes_id_seq')::TEXT, 4, '0');
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.generar_codigo_paciente() OWNER TO centro_user;

--
-- Name: generar_numero_factura(); Type: FUNCTION; Schema: public; Owner: centro_user
--

CREATE FUNCTION public.generar_numero_factura() RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE
    nuevo_numero VARCHAR;
    anio VARCHAR;
    contador INTEGER;
BEGIN
    anio := TO_CHAR(CURRENT_DATE, 'YYYY');
    
    SELECT COUNT(*) + 1 INTO contador
    FROM facturas
    WHERE TO_CHAR(fecha_factura, 'YYYY') = anio;
    
    nuevo_numero := 'FAC-' || anio || '-' || LPAD(contador::TEXT, 6, '0');
    
    RETURN nuevo_numero;
END;
$$;


ALTER FUNCTION public.generar_numero_factura() OWNER TO centro_user;

--
-- Name: generar_numero_orden(); Type: FUNCTION; Schema: public; Owner: centro_user
--

CREATE FUNCTION public.generar_numero_orden() RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE
    nuevo_numero VARCHAR;
    anio VARCHAR;
    mes VARCHAR;
    contador INTEGER;
BEGIN
    anio := TO_CHAR(CURRENT_DATE, 'YY');
    mes := TO_CHAR(CURRENT_DATE, 'MM');
    
    SELECT COUNT(*) + 1 INTO contador
    FROM ordenes
    WHERE TO_CHAR(fecha_orden, 'YYMM') = anio || mes;
    
    nuevo_numero := 'ORD-' || anio || mes || '-' || LPAD(contador::TEXT, 5, '0');
    
    RETURN nuevo_numero;
END;
$$;


ALTER FUNCTION public.generar_numero_orden() OWNER TO centro_user;

--
-- Name: obtener_siguiente_ncf(character varying); Type: FUNCTION; Schema: public; Owner: centro_user
--

CREATE FUNCTION public.obtener_siguiente_ncf(tipo character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE
    secuencia RECORD;
    ncf VARCHAR;
BEGIN
    SELECT * INTO secuencia
    FROM ncf_secuencias
    WHERE tipo_comprobante = tipo
    AND activo = true
    AND secuencia_actual < secuencia_fin
    AND fecha_vencimiento > CURRENT_DATE
    ORDER BY fecha_vencimiento DESC
    LIMIT 1;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No hay secuencia NCF disponible para tipo %', tipo;
    END IF;
    
    ncf := tipo || '-' || secuencia.serie || '-' || LPAD(secuencia.secuencia_actual::TEXT, 8, '0');
    
    UPDATE ncf_secuencias
    SET secuencia_actual = secuencia_actual + 1
    WHERE id = secuencia.id;
    
    RETURN ncf;
END;
$$;


ALTER FUNCTION public.obtener_siguiente_ncf(tipo character varying) OWNER TO centro_user;

--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: centro_user
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_updated_at_column() OWNER TO centro_user;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: alembic_version; Type: TABLE; Schema: public; Owner: centro_user
--

CREATE TABLE public.alembic_version (
    version_num character varying(32) NOT NULL
);


ALTER TABLE public.alembic_version OWNER TO centro_user;

--
-- Name: auditoria; Type: TABLE; Schema: public; Owner: centro_user
--

CREATE TABLE public.auditoria (
    id integer NOT NULL,
    tabla character varying(50) NOT NULL,
    registro_id integer NOT NULL,
    accion character varying(20),
    usuario_id integer,
    datos_anteriores jsonb,
    datos_nuevos jsonb,
    ip_address character varying(45),
    user_agent text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT auditoria_accion_check CHECK (((accion)::text = ANY ((ARRAY['crear'::character varying, 'actualizar'::character varying, 'eliminar'::character varying, 'ver'::character varying])::text[])))
);


ALTER TABLE public.auditoria OWNER TO centro_user;

--
-- Name: auditoria_id_seq; Type: SEQUENCE; Schema: public; Owner: centro_user
--

CREATE SEQUENCE public.auditoria_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.auditoria_id_seq OWNER TO centro_user;

--
-- Name: auditoria_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: centro_user
--

ALTER SEQUENCE public.auditoria_id_seq OWNED BY public.auditoria.id;


--
-- Name: caja_movimientos; Type: TABLE; Schema: public; Owner: centro_user
--

CREATE TABLE public.caja_movimientos (
    id integer NOT NULL,
    caja_id integer,
    tipo_movimiento character varying(20),
    concepto character varying(255) NOT NULL,
    monto numeric(10,2) NOT NULL,
    pago_id integer,
    usuario_id integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT caja_movimientos_tipo_movimiento_check CHECK (((tipo_movimiento)::text = ANY ((ARRAY['ingreso'::character varying, 'egreso'::character varying, 'apertura'::character varying, 'cierre'::character varying])::text[])))
);


ALTER TABLE public.caja_movimientos OWNER TO centro_user;

--
-- Name: caja_movimientos_id_seq; Type: SEQUENCE; Schema: public; Owner: centro_user
--

CREATE SEQUENCE public.caja_movimientos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.caja_movimientos_id_seq OWNER TO centro_user;

--
-- Name: caja_movimientos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: centro_user
--

ALTER SEQUENCE public.caja_movimientos_id_seq OWNED BY public.caja_movimientos.id;


--
-- Name: cajas; Type: TABLE; Schema: public; Owner: centro_user
--

CREATE TABLE public.cajas (
    id integer NOT NULL,
    numero_caja character varying(20) NOT NULL,
    nombre character varying(100),
    usuario_id integer,
    fecha_apertura timestamp without time zone NOT NULL,
    fecha_cierre timestamp without time zone,
    monto_apertura numeric(10,2) DEFAULT 0 NOT NULL,
    monto_cierre numeric(10,2),
    estado character varying(20) DEFAULT 'abierta'::character varying,
    notas_apertura text,
    notas_cierre text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT cajas_estado_check CHECK (((estado)::text = ANY ((ARRAY['abierta'::character varying, 'cerrada'::character varying])::text[])))
);


ALTER TABLE public.cajas OWNER TO centro_user;

--
-- Name: cajas_id_seq; Type: SEQUENCE; Schema: public; Owner: centro_user
--

CREATE SEQUENCE public.cajas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.cajas_id_seq OWNER TO centro_user;

--
-- Name: cajas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: centro_user
--

ALTER SEQUENCE public.cajas_id_seq OWNED BY public.cajas.id;


--
-- Name: campanas_envios; Type: TABLE; Schema: public; Owner: centro_user
--

CREATE TABLE public.campanas_envios (
    id integer NOT NULL,
    campana_id integer,
    paciente_id integer,
    numero_telefono character varying(20),
    estado character varying(50) DEFAULT 'pendiente'::character varying,
    fecha_envio timestamp without time zone,
    mensaje_id character varying(100),
    error text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.campanas_envios OWNER TO centro_user;

--
-- Name: campanas_envios_id_seq; Type: SEQUENCE; Schema: public; Owner: centro_user
--

CREATE SEQUENCE public.campanas_envios_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.campanas_envios_id_seq OWNER TO centro_user;

--
-- Name: campanas_envios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: centro_user
--

ALTER SEQUENCE public.campanas_envios_id_seq OWNED BY public.campanas_envios.id;


--
-- Name: campanas_whatsapp; Type: TABLE; Schema: public; Owner: centro_user
--

CREATE TABLE public.campanas_whatsapp (
    id integer NOT NULL,
    nombre character varying(200) NOT NULL,
    mensaje text NOT NULL,
    fecha_programada timestamp without time zone,
    estado character varying(50) DEFAULT 'pendiente'::character varying,
    total_enviados integer DEFAULT 0,
    total_fallidos integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    usuario_creador_id integer
);


ALTER TABLE public.campanas_whatsapp OWNER TO centro_user;

--
-- Name: campanas_whatsapp_id_seq; Type: SEQUENCE; Schema: public; Owner: centro_user
--

CREATE SEQUENCE public.campanas_whatsapp_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.campanas_whatsapp_id_seq OWNER TO centro_user;

--
-- Name: campanas_whatsapp_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: centro_user
--

ALTER SEQUENCE public.campanas_whatsapp_id_seq OWNED BY public.campanas_whatsapp.id;


--
-- Name: categorias; Type: TABLE; Schema: public; Owner: centro_user
--

CREATE TABLE public.categorias (
    id integer NOT NULL,
    nombre character varying(100) NOT NULL,
    descripcion text,
    activo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.categorias OWNER TO centro_user;

--
-- Name: categorias_estudios; Type: TABLE; Schema: public; Owner: centro_user
--

CREATE TABLE public.categorias_estudios (
    id integer NOT NULL,
    nombre character varying(100) NOT NULL,
    descripcion text,
    color character varying(7),
    icono character varying(50),
    activo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.categorias_estudios OWNER TO centro_user;

--
-- Name: categorias_estudios_id_seq; Type: SEQUENCE; Schema: public; Owner: centro_user
--

CREATE SEQUENCE public.categorias_estudios_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.categorias_estudios_id_seq OWNER TO centro_user;

--
-- Name: categorias_estudios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: centro_user
--

ALTER SEQUENCE public.categorias_estudios_id_seq OWNED BY public.categorias_estudios.id;


--
-- Name: categorias_id_seq; Type: SEQUENCE; Schema: public; Owner: centro_user
--

CREATE SEQUENCE public.categorias_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.categorias_id_seq OWNER TO centro_user;

--
-- Name: categorias_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: centro_user
--

ALTER SEQUENCE public.categorias_id_seq OWNED BY public.categorias.id;


--
-- Name: configuracion; Type: TABLE; Schema: public; Owner: centro_user
--

CREATE TABLE public.configuracion (
    id integer NOT NULL,
    clave character varying(100) NOT NULL,
    valor text,
    tipo character varying(20),
    descripcion text,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT configuracion_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['texto'::character varying, 'numero'::character varying, 'boolean'::character varying, 'json'::character varying])::text[])))
);


ALTER TABLE public.configuracion OWNER TO centro_user;

--
-- Name: configuracion_id_seq; Type: SEQUENCE; Schema: public; Owner: centro_user
--

CREATE SEQUENCE public.configuracion_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.configuracion_id_seq OWNER TO centro_user;

--
-- Name: configuracion_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: centro_user
--

ALTER SEQUENCE public.configuracion_id_seq OWNED BY public.configuracion.id;


--
-- Name: estudios; Type: TABLE; Schema: public; Owner: centro_user
--

CREATE TABLE public.estudios (
    id integer NOT NULL,
    uuid uuid DEFAULT public.uuid_generate_v4(),
    codigo character varying(20) NOT NULL,
    nombre character varying(200) NOT NULL,
    categoria_id integer,
    descripcion text,
    precio numeric(10,2) NOT NULL,
    costo numeric(10,2),
    tiempo_estimado integer,
    requiere_preparacion boolean DEFAULT false,
    instrucciones_preparacion text,
    tipo_resultado character varying(20),
    equipo_asignado character varying(100),
    activo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT estudios_tipo_resultado_check CHECK (((tipo_resultado)::text = ANY ((ARRAY['pdf'::character varying, 'dicom'::character varying, 'hl7'::character varying, 'manual'::character varying])::text[])))
);


ALTER TABLE public.estudios OWNER TO centro_user;

--
-- Name: TABLE estudios; Type: COMMENT; Schema: public; Owner: centro_user
--

COMMENT ON TABLE public.estudios IS 'Catálogo de estudios y servicios ofrecidos';


--
-- Name: estudios_id_seq; Type: SEQUENCE; Schema: public; Owner: centro_user
--

CREATE SEQUENCE public.estudios_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.estudios_id_seq OWNER TO centro_user;

--
-- Name: estudios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: centro_user
--

ALTER SEQUENCE public.estudios_id_seq OWNED BY public.estudios.id;


--
-- Name: factura_detalles; Type: TABLE; Schema: public; Owner: centro_user
--

CREATE TABLE public.factura_detalles (
    id integer NOT NULL,
    factura_id integer,
    orden_detalle_id integer,
    descripcion character varying(255) NOT NULL,
    cantidad integer DEFAULT 1,
    precio_unitario numeric(10,2) NOT NULL,
    descuento numeric(10,2) DEFAULT 0,
    itbis numeric(10,2) DEFAULT 0,
    total numeric(10,2) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.factura_detalles OWNER TO centro_user;

--
-- Name: factura_detalles_id_seq; Type: SEQUENCE; Schema: public; Owner: centro_user
--

CREATE SEQUENCE public.factura_detalles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.factura_detalles_id_seq OWNER TO centro_user;

--
-- Name: factura_detalles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: centro_user
--

ALTER SEQUENCE public.factura_detalles_id_seq OWNED BY public.factura_detalles.id;


--
-- Name: facturas; Type: TABLE; Schema: public; Owner: centro_user
--

CREATE TABLE public.facturas (
    id integer NOT NULL,
    uuid uuid DEFAULT public.uuid_generate_v4(),
    numero_factura character varying(30) NOT NULL,
    ncf character varying(19),
    tipo_comprobante character varying(3),
    orden_id integer,
    paciente_id integer NOT NULL,
    fecha_factura timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    fecha_vencimiento date,
    subtotal numeric(10,2) NOT NULL,
    descuento numeric(10,2) DEFAULT 0,
    itbis numeric(10,2) DEFAULT 0,
    otros_impuestos numeric(10,2) DEFAULT 0,
    total numeric(10,2) NOT NULL,
    estado character varying(20) DEFAULT 'pendiente'::character varying,
    forma_pago character varying(30),
    notas text,
    usuario_emision_id integer,
    anulada_por_id integer,
    motivo_anulacion text,
    fecha_anulacion timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT facturas_estado_check CHECK (((estado)::text = ANY ((ARRAY['pendiente'::character varying, 'pagada'::character varying, 'parcial'::character varying, 'anulada'::character varying, 'vencida'::character varying])::text[])))
);


ALTER TABLE public.facturas OWNER TO centro_user;

--
-- Name: TABLE facturas; Type: COMMENT; Schema: public; Owner: centro_user
--

COMMENT ON TABLE public.facturas IS 'Facturas emitidas con NCF';


--
-- Name: facturas_id_seq; Type: SEQUENCE; Schema: public; Owner: centro_user
--

CREATE SEQUENCE public.facturas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.facturas_id_seq OWNER TO centro_user;

--
-- Name: facturas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: centro_user
--

ALTER SEQUENCE public.facturas_id_seq OWNED BY public.facturas.id;


--
-- Name: facturas_qr; Type: TABLE; Schema: public; Owner: centro_user
--

CREATE TABLE public.facturas_qr (
    id integer NOT NULL,
    factura_id integer,
    codigo_qr character varying(100) NOT NULL,
    url_acceso text,
    fecha_generacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    accesos integer DEFAULT 0
);


ALTER TABLE public.facturas_qr OWNER TO centro_user;

--
-- Name: facturas_qr_id_seq; Type: SEQUENCE; Schema: public; Owner: centro_user
--

CREATE SEQUENCE public.facturas_qr_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.facturas_qr_id_seq OWNER TO centro_user;

--
-- Name: facturas_qr_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: centro_user
--

ALTER SEQUENCE public.facturas_qr_id_seq OWNED BY public.facturas_qr.id;


--
-- Name: inventario; Type: TABLE; Schema: public; Owner: centro_user
--

CREATE TABLE public.inventario (
    id integer NOT NULL,
    codigo character varying(50) NOT NULL,
    nombre character varying(200) NOT NULL,
    categoria character varying(50),
    unidad_medida character varying(20),
    cantidad_actual integer DEFAULT 0,
    cantidad_minima integer,
    costo_unitario numeric(10,2),
    proveedor character varying(100),
    fecha_vencimiento date,
    lote character varying(50),
    activo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.inventario OWNER TO centro_user;

--
-- Name: inventario_id_seq; Type: SEQUENCE; Schema: public; Owner: centro_user
--

CREATE SEQUENCE public.inventario_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.inventario_id_seq OWNER TO centro_user;

--
-- Name: inventario_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: centro_user
--

ALTER SEQUENCE public.inventario_id_seq OWNED BY public.inventario.id;


--
-- Name: ncf_secuencias; Type: TABLE; Schema: public; Owner: centro_user
--

CREATE TABLE public.ncf_secuencias (
    id integer NOT NULL,
    tipo_comprobante character varying(20) NOT NULL,
    serie character varying(3) NOT NULL,
    secuencia_inicio bigint NOT NULL,
    secuencia_fin bigint NOT NULL,
    secuencia_actual bigint NOT NULL,
    fecha_vencimiento date NOT NULL,
    activo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ncf_secuencias_tipo_comprobante_check CHECK (((tipo_comprobante)::text = ANY ((ARRAY['B01'::character varying, 'B02'::character varying, 'B14'::character varying, 'B15'::character varying, 'B16'::character varying])::text[])))
);


ALTER TABLE public.ncf_secuencias OWNER TO centro_user;

--
-- Name: TABLE ncf_secuencias; Type: COMMENT; Schema: public; Owner: centro_user
--

COMMENT ON TABLE public.ncf_secuencias IS 'Control de secuencias de NCF según DGII';


--
-- Name: ncf_secuencias_id_seq; Type: SEQUENCE; Schema: public; Owner: centro_user
--

CREATE SEQUENCE public.ncf_secuencias_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ncf_secuencias_id_seq OWNER TO centro_user;

--
-- Name: ncf_secuencias_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: centro_user
--

ALTER SEQUENCE public.ncf_secuencias_id_seq OWNED BY public.ncf_secuencias.id;


--
-- Name: orden_detalles; Type: TABLE; Schema: public; Owner: centro_user
--

CREATE TABLE public.orden_detalles (
    id integer NOT NULL,
    orden_id integer,
    estudio_id integer,
    precio numeric(10,2) NOT NULL,
    descuento numeric(10,2) DEFAULT 0,
    precio_final numeric(10,2) NOT NULL,
    estado character varying(20) DEFAULT 'pendiente'::character varying,
    resultado_disponible boolean DEFAULT false,
    fecha_resultado timestamp without time zone,
    tecnico_id integer,
    observaciones text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT orden_detalles_estado_check CHECK (((estado)::text = ANY ((ARRAY['pendiente'::character varying, 'en_proceso'::character varying, 'completado'::character varying, 'cancelado'::character varying])::text[])))
);


ALTER TABLE public.orden_detalles OWNER TO centro_user;

--
-- Name: orden_detalles_id_seq; Type: SEQUENCE; Schema: public; Owner: centro_user
--

CREATE SEQUENCE public.orden_detalles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.orden_detalles_id_seq OWNER TO centro_user;

--
-- Name: orden_detalles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: centro_user
--

ALTER SEQUENCE public.orden_detalles_id_seq OWNED BY public.orden_detalles.id;


--
-- Name: ordenes; Type: TABLE; Schema: public; Owner: centro_user
--

CREATE TABLE public.ordenes (
    id integer NOT NULL,
    uuid uuid DEFAULT public.uuid_generate_v4(),
    numero_orden character varying(20) NOT NULL,
    paciente_id integer NOT NULL,
    medico_referente character varying(100),
    fecha_orden timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    fecha_cita timestamp without time zone,
    estado character varying(20) DEFAULT 'pendiente'::character varying,
    prioridad character varying(20) DEFAULT 'normal'::character varying,
    observaciones text,
    usuario_registro_id integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ordenes_estado_check CHECK (((estado)::text = ANY ((ARRAY['pendiente'::character varying, 'en_proceso'::character varying, 'completada'::character varying, 'cancelada'::character varying, 'facturada'::character varying])::text[]))),
    CONSTRAINT ordenes_prioridad_check CHECK (((prioridad)::text = ANY ((ARRAY['normal'::character varying, 'urgente'::character varying, 'stat'::character varying])::text[])))
);


ALTER TABLE public.ordenes OWNER TO centro_user;

--
-- Name: TABLE ordenes; Type: COMMENT; Schema: public; Owner: centro_user
--

COMMENT ON TABLE public.ordenes IS 'Órdenes de servicio generadas';


--
-- Name: ordenes_id_seq; Type: SEQUENCE; Schema: public; Owner: centro_user
--

CREATE SEQUENCE public.ordenes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ordenes_id_seq OWNER TO centro_user;

--
-- Name: ordenes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: centro_user
--

ALTER SEQUENCE public.ordenes_id_seq OWNED BY public.ordenes.id;


--
-- Name: pacientes; Type: TABLE; Schema: public; Owner: centro_user
--

CREATE TABLE public.pacientes (
    id integer NOT NULL,
    uuid uuid DEFAULT public.uuid_generate_v4(),
    cedula character varying(20),
    pasaporte character varying(30),
    nombre character varying(100) NOT NULL,
    apellido character varying(100) NOT NULL,
    fecha_nacimiento date,
    sexo character(1),
    telefono character varying(20),
    celular character varying(20),
    email character varying(100),
    direccion text,
    ciudad character varying(100),
    seguro_medico character varying(100),
    numero_poliza character varying(50),
    tipo_sangre character varying(5),
    alergias text,
    notas_medicas text,
    estado character varying(20) DEFAULT 'activo'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    codigo_paciente character varying(50),
    portal_usuario character varying(100),
    portal_password character varying(255),
    ultimo_acceso_portal timestamp without time zone,
    CONSTRAINT pacientes_estado_check CHECK (((estado)::text = ANY ((ARRAY['activo'::character varying, 'inactivo'::character varying])::text[]))),
    CONSTRAINT pacientes_sexo_check CHECK ((sexo = ANY (ARRAY['M'::bpchar, 'F'::bpchar])))
);


ALTER TABLE public.pacientes OWNER TO centro_user;

--
-- Name: TABLE pacientes; Type: COMMENT; Schema: public; Owner: centro_user
--

COMMENT ON TABLE public.pacientes IS 'Registro de pacientes del centro diagnóstico';


--
-- Name: pacientes_id_seq; Type: SEQUENCE; Schema: public; Owner: centro_user
--

CREATE SEQUENCE public.pacientes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pacientes_id_seq OWNER TO centro_user;

--
-- Name: pacientes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: centro_user
--

ALTER SEQUENCE public.pacientes_id_seq OWNED BY public.pacientes.id;


--
-- Name: pagos; Type: TABLE; Schema: public; Owner: centro_user
--

CREATE TABLE public.pagos (
    id integer NOT NULL,
    uuid uuid DEFAULT public.uuid_generate_v4(),
    factura_id integer,
    fecha_pago timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    monto numeric(10,2) NOT NULL,
    metodo_pago character varying(30) NOT NULL,
    referencia character varying(100),
    banco character varying(100),
    notas text,
    usuario_recibe_id integer,
    caja_id integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pagos_metodo_pago_check CHECK (((metodo_pago)::text = ANY ((ARRAY['efectivo'::character varying, 'tarjeta'::character varying, 'transferencia'::character varying, 'cheque'::character varying, 'seguro'::character varying, 'mixto'::character varying])::text[])))
);


ALTER TABLE public.pagos OWNER TO centro_user;

--
-- Name: pagos_id_seq; Type: SEQUENCE; Schema: public; Owner: centro_user
--

CREATE SEQUENCE public.pagos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pagos_id_seq OWNER TO centro_user;

--
-- Name: pagos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: centro_user
--

ALTER SEQUENCE public.pagos_id_seq OWNED BY public.pagos.id;


--
-- Name: portal_paciente_accesos; Type: TABLE; Schema: public; Owner: centro_user
--

CREATE TABLE public.portal_paciente_accesos (
    id integer NOT NULL,
    paciente_id integer,
    fecha_acceso timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    ip_address character varying(50),
    dispositivo character varying(100)
);


ALTER TABLE public.portal_paciente_accesos OWNER TO centro_user;

--
-- Name: portal_paciente_accesos_id_seq; Type: SEQUENCE; Schema: public; Owner: centro_user
--

CREATE SEQUENCE public.portal_paciente_accesos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.portal_paciente_accesos_id_seq OWNER TO centro_user;

--
-- Name: portal_paciente_accesos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: centro_user
--

ALTER SEQUENCE public.portal_paciente_accesos_id_seq OWNED BY public.portal_paciente_accesos.id;


--
-- Name: radiografias; Type: TABLE; Schema: public; Owner: centro_user
--

CREATE TABLE public.radiografias (
    id integer NOT NULL,
    orden_detalle_id integer,
    paciente_id integer,
    tipo_estudio character varying(100),
    region_anatomica character varying(100),
    imagen_original text,
    imagen_procesada text,
    formato character varying(20),
    ancho integer,
    alto integer,
    informe_medico text,
    hallazgos text,
    conclusion text,
    medico_id integer,
    fecha_toma timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    fecha_informe timestamp without time zone,
    estado character varying(50) DEFAULT 'pendiente'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    radiologo_id integer,
    fecha_diagnostico timestamp without time zone
);


ALTER TABLE public.radiografias OWNER TO centro_user;

--
-- Name: radiografias_id_seq; Type: SEQUENCE; Schema: public; Owner: centro_user
--

CREATE SEQUENCE public.radiografias_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.radiografias_id_seq OWNER TO centro_user;

--
-- Name: radiografias_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: centro_user
--

ALTER SEQUENCE public.radiografias_id_seq OWNED BY public.radiografias.id;


--
-- Name: resultados; Type: TABLE; Schema: public; Owner: centro_user
--

CREATE TABLE public.resultados (
    id integer NOT NULL,
    uuid uuid DEFAULT public.uuid_generate_v4(),
    orden_detalle_id integer,
    tipo_archivo character varying(10),
    ruta_archivo character varying(500),
    ruta_nube character varying(500),
    nombre_archivo character varying(255),
    tamano_bytes bigint,
    hash_archivo character varying(64),
    datos_hl7 text,
    datos_dicom jsonb,
    interpretacion text,
    valores_referencia text,
    estado_validacion character varying(20) DEFAULT 'pendiente'::character varying,
    validado_por_id integer,
    fecha_validacion timestamp without time zone,
    impreso boolean DEFAULT false,
    enviado_email boolean DEFAULT false,
    fecha_importacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT resultados_estado_validacion_check CHECK (((estado_validacion)::text = ANY ((ARRAY['pendiente'::character varying, 'validado'::character varying, 'rechazado'::character varying])::text[]))),
    CONSTRAINT resultados_tipo_archivo_check CHECK (((tipo_archivo)::text = ANY ((ARRAY['pdf'::character varying, 'dicom'::character varying, 'hl7'::character varying, 'jpg'::character varying, 'png'::character varying])::text[])))
);


ALTER TABLE public.resultados OWNER TO centro_user;

--
-- Name: TABLE resultados; Type: COMMENT; Schema: public; Owner: centro_user
--

COMMENT ON TABLE public.resultados IS 'Resultados de estudios importados de equipos';


--
-- Name: resultados_id_seq; Type: SEQUENCE; Schema: public; Owner: centro_user
--

CREATE SEQUENCE public.resultados_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.resultados_id_seq OWNER TO centro_user;

--
-- Name: resultados_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: centro_user
--

ALTER SEQUENCE public.resultados_id_seq OWNED BY public.resultados.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: centro_user
--

CREATE TABLE public.roles (
    id integer NOT NULL,
    nombre character varying(50) NOT NULL,
    descripcion text,
    permisos jsonb,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.roles OWNER TO centro_user;

--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: centro_user
--

CREATE SEQUENCE public.roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.roles_id_seq OWNER TO centro_user;

--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: centro_user
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- Name: sonografias; Type: TABLE; Schema: public; Owner: centro_user
--

CREATE TABLE public.sonografias (
    id integer NOT NULL,
    orden_detalle_id integer,
    paciente_id integer,
    tipo_estudio character varying(100),
    region character varying(100),
    imagenes jsonb,
    video_url text,
    informe_medico text,
    hallazgos text,
    biometria jsonb,
    conclusion text,
    medico_id integer,
    fecha_estudio timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    fecha_informe timestamp without time zone,
    estado character varying(50) DEFAULT 'pendiente'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.sonografias OWNER TO centro_user;

--
-- Name: sonografias_id_seq; Type: SEQUENCE; Schema: public; Owner: centro_user
--

CREATE SEQUENCE public.sonografias_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sonografias_id_seq OWNER TO centro_user;

--
-- Name: sonografias_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: centro_user
--

ALTER SEQUENCE public.sonografias_id_seq OWNED BY public.sonografias.id;


--
-- Name: sync_queue; Type: TABLE; Schema: public; Owner: centro_user
--

CREATE TABLE public.sync_queue (
    id integer NOT NULL,
    tabla character varying(50) NOT NULL,
    registro_id integer NOT NULL,
    accion character varying(20),
    datos jsonb,
    intentos integer DEFAULT 0,
    estado character varying(20) DEFAULT 'pendiente'::character varying,
    error_mensaje text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    processed_at timestamp without time zone,
    CONSTRAINT sync_queue_estado_check CHECK (((estado)::text = ANY ((ARRAY['pendiente'::character varying, 'procesando'::character varying, 'completado'::character varying, 'error'::character varying])::text[])))
);


ALTER TABLE public.sync_queue OWNER TO centro_user;

--
-- Name: sync_queue_id_seq; Type: SEQUENCE; Schema: public; Owner: centro_user
--

CREATE SEQUENCE public.sync_queue_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sync_queue_id_seq OWNER TO centro_user;

--
-- Name: sync_queue_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: centro_user
--

ALTER SEQUENCE public.sync_queue_id_seq OWNED BY public.sync_queue.id;


--
-- Name: usuarios; Type: TABLE; Schema: public; Owner: centro_user
--

CREATE TABLE public.usuarios (
    id integer NOT NULL,
    uuid uuid DEFAULT public.uuid_generate_v4(),
    username character varying(50) NOT NULL,
    password_hash character varying(255) NOT NULL,
    nombre character varying(100) NOT NULL,
    apellido character varying(100) NOT NULL,
    email character varying(100),
    rol character varying(20) NOT NULL,
    permisos jsonb,
    activo boolean DEFAULT true,
    ultimo_acceso timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    rol_id integer,
    especialidad character varying(100),
    firma_digital text,
    CONSTRAINT usuarios_rol_check CHECK (((rol)::text = ANY ((ARRAY['admin'::character varying, 'cajero'::character varying, 'tecnico'::character varying, 'medico'::character varying, 'recepcion'::character varying])::text[])))
);


ALTER TABLE public.usuarios OWNER TO centro_user;

--
-- Name: usuarios_id_seq; Type: SEQUENCE; Schema: public; Owner: centro_user
--

CREATE SEQUENCE public.usuarios_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.usuarios_id_seq OWNER TO centro_user;

--
-- Name: usuarios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: centro_user
--

ALTER SEQUENCE public.usuarios_id_seq OWNED BY public.usuarios.id;


--
-- Name: vista_facturas_completa; Type: VIEW; Schema: public; Owner: centro_user
--

CREATE VIEW public.vista_facturas_completa AS
SELECT
    NULL::integer AS id,
    NULL::uuid AS uuid,
    NULL::character varying(30) AS numero_factura,
    NULL::character varying(19) AS ncf,
    NULL::timestamp without time zone AS fecha_factura,
    NULL::numeric(10,2) AS total,
    NULL::character varying(20) AS estado,
    NULL::character varying(20) AS paciente_cedula,
    NULL::text AS paciente_nombre,
    NULL::character varying(20) AS paciente_telefono,
    NULL::character varying(50) AS usuario_emision,
    NULL::numeric AS monto_pagado,
    NULL::numeric AS saldo_pendiente;


ALTER TABLE public.vista_facturas_completa OWNER TO centro_user;

--
-- Name: vista_ordenes_pendientes; Type: VIEW; Schema: public; Owner: centro_user
--

CREATE VIEW public.vista_ordenes_pendientes AS
SELECT
    NULL::integer AS id,
    NULL::character varying(20) AS numero_orden,
    NULL::timestamp without time zone AS fecha_orden,
    NULL::character varying(20) AS estado,
    NULL::text AS paciente,
    NULL::character varying(20) AS cedula,
    NULL::bigint AS total_estudios,
    NULL::bigint AS estudios_completados;


ALTER TABLE public.vista_ordenes_pendientes OWNER TO centro_user;

--
-- Name: whatsapp_messages; Type: TABLE; Schema: public; Owner: centro_user
--

CREATE TABLE public.whatsapp_messages (
    id integer NOT NULL,
    telefono character varying(50) NOT NULL,
    mensaje_recibido text,
    mensaje_enviado text,
    fecha timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    procesado boolean DEFAULT false,
    enviado_por_sistema boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.whatsapp_messages OWNER TO centro_user;

--
-- Name: whatsapp_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: centro_user
--

CREATE SEQUENCE public.whatsapp_messages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.whatsapp_messages_id_seq OWNER TO centro_user;

--
-- Name: whatsapp_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: centro_user
--

ALTER SEQUENCE public.whatsapp_messages_id_seq OWNED BY public.whatsapp_messages.id;


--
-- Name: auditoria id; Type: DEFAULT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.auditoria ALTER COLUMN id SET DEFAULT nextval('public.auditoria_id_seq'::regclass);


--
-- Name: caja_movimientos id; Type: DEFAULT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.caja_movimientos ALTER COLUMN id SET DEFAULT nextval('public.caja_movimientos_id_seq'::regclass);


--
-- Name: cajas id; Type: DEFAULT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.cajas ALTER COLUMN id SET DEFAULT nextval('public.cajas_id_seq'::regclass);


--
-- Name: campanas_envios id; Type: DEFAULT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.campanas_envios ALTER COLUMN id SET DEFAULT nextval('public.campanas_envios_id_seq'::regclass);


--
-- Name: campanas_whatsapp id; Type: DEFAULT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.campanas_whatsapp ALTER COLUMN id SET DEFAULT nextval('public.campanas_whatsapp_id_seq'::regclass);


--
-- Name: categorias id; Type: DEFAULT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.categorias ALTER COLUMN id SET DEFAULT nextval('public.categorias_id_seq'::regclass);


--
-- Name: categorias_estudios id; Type: DEFAULT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.categorias_estudios ALTER COLUMN id SET DEFAULT nextval('public.categorias_estudios_id_seq'::regclass);


--
-- Name: configuracion id; Type: DEFAULT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.configuracion ALTER COLUMN id SET DEFAULT nextval('public.configuracion_id_seq'::regclass);


--
-- Name: estudios id; Type: DEFAULT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.estudios ALTER COLUMN id SET DEFAULT nextval('public.estudios_id_seq'::regclass);


--
-- Name: factura_detalles id; Type: DEFAULT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.factura_detalles ALTER COLUMN id SET DEFAULT nextval('public.factura_detalles_id_seq'::regclass);


--
-- Name: facturas id; Type: DEFAULT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.facturas ALTER COLUMN id SET DEFAULT nextval('public.facturas_id_seq'::regclass);


--
-- Name: facturas_qr id; Type: DEFAULT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.facturas_qr ALTER COLUMN id SET DEFAULT nextval('public.facturas_qr_id_seq'::regclass);


--
-- Name: inventario id; Type: DEFAULT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.inventario ALTER COLUMN id SET DEFAULT nextval('public.inventario_id_seq'::regclass);


--
-- Name: ncf_secuencias id; Type: DEFAULT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.ncf_secuencias ALTER COLUMN id SET DEFAULT nextval('public.ncf_secuencias_id_seq'::regclass);


--
-- Name: orden_detalles id; Type: DEFAULT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.orden_detalles ALTER COLUMN id SET DEFAULT nextval('public.orden_detalles_id_seq'::regclass);


--
-- Name: ordenes id; Type: DEFAULT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.ordenes ALTER COLUMN id SET DEFAULT nextval('public.ordenes_id_seq'::regclass);


--
-- Name: pacientes id; Type: DEFAULT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.pacientes ALTER COLUMN id SET DEFAULT nextval('public.pacientes_id_seq'::regclass);


--
-- Name: pagos id; Type: DEFAULT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.pagos ALTER COLUMN id SET DEFAULT nextval('public.pagos_id_seq'::regclass);


--
-- Name: portal_paciente_accesos id; Type: DEFAULT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.portal_paciente_accesos ALTER COLUMN id SET DEFAULT nextval('public.portal_paciente_accesos_id_seq'::regclass);


--
-- Name: radiografias id; Type: DEFAULT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.radiografias ALTER COLUMN id SET DEFAULT nextval('public.radiografias_id_seq'::regclass);


--
-- Name: resultados id; Type: DEFAULT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.resultados ALTER COLUMN id SET DEFAULT nextval('public.resultados_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- Name: sonografias id; Type: DEFAULT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.sonografias ALTER COLUMN id SET DEFAULT nextval('public.sonografias_id_seq'::regclass);


--
-- Name: sync_queue id; Type: DEFAULT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.sync_queue ALTER COLUMN id SET DEFAULT nextval('public.sync_queue_id_seq'::regclass);


--
-- Name: usuarios id; Type: DEFAULT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.usuarios ALTER COLUMN id SET DEFAULT nextval('public.usuarios_id_seq'::regclass);


--
-- Name: whatsapp_messages id; Type: DEFAULT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.whatsapp_messages ALTER COLUMN id SET DEFAULT nextval('public.whatsapp_messages_id_seq'::regclass);


--
-- Data for Name: alembic_version; Type: TABLE DATA; Schema: public; Owner: centro_user
--

COPY public.alembic_version (version_num) FROM stdin;
\.


--
-- Data for Name: auditoria; Type: TABLE DATA; Schema: public; Owner: centro_user
--

COPY public.auditoria (id, tabla, registro_id, accion, usuario_id, datos_anteriores, datos_nuevos, ip_address, user_agent, created_at) FROM stdin;
\.


--
-- Data for Name: caja_movimientos; Type: TABLE DATA; Schema: public; Owner: centro_user
--

COPY public.caja_movimientos (id, caja_id, tipo_movimiento, concepto, monto, pago_id, usuario_id, created_at) FROM stdin;
\.


--
-- Data for Name: cajas; Type: TABLE DATA; Schema: public; Owner: centro_user
--

COPY public.cajas (id, numero_caja, nombre, usuario_id, fecha_apertura, fecha_cierre, monto_apertura, monto_cierre, estado, notas_apertura, notas_cierre, created_at) FROM stdin;
\.


--
-- Data for Name: campanas_envios; Type: TABLE DATA; Schema: public; Owner: centro_user
--

COPY public.campanas_envios (id, campana_id, paciente_id, numero_telefono, estado, fecha_envio, mensaje_id, error, created_at) FROM stdin;
\.


--
-- Data for Name: campanas_whatsapp; Type: TABLE DATA; Schema: public; Owner: centro_user
--

COPY public.campanas_whatsapp (id, nombre, mensaje, fecha_programada, estado, total_enviados, total_fallidos, created_at, usuario_creador_id) FROM stdin;
\.


--
-- Data for Name: categorias; Type: TABLE DATA; Schema: public; Owner: centro_user
--

COPY public.categorias (id, nombre, descripcion, activo, created_at, updated_at) FROM stdin;
1	Laboratorio Clínico	Análisis de sangre, orina y otros fluidos	t	2026-02-16 12:46:01.445259	2026-02-16 12:46:01.445259
2	Imagenología	Radiografías, tomografías, resonancias	t	2026-02-16 12:46:01.445259	2026-02-16 12:46:01.445259
3	Ultrasonido	Ecografías y sonografías	t	2026-02-16 12:46:01.445259	2026-02-16 12:46:01.445259
4	Cardiología	Electrocardiogramas y pruebas cardíacas	t	2026-02-16 12:46:01.445259	2026-02-16 12:46:01.445259
5	Microbiología	Cultivos y análisis microbiológicos	t	2026-02-16 12:46:01.445259	2026-02-16 12:46:01.445259
\.


--
-- Data for Name: categorias_estudios; Type: TABLE DATA; Schema: public; Owner: centro_user
--

COPY public.categorias_estudios (id, nombre, descripcion, color, icono, activo, created_at) FROM stdin;
1	Laboratorio Clínico	Análisis de sangre, orina y otros fluidos	#3B82F6	test-tube	t	2026-02-14 08:51:33.087083
2	Imagenología	Rayos X, Ultrasonido, etc.	#10B981	image	t	2026-02-14 08:51:33.087083
3	Cardiología	Electrocardiogramas y estudios cardíacos	#EF4444	heart	t	2026-02-14 08:51:33.087083
4	Microbiología	Cultivos y estudios bacteriológicos	#8B5CF6	microscope	t	2026-02-14 08:51:33.087083
5	Hematología	Estudios de sangre especializados	#F59E0B	droplet	t	2026-02-14 08:51:33.087083
6	Uroanálisis	Análisis de orina	#F59E0B	flask	t	2026-02-15 07:35:49.493817
7	Perfil Hormonal	Estudios hormonales	#EC4899	activity	t	2026-02-15 07:35:49.493817
8	Marcadores Tumorales	Detección de marcadores	#7C3AED	alert-triangle	t	2026-02-15 07:35:49.493817
9	Pruebas Especiales	Estudios especializados	#059669	star	t	2026-02-15 07:35:49.493817
\.


--
-- Data for Name: configuracion; Type: TABLE DATA; Schema: public; Owner: centro_user
--

COPY public.configuracion (id, clave, valor, tipo, descripcion, updated_at) FROM stdin;
1	empresa_nombre	Centro de Diagnóstico Medical Plus	texto	Nombre del centro médico	2026-02-14 08:51:33.092679
2	empresa_rnc	000-00000-0	texto	RNC del centro	2026-02-14 08:51:33.092679
3	empresa_telefono	809-000-0000	texto	Teléfono principal	2026-02-14 08:51:33.092679
4	empresa_direccion	Calle Principal #123, Santo Domingo	texto	Dirección física	2026-02-14 08:51:33.092679
5	itbis_porcentaje	18	numero	Porcentaje de ITBIS	2026-02-14 08:51:33.092679
6	dias_vencimiento_factura	30	numero	Días para vencimiento de facturas	2026-02-14 08:51:33.092679
7	ruta_exportacion_equipos	/mnt/equipos/export/	texto	Ruta donde los equipos exportan archivos	2026-02-14 08:51:33.092679
8	sync_intervalo_minutos	5	numero	Intervalo de sincronización con nube	2026-02-14 08:51:33.092679
9	email_notificaciones	resultados@centrodiagnostico.com	texto	Email para notificaciones	2026-02-14 08:51:33.092679
\.


--
-- Data for Name: estudios; Type: TABLE DATA; Schema: public; Owner: centro_user
--

COPY public.estudios (id, uuid, codigo, nombre, categoria_id, descripcion, precio, costo, tiempo_estimado, requiere_preparacion, instrucciones_preparacion, tipo_resultado, equipo_asignado, activo, created_at, updated_at) FROM stdin;
1	b69973eb-7432-4b7b-821b-7f7d577c8f57	HEM001	Hemograma Completo	5	\N	350.00	\N	\N	f	\N	hl7	\N	t	2026-02-14 08:51:33.088581	2026-02-14 08:51:33.088581
2	e54755de-32c3-486f-9cbd-59bd90816f5a	HEM002	Glicemia en Ayunas	1	\N	200.00	\N	\N	f	\N	hl7	\N	t	2026-02-14 08:51:33.088581	2026-02-14 08:51:33.088581
3	96029bea-4783-403c-8e55-a8adc4721798	HEM003	Perfil Lipídico	1	\N	800.00	\N	\N	f	\N	hl7	\N	t	2026-02-14 08:51:33.088581	2026-02-14 08:51:33.088581
4	3a987d10-80ef-4981-bf1b-e285feed1551	HEM004	Creatinina	1	\N	250.00	\N	\N	f	\N	hl7	\N	t	2026-02-14 08:51:33.088581	2026-02-14 08:51:33.088581
5	3c2cafa4-7a32-4ff4-b09f-6eeb79a0c10a	HEM005	Ácido Úrico	1	\N	250.00	\N	\N	f	\N	hl7	\N	t	2026-02-14 08:51:33.088581	2026-02-14 08:51:33.088581
6	a43fa442-6d7c-432f-b7c8-dec410cf160e	IMG001	Rayos X de Tórax	2	\N	600.00	\N	\N	f	\N	dicom	\N	t	2026-02-14 08:51:33.088581	2026-02-14 08:51:33.088581
7	a0a10dd7-a292-4120-99f5-66be6eba926a	IMG002	Sonografía Abdominal	2	\N	1200.00	\N	\N	f	\N	dicom	\N	t	2026-02-14 08:51:33.088581	2026-02-14 08:51:33.088581
8	33203fae-c50f-4980-93c1-163568d0d123	IMG003	Sonografía Pélvica	2	\N	1200.00	\N	\N	f	\N	dicom	\N	t	2026-02-14 08:51:33.088581	2026-02-14 08:51:33.088581
9	c8a0d9a8-6cd9-4809-9017-728a64d9804d	IMG004	Sonografía Obstétrica	2	\N	1500.00	\N	\N	f	\N	dicom	\N	t	2026-02-14 08:51:33.088581	2026-02-14 08:51:33.088581
10	830f0784-90ef-493f-9b11-59fd5485df89	CAR001	Electrocardiograma	3	\N	500.00	\N	\N	f	\N	pdf	\N	t	2026-02-14 08:51:33.088581	2026-02-14 08:51:33.088581
11	4adbcb27-163e-4265-af72-38958dfcaba6	LAB001	Urea	1	Medición de urea en sangre	200.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
12	cc53b475-1337-4ca6-835a-c3e814faea20	LAB002	Transaminasas (TGO/TGP)	1	Función hepática	400.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
13	23b18f8d-e964-4301-a9ab-177ae01051b3	LAB003	Bilirrubina Total y Fraccionada	1	Función hepática	350.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
14	a13aae7c-98cd-4b21-ab8e-de1c6913df71	LAB004	Fosfatasa Alcalina	1	Enzima hepática	250.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
15	d7258320-f1a7-42f4-80e7-d513aca229f3	LAB005	Proteínas Totales y Fraccionadas	1	Proteínas séricas	300.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
16	bdb239a2-d865-4dd2-aeac-078236378079	LAB006	Triglicéridos	1	Perfil lipídico	250.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
17	1828a076-8e13-4fd5-98d2-fe5e568ce46c	LAB007	Colesterol HDL	1	Colesterol bueno	250.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
18	8082accc-e7eb-43be-9b22-dc368e002012	LAB008	Colesterol LDL	1	Colesterol malo	250.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
19	947aecee-0547-46dc-a308-12c29b26f6ae	LAB009	HbA1c (Hemoglobina Glicosilada)	1	Control de diabetes	600.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
20	40b510f5-f18b-483e-9c85-fae21fd5502d	LAB010	PCR (Proteína C Reactiva)	1	Marcador inflamatorio	350.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
21	aad298cc-34a3-40f8-83e8-975598ea20f0	LAB011	VSG (Velocidad Sedimentación)	1	Marcador inflamatorio	200.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
22	7a9013a6-dc19-4939-918c-0ceb6b6859f1	LAB012	Calcio Sérico	1	Electrolito	250.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
23	bd792287-d228-4ddb-acc9-a4ec8650e458	LAB013	Fósforo	1	Electrolito	250.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
24	e8c094e4-50cc-4c63-98af-5f02f4b905fe	LAB014	Magnesio	1	Electrolito	250.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
25	b10877a2-21c2-47d7-8b77-ae545fd1c7c2	LAB015	Sodio y Potasio	1	Electrolitos	350.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
26	c507712d-c575-45fa-99b6-cf84e06bf238	LAB016	Hierro Sérico	1	Metabolismo del hierro	300.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
27	0415a4a3-86d6-4ed5-a3b4-c8f5c62fcfd9	LAB017	Ferritina	1	Reservas de hierro	450.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
28	541828fe-d9a1-4f08-a054-18d8bd7bfe45	LAB018	Vitamina D	1	25-OH Vitamina D	800.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
29	039530c1-2b91-4716-b4da-f53971de43a2	LAB019	Vitamina B12	1	Cobalamina	700.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
30	b38fe5a9-4ae2-4422-8a17-d6ea72cd5e45	LAB020	Ácido Fólico	1	Vitamina B9	500.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
31	5918adb2-11d9-4fde-a752-5c1a7ad38eaf	URO001	Orina Completa	6	Examen general de orina	200.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
32	f271a9f9-a3d7-4b47-a676-37e8006e4ab1	URO002	Urocultivo	6	Cultivo de orina	500.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
33	fbf633d7-12aa-4475-8841-02ff618cc335	URO003	Microalbuminuria	6	Detección temprana daño renal	400.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
34	0fa8df88-4842-4c77-8684-4ceef6c7d257	URO004	Depuración de Creatinina	6	Función renal	400.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
35	850a9900-d1a7-437b-9a60-40c1028ff603	HOR001	TSH	7	Hormona estimulante de tiroides	500.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
36	31d7916d-25a4-4150-b2bf-5ef18a7fddeb	HOR002	T3 Libre	7	Triyodotironina libre	400.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
37	dbb67c08-b50b-442a-ac79-0632cc700f3a	HOR003	T4 Libre	7	Tiroxina libre	400.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
38	9e734cb2-7775-4c14-812f-99931d8b1efd	HOR004	Perfil Tiroideo Completo	7	TSH + T3 + T4	1200.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
39	1d599109-f454-457d-9764-0ae45ee700f8	HOR005	Testosterona Total	7	Hormona masculina	600.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
40	e713348a-a631-43d8-9455-3557fe9fb9c1	HOR006	Estradiol	7	Hormona femenina	500.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
41	551ddc2c-532b-4628-b54c-97ceb6ec882a	HOR007	Progesterona	7	Hormona femenina	500.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
42	59b07c67-2668-4de3-9b43-6ea8dc4c1fca	HOR008	FSH	7	Hormona foliculoestimulante	500.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
43	4cf03a1b-4a5a-402f-8c1d-8f81de3cea86	HOR009	LH	7	Hormona luteinizante	500.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
44	11acfc23-5e08-4c48-9658-ce0bd51753db	HOR010	Prolactina	7	Hormona de lactancia	500.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
45	0074dab5-f87e-41e7-80da-738ed01de09f	HOR011	Insulina Basal	7	Resistencia a la insulina	500.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
46	1d6870d3-bd40-42ba-8ca2-3e1bff96c0f2	HOR012	Cortisol AM	7	Hormona del estrés	500.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
47	7bbefffc-cafe-4843-a7f5-14f9461ececa	HOR013	PSA Total	7	Antígeno prostático	600.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
48	c88b08fc-e3a0-41b0-bb63-136056aa5730	HOR014	Beta HCG	7	Prueba de embarazo cuantitativa	500.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
49	5a8827f3-6ca2-464c-9018-7e6eccc9420f	TUM001	CA 125	8	Marcador ovárico	800.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
50	1ee48439-f174-47e6-92da-d87424798c33	TUM002	CA 19-9	8	Marcador pancreático	800.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
51	39576f53-1de3-4623-b6e4-7096f52834f4	TUM003	CA 15-3	8	Marcador mamario	800.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
52	c4ba9075-8c21-41ed-9f09-eeebe9006cd2	TUM004	CEA	8	Antígeno carcinoembrionario	700.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
53	ce81599f-88ee-482c-9180-cee5000e0dc6	TUM005	AFP	8	Alfafetoproteína	700.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
54	2c3c6040-e308-4dd1-ad28-2ee40ccaf1df	ESP001	Prueba COVID-19 PCR	9	PCR tiempo real	1500.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
55	56577162-07b8-42c4-9618-921fd2a3a680	ESP002	Prueba COVID-19 Antígeno	9	Prueba rápida	500.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
56	7261eecb-b447-48ff-89f6-2a3cc8da0efd	ESP003	Dengue NS1 + IgM/IgG	9	Panel dengue	800.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
57	8f18fc8d-a5e0-450f-bc74-fcb270b38017	ESP004	HIV 1/2	9	Prueba de VIH	500.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
58	f28a622d-9fd9-45b3-9f35-874425cb6032	ESP005	VDRL	9	Prueba de sífilis	300.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
59	0b3eeaa7-1167-49f4-be05-1b99669503c7	ESP006	Hepatitis B (HBsAg)	9	Antígeno superficie	500.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
60	9ef1118a-e82c-4582-aa40-64b37c4a69b9	ESP007	Hepatitis C (Anti-HCV)	9	Anticuerpos	500.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
61	bf3caebb-7cfc-4909-8bad-1f16c8fff88c	ESP008	Factor Reumatoideo	9	Marcador autoinmune	350.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
62	83f9c7d3-8dcd-4dc9-8583-790aeccd885c	ESP009	ASTO	9	Antiestreptolisina O	300.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
63	0e8d3be2-3c3d-400c-b920-3ddad90f0a85	ESP010	Tipificación Sanguínea	9	Grupo y Rh	300.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
64	b3d482db-3cf9-42a2-9790-4926f30bc1f2	IMG005	Sonografía Mamaria	2	Ultrasonido de mamas	1500.00	\N	\N	f	\N	dicom	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
65	fd9ebe06-1cc3-44d8-87cd-c32e9d34d679	IMG006	Sonografía Renal	2	Ultrasonido renal	1200.00	\N	\N	f	\N	dicom	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
66	160877b7-a49e-4600-8087-3ce6b1674d9e	IMG007	Sonografía Prostática	2	Ultrasonido próstata	1200.00	\N	\N	f	\N	dicom	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
67	1fa8be48-da4e-403d-ae3b-761e4bfe31a7	IMG008	Sonografía Tiroidea	2	Ultrasonido tiroides	1200.00	\N	\N	f	\N	dicom	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
68	cccdf785-bd3e-4ff0-ba4a-43b1bbbcc71d	IMG009	Sonografía Doppler	2	Doppler vascular	2000.00	\N	\N	f	\N	dicom	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
69	5b9c6784-cc02-41e0-a52f-e0650b633fde	IMG010	Rayos X Columna	2	Radiografía columna	800.00	\N	\N	f	\N	dicom	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
70	7b90f1f8-8755-4fa7-a548-4b05457a79a7	IMG011	Rayos X Rodilla	2	Radiografía rodilla	600.00	\N	\N	f	\N	dicom	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
71	279d5e5e-06b9-4868-bea0-b9fa4b452bed	IMG012	Rayos X Mano	2	Radiografía mano	500.00	\N	\N	f	\N	dicom	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
72	2078cf12-6023-47a9-bf5c-23087f5f3080	IMG013	Densitometría Ósea	2	Medición densidad ósea	2500.00	\N	\N	f	\N	dicom	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
73	c71aa49a-deab-4ad6-93d1-fde3b47b76c1	IMG014	Mamografía	2	Rayos X mama	2000.00	\N	\N	f	\N	dicom	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
74	994e6cb3-3a3c-41d0-8e85-f60e3c8904c6	HEM006	Tiempo de Protrombina (PT)	5	Coagulación	300.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
75	d8c71a9e-9ecb-4faa-949e-98e3021db3ee	HEM007	Tiempo de Tromboplastina (PTT)	5	Coagulación	300.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
76	20083f62-7a4e-4593-896c-c32ed6aff5ee	HEM008	Reticulocitos	5	Producción de glóbulos rojos	250.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
77	9752df39-0db1-4c19-8ac9-afc6c2df6506	HEM009	Frotis de Sangre Periférica	5	Morfología celular	400.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
78	b04b27ff-2c6d-4f64-9643-06a429160ff3	HEM010	Electroforesis de Hemoglobina	5	Hemoglobinopatías	800.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
79	d4033832-b008-488d-af7d-013630926c57	MIC001	Coprocultivo	4	Cultivo de heces	500.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
80	f88dc41e-1113-4fa2-8c10-e8d7558cebaa	MIC002	Exudado Faríngeo	4	Cultivo faríngeo	400.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
81	0e4340d8-e941-4130-9471-439ccb0cf05e	MIC003	Hemocultivo	4	Cultivo de sangre	700.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
82	ae36a785-317c-4131-bd9c-d8cedc77e007	MIC004	KOH (Hongos)	4	Examen directo hongos	300.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
83	ef595708-2f77-425f-9d81-65bd7266eb3e	MIC005	Coproparasitológico	4	Parásitos en heces	200.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
84	2e8a421f-1f45-4fce-818b-bd767de07e56	CAR002	Ecocardiograma	3	Ultrasonido cardíaco	2500.00	\N	\N	f	\N	dicom	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
85	4d9fdf00-003b-41a1-b61d-6aa1d880500d	CAR003	Holter 24h	3	Monitoreo cardíaco	3000.00	\N	\N	f	\N	pdf	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
86	3e2f3eba-dda3-490f-8d32-b62c1d7f608d	CAR004	MAPA 24h	3	Monitoreo presión arterial	2500.00	\N	\N	f	\N	pdf	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
87	f4621cac-3402-49dc-9fa7-82d80737399f	CAR005	Prueba de Esfuerzo	3	Ergometría	3500.00	\N	\N	f	\N	pdf	\N	t	2026-02-15 07:35:49.497429	2026-02-15 07:35:49.497429
88	5930b186-4bdd-45b1-aea2-6d5d4649802d	PKG001	Chequeo General Básico	1	Hemograma + Glicemia + Creatinina + Ácido Úrico + Perfil Lipídico + Orina	2500.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.509602	2026-02-15 07:35:49.509602
89	42438bb9-dfee-4bb3-ae84-f159eb9da68b	PKG002	Chequeo General Completo	1	Básico + Hepático + Tiroideo + ECG + Rx Tórax	5000.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.509602	2026-02-15 07:35:49.509602
90	ba144647-d738-40ba-bd1b-d0e0a59ba066	PKG003	Perfil Hepático	1	TGO + TGP + Bilirrubinas + Fosfatasa + Proteínas	1200.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.509602	2026-02-15 07:35:49.509602
91	209b040a-6f9d-4f96-aeb3-4d40ee6b7e7b	PKG004	Perfil Renal	1	Creatinina + Urea + Ácido Úrico + Electrolitos + Orina	1000.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.509602	2026-02-15 07:35:49.509602
92	d317ca2e-2c45-4f5a-ac5c-92d9b15f5de1	PKG005	Perfil Prenatal	1	Hemograma + Grupo + VDRL + HIV + Hepatitis B + Orina + Glicemia	3500.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.509602	2026-02-15 07:35:49.509602
93	f49b737b-550d-4cc3-b2e8-d6eb8e9b1ad0	PKG006	Perfil Prequirúrgico	1	Hemograma + PT + PTT + Glicemia + Creatinina + Tipificación	2000.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.509602	2026-02-15 07:35:49.509602
94	8dbcfb0e-ca6d-452a-b95f-49b26127c163	PKG007	Panel Diabético	1	Glicemia + HbA1c + Perfil Lipídico + Creatinina + Microalbuminuria	1500.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.509602	2026-02-15 07:35:49.509602
95	02941ea7-a6ad-4340-9eda-02d2f4b5a886	PKG008	Perfil Tiroideo Completo + Eco	7	TSH + T3 + T4 + Sonografía Tiroidea	2500.00	\N	\N	f	\N	hl7	\N	t	2026-02-15 07:35:49.509602	2026-02-15 07:35:49.509602
\.


--
-- Data for Name: factura_detalles; Type: TABLE DATA; Schema: public; Owner: centro_user
--

COPY public.factura_detalles (id, factura_id, orden_detalle_id, descripcion, cantidad, precio_unitario, descuento, itbis, total, created_at) FROM stdin;
1	1	1	Hemograma Completo	1	350.00	0.00	0.00	350.00	2026-02-14 16:03:03.402855
2	1	2	Glicemia en Ayunas	1	200.00	0.00	0.00	200.00	2026-02-14 16:03:03.405955
3	2	6	Hemograma Completo	1	350.00	0.00	0.00	350.00	2026-02-14 16:24:36.33606
4	2	7	Glicemia en Ayunas	1	200.00	0.00	0.00	200.00	2026-02-14 16:24:36.339218
5	2	8	Perfil Lipídico	1	800.00	50.00	0.00	750.00	2026-02-14 16:24:36.341201
6	3	22	Ácido Úrico	1	250.00	0.00	0.00	250.00	2026-02-15 04:46:39.04784
7	3	23	Creatinina	1	250.00	0.00	0.00	250.00	2026-02-15 04:46:39.05161
8	3	24	Electrocardiograma	1	500.00	0.00	0.00	500.00	2026-02-15 04:46:39.053593
9	3	25	Glicemia en Ayunas	1	200.00	0.00	0.00	200.00	2026-02-15 04:46:39.055476
10	3	26	Hemograma Completo	1	350.00	0.00	0.00	350.00	2026-02-15 04:46:39.057492
11	3	27	Perfil Lipídico	1	800.00	0.00	0.00	800.00	2026-02-15 04:46:39.059501
12	3	28	Rayos X de Tórax	1	600.00	0.00	0.00	600.00	2026-02-15 04:46:39.061397
13	3	29	Sonografía Abdominal	1	1200.00	0.00	0.00	1200.00	2026-02-15 04:46:39.063171
14	3	30	Sonografía Obstétrica	1	1500.00	0.00	0.00	1500.00	2026-02-15 04:46:39.064871
15	3	31	Sonografía Pélvica	1	1200.00	0.00	0.00	1200.00	2026-02-15 04:46:39.066663
16	4	32	Ácido Úrico	1	250.00	0.00	0.00	250.00	2026-02-15 05:16:01.870173
17	4	33	Creatinina	1	250.00	0.00	0.00	250.00	2026-02-15 05:16:01.872041
18	4	34	Electrocardiograma	1	500.00	0.00	0.00	500.00	2026-02-15 05:16:01.873825
19	4	35	Glicemia en Ayunas	1	200.00	0.00	0.00	200.00	2026-02-15 05:16:01.875596
20	4	36	Hemograma Completo	1	350.00	0.00	0.00	350.00	2026-02-15 05:16:01.877371
21	4	37	Perfil Lipídico	1	800.00	0.00	0.00	800.00	2026-02-15 05:16:01.880203
22	4	38	Rayos X de Tórax	1	600.00	0.00	0.00	600.00	2026-02-15 05:16:01.882034
23	4	39	Sonografía Abdominal	1	1200.00	0.00	0.00	1200.00	2026-02-15 05:16:01.883761
24	4	40	Sonografía Obstétrica	1	1500.00	0.00	0.00	1500.00	2026-02-15 05:16:01.885535
25	4	41	Sonografía Pélvica	1	1200.00	0.00	0.00	1200.00	2026-02-15 05:16:01.887343
26	5	238	Ácido Fólico	1	500.00	0.00	0.00	500.00	2026-02-16 04:34:00.920706
27	5	239	Ácido Úrico	1	250.00	0.00	0.00	250.00	2026-02-16 04:34:00.924141
28	5	240	AFP	1	700.00	0.00	0.00	700.00	2026-02-16 04:34:00.926883
29	5	241	ASTO	1	300.00	0.00	0.00	300.00	2026-02-16 04:34:00.929746
30	5	242	Beta HCG	1	500.00	0.00	0.00	500.00	2026-02-16 04:34:00.932583
31	6	256	Ácido Fólico	1	500.00	0.00	0.00	500.00	2026-02-16 06:29:19.486349
32	6	257	Ácido Úrico	1	250.00	0.00	0.00	250.00	2026-02-16 06:29:19.492316
33	6	258	AFP	1	700.00	0.00	0.00	700.00	2026-02-16 06:29:19.495265
\.


--
-- Data for Name: facturas; Type: TABLE DATA; Schema: public; Owner: centro_user
--

COPY public.facturas (id, uuid, numero_factura, ncf, tipo_comprobante, orden_id, paciente_id, fecha_factura, fecha_vencimiento, subtotal, descuento, itbis, otros_impuestos, total, estado, forma_pago, notas, usuario_emision_id, anulada_por_id, motivo_anulacion, fecha_anulacion, created_at, updated_at) FROM stdin;
1	75b4d4fa-9463-4c73-899c-59ecb2cefc66	FAC-2026-000001	\N	\N	2	1	2026-02-14 16:03:03.385835	2026-03-16	550.00	0.00	0.00	0.00	550.00	pagada	tarjeta	\N	1	\N	\N	\N	2026-02-14 16:03:03.393167	2026-02-14 16:03:03.819693
2	8780ed5c-9d78-489d-84f9-9298729509fd	FAC-2026-000002	\N	\N	4	2	2026-02-14 16:24:36.324061	2026-03-16	1300.00	0.00	0.00	0.00	1300.00	pagada	tarjeta	\N	1	\N	\N	\N	2026-02-14 16:24:36.330081	2026-02-14 16:24:36.728656
3	0bfcd02f-c66b-48ae-8b4e-77612fb9399e	FAC-2026-000003	\N	\N	8	2	2026-02-15 04:46:39.031003	2026-03-17	6850.00	0.00	0.00	0.00	6850.00	pendiente	efectivo	\N	1	\N	\N	\N	2026-02-15 04:46:39.039382	2026-02-15 04:46:39.039385
4	52797710-a0ff-4503-93e1-a37c5d4f3852	FAC-2026-000004	\N	\N	9	3	2026-02-15 05:16:01.865382	2026-03-17	6850.00	0.00	1233.00	0.00	8083.00	pagada	efectivo	\N	1	\N	\N	\N	2026-02-15 05:16:01.867578	2026-02-15 07:47:46.801418
5	73df23e7-6578-4be4-9ebe-e1c82b1d74c9	FAC-2026-000005	B02-001-00000001	B02	14	11	2026-02-16 04:34:00.900081	2026-03-18	2250.00	0.00	405.00	0.00	2655.00	pendiente	efectivo	\N	1	\N	\N	\N	2026-02-16 04:34:00.912582	2026-02-16 04:34:00.912585
6	3dafd9e9-2b78-427e-a297-5137ee590008	FAC-2026-000006	B02-001-00000002	B02	21	9	2026-02-16 06:29:19.464356	2026-03-18	1450.00	0.00	0.00	0.00	1450.00	pagada	efectivo	\N	1	\N	\N	\N	2026-02-16 06:29:19.477463	2026-02-16 06:29:39.338177
\.


--
-- Data for Name: facturas_qr; Type: TABLE DATA; Schema: public; Owner: centro_user
--

COPY public.facturas_qr (id, factura_id, codigo_qr, url_acceso, fecha_generacion, accesos) FROM stdin;
\.


--
-- Data for Name: inventario; Type: TABLE DATA; Schema: public; Owner: centro_user
--

COPY public.inventario (id, codigo, nombre, categoria, unidad_medida, cantidad_actual, cantidad_minima, costo_unitario, proveedor, fecha_vencimiento, lote, activo, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: ncf_secuencias; Type: TABLE DATA; Schema: public; Owner: centro_user
--

COPY public.ncf_secuencias (id, tipo_comprobante, serie, secuencia_inicio, secuencia_fin, secuencia_actual, fecha_vencimiento, activo, created_at) FROM stdin;
1	B01	001	1	10000	1	2027-12-31	t	2026-02-14 08:51:33.091426
2	B02	001	1	5000	3	2027-12-31	t	2026-02-14 08:51:33.091426
\.


--
-- Data for Name: orden_detalles; Type: TABLE DATA; Schema: public; Owner: centro_user
--

COPY public.orden_detalles (id, orden_id, estudio_id, precio, descuento, precio_final, estado, resultado_disponible, fecha_resultado, tecnico_id, observaciones, created_at) FROM stdin;
9	5	6	600.00	0.00	600.00	pendiente	f	\N	\N	\N	2026-02-14 19:35:34.103661
12	7	5	250.00	0.00	250.00	pendiente	f	\N	\N	\N	2026-02-14 20:38:51.803813
13	7	4	250.00	0.00	250.00	pendiente	f	\N	\N	\N	2026-02-14 20:38:51.808239
14	7	10	500.00	0.00	500.00	pendiente	f	\N	\N	\N	2026-02-14 20:38:51.810411
15	7	2	200.00	0.00	200.00	pendiente	f	\N	\N	\N	2026-02-14 20:38:51.81258
16	7	1	350.00	0.00	350.00	pendiente	f	\N	\N	\N	2026-02-14 20:38:51.81466
17	7	3	800.00	0.00	800.00	pendiente	f	\N	\N	\N	2026-02-14 20:38:51.816962
18	7	6	600.00	0.00	600.00	pendiente	f	\N	\N	\N	2026-02-14 20:38:51.819184
19	7	7	1200.00	0.00	1200.00	pendiente	f	\N	\N	\N	2026-02-14 20:38:51.821235
20	7	9	1500.00	0.00	1500.00	pendiente	f	\N	\N	\N	2026-02-14 20:38:51.823209
21	7	8	1200.00	0.00	1200.00	pendiente	f	\N	\N	\N	2026-02-14 20:38:51.824975
22	8	5	250.00	0.00	250.00	pendiente	f	\N	\N	\N	2026-02-15 04:45:35.224546
23	8	4	250.00	0.00	250.00	pendiente	f	\N	\N	\N	2026-02-15 04:45:35.22772
24	8	10	500.00	0.00	500.00	pendiente	f	\N	\N	\N	2026-02-15 04:45:35.229872
25	8	2	200.00	0.00	200.00	pendiente	f	\N	\N	\N	2026-02-15 04:45:35.231923
26	8	1	350.00	0.00	350.00	pendiente	f	\N	\N	\N	2026-02-15 04:45:35.234054
27	8	3	800.00	0.00	800.00	pendiente	f	\N	\N	\N	2026-02-15 04:45:35.237125
28	8	6	600.00	0.00	600.00	pendiente	f	\N	\N	\N	2026-02-15 04:45:35.239317
29	8	7	1200.00	0.00	1200.00	pendiente	f	\N	\N	\N	2026-02-15 04:45:35.241285
30	8	9	1500.00	0.00	1500.00	pendiente	f	\N	\N	\N	2026-02-15 04:45:35.243314
31	8	8	1200.00	0.00	1200.00	pendiente	f	\N	\N	\N	2026-02-15 04:45:35.245016
38	9	6	600.00	0.00	600.00	pendiente	f	\N	\N	\N	2026-02-15 05:15:11.906089
39	9	7	1200.00	0.00	1200.00	pendiente	f	\N	\N	\N	2026-02-15 05:15:11.908161
40	9	9	1500.00	0.00	1500.00	pendiente	f	\N	\N	\N	2026-02-15 05:15:11.910196
41	9	8	1200.00	0.00	1200.00	pendiente	f	\N	\N	\N	2026-02-15 05:15:11.912023
42	10	72	2500.00	19.00	2481.00	pendiente	f	\N	\N	\N	2026-02-15 08:13:27.513976
43	11	30	500.00	0.00	500.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.105132
44	11	5	250.00	0.00	250.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.108162
45	11	53	700.00	0.00	700.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.110416
46	11	62	300.00	0.00	300.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.112572
47	11	48	500.00	0.00	500.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.114682
48	11	13	350.00	0.00	350.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.116757
49	11	49	800.00	0.00	800.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.118849
50	11	51	800.00	0.00	800.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.120845
51	11	50	800.00	0.00	800.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.12286
52	11	22	250.00	0.00	250.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.124887
53	11	52	700.00	0.00	700.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.126987
54	11	88	2500.00	0.00	2500.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.128938
55	11	89	5000.00	0.00	5000.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.130955
56	11	17	250.00	0.00	250.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.132954
57	11	18	250.00	0.00	250.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.134937
58	11	79	500.00	0.00	500.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.136928
59	11	83	200.00	0.00	200.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.138892
60	11	46	500.00	0.00	500.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.140854
61	11	4	250.00	0.00	250.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.142905
62	11	56	800.00	0.00	800.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.144906
63	11	72	2500.00	0.00	2500.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.146875
64	11	34	400.00	0.00	400.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.148927
65	11	84	2500.00	0.00	2500.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.150855
66	11	10	500.00	0.00	500.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.152821
67	11	78	800.00	0.00	800.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.154854
68	11	40	500.00	0.00	500.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.156853
69	11	80	400.00	0.00	400.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.158845
70	11	61	350.00	0.00	350.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.160858
71	11	27	450.00	0.00	450.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.162867
72	11	14	250.00	0.00	250.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.164858
73	11	23	250.00	0.00	250.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.166859
74	11	77	400.00	0.00	400.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.168902
75	11	42	500.00	0.00	500.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.170903
76	11	2	200.00	0.00	200.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.173026
77	11	19	600.00	0.00	600.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.175039
78	11	81	700.00	0.00	700.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.177009
79	11	1	350.00	0.00	350.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.178927
80	11	59	500.00	0.00	500.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.180878
81	11	60	500.00	0.00	500.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.18281
82	11	26	300.00	0.00	300.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.184874
83	11	57	500.00	0.00	500.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.186894
84	11	85	3000.00	0.00	3000.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.189103
85	11	45	500.00	0.00	500.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.191098
86	11	82	300.00	0.00	300.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.193099
87	11	43	500.00	0.00	500.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.19502
88	11	24	250.00	0.00	250.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.196924
89	11	73	2000.00	0.00	2000.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.198861
90	11	86	2500.00	0.00	2500.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.200832
91	11	33	400.00	0.00	400.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.202876
92	11	31	200.00	0.00	200.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.204883
93	11	94	1500.00	0.00	1500.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.20684
94	11	20	350.00	0.00	350.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.208857
95	11	90	1200.00	0.00	1200.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.210914
96	11	3	800.00	0.00	800.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.212911
97	11	92	3500.00	0.00	3500.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.214961
98	11	93	2000.00	0.00	2000.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.216961
99	11	91	1000.00	0.00	1000.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.219255
100	11	38	1200.00	0.00	1200.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.221237
101	11	95	2500.00	0.00	2500.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.223222
102	11	41	500.00	0.00	500.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.225306
103	11	44	500.00	0.00	500.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.227338
104	11	15	300.00	0.00	300.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.229309
105	11	55	500.00	0.00	500.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.231247
106	11	54	1500.00	0.00	1500.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.233245
107	11	87	3500.00	0.00	3500.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.23522
108	11	47	600.00	0.00	600.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.237169
109	11	69	800.00	0.00	800.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.239133
110	11	6	600.00	0.00	600.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.241131
111	11	71	500.00	0.00	500.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.243118
112	11	70	600.00	0.00	600.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.245076
113	11	76	250.00	0.00	250.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.247008
114	11	25	350.00	0.00	350.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.248953
115	11	7	1200.00	0.00	1200.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.250926
116	11	68	2000.00	0.00	2000.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.25289
117	11	64	1500.00	0.00	1500.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.255036
118	11	9	1500.00	0.00	1500.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.257056
119	11	8	1200.00	0.00	1200.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.259061
120	11	66	1200.00	0.00	1200.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.260965
121	11	65	1200.00	0.00	1200.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.262944
122	11	67	1200.00	0.00	1200.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.264879
123	11	36	400.00	0.00	400.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.266825
124	11	37	400.00	0.00	400.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.26885
125	11	39	600.00	0.00	600.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.270821
126	11	74	300.00	0.00	300.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.272822
127	11	75	300.00	0.00	300.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.274814
128	11	63	300.00	0.00	300.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.276798
129	11	12	400.00	0.00	400.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.279417
130	11	16	250.00	0.00	250.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.282005
131	11	35	500.00	0.00	500.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.284327
132	11	11	200.00	0.00	200.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.286481
133	11	32	500.00	0.00	500.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.288549
134	11	58	300.00	0.00	300.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.290638
135	11	29	700.00	0.00	700.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.29276
136	11	28	800.00	0.00	800.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.29485
137	11	21	200.00	0.00	200.00	pendiente	f	\N	\N	\N	2026-02-16 02:08:58.2975
138	12	21	200.00	0.00	200.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.11999
139	12	28	800.00	0.00	800.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.123531
140	12	29	700.00	0.00	700.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.126254
141	12	58	300.00	0.00	300.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.128981
142	12	32	500.00	0.00	500.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.131629
143	12	11	200.00	0.00	200.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.13432
144	12	35	500.00	0.00	500.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.137135
145	12	16	250.00	0.00	250.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.139609
146	12	12	400.00	0.00	400.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.141815
147	12	63	300.00	0.00	300.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.144
148	12	75	300.00	0.00	300.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.146208
149	12	74	300.00	0.00	300.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.148418
150	12	39	600.00	0.00	600.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.150734
151	12	37	400.00	0.00	400.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.153213
152	12	36	400.00	0.00	400.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.155673
153	12	67	1200.00	0.00	1200.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.158235
154	12	65	1200.00	0.00	1200.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.160608
155	12	66	1200.00	0.00	1200.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.162929
156	12	8	1200.00	0.00	1200.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.165257
157	12	9	1500.00	0.00	1500.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.16758
158	12	64	1500.00	0.00	1500.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.169909
159	12	68	2000.00	0.00	2000.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.172229
160	12	7	1200.00	0.00	1200.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.174628
161	12	25	350.00	0.00	350.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.176933
162	12	76	250.00	0.00	250.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.179215
163	12	70	600.00	0.00	600.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.181598
164	12	71	500.00	0.00	500.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.183914
165	12	6	600.00	0.00	600.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.186218
166	12	69	800.00	0.00	800.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.188549
167	12	47	600.00	0.00	600.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.190847
168	12	87	3500.00	0.00	3500.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.193147
169	12	54	1500.00	0.00	1500.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.195453
170	12	55	500.00	0.00	500.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.19775
171	12	15	300.00	0.00	300.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.200073
172	12	44	500.00	0.00	500.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.20241
173	12	41	500.00	0.00	500.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.204692
174	12	95	2500.00	0.00	2500.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.206991
175	12	38	1200.00	0.00	1200.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.209319
176	12	91	1000.00	0.00	1000.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.211623
177	12	93	2000.00	0.00	2000.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.213975
178	12	92	3500.00	0.00	3500.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.216351
179	12	3	800.00	0.00	800.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.218767
180	12	90	1200.00	0.00	1200.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.221063
181	12	20	350.00	0.00	350.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.223379
182	12	94	1500.00	0.00	1500.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.225669
183	12	31	200.00	0.00	200.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.227998
184	12	33	400.00	0.00	400.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.230469
185	12	86	2500.00	0.00	2500.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.232791
186	12	73	2000.00	0.00	2000.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.235136
187	12	24	250.00	0.00	250.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.237487
188	12	43	500.00	0.00	500.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.239788
189	12	82	300.00	0.00	300.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.242088
190	12	45	500.00	0.00	500.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.244375
191	12	85	3000.00	0.00	3000.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.246666
192	12	57	500.00	0.00	500.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.249035
193	12	26	300.00	0.00	300.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.251392
194	12	60	500.00	0.00	500.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.253726
195	12	59	500.00	0.00	500.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.256229
196	12	1	350.00	0.00	350.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.260076
197	12	81	700.00	0.00	700.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.262617
198	12	19	600.00	0.00	600.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.264892
199	12	2	200.00	0.00	200.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.267062
200	12	42	500.00	0.00	500.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.269284
201	12	77	400.00	0.00	400.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.271518
202	12	23	250.00	0.00	250.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.27368
203	12	14	250.00	0.00	250.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.275982
204	12	27	450.00	0.00	450.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.278206
205	12	61	350.00	0.00	350.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.280419
206	12	80	400.00	0.00	400.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.28256
207	12	40	500.00	0.00	500.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.284701
208	12	78	800.00	0.00	800.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.28681
209	12	10	500.00	0.00	500.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.288978
210	12	84	2500.00	0.00	2500.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.291169
211	12	34	400.00	0.00	400.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.293296
212	12	72	2500.00	0.00	2500.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.295449
213	12	56	800.00	0.00	800.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.297605
214	12	4	250.00	0.00	250.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.299747
215	12	46	500.00	0.00	500.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.301891
216	12	83	200.00	0.00	200.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.304104
217	12	79	500.00	0.00	500.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.306313
218	12	18	250.00	0.00	250.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.30849
219	12	17	250.00	0.00	250.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.310672
220	12	89	5000.00	0.00	5000.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.312833
221	12	88	2500.00	0.00	2500.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.315043
222	12	52	700.00	0.00	700.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.317303
223	12	22	250.00	0.00	250.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.319518
224	12	50	800.00	0.00	800.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.32174
225	12	51	800.00	0.00	800.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.323918
226	12	49	800.00	0.00	800.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.32609
227	12	13	350.00	0.00	350.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.328314
228	12	48	500.00	0.00	500.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.330492
229	12	62	300.00	0.00	300.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.332689
230	12	53	700.00	0.00	700.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.334879
231	12	5	250.00	0.00	250.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.337036
232	12	30	500.00	0.00	500.00	pendiente	f	\N	\N	\N	2026-02-16 02:25:32.338928
1	2	1	350.00	0.00	350.00	completado	t	2026-02-16 02:45:09.262334	\N	\N	2026-02-14 15:54:07.873596
2	2	2	200.00	0.00	200.00	completado	t	2026-02-16 02:45:09.271409	\N	\N	2026-02-14 15:54:07.876761
3	3	1	350.00	0.00	350.00	completado	t	2026-02-16 02:45:09.275731	\N	\N	2026-02-14 15:59:13.236198
4	3	2	200.00	0.00	200.00	completado	t	2026-02-16 02:45:09.28103	\N	\N	2026-02-14 15:59:13.23952
5	3	3	800.00	50.00	750.00	completado	t	2026-02-16 02:45:09.289297	\N	\N	2026-02-14 15:59:13.24147
6	4	1	350.00	0.00	350.00	completado	t	2026-02-16 02:45:09.294759	\N	\N	2026-02-14 16:24:35.941995
7	4	2	200.00	0.00	200.00	completado	t	2026-02-16 02:45:09.299169	\N	\N	2026-02-14 16:24:35.945107
8	4	3	800.00	50.00	750.00	completado	t	2026-02-16 02:45:09.303184	\N	\N	2026-02-14 16:24:35.947125
10	6	6	600.00	0.00	600.00	completado	t	2026-02-16 02:45:09.307145	\N	\N	2026-02-14 20:19:31.402863
11	6	1	350.00	0.00	350.00	completado	t	2026-02-16 02:45:09.311157	\N	\N	2026-02-14 20:19:31.406918
32	9	5	250.00	0.00	250.00	completado	t	2026-02-16 02:45:09.316302	\N	\N	2026-02-15 05:15:11.892997
33	9	4	250.00	0.00	250.00	completado	t	2026-02-16 02:45:09.323245	\N	\N	2026-02-15 05:15:11.89547
34	9	10	500.00	0.00	500.00	completado	t	2026-02-16 02:45:09.327228	\N	\N	2026-02-15 05:15:11.897615
35	9	2	200.00	0.00	200.00	completado	t	2026-02-16 02:45:09.332212	\N	\N	2026-02-15 05:15:11.899713
36	9	1	350.00	0.00	350.00	completado	t	2026-02-16 02:45:09.336559	\N	\N	2026-02-15 05:15:11.901791
37	9	3	800.00	0.00	800.00	completado	t	2026-02-16 02:45:09.340671	\N	\N	2026-02-15 05:15:11.903946
233	13	30	500.00	0.00	500.00	pendiente	f	\N	\N	\N	2026-02-16 03:02:28.418802
234	13	5	250.00	0.00	250.00	pendiente	f	\N	\N	\N	2026-02-16 03:02:28.422091
235	13	62	300.00	0.00	300.00	pendiente	f	\N	\N	\N	2026-02-16 03:02:28.424521
236	13	53	700.00	0.00	700.00	pendiente	f	\N	\N	\N	2026-02-16 03:02:28.426844
237	13	48	500.00	0.00	500.00	pendiente	f	\N	\N	\N	2026-02-16 03:02:28.428917
238	14	30	500.00	0.00	500.00	pendiente	f	\N	\N	\N	2026-02-16 04:33:40.275692
239	14	5	250.00	0.00	250.00	pendiente	f	\N	\N	\N	2026-02-16 04:33:40.278935
240	14	53	700.00	0.00	700.00	pendiente	f	\N	\N	\N	2026-02-16 04:33:40.281233
241	14	62	300.00	0.00	300.00	pendiente	f	\N	\N	\N	2026-02-16 04:33:40.283534
242	14	48	500.00	0.00	500.00	pendiente	f	\N	\N	\N	2026-02-16 04:33:40.285401
244	16	62	386.63	0.00	386.63	completado	f	\N	\N	\N	2026-01-29 09:58:19.47867
245	16	5	386.02	0.00	386.02	completado	f	\N	\N	\N	2026-02-10 04:33:21.549292
246	17	36	100.72	0.00	100.72	completado	f	\N	\N	\N	2026-02-01 09:44:52.108122
247	17	10	299.20	0.00	299.20	completado	f	\N	\N	\N	2026-02-05 07:55:05.371152
248	17	66	298.33	0.00	298.33	completado	f	\N	\N	\N	2026-02-12 05:48:40.292462
249	18	69	426.77	0.00	426.77	completado	f	\N	\N	\N	2026-02-10 11:33:12.119977
250	18	84	441.00	0.00	441.00	completado	f	\N	\N	\N	2026-02-05 13:42:16.432414
251	19	1	158.17	0.00	158.17	completado	f	\N	\N	\N	2026-02-10 21:35:04.851371
252	19	84	362.42	0.00	362.42	completado	f	\N	\N	\N	2026-02-13 19:31:26.298426
253	20	48	387.61	0.00	387.61	completado	f	\N	\N	\N	2026-02-03 05:39:53.329012
254	20	80	495.33	0.00	495.33	completado	f	\N	\N	\N	2026-02-07 11:10:42.018814
255	20	79	471.35	0.00	471.35	completado	f	\N	\N	\N	2026-02-03 06:21:28.43674
256	21	30	500.00	0.00	500.00	pendiente	f	\N	\N	\N	2026-02-16 06:29:14.724509
257	21	5	250.00	0.00	250.00	pendiente	f	\N	\N	\N	2026-02-16 06:29:14.727805
258	21	53	700.00	0.00	700.00	pendiente	f	\N	\N	\N	2026-02-16 06:29:14.729767
\.


--
-- Data for Name: ordenes; Type: TABLE DATA; Schema: public; Owner: centro_user
--

COPY public.ordenes (id, uuid, numero_orden, paciente_id, medico_referente, fecha_orden, fecha_cita, estado, prioridad, observaciones, usuario_registro_id, created_at, updated_at) FROM stdin;
5	a42b7cf4-8936-4bfb-849e-15500d28c7a3	ORD-2602-00004	2	chris	2026-02-14 19:35:34.018845	\N	pendiente	normal	\N	1	2026-02-14 19:35:34.018849	2026-02-14 19:35:34.01885
7	68e9cf56-ff86-4d1b-bd06-89be443ce471	ORD-2602-00006	2	chris	2026-02-14 20:38:51.796027	\N	pendiente	normal	\N	1	2026-02-14 20:38:51.79603	2026-02-14 20:38:51.796031
8	1c3307cb-841a-41fb-a0c4-20bc666b21b5	ORD-2602-00007	2	christopher	2026-02-15 04:45:35.216733	\N	facturada	normal	\N	1	2026-02-15 04:45:35.216735	2026-02-15 04:46:39.025478
9	fa979c1c-9db9-48fe-9e2d-8dba2b0eeb9c	ORD-2602-00008	3		2026-02-15 05:15:11.888736	\N	facturada	normal	\N	1	2026-02-15 05:15:11.888738	2026-02-15 05:16:01.86246
10	9063dea4-d500-4ac5-bd91-a0b95ac6e132	ORD-2602-00009	7		2026-02-15 08:13:27.506873	\N	pendiente	urgente	\N	1	2026-02-15 08:13:27.506875	2026-02-15 08:13:27.506877
11	50c74768-563e-44b2-989e-192b07ede835	ORD-2602-00010	7		2026-02-16 02:08:58.098691	\N	pendiente	normal	\N	1	2026-02-16 02:08:58.098693	2026-02-16 02:08:58.098695
12	d02a4f2b-6414-4926-8b8a-5cba44bde7c1	ORD-2602-00011	7		2026-02-16 02:25:32.112404	\N	pendiente	normal	\N	1	2026-02-16 02:25:32.112407	2026-02-16 02:25:32.112408
2	836282f3-bfc9-42aa-923f-88f4e5dbed35	ORD-2602-00001	1	Dr. Garcia	2026-02-14 15:54:07.865301	\N	completada	normal	\N	1	2026-02-14 15:54:07.865303	2026-02-16 02:45:09.250492
3	915ebd4a-4d63-433c-aab1-f7f29492a6fd	ORD-2602-00002	2	Dr. Martinez	2026-02-14 15:59:13.229934	\N	completada	normal	\N	1	2026-02-14 15:59:13.229937	2026-02-16 02:45:09.250492
4	ede331fa-8f3b-4aba-8bf8-5d0cd9c9d71e	ORD-2602-00003	2	Dr. Martinez	2026-02-14 16:24:35.935595	\N	completada	normal	\N	1	2026-02-14 16:24:35.935597	2026-02-16 02:45:09.250492
6	6144ab26-f138-475e-b6a2-4f711f1b0c13	ORD-2602-00005	3	chris	2026-02-14 20:19:31.392008	\N	completada	normal	\N	1	2026-02-14 20:19:31.392013	2026-02-16 02:45:09.250492
13	871305c0-2a9e-4310-8fdb-f4733da0ff11	ORD-2602-00012	9		2026-02-16 03:02:28.412388	\N	pendiente	normal	\N	1	2026-02-16 03:02:28.412391	2026-02-16 03:02:28.412392
14	4adc136d-700e-4499-8e7a-2e652af3d82b	ORD-2602-00013	11		2026-02-16 04:33:40.269031	\N	facturada	normal	\N	1	2026-02-16 04:33:40.269034	2026-02-16 04:34:00.912864
16	01ed611f-557d-47d8-ad89-8a81ebb199f3	ORD-20260216-0977	1	Dr. Carlos Méndez	2026-01-21 00:00:00	\N	completada	normal	\N	\N	2026-02-08 23:23:43.724997	2026-02-16 06:14:50.798751
17	e73110b2-b92c-4eef-ad34-4744f7198332	ORD-20260216-0434	2	Dr. José Rodríguez	2026-01-27 00:00:00	\N	completada	normal	\N	\N	2026-01-17 07:35:38.841	2026-02-16 06:14:50.798751
18	5ceab680-dd8a-402c-982b-6288c310631d	ORD-20260216-0544	3	Dra. María García	2026-01-25 00:00:00	\N	completada	normal	\N	\N	2026-01-18 03:55:32.220527	2026-02-16 06:14:50.798751
19	a061b88c-fe7e-4553-82be-e9a81f6bf0ab	ORD-20260216-0333	4	Dra. Ana Martínez	2026-02-01 00:00:00	\N	completada	normal	\N	\N	2026-02-11 01:05:13.110439	2026-02-16 06:14:50.798751
20	27aad60a-b501-4308-bd2f-bd439e16d7d8	ORD-20260216-0959	5	Dra. Ana Martínez	2026-02-12 00:00:00	\N	completada	normal	\N	\N	2026-02-15 14:36:02.953849	2026-02-16 06:14:50.798751
21	f365f891-eb9a-4132-9e3e-6300e5fecb4c	ORD-2602-00016	9		2026-02-16 06:29:14.716489	\N	facturada	normal	\N	1	2026-02-16 06:29:14.716492	2026-02-16 06:29:19.477751
\.


--
-- Data for Name: pacientes; Type: TABLE DATA; Schema: public; Owner: centro_user
--

COPY public.pacientes (id, uuid, cedula, pasaporte, nombre, apellido, fecha_nacimiento, sexo, telefono, celular, email, direccion, ciudad, seguro_medico, numero_poliza, tipo_sangre, alergias, notas_medicas, estado, created_at, updated_at, codigo_paciente, portal_usuario, portal_password, ultimo_acceso_portal) FROM stdin;
1	891015ab-7d97-466a-96d3-a05ad321b85f	402-1234567-8	\N	Juan	Perez	1990-01-15	M	809-555-1234	\N	\N	\N	\N	\N	\N	\N	\N	\N	activo	2026-02-14 15:54:07.499788	2026-02-15 03:58:51.853352	PAC-20260215-0001	\N	\N	\N
2	76186415-2ff8-463e-bce5-67c311f14665	402-9876543-2	\N	Ana	Rodriguez	1992-05-20	F	809-555-9999	829-555-8888	ana.rodriguez@email.com	Av. Independencia 789	Santo Domingo	\N	\N	\N	\N	\N	activo	2026-02-14 15:59:12.485777	2026-02-15 03:58:51.853352	PAC-20260215-0002	\N	\N	\N
3	c7095e39-c25d-4d8e-aedf-875f388b9fa1	40233104013	\N	cristopher	rodriguez bocio	2002-09-30	M		faWF	2025-0108@unad.edu.do	cancino	Santo Domingo	\N	\N	\N	\N	\N	activo	2026-02-14 19:36:07.63761	2026-02-15 03:58:51.853352	PAC-20260215-0003	\N	\N	\N
4	7c1ad74d-1f2b-4031-8665-c3d0cd684243	402-9999999-9	\N	Test	Prueba	1990-01-01	M	809-555-0000	\N	\N	\N	\N	\N	\N	\N	\N	\N	activo	2026-02-14 20:49:59.713712	2026-02-15 03:58:51.853352	PAC-20260215-0004	\N	\N	\N
5	6c5ddc0f-41db-486b-a12e-af9536168337	40233104011	\N	cristopher	rodriguez bocio	2002-09-30	M		8493736446	christopherhonor540@gmail.com	cancino	Santo Domingo	\N	\N	\N	\N	\N	activo	2026-02-15 04:41:55.744956	2026-02-15 04:41:55.744958	PAC-20260215-0006	\N	\N	\N
7	f4f18447-3c74-4b10-85ca-3f0cbaee72ff	40233104012	\N	cristopher	rodriguez bocio	2002-09-30	M		8493736446		cancino				A+		\N	activo	2026-02-15 07:45:48.237043	2026-02-15 07:45:48.237046	PAC-20260215-0008	\N	\N	\N
9	24cf2544-3388-4abe-ae6f-c0232cc86306	402-3310401-0	\N	rosalba	garcia	\N	\N	8493736446									\N	activo	2026-02-16 03:02:18.208306	2026-02-16 03:02:18.208309	PAC-20260216-0010	\N	\N	\N
11	e16aef87-6542-4f2e-acf4-77e02d5686fc	40233104019	\N	cristopher	rodriguez bocio	\N	\N	8493736446									\N	activo	2026-02-16 04:33:32.885326	2026-02-16 04:33:32.885329	PAC-20260216-0012	\N	\N	\N
\.


--
-- Data for Name: pagos; Type: TABLE DATA; Schema: public; Owner: centro_user
--

COPY public.pagos (id, uuid, factura_id, fecha_pago, monto, metodo_pago, referencia, banco, notas, usuario_recibe_id, caja_id, created_at) FROM stdin;
1	d2a03906-95e3-4b6b-b099-a63e66b61d8f	1	2026-02-14 16:03:03.828685	550.00	tarjeta	VISA-4532	Banco Popular	\N	1	\N	2026-02-14 16:03:03.828687
2	161ded7d-1d3f-4d2e-8c25-ad2c0af1bd1b	2	2026-02-14 16:24:36.73483	1300.00	tarjeta	VISA-4532	Banco Popular	\N	1	\N	2026-02-14 16:24:36.734832
3	6a245318-bdff-46a8-b3a4-d929ad3b4780	4	2026-02-15 07:47:46.811813	8083.00	efectivo			\N	1	\N	2026-02-15 07:47:46.811816
4	9ae3063b-99dd-4c0d-8942-156f885db57f	6	2026-02-16 06:29:39.349298	1450.00	efectivo			\N	1	\N	2026-02-16 06:29:39.349301
\.


--
-- Data for Name: portal_paciente_accesos; Type: TABLE DATA; Schema: public; Owner: centro_user
--

COPY public.portal_paciente_accesos (id, paciente_id, fecha_acceso, ip_address, dispositivo) FROM stdin;
\.


--
-- Data for Name: radiografias; Type: TABLE DATA; Schema: public; Owner: centro_user
--

COPY public.radiografias (id, orden_detalle_id, paciente_id, tipo_estudio, region_anatomica, imagen_original, imagen_procesada, formato, ancho, alto, informe_medico, hallazgos, conclusion, medico_id, fecha_toma, fecha_informe, estado, created_at, radiologo_id, fecha_diagnostico) FROM stdin;
\.


--
-- Data for Name: resultados; Type: TABLE DATA; Schema: public; Owner: centro_user
--

COPY public.resultados (id, uuid, orden_detalle_id, tipo_archivo, ruta_archivo, ruta_nube, nombre_archivo, tamano_bytes, hash_archivo, datos_hl7, datos_dicom, interpretacion, valores_referencia, estado_validacion, validado_por_id, fecha_validacion, impreso, enviado_email, fecha_importacion, created_at) FROM stdin;
17	0f8eb375-db2b-4678-b754-0f47429b5e13	244	pdf	/uploads/resultados/16/	\N	analisis_1_20260216.pdf	453844	44bdd21408a9cffa3890914fa3387af9	\N	{"hdl": {"valor": 41.27, "estado": "normal", "unidad": "mg/dL", "referencia": ">40 mg/dL"}, "ldl": {"valor": 135.48, "estado": "normal", "unidad": "mg/dL", "referencia": "<130 mg/dL"}, "glucosa": {"valor": 67.81, "estado": "alto", "unidad": "mg/dL", "referencia": "70-110 mg/dL"}, "plaquetas": {"valor": 289317, "estado": "bajo", "unidad": "cel/µL", "referencia": "150000-400000 cel/µL"}, "creatinina": {"valor": 1.49, "estado": "alto", "unidad": "mg/dL", "referencia": "0.6-1.2 mg/dL"}, "leucocitos": {"valor": 11469, "estado": "alto", "unidad": "cel/µL", "referencia": "4000-11000 cel/µL"}, "hemoglobina": {"valor": 15.94, "estado": "alto", "unidad": "g/dL", "referencia": "12-16 g/dL"}, "trigliceridos": {"valor": 264.40, "estado": "normal", "unidad": "mg/dL", "referencia": "<150 mg/dL"}, "colesterol_total": {"valor": 178.46, "estado": "alto", "unidad": "mg/dL", "referencia": "<200 mg/dL"}}	Leve elevación en algunos valores. Se recomienda dieta balanceada y control en 3 meses.	Ver rangos de referencia en cada parámetro	validado	\N	\N	f	f	2026-01-31 07:19:33.842218	2026-02-10 01:07:32.803555
18	49b6801e-5638-4873-b2c1-364f29543f25	245	pdf	/uploads/resultados/16/	\N	analisis_2_20260216.pdf	230116	e465a747465dde80174a69dbd6dee97a	\N	{"hdl": {"valor": 34.03, "estado": "normal", "unidad": "mg/dL", "referencia": ">40 mg/dL"}, "ldl": {"valor": 107.43, "estado": "normal", "unidad": "mg/dL", "referencia": "<130 mg/dL"}, "glucosa": {"valor": 109.56, "estado": "alto", "unidad": "mg/dL", "referencia": "70-110 mg/dL"}, "plaquetas": {"valor": 215398, "estado": "alto", "unidad": "cel/µL", "referencia": "150000-400000 cel/µL"}, "creatinina": {"valor": 1.06, "estado": "alto", "unidad": "mg/dL", "referencia": "0.6-1.2 mg/dL"}, "leucocitos": {"valor": 9719, "estado": "bajo", "unidad": "cel/µL", "referencia": "4000-11000 cel/µL"}, "hemoglobina": {"valor": 13.53, "estado": "normal", "unidad": "g/dL", "referencia": "12-16 g/dL"}, "trigliceridos": {"valor": 197.09, "estado": "normal", "unidad": "mg/dL", "referencia": "<150 mg/dL"}, "colesterol_total": {"valor": 191.36, "estado": "alto", "unidad": "mg/dL", "referencia": "<200 mg/dL"}}	Leve elevación en algunos valores. Se recomienda dieta balanceada y control en 3 meses.	Ver rangos de referencia en cada parámetro	pendiente	\N	\N	f	f	2026-02-06 02:02:57.407317	2026-01-30 03:18:27.155832
19	272b0a90-5f30-41cb-8646-33f3400d6760	246	pdf	/uploads/resultados/17/	\N	analisis_3_20260216.pdf	378721	252a080210704c86e13f951b8f4ff4b2	\N	{"hdl": {"valor": 31.67, "estado": "normal", "unidad": "mg/dL", "referencia": ">40 mg/dL"}, "ldl": {"valor": 95.22, "estado": "normal", "unidad": "mg/dL", "referencia": "<130 mg/dL"}, "glucosa": {"valor": 120.36, "estado": "normal", "unidad": "mg/dL", "referencia": "70-110 mg/dL"}, "plaquetas": {"valor": 215459, "estado": "normal", "unidad": "cel/µL", "referencia": "150000-400000 cel/µL"}, "creatinina": {"valor": 1.42, "estado": "alto", "unidad": "mg/dL", "referencia": "0.6-1.2 mg/dL"}, "leucocitos": {"valor": 8154, "estado": "normal", "unidad": "cel/µL", "referencia": "4000-11000 cel/µL"}, "hemoglobina": {"valor": 17.71, "estado": "normal", "unidad": "g/dL", "referencia": "12-16 g/dL"}, "trigliceridos": {"valor": 246.13, "estado": "alto", "unidad": "mg/dL", "referencia": "<150 mg/dL"}, "colesterol_total": {"valor": 158.69, "estado": "normal", "unidad": "mg/dL", "referencia": "<200 mg/dL"}}	Leve elevación en algunos valores. Se recomienda dieta balanceada y control en 3 meses.	Ver rangos de referencia en cada parámetro	validado	\N	\N	f	f	2026-02-13 11:15:00.654443	2026-02-04 22:26:23.266181
20	3c60cf58-b85f-4e6a-a452-479e768450c5	247	pdf	/uploads/resultados/17/	\N	analisis_4_20260216.pdf	458092	216e13a17788a3085fd3da90616701ae	\N	{"hdl": {"valor": 69.75, "estado": "normal", "unidad": "mg/dL", "referencia": ">40 mg/dL"}, "ldl": {"valor": 115.84, "estado": "normal", "unidad": "mg/dL", "referencia": "<130 mg/dL"}, "glucosa": {"valor": 106.59, "estado": "normal", "unidad": "mg/dL", "referencia": "70-110 mg/dL"}, "plaquetas": {"valor": 197195, "estado": "normal", "unidad": "cel/µL", "referencia": "150000-400000 cel/µL"}, "creatinina": {"valor": 1.05, "estado": "alto", "unidad": "mg/dL", "referencia": "0.6-1.2 mg/dL"}, "leucocitos": {"valor": 9881, "estado": "normal", "unidad": "cel/µL", "referencia": "4000-11000 cel/µL"}, "hemoglobina": {"valor": 11.11, "estado": "normal", "unidad": "g/dL", "referencia": "12-16 g/dL"}, "trigliceridos": {"valor": 163.76, "estado": "normal", "unidad": "mg/dL", "referencia": "<150 mg/dL"}, "colesterol_total": {"valor": 168.13, "estado": "normal", "unidad": "mg/dL", "referencia": "<200 mg/dL"}}	Leve elevación en algunos valores. Se recomienda dieta balanceada y control en 3 meses.	Ver rangos de referencia en cada parámetro	validado	\N	\N	f	f	2026-02-11 08:32:41.615518	2026-02-16 05:27:14.678257
21	85e71041-d8f3-4178-9607-e12f0d77bf19	248	pdf	/uploads/resultados/17/	\N	analisis_5_20260216.pdf	312136	0aad93af2a40ed04ac9562f98ca2310b	\N	{"hdl": {"valor": 56.95, "estado": "normal", "unidad": "mg/dL", "referencia": ">40 mg/dL"}, "ldl": {"valor": 136.55, "estado": "normal", "unidad": "mg/dL", "referencia": "<130 mg/dL"}, "glucosa": {"valor": 76.28, "estado": "alto", "unidad": "mg/dL", "referencia": "70-110 mg/dL"}, "plaquetas": {"valor": 227587, "estado": "normal", "unidad": "cel/µL", "referencia": "150000-400000 cel/µL"}, "creatinina": {"valor": 1.07, "estado": "normal", "unidad": "mg/dL", "referencia": "0.6-1.2 mg/dL"}, "leucocitos": {"valor": 8754, "estado": "normal", "unidad": "cel/µL", "referencia": "4000-11000 cel/µL"}, "hemoglobina": {"valor": 16.30, "estado": "bajo", "unidad": "g/dL", "referencia": "12-16 g/dL"}, "trigliceridos": {"valor": 113.54, "estado": "normal", "unidad": "mg/dL", "referencia": "<150 mg/dL"}, "colesterol_total": {"valor": 232.52, "estado": "normal", "unidad": "mg/dL", "referencia": "<200 mg/dL"}}	Todos los valores dentro de parámetros normales. Seguimiento rutinario.	Ver rangos de referencia en cada parámetro	validado	\N	\N	f	f	2026-02-12 11:42:59.535389	2026-02-02 09:54:27.918614
22	729bf0fe-b8c0-4fa3-bbcb-cb7a5c27d5a6	249	pdf	/uploads/resultados/18/	\N	analisis_6_20260216.pdf	80038	45a4eb21dcb281d1fa1672e4df00a612	\N	{"hdl": {"valor": 42.51, "estado": "normal", "unidad": "mg/dL", "referencia": ">40 mg/dL"}, "ldl": {"valor": 134.38, "estado": "normal", "unidad": "mg/dL", "referencia": "<130 mg/dL"}, "glucosa": {"valor": 112.11, "estado": "alto", "unidad": "mg/dL", "referencia": "70-110 mg/dL"}, "plaquetas": {"valor": 369403, "estado": "normal", "unidad": "cel/µL", "referencia": "150000-400000 cel/µL"}, "creatinina": {"valor": 1.35, "estado": "normal", "unidad": "mg/dL", "referencia": "0.6-1.2 mg/dL"}, "leucocitos": {"valor": 4669, "estado": "alto", "unidad": "cel/µL", "referencia": "4000-11000 cel/µL"}, "hemoglobina": {"valor": 17.74, "estado": "bajo", "unidad": "g/dL", "referencia": "12-16 g/dL"}, "trigliceridos": {"valor": 178.48, "estado": "alto", "unidad": "mg/dL", "referencia": "<150 mg/dL"}, "colesterol_total": {"valor": 177.00, "estado": "normal", "unidad": "mg/dL", "referencia": "<200 mg/dL"}}	Valores ligeramente alterados. Consultar con médico para evaluación.	Ver rangos de referencia en cada parámetro	validado	\N	\N	f	f	2026-02-09 09:51:29.009823	2026-02-12 04:33:45.194951
23	47c78d41-80c9-4dbc-ad4b-f1c1b598beea	250	pdf	/uploads/resultados/18/	\N	analisis_7_20260216.pdf	166379	c5d2e9e7367af251bb2b62d2488c33c6	\N	{"hdl": {"valor": 60.39, "estado": "normal", "unidad": "mg/dL", "referencia": ">40 mg/dL"}, "ldl": {"valor": 109.29, "estado": "alto", "unidad": "mg/dL", "referencia": "<130 mg/dL"}, "glucosa": {"valor": 124.26, "estado": "normal", "unidad": "mg/dL", "referencia": "70-110 mg/dL"}, "plaquetas": {"valor": 236301, "estado": "normal", "unidad": "cel/µL", "referencia": "150000-400000 cel/µL"}, "creatinina": {"valor": 0.89, "estado": "normal", "unidad": "mg/dL", "referencia": "0.6-1.2 mg/dL"}, "leucocitos": {"valor": 5013, "estado": "alto", "unidad": "cel/µL", "referencia": "4000-11000 cel/µL"}, "hemoglobina": {"valor": 12.23, "estado": "normal", "unidad": "g/dL", "referencia": "12-16 g/dL"}, "trigliceridos": {"valor": 243.80, "estado": "alto", "unidad": "mg/dL", "referencia": "<150 mg/dL"}, "colesterol_total": {"valor": 234.53, "estado": "normal", "unidad": "mg/dL", "referencia": "<200 mg/dL"}}	Todos los valores dentro de parámetros normales. Seguimiento rutinario.	Ver rangos de referencia en cada parámetro	validado	\N	\N	f	f	2026-02-14 15:29:50.331762	2026-02-14 15:54:47.16038
24	64aeac46-e6a4-4276-b8b8-93e81dea24f4	251	pdf	/uploads/resultados/19/	\N	analisis_8_20260216.pdf	52336	8842611c539e5373285d4b1bce824c52	\N	{"hdl": {"valor": 41.42, "estado": "normal", "unidad": "mg/dL", "referencia": ">40 mg/dL"}, "ldl": {"valor": 81.10, "estado": "alto", "unidad": "mg/dL", "referencia": "<130 mg/dL"}, "glucosa": {"valor": 87.38, "estado": "normal", "unidad": "mg/dL", "referencia": "70-110 mg/dL"}, "plaquetas": {"valor": 216824, "estado": "normal", "unidad": "cel/µL", "referencia": "150000-400000 cel/µL"}, "creatinina": {"valor": 1.18, "estado": "normal", "unidad": "mg/dL", "referencia": "0.6-1.2 mg/dL"}, "leucocitos": {"valor": 6016, "estado": "bajo", "unidad": "cel/µL", "referencia": "4000-11000 cel/µL"}, "hemoglobina": {"valor": 15.93, "estado": "normal", "unidad": "g/dL", "referencia": "12-16 g/dL"}, "trigliceridos": {"valor": 64.75, "estado": "alto", "unidad": "mg/dL", "referencia": "<150 mg/dL"}, "colesterol_total": {"valor": 157.94, "estado": "normal", "unidad": "mg/dL", "referencia": "<200 mg/dL"}}	Todos los valores dentro de parámetros normales. Seguimiento rutinario.	Ver rangos de referencia en cada parámetro	validado	\N	\N	f	f	2026-02-07 13:24:34.72872	2026-02-14 01:39:55.532225
25	0025217c-a0ca-4411-8ebe-84cdc0844f16	252	pdf	/uploads/resultados/19/	\N	analisis_9_20260216.pdf	75019	4c58928020a485775f3b7303bd313cd8	\N	{"hdl": {"valor": 37.97, "estado": "normal", "unidad": "mg/dL", "referencia": ">40 mg/dL"}, "ldl": {"valor": 142.10, "estado": "alto", "unidad": "mg/dL", "referencia": "<130 mg/dL"}, "glucosa": {"valor": 117.49, "estado": "normal", "unidad": "mg/dL", "referencia": "70-110 mg/dL"}, "plaquetas": {"valor": 268321, "estado": "normal", "unidad": "cel/µL", "referencia": "150000-400000 cel/µL"}, "creatinina": {"valor": 1.29, "estado": "normal", "unidad": "mg/dL", "referencia": "0.6-1.2 mg/dL"}, "leucocitos": {"valor": 8720, "estado": "normal", "unidad": "cel/µL", "referencia": "4000-11000 cel/µL"}, "hemoglobina": {"valor": 12.83, "estado": "normal", "unidad": "g/dL", "referencia": "12-16 g/dL"}, "trigliceridos": {"valor": 133.21, "estado": "alto", "unidad": "mg/dL", "referencia": "<150 mg/dL"}, "colesterol_total": {"valor": 180.72, "estado": "normal", "unidad": "mg/dL", "referencia": "<200 mg/dL"}}	Leve elevación en algunos valores. Se recomienda dieta balanceada y control en 3 meses.	Ver rangos de referencia en cada parámetro	validado	\N	\N	f	f	2026-02-14 13:46:05.426662	2026-02-03 17:38:19.55593
26	cb0e868e-d312-4bb6-994a-3848e0235b29	253	pdf	/uploads/resultados/20/	\N	analisis_10_20260216.pdf	346733	48ad1aea6b5e0c88a03d2ce3b3b64b83	\N	{"hdl": {"valor": 33.94, "estado": "normal", "unidad": "mg/dL", "referencia": ">40 mg/dL"}, "ldl": {"valor": 133.19, "estado": "normal", "unidad": "mg/dL", "referencia": "<130 mg/dL"}, "glucosa": {"valor": 100.23, "estado": "alto", "unidad": "mg/dL", "referencia": "70-110 mg/dL"}, "plaquetas": {"valor": 268136, "estado": "normal", "unidad": "cel/µL", "referencia": "150000-400000 cel/µL"}, "creatinina": {"valor": 1.25, "estado": "alto", "unidad": "mg/dL", "referencia": "0.6-1.2 mg/dL"}, "leucocitos": {"valor": 9019, "estado": "bajo", "unidad": "cel/µL", "referencia": "4000-11000 cel/µL"}, "hemoglobina": {"valor": 11.67, "estado": "normal", "unidad": "g/dL", "referencia": "12-16 g/dL"}, "trigliceridos": {"valor": 257.54, "estado": "alto", "unidad": "mg/dL", "referencia": "<150 mg/dL"}, "colesterol_total": {"valor": 249.19, "estado": "alto", "unidad": "mg/dL", "referencia": "<200 mg/dL"}}	Leve elevación en algunos valores. Se recomienda dieta balanceada y control en 3 meses.	Ver rangos de referencia en cada parámetro	validado	\N	\N	f	f	2026-02-07 02:47:48.170194	2026-02-09 05:30:19.225634
27	918cc066-a2e1-4b38-b77e-90716717bbcc	254	pdf	/uploads/resultados/20/	\N	analisis_11_20260216.pdf	538630	8909f619864f13bcbaf3a8b8e10afb9c	\N	{"hdl": {"valor": 53.20, "estado": "bajo", "unidad": "mg/dL", "referencia": ">40 mg/dL"}, "ldl": {"valor": 94.37, "estado": "alto", "unidad": "mg/dL", "referencia": "<130 mg/dL"}, "glucosa": {"valor": 102.25, "estado": "normal", "unidad": "mg/dL", "referencia": "70-110 mg/dL"}, "plaquetas": {"valor": 288779, "estado": "normal", "unidad": "cel/µL", "referencia": "150000-400000 cel/µL"}, "creatinina": {"valor": 1.14, "estado": "normal", "unidad": "mg/dL", "referencia": "0.6-1.2 mg/dL"}, "leucocitos": {"valor": 4893, "estado": "normal", "unidad": "cel/µL", "referencia": "4000-11000 cel/µL"}, "hemoglobina": {"valor": 15.51, "estado": "normal", "unidad": "g/dL", "referencia": "12-16 g/dL"}, "trigliceridos": {"valor": 168.28, "estado": "alto", "unidad": "mg/dL", "referencia": "<150 mg/dL"}, "colesterol_total": {"valor": 230.15, "estado": "normal", "unidad": "mg/dL", "referencia": "<200 mg/dL"}}	Valores ligeramente alterados. Consultar con médico para evaluación.	Ver rangos de referencia en cada parámetro	validado	\N	\N	f	f	2026-02-06 01:13:27.496056	2026-02-14 10:37:55.014477
28	755a0cd2-15fa-449f-b603-968b22ff1dca	255	pdf	/uploads/resultados/20/	\N	analisis_12_20260216.pdf	188015	d31f4e41495a5a3f5e584b4e8cb72d19	\N	{"hdl": {"valor": 35.29, "estado": "normal", "unidad": "mg/dL", "referencia": ">40 mg/dL"}, "ldl": {"valor": 81.10, "estado": "normal", "unidad": "mg/dL", "referencia": "<130 mg/dL"}, "glucosa": {"valor": 126.96, "estado": "normal", "unidad": "mg/dL", "referencia": "70-110 mg/dL"}, "plaquetas": {"valor": 421191, "estado": "normal", "unidad": "cel/µL", "referencia": "150000-400000 cel/µL"}, "creatinina": {"valor": 1.07, "estado": "alto", "unidad": "mg/dL", "referencia": "0.6-1.2 mg/dL"}, "leucocitos": {"valor": 12645, "estado": "bajo", "unidad": "cel/µL", "referencia": "4000-11000 cel/µL"}, "hemoglobina": {"valor": 15.96, "estado": "normal", "unidad": "g/dL", "referencia": "12-16 g/dL"}, "trigliceridos": {"valor": 117.49, "estado": "normal", "unidad": "mg/dL", "referencia": "<150 mg/dL"}, "colesterol_total": {"valor": 228.91, "estado": "normal", "unidad": "mg/dL", "referencia": "<200 mg/dL"}}	Valores ligeramente alterados. Consultar con médico para evaluación.	Ver rangos de referencia en cada parámetro	validado	\N	\N	f	f	2026-02-05 18:03:24.494175	2026-02-12 19:10:31.975331
1	54534224-7c12-4b34-8cd5-09b99cafe53a	1	pdf	/uploads/resultados/hemograma_juan_perez.pdf	\N	hemograma_juan_perez.pdf	125000	\N	\N	{"hdl": {"valor": 67.88, "estado": "normal", "unidad": "mg/dL", "referencia": ">40 mg/dL"}, "ldl": {"valor": 103.41, "estado": "normal", "unidad": "mg/dL", "referencia": "<130 mg/dL"}, "glucosa": {"valor": 100.34, "estado": "alto", "unidad": "mg/dL", "referencia": "70-110 mg/dL"}, "plaquetas": {"valor": 391892, "estado": "normal", "unidad": "cel/µL", "referencia": "150000-400000 cel/µL"}, "creatinina": {"valor": 0.68, "estado": "alto", "unidad": "mg/dL", "referencia": "0.6-1.2 mg/dL"}, "leucocitos": {"valor": 5391, "estado": "normal", "unidad": "cel/µL", "referencia": "4000-11000 cel/µL"}, "hemoglobina": {"valor": 11.98, "estado": "normal", "unidad": "g/dL", "referencia": "12-16 g/dL"}, "trigliceridos": {"valor": 50.02, "estado": "normal", "unidad": "mg/dL", "referencia": "<150 mg/dL"}, "colesterol_total": {"valor": 197.06, "estado": "alto", "unidad": "mg/dL", "referencia": "<200 mg/dL"}}	Valores ligeramente alterados. Se recomienda consultar con médico tratante para evaluación detallada y posible tratamiento.	Ver rangos de referencia específicos en cada parámetro del análisis.	validado	\N	\N	f	f	2026-02-16 02:45:09.252672	2026-02-16 02:45:09.255806
2	023afd36-5e49-405b-89ac-65cd658f56e7	2	pdf	/uploads/resultados/glicemia_juan_perez.pdf	\N	glicemia_juan_perez.pdf	125000	\N	\N	{"hdl": {"valor": 67.52, "estado": "normal", "unidad": "mg/dL", "referencia": ">40 mg/dL"}, "ldl": {"valor": 88.84, "estado": "normal", "unidad": "mg/dL", "referencia": "<130 mg/dL"}, "glucosa": {"valor": 91.93, "estado": "normal", "unidad": "mg/dL", "referencia": "70-110 mg/dL"}, "plaquetas": {"valor": 344426, "estado": "normal", "unidad": "cel/µL", "referencia": "150000-400000 cel/µL"}, "creatinina": {"valor": 0.75, "estado": "alto", "unidad": "mg/dL", "referencia": "0.6-1.2 mg/dL"}, "leucocitos": {"valor": 4431, "estado": "bajo", "unidad": "cel/µL", "referencia": "4000-11000 cel/µL"}, "hemoglobina": {"valor": 14.26, "estado": "normal", "unidad": "g/dL", "referencia": "12-16 g/dL"}, "trigliceridos": {"valor": 205.02, "estado": "alto", "unidad": "mg/dL", "referencia": "<150 mg/dL"}, "colesterol_total": {"valor": 144.67, "estado": "alto", "unidad": "mg/dL", "referencia": "<200 mg/dL"}}	Valores ligeramente alterados. Se recomienda consultar con médico tratante para evaluación detallada y posible tratamiento.	Ver rangos de referencia específicos en cada parámetro del análisis.	validado	\N	\N	f	f	2026-02-16 02:45:09.267769	2026-02-16 02:45:09.268954
3	3e919366-79cf-4e8a-be3b-2ee3dc240b29	3	pdf	/uploads/resultados/hemograma_ana_rodriguez.pdf	\N	hemograma_ana_rodriguez.pdf	125000	\N	\N	{"hdl": {"valor": 37.05, "estado": "normal", "unidad": "mg/dL", "referencia": ">40 mg/dL"}, "ldl": {"valor": 146.81, "estado": "alto", "unidad": "mg/dL", "referencia": "<130 mg/dL"}, "glucosa": {"valor": 98.45, "estado": "normal", "unidad": "mg/dL", "referencia": "70-110 mg/dL"}, "plaquetas": {"valor": 390588, "estado": "normal", "unidad": "cel/µL", "referencia": "150000-400000 cel/µL"}, "creatinina": {"valor": 0.95, "estado": "alto", "unidad": "mg/dL", "referencia": "0.6-1.2 mg/dL"}, "leucocitos": {"valor": 3517, "estado": "normal", "unidad": "cel/µL", "referencia": "4000-11000 cel/µL"}, "hemoglobina": {"valor": 11.22, "estado": "normal", "unidad": "g/dL", "referencia": "12-16 g/dL"}, "trigliceridos": {"valor": 72.03, "estado": "normal", "unidad": "mg/dL", "referencia": "<150 mg/dL"}, "colesterol_total": {"valor": 255.34, "estado": "normal", "unidad": "mg/dL", "referencia": "<200 mg/dL"}}	Valores ligeramente alterados. Se recomienda consultar con médico tratante para evaluación detallada y posible tratamiento.	Ver rangos de referencia específicos en cada parámetro del análisis.	validado	\N	\N	f	f	2026-02-16 02:45:09.273654	2026-02-16 02:45:09.274311
4	fb528b41-cb20-4b9d-9a53-bf134e33f91f	4	pdf	/uploads/resultados/glicemia_ana_rodriguez.pdf	\N	glicemia_ana_rodriguez.pdf	125000	\N	\N	{"hdl": {"valor": 54.41, "estado": "normal", "unidad": "mg/dL", "referencia": ">40 mg/dL"}, "ldl": {"valor": 88.41, "estado": "normal", "unidad": "mg/dL", "referencia": "<130 mg/dL"}, "glucosa": {"valor": 69.71, "estado": "normal", "unidad": "mg/dL", "referencia": "70-110 mg/dL"}, "plaquetas": {"valor": 360140, "estado": "bajo", "unidad": "cel/µL", "referencia": "150000-400000 cel/µL"}, "creatinina": {"valor": 1.37, "estado": "alto", "unidad": "mg/dL", "referencia": "0.6-1.2 mg/dL"}, "leucocitos": {"valor": 7776, "estado": "bajo", "unidad": "cel/µL", "referencia": "4000-11000 cel/µL"}, "hemoglobina": {"valor": 11.46, "estado": "normal", "unidad": "g/dL", "referencia": "12-16 g/dL"}, "trigliceridos": {"valor": 219.32, "estado": "alto", "unidad": "mg/dL", "referencia": "<150 mg/dL"}, "colesterol_total": {"valor": 226.28, "estado": "alto", "unidad": "mg/dL", "referencia": "<200 mg/dL"}}	Valores ligeramente alterados. Se recomienda consultar con médico tratante para evaluación detallada y posible tratamiento.	Ver rangos de referencia específicos en cada parámetro del análisis.	validado	\N	\N	f	f	2026-02-16 02:45:09.278648	2026-02-16 02:45:09.279368
5	a9053c4c-8a6a-48c3-ae17-163350feac00	5	pdf	/uploads/resultados/perfil_lipidico_ana_rodriguez.pdf	\N	perfil_lipidico_ana_rodriguez.pdf	125000	\N	\N	{"hdl": {"valor": 47.95, "estado": "normal", "unidad": "mg/dL", "referencia": ">40 mg/dL"}, "ldl": {"valor": 111.34, "estado": "normal", "unidad": "mg/dL", "referencia": "<130 mg/dL"}, "glucosa": {"valor": 132.44, "estado": "normal", "unidad": "mg/dL", "referencia": "70-110 mg/dL"}, "plaquetas": {"valor": 388267, "estado": "normal", "unidad": "cel/µL", "referencia": "150000-400000 cel/µL"}, "creatinina": {"valor": 1.42, "estado": "bajo", "unidad": "mg/dL", "referencia": "0.6-1.2 mg/dL"}, "leucocitos": {"valor": 6723, "estado": "normal", "unidad": "cel/µL", "referencia": "4000-11000 cel/µL"}, "hemoglobina": {"valor": 14.50, "estado": "normal", "unidad": "g/dL", "referencia": "12-16 g/dL"}, "trigliceridos": {"valor": 54.32, "estado": "alto", "unidad": "mg/dL", "referencia": "<150 mg/dL"}, "colesterol_total": {"valor": 204.80, "estado": "normal", "unidad": "mg/dL", "referencia": "<200 mg/dL"}}	Leve elevación en algunos valores. Se recomienda dieta balanceada, ejercicio regular y control en 3 meses.	Ver rangos de referencia específicos en cada parámetro del análisis.	validado	\N	\N	f	f	2026-02-16 02:45:09.283665	2026-02-16 02:45:09.284717
6	3716642d-22b0-4beb-805f-a9ac135ffe69	6	pdf	/uploads/resultados/hemograma_ana_ord4.pdf	\N	hemograma_ana_ord4.pdf	125000	\N	\N	{"hdl": {"valor": 43.62, "estado": "bajo", "unidad": "mg/dL", "referencia": ">40 mg/dL"}, "ldl": {"valor": 60.26, "estado": "normal", "unidad": "mg/dL", "referencia": "<130 mg/dL"}, "glucosa": {"valor": 122.25, "estado": "normal", "unidad": "mg/dL", "referencia": "70-110 mg/dL"}, "plaquetas": {"valor": 328268, "estado": "bajo", "unidad": "cel/µL", "referencia": "150000-400000 cel/µL"}, "creatinina": {"valor": 1.32, "estado": "alto", "unidad": "mg/dL", "referencia": "0.6-1.2 mg/dL"}, "leucocitos": {"valor": 9215, "estado": "alto", "unidad": "cel/µL", "referencia": "4000-11000 cel/µL"}, "hemoglobina": {"valor": 15.65, "estado": "bajo", "unidad": "g/dL", "referencia": "12-16 g/dL"}, "trigliceridos": {"valor": 166.96, "estado": "alto", "unidad": "mg/dL", "referencia": "<150 mg/dL"}, "colesterol_total": {"valor": 179.38, "estado": "normal", "unidad": "mg/dL", "referencia": "<200 mg/dL"}}	Leve elevación en algunos valores. Se recomienda dieta balanceada, ejercicio regular y control en 3 meses.	Ver rangos de referencia específicos en cada parámetro del análisis.	validado	\N	\N	f	f	2026-02-16 02:45:09.291822	2026-02-16 02:45:09.292704
7	bff36603-b592-4915-8708-567f7a335113	7	pdf	/uploads/resultados/glicemia_ana_ord4.pdf	\N	glicemia_ana_ord4.pdf	125000	\N	\N	{"hdl": {"valor": 57.50, "estado": "bajo", "unidad": "mg/dL", "referencia": ">40 mg/dL"}, "ldl": {"valor": 131.74, "estado": "normal", "unidad": "mg/dL", "referencia": "<130 mg/dL"}, "glucosa": {"valor": 94.30, "estado": "normal", "unidad": "mg/dL", "referencia": "70-110 mg/dL"}, "plaquetas": {"valor": 270928, "estado": "normal", "unidad": "cel/µL", "referencia": "150000-400000 cel/µL"}, "creatinina": {"valor": 1.36, "estado": "normal", "unidad": "mg/dL", "referencia": "0.6-1.2 mg/dL"}, "leucocitos": {"valor": 9449, "estado": "normal", "unidad": "cel/µL", "referencia": "4000-11000 cel/µL"}, "hemoglobina": {"valor": 14.01, "estado": "normal", "unidad": "g/dL", "referencia": "12-16 g/dL"}, "trigliceridos": {"valor": 206.86, "estado": "normal", "unidad": "mg/dL", "referencia": "<150 mg/dL"}, "colesterol_total": {"valor": 210.81, "estado": "normal", "unidad": "mg/dL", "referencia": "<200 mg/dL"}}	Todos los valores dentro de parámetros normales. Se recomienda seguimiento rutinario y mantener estilo de vida saludable.	Ver rangos de referencia específicos en cada parámetro del análisis.	validado	\N	\N	f	f	2026-02-16 02:45:09.297118	2026-02-16 02:45:09.297774
8	91274062-ff4c-4cbf-a56e-f3c8178dfb59	8	pdf	/uploads/resultados/perfil_lipidico_ana_ord4.pdf	\N	perfil_lipidico_ana_ord4.pdf	125000	\N	\N	{"hdl": {"valor": 53.39, "estado": "normal", "unidad": "mg/dL", "referencia": ">40 mg/dL"}, "ldl": {"valor": 115.87, "estado": "normal", "unidad": "mg/dL", "referencia": "<130 mg/dL"}, "glucosa": {"valor": 77.59, "estado": "normal", "unidad": "mg/dL", "referencia": "70-110 mg/dL"}, "plaquetas": {"valor": 257930, "estado": "normal", "unidad": "cel/µL", "referencia": "150000-400000 cel/µL"}, "creatinina": {"valor": 1.35, "estado": "normal", "unidad": "mg/dL", "referencia": "0.6-1.2 mg/dL"}, "leucocitos": {"valor": 6036, "estado": "alto", "unidad": "cel/µL", "referencia": "4000-11000 cel/µL"}, "hemoglobina": {"valor": 14.76, "estado": "normal", "unidad": "g/dL", "referencia": "12-16 g/dL"}, "trigliceridos": {"valor": 289.23, "estado": "normal", "unidad": "mg/dL", "referencia": "<150 mg/dL"}, "colesterol_total": {"valor": 253.09, "estado": "normal", "unidad": "mg/dL", "referencia": "<200 mg/dL"}}	Todos los valores dentro de parámetros normales. Se recomienda seguimiento rutinario y mantener estilo de vida saludable.	Ver rangos de referencia específicos en cada parámetro del análisis.	validado	\N	\N	f	f	2026-02-16 02:45:09.301173	2026-02-16 02:45:09.301788
9	21912768-78dd-40ce-bae3-93db45e04a03	10	pdf	/uploads/resultados/rayosx_torax_cristopher.pdf	\N	rayosx_torax_cristopher.pdf	125000	\N	\N	{"hdl": {"valor": 58.12, "estado": "normal", "unidad": "mg/dL", "referencia": ">40 mg/dL"}, "ldl": {"valor": 156.10, "estado": "normal", "unidad": "mg/dL", "referencia": "<130 mg/dL"}, "glucosa": {"valor": 86.82, "estado": "alto", "unidad": "mg/dL", "referencia": "70-110 mg/dL"}, "plaquetas": {"valor": 138094, "estado": "normal", "unidad": "cel/µL", "referencia": "150000-400000 cel/µL"}, "creatinina": {"valor": 0.85, "estado": "normal", "unidad": "mg/dL", "referencia": "0.6-1.2 mg/dL"}, "leucocitos": {"valor": 10839, "estado": "normal", "unidad": "cel/µL", "referencia": "4000-11000 cel/µL"}, "hemoglobina": {"valor": 15.74, "estado": "normal", "unidad": "g/dL", "referencia": "12-16 g/dL"}, "trigliceridos": {"valor": 206.76, "estado": "normal", "unidad": "mg/dL", "referencia": "<150 mg/dL"}, "colesterol_total": {"valor": 173.17, "estado": "alto", "unidad": "mg/dL", "referencia": "<200 mg/dL"}}	Valores ligeramente alterados. Se recomienda consultar con médico tratante para evaluación detallada y posible tratamiento.	Ver rangos de referencia específicos en cada parámetro del análisis.	validado	\N	\N	f	f	2026-02-16 02:45:09.305157	2026-02-16 02:45:09.305762
10	c3afdc96-86ef-4c6b-9965-66adfedf3dbf	11	pdf	/uploads/resultados/hemograma_cristopher.pdf	\N	hemograma_cristopher.pdf	125000	\N	\N	{"hdl": {"valor": 35.97, "estado": "normal", "unidad": "mg/dL", "referencia": ">40 mg/dL"}, "ldl": {"valor": 140.76, "estado": "normal", "unidad": "mg/dL", "referencia": "<130 mg/dL"}, "glucosa": {"valor": 83.48, "estado": "alto", "unidad": "mg/dL", "referencia": "70-110 mg/dL"}, "plaquetas": {"valor": 230344, "estado": "normal", "unidad": "cel/µL", "referencia": "150000-400000 cel/µL"}, "creatinina": {"valor": 0.96, "estado": "normal", "unidad": "mg/dL", "referencia": "0.6-1.2 mg/dL"}, "leucocitos": {"valor": 11935, "estado": "normal", "unidad": "cel/µL", "referencia": "4000-11000 cel/µL"}, "hemoglobina": {"valor": 11.84, "estado": "normal", "unidad": "g/dL", "referencia": "12-16 g/dL"}, "trigliceridos": {"valor": 286.47, "estado": "alto", "unidad": "mg/dL", "referencia": "<150 mg/dL"}, "colesterol_total": {"valor": 154.46, "estado": "normal", "unidad": "mg/dL", "referencia": "<200 mg/dL"}}	Leve elevación en algunos valores. Se recomienda dieta balanceada, ejercicio regular y control en 3 meses.	Ver rangos de referencia específicos en cada parámetro del análisis.	validado	\N	\N	f	f	2026-02-16 02:45:09.309124	2026-02-16 02:45:09.309732
11	3e516013-daab-4b66-a6ee-7422204ff0aa	32	pdf	/uploads/resultados/acido_urico_cristopher.pdf	\N	acido_urico_cristopher.pdf	125000	\N	\N	{"hdl": {"valor": 44.01, "estado": "normal", "unidad": "mg/dL", "referencia": ">40 mg/dL"}, "ldl": {"valor": 151.04, "estado": "normal", "unidad": "mg/dL", "referencia": "<130 mg/dL"}, "glucosa": {"valor": 122.17, "estado": "alto", "unidad": "mg/dL", "referencia": "70-110 mg/dL"}, "plaquetas": {"valor": 189813, "estado": "normal", "unidad": "cel/µL", "referencia": "150000-400000 cel/µL"}, "creatinina": {"valor": 1.44, "estado": "bajo", "unidad": "mg/dL", "referencia": "0.6-1.2 mg/dL"}, "leucocitos": {"valor": 9457, "estado": "normal", "unidad": "cel/µL", "referencia": "4000-11000 cel/µL"}, "hemoglobina": {"valor": 11.14, "estado": "bajo", "unidad": "g/dL", "referencia": "12-16 g/dL"}, "trigliceridos": {"valor": 187.52, "estado": "normal", "unidad": "mg/dL", "referencia": "<150 mg/dL"}, "colesterol_total": {"valor": 232.57, "estado": "normal", "unidad": "mg/dL", "referencia": "<200 mg/dL"}}	Valores ligeramente alterados. Se recomienda consultar con médico tratante para evaluación detallada y posible tratamiento.	Ver rangos de referencia específicos en cada parámetro del análisis.	validado	\N	\N	f	f	2026-02-16 02:45:09.313556	2026-02-16 02:45:09.314301
12	c0a30c79-95de-4263-a587-a804219c98f7	33	pdf	/uploads/resultados/creatinina_cristopher.pdf	\N	creatinina_cristopher.pdf	125000	\N	\N	{"hdl": {"valor": 47.33, "estado": "bajo", "unidad": "mg/dL", "referencia": ">40 mg/dL"}, "ldl": {"valor": 68.51, "estado": "alto", "unidad": "mg/dL", "referencia": "<130 mg/dL"}, "glucosa": {"valor": 87.42, "estado": "bajo", "unidad": "mg/dL", "referencia": "70-110 mg/dL"}, "plaquetas": {"valor": 275236, "estado": "normal", "unidad": "cel/µL", "referencia": "150000-400000 cel/µL"}, "creatinina": {"valor": 1.28, "estado": "normal", "unidad": "mg/dL", "referencia": "0.6-1.2 mg/dL"}, "leucocitos": {"valor": 7985, "estado": "bajo", "unidad": "cel/µL", "referencia": "4000-11000 cel/µL"}, "hemoglobina": {"valor": 11.00, "estado": "normal", "unidad": "g/dL", "referencia": "12-16 g/dL"}, "trigliceridos": {"valor": 53.54, "estado": "normal", "unidad": "mg/dL", "referencia": "<150 mg/dL"}, "colesterol_total": {"valor": 174.27, "estado": "normal", "unidad": "mg/dL", "referencia": "<200 mg/dL"}}	Leve elevación en algunos valores. Se recomienda dieta balanceada, ejercicio regular y control en 3 meses.	Ver rangos de referencia específicos en cada parámetro del análisis.	validado	\N	\N	f	f	2026-02-16 02:45:09.320886	2026-02-16 02:45:09.321729
13	2c1bb05a-1c47-4ebe-aeaf-70f6d3406017	34	pdf	/uploads/resultados/electrocardiograma_cristopher.pdf	\N	electrocardiograma_cristopher.pdf	125000	\N	\N	{"hdl": {"valor": 50.00, "estado": "normal", "unidad": "mg/dL", "referencia": ">40 mg/dL"}, "ldl": {"valor": 67.79, "estado": "normal", "unidad": "mg/dL", "referencia": "<130 mg/dL"}, "glucosa": {"valor": 65.35, "estado": "alto", "unidad": "mg/dL", "referencia": "70-110 mg/dL"}, "plaquetas": {"valor": 180165, "estado": "alto", "unidad": "cel/µL", "referencia": "150000-400000 cel/µL"}, "creatinina": {"valor": 1.19, "estado": "bajo", "unidad": "mg/dL", "referencia": "0.6-1.2 mg/dL"}, "leucocitos": {"valor": 4658, "estado": "normal", "unidad": "cel/µL", "referencia": "4000-11000 cel/µL"}, "hemoglobina": {"valor": 12.77, "estado": "normal", "unidad": "g/dL", "referencia": "12-16 g/dL"}, "trigliceridos": {"valor": 140.05, "estado": "alto", "unidad": "mg/dL", "referencia": "<150 mg/dL"}, "colesterol_total": {"valor": 173.83, "estado": "normal", "unidad": "mg/dL", "referencia": "<200 mg/dL"}}	Todos los valores dentro de parámetros normales. Se recomienda seguimiento rutinario y mantener estilo de vida saludable.	Ver rangos de referencia específicos en cada parámetro del análisis.	validado	\N	\N	f	f	2026-02-16 02:45:09.325328	2026-02-16 02:45:09.325972
14	ffb83ade-9d97-4b44-8e31-6c32e34f357c	35	pdf	/uploads/resultados/glicemia_cristopher.pdf	\N	glicemia_cristopher.pdf	125000	\N	\N	{"hdl": {"valor": 51.71, "estado": "bajo", "unidad": "mg/dL", "referencia": ">40 mg/dL"}, "ldl": {"valor": 78.22, "estado": "normal", "unidad": "mg/dL", "referencia": "<130 mg/dL"}, "glucosa": {"valor": 81.30, "estado": "normal", "unidad": "mg/dL", "referencia": "70-110 mg/dL"}, "plaquetas": {"valor": 343078, "estado": "bajo", "unidad": "cel/µL", "referencia": "150000-400000 cel/µL"}, "creatinina": {"valor": 1.35, "estado": "normal", "unidad": "mg/dL", "referencia": "0.6-1.2 mg/dL"}, "leucocitos": {"valor": 4951, "estado": "normal", "unidad": "cel/µL", "referencia": "4000-11000 cel/µL"}, "hemoglobina": {"valor": 16.13, "estado": "alto", "unidad": "g/dL", "referencia": "12-16 g/dL"}, "trigliceridos": {"valor": 156.41, "estado": "alto", "unidad": "mg/dL", "referencia": "<150 mg/dL"}, "colesterol_total": {"valor": 244.75, "estado": "alto", "unidad": "mg/dL", "referencia": "<200 mg/dL"}}	Valores ligeramente alterados. Se recomienda consultar con médico tratante para evaluación detallada y posible tratamiento.	Ver rangos de referencia específicos en cada parámetro del análisis.	validado	\N	\N	f	f	2026-02-16 02:45:09.329428	2026-02-16 02:45:09.330312
15	0b9f8a3d-b4f0-4155-b723-2fd76e20260d	36	pdf	/uploads/resultados/hemograma_cristopher_ord9.pdf	\N	hemograma_cristopher_ord9.pdf	125000	\N	\N	{"hdl": {"valor": 45.53, "estado": "bajo", "unidad": "mg/dL", "referencia": ">40 mg/dL"}, "ldl": {"valor": 86.44, "estado": "normal", "unidad": "mg/dL", "referencia": "<130 mg/dL"}, "glucosa": {"valor": 106.36, "estado": "normal", "unidad": "mg/dL", "referencia": "70-110 mg/dL"}, "plaquetas": {"valor": 426246, "estado": "normal", "unidad": "cel/µL", "referencia": "150000-400000 cel/µL"}, "creatinina": {"valor": 0.94, "estado": "normal", "unidad": "mg/dL", "referencia": "0.6-1.2 mg/dL"}, "leucocitos": {"valor": 10911, "estado": "normal", "unidad": "cel/µL", "referencia": "4000-11000 cel/µL"}, "hemoglobina": {"valor": 15.12, "estado": "bajo", "unidad": "g/dL", "referencia": "12-16 g/dL"}, "trigliceridos": {"valor": 260.12, "estado": "normal", "unidad": "mg/dL", "referencia": "<150 mg/dL"}, "colesterol_total": {"valor": 171.35, "estado": "normal", "unidad": "mg/dL", "referencia": "<200 mg/dL"}}	Valores ligeramente alterados. Se recomienda consultar con médico tratante para evaluación detallada y posible tratamiento.	Ver rangos de referencia específicos en cada parámetro del análisis.	validado	\N	\N	f	f	2026-02-16 02:45:09.334479	2026-02-16 02:45:09.335108
16	795455a8-c7b0-4ee6-adb2-f345a99c72cf	37	pdf	/uploads/resultados/perfil_lipidico_cristopher.pdf	\N	perfil_lipidico_cristopher.pdf	125000	\N	\N	{"hdl": {"valor": 37.15, "estado": "normal", "unidad": "mg/dL", "referencia": ">40 mg/dL"}, "ldl": {"valor": 107.08, "estado": "normal", "unidad": "mg/dL", "referencia": "<130 mg/dL"}, "glucosa": {"valor": 131.18, "estado": "normal", "unidad": "mg/dL", "referencia": "70-110 mg/dL"}, "plaquetas": {"valor": 307365, "estado": "normal", "unidad": "cel/µL", "referencia": "150000-400000 cel/µL"}, "creatinina": {"valor": 0.90, "estado": "normal", "unidad": "mg/dL", "referencia": "0.6-1.2 mg/dL"}, "leucocitos": {"valor": 12851, "estado": "bajo", "unidad": "cel/µL", "referencia": "4000-11000 cel/µL"}, "hemoglobina": {"valor": 13.20, "estado": "normal", "unidad": "g/dL", "referencia": "12-16 g/dL"}, "trigliceridos": {"valor": 62.34, "estado": "normal", "unidad": "mg/dL", "referencia": "<150 mg/dL"}, "colesterol_total": {"valor": 212.20, "estado": "normal", "unidad": "mg/dL", "referencia": "<200 mg/dL"}}	Todos los valores dentro de parámetros normales. Se recomienda seguimiento rutinario y mantener estilo de vida saludable.	Ver rangos de referencia específicos en cada parámetro del análisis.	validado	\N	\N	f	f	2026-02-16 02:45:09.338662	2026-02-16 02:45:09.339257
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: centro_user
--

COPY public.roles (id, nombre, descripcion, permisos, created_at) FROM stdin;
1	administrador	Acceso total al sistema	{"todos": true}	2026-02-15 04:20:40.873412
2	medico_radiologo	Médico especialista en radiología	{"radiografias": true, "ver_pacientes": true, "ver_resultados": true, "editar_informes": true}	2026-02-15 04:20:40.873412
3	medico_sonografia	Médico especialista en sonografía	{"sonografias": true, "ver_pacientes": true, "ver_resultados": true, "editar_informes": true}	2026-02-15 04:20:40.873412
4	recepcionista	Personal de recepción	{"cobrar": true, "crear_ordenes": true, "crear_facturas": true, "registrar_pacientes": true}	2026-02-15 04:20:40.873412
5	laboratorista	Personal de laboratorio	{"ver_ordenes": true, "subir_resultados": true, "registrar_muestras": true}	2026-02-15 04:20:40.873412
6	cajero	Personal de caja	{"cobrar": true, "ver_facturas": true, "imprimir_facturas": true}	2026-02-15 04:20:40.873412
\.


--
-- Data for Name: sonografias; Type: TABLE DATA; Schema: public; Owner: centro_user
--

COPY public.sonografias (id, orden_detalle_id, paciente_id, tipo_estudio, region, imagenes, video_url, informe_medico, hallazgos, biometria, conclusion, medico_id, fecha_estudio, fecha_informe, estado, created_at) FROM stdin;
\.


--
-- Data for Name: sync_queue; Type: TABLE DATA; Schema: public; Owner: centro_user
--

COPY public.sync_queue (id, tabla, registro_id, accion, datos, intentos, estado, error_mensaje, created_at, processed_at) FROM stdin;
\.


--
-- Data for Name: usuarios; Type: TABLE DATA; Schema: public; Owner: centro_user
--

COPY public.usuarios (id, uuid, username, password_hash, nombre, apellido, email, rol, permisos, activo, ultimo_acceso, created_at, updated_at, rol_id, especialidad, firma_digital) FROM stdin;
2	10b35f8e-3d52-412f-bf09-abab942f7278	chris	$2b$12$oFwG.M8oIXZQFPJPmzFBheEKEn8xZmwetURNnuc5PsccF33/3DTze	thz	rod		medico	\N	t	\N	2026-02-15 08:12:20.388218	2026-02-15 08:12:20.388222	\N	\N	\N
4	18abcf65-7b14-483a-9cb5-84ef650dffa5	admin2	scrypt:32768:8:1$BoxzUMbNYfzAvETb$6634b06821fb8aab8e70ac155d41b3ac036ffd733cdcfa79bcfb9e0aed7deb0bf1642da512939b0579946228e77a37ab79af70330d8ec418213ecdf02bf0ca1a	Administrador	Mi Esperanza	admin@miesperanza.com	admin	\N	t	2026-02-17 04:57:48.464296	2026-02-17 04:13:52.782848	2026-02-17 04:57:48.464933	\N	\N	\N
1	49f956a2-b259-4bc7-a5d2-51c975c17ed1	admin	scrypt:32768:8:1$3NkPdebNSvxdruHD$8637d9e3dad0aa8b5b1274804525eae5a3e77c0e6627a73c5266d3f869d03d080d631862b25da98204eb09bd2c5b2b24961c93c0ef1255a5e5dad72fdaec958d	Administrador	Mi Esperanza	admin@miesperanza.com	admin	\N	t	2026-02-17 05:06:37.021121	2026-02-14 08:51:33.094004	2026-02-17 05:06:37.021675	1	\N	\N
\.


--
-- Data for Name: whatsapp_messages; Type: TABLE DATA; Schema: public; Owner: centro_user
--

COPY public.whatsapp_messages (id, telefono, mensaje_recibido, mensaje_enviado, fecha, procesado, enviado_por_sistema, created_at) FROM stdin;
1	+18095551234	\N	Bienvenido al sistema de WhatsApp	2026-02-17 03:21:18.883326	f	t	2026-02-17 03:21:18.883326
2	+18095551234	\N	Bienvenido al sistema de WhatsApp	2026-02-17 03:21:46.419463	f	t	2026-02-17 03:21:46.419463
3	+18095551234	\N	Bienvenido al sistema de WhatsApp	2026-02-17 03:22:06.373305	f	t	2026-02-17 03:22:06.373305
4	+18095551234	\N	Mensaje de prueba	2026-02-17 03:23:35.917468	f	t	2026-02-17 03:23:35.917468
\.


--
-- Name: auditoria_id_seq; Type: SEQUENCE SET; Schema: public; Owner: centro_user
--

SELECT pg_catalog.setval('public.auditoria_id_seq', 1, false);


--
-- Name: caja_movimientos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: centro_user
--

SELECT pg_catalog.setval('public.caja_movimientos_id_seq', 1, false);


--
-- Name: cajas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: centro_user
--

SELECT pg_catalog.setval('public.cajas_id_seq', 1, false);


--
-- Name: campanas_envios_id_seq; Type: SEQUENCE SET; Schema: public; Owner: centro_user
--

SELECT pg_catalog.setval('public.campanas_envios_id_seq', 1, false);


--
-- Name: campanas_whatsapp_id_seq; Type: SEQUENCE SET; Schema: public; Owner: centro_user
--

SELECT pg_catalog.setval('public.campanas_whatsapp_id_seq', 1, false);


--
-- Name: categorias_estudios_id_seq; Type: SEQUENCE SET; Schema: public; Owner: centro_user
--

SELECT pg_catalog.setval('public.categorias_estudios_id_seq', 9, true);


--
-- Name: categorias_id_seq; Type: SEQUENCE SET; Schema: public; Owner: centro_user
--

SELECT pg_catalog.setval('public.categorias_id_seq', 5, true);


--
-- Name: configuracion_id_seq; Type: SEQUENCE SET; Schema: public; Owner: centro_user
--

SELECT pg_catalog.setval('public.configuracion_id_seq', 9, true);


--
-- Name: estudios_id_seq; Type: SEQUENCE SET; Schema: public; Owner: centro_user
--

SELECT pg_catalog.setval('public.estudios_id_seq', 95, true);


--
-- Name: factura_detalles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: centro_user
--

SELECT pg_catalog.setval('public.factura_detalles_id_seq', 33, true);


--
-- Name: facturas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: centro_user
--

SELECT pg_catalog.setval('public.facturas_id_seq', 6, true);


--
-- Name: facturas_qr_id_seq; Type: SEQUENCE SET; Schema: public; Owner: centro_user
--

SELECT pg_catalog.setval('public.facturas_qr_id_seq', 1, false);


--
-- Name: inventario_id_seq; Type: SEQUENCE SET; Schema: public; Owner: centro_user
--

SELECT pg_catalog.setval('public.inventario_id_seq', 1, false);


--
-- Name: ncf_secuencias_id_seq; Type: SEQUENCE SET; Schema: public; Owner: centro_user
--

SELECT pg_catalog.setval('public.ncf_secuencias_id_seq', 2, true);


--
-- Name: orden_detalles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: centro_user
--

SELECT pg_catalog.setval('public.orden_detalles_id_seq', 258, true);


--
-- Name: ordenes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: centro_user
--

SELECT pg_catalog.setval('public.ordenes_id_seq', 21, true);


--
-- Name: pacientes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: centro_user
--

SELECT pg_catalog.setval('public.pacientes_id_seq', 12, true);


--
-- Name: pagos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: centro_user
--

SELECT pg_catalog.setval('public.pagos_id_seq', 4, true);


--
-- Name: portal_paciente_accesos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: centro_user
--

SELECT pg_catalog.setval('public.portal_paciente_accesos_id_seq', 1, false);


--
-- Name: radiografias_id_seq; Type: SEQUENCE SET; Schema: public; Owner: centro_user
--

SELECT pg_catalog.setval('public.radiografias_id_seq', 1, false);


--
-- Name: resultados_id_seq; Type: SEQUENCE SET; Schema: public; Owner: centro_user
--

SELECT pg_catalog.setval('public.resultados_id_seq', 28, true);


--
-- Name: roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: centro_user
--

SELECT pg_catalog.setval('public.roles_id_seq', 6, true);


--
-- Name: sonografias_id_seq; Type: SEQUENCE SET; Schema: public; Owner: centro_user
--

SELECT pg_catalog.setval('public.sonografias_id_seq', 1, false);


--
-- Name: sync_queue_id_seq; Type: SEQUENCE SET; Schema: public; Owner: centro_user
--

SELECT pg_catalog.setval('public.sync_queue_id_seq', 1, false);


--
-- Name: usuarios_id_seq; Type: SEQUENCE SET; Schema: public; Owner: centro_user
--

SELECT pg_catalog.setval('public.usuarios_id_seq', 4, true);


--
-- Name: whatsapp_messages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: centro_user
--

SELECT pg_catalog.setval('public.whatsapp_messages_id_seq', 4, true);


--
-- Name: alembic_version alembic_version_pkc; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.alembic_version
    ADD CONSTRAINT alembic_version_pkc PRIMARY KEY (version_num);


--
-- Name: auditoria auditoria_pkey; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.auditoria
    ADD CONSTRAINT auditoria_pkey PRIMARY KEY (id);


--
-- Name: caja_movimientos caja_movimientos_pkey; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.caja_movimientos
    ADD CONSTRAINT caja_movimientos_pkey PRIMARY KEY (id);


--
-- Name: cajas cajas_numero_caja_key; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.cajas
    ADD CONSTRAINT cajas_numero_caja_key UNIQUE (numero_caja);


--
-- Name: cajas cajas_pkey; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.cajas
    ADD CONSTRAINT cajas_pkey PRIMARY KEY (id);


--
-- Name: campanas_envios campanas_envios_pkey; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.campanas_envios
    ADD CONSTRAINT campanas_envios_pkey PRIMARY KEY (id);


--
-- Name: campanas_whatsapp campanas_whatsapp_pkey; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.campanas_whatsapp
    ADD CONSTRAINT campanas_whatsapp_pkey PRIMARY KEY (id);


--
-- Name: categorias_estudios categorias_estudios_pkey; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.categorias_estudios
    ADD CONSTRAINT categorias_estudios_pkey PRIMARY KEY (id);


--
-- Name: categorias categorias_nombre_key; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.categorias
    ADD CONSTRAINT categorias_nombre_key UNIQUE (nombre);


--
-- Name: categorias categorias_pkey; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.categorias
    ADD CONSTRAINT categorias_pkey PRIMARY KEY (id);


--
-- Name: configuracion configuracion_clave_key; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.configuracion
    ADD CONSTRAINT configuracion_clave_key UNIQUE (clave);


--
-- Name: configuracion configuracion_pkey; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.configuracion
    ADD CONSTRAINT configuracion_pkey PRIMARY KEY (id);


--
-- Name: estudios estudios_codigo_key; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.estudios
    ADD CONSTRAINT estudios_codigo_key UNIQUE (codigo);


--
-- Name: estudios estudios_pkey; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.estudios
    ADD CONSTRAINT estudios_pkey PRIMARY KEY (id);


--
-- Name: estudios estudios_uuid_key; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.estudios
    ADD CONSTRAINT estudios_uuid_key UNIQUE (uuid);


--
-- Name: factura_detalles factura_detalles_pkey; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.factura_detalles
    ADD CONSTRAINT factura_detalles_pkey PRIMARY KEY (id);


--
-- Name: facturas facturas_numero_factura_key; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.facturas
    ADD CONSTRAINT facturas_numero_factura_key UNIQUE (numero_factura);


--
-- Name: facturas facturas_pkey; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.facturas
    ADD CONSTRAINT facturas_pkey PRIMARY KEY (id);


--
-- Name: facturas_qr facturas_qr_codigo_qr_key; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.facturas_qr
    ADD CONSTRAINT facturas_qr_codigo_qr_key UNIQUE (codigo_qr);


--
-- Name: facturas_qr facturas_qr_pkey; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.facturas_qr
    ADD CONSTRAINT facturas_qr_pkey PRIMARY KEY (id);


--
-- Name: facturas facturas_uuid_key; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.facturas
    ADD CONSTRAINT facturas_uuid_key UNIQUE (uuid);


--
-- Name: inventario inventario_codigo_key; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.inventario
    ADD CONSTRAINT inventario_codigo_key UNIQUE (codigo);


--
-- Name: inventario inventario_pkey; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.inventario
    ADD CONSTRAINT inventario_pkey PRIMARY KEY (id);


--
-- Name: ncf_secuencias ncf_secuencias_pkey; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.ncf_secuencias
    ADD CONSTRAINT ncf_secuencias_pkey PRIMARY KEY (id);


--
-- Name: ncf_secuencias ncf_secuencias_tipo_comprobante_serie_key; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.ncf_secuencias
    ADD CONSTRAINT ncf_secuencias_tipo_comprobante_serie_key UNIQUE (tipo_comprobante, serie);


--
-- Name: orden_detalles orden_detalles_pkey; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.orden_detalles
    ADD CONSTRAINT orden_detalles_pkey PRIMARY KEY (id);


--
-- Name: ordenes ordenes_numero_orden_key; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.ordenes
    ADD CONSTRAINT ordenes_numero_orden_key UNIQUE (numero_orden);


--
-- Name: ordenes ordenes_pkey; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.ordenes
    ADD CONSTRAINT ordenes_pkey PRIMARY KEY (id);


--
-- Name: ordenes ordenes_uuid_key; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.ordenes
    ADD CONSTRAINT ordenes_uuid_key UNIQUE (uuid);


--
-- Name: pacientes pacientes_cedula_key; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.pacientes
    ADD CONSTRAINT pacientes_cedula_key UNIQUE (cedula);


--
-- Name: pacientes pacientes_codigo_paciente_key; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.pacientes
    ADD CONSTRAINT pacientes_codigo_paciente_key UNIQUE (codigo_paciente);


--
-- Name: pacientes pacientes_pkey; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.pacientes
    ADD CONSTRAINT pacientes_pkey PRIMARY KEY (id);


--
-- Name: pacientes pacientes_portal_usuario_key; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.pacientes
    ADD CONSTRAINT pacientes_portal_usuario_key UNIQUE (portal_usuario);


--
-- Name: pacientes pacientes_uuid_key; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.pacientes
    ADD CONSTRAINT pacientes_uuid_key UNIQUE (uuid);


--
-- Name: pagos pagos_pkey; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_pkey PRIMARY KEY (id);


--
-- Name: pagos pagos_uuid_key; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_uuid_key UNIQUE (uuid);


--
-- Name: portal_paciente_accesos portal_paciente_accesos_pkey; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.portal_paciente_accesos
    ADD CONSTRAINT portal_paciente_accesos_pkey PRIMARY KEY (id);


--
-- Name: radiografias radiografias_pkey; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.radiografias
    ADD CONSTRAINT radiografias_pkey PRIMARY KEY (id);


--
-- Name: resultados resultados_pkey; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.resultados
    ADD CONSTRAINT resultados_pkey PRIMARY KEY (id);


--
-- Name: resultados resultados_uuid_key; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.resultados
    ADD CONSTRAINT resultados_uuid_key UNIQUE (uuid);


--
-- Name: roles roles_nombre_key; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_nombre_key UNIQUE (nombre);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: sonografias sonografias_pkey; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.sonografias
    ADD CONSTRAINT sonografias_pkey PRIMARY KEY (id);


--
-- Name: sync_queue sync_queue_pkey; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.sync_queue
    ADD CONSTRAINT sync_queue_pkey PRIMARY KEY (id);


--
-- Name: usuarios usuarios_pkey; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id);


--
-- Name: usuarios usuarios_username_key; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_username_key UNIQUE (username);


--
-- Name: usuarios usuarios_uuid_key; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_uuid_key UNIQUE (uuid);


--
-- Name: whatsapp_messages whatsapp_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.whatsapp_messages
    ADD CONSTRAINT whatsapp_messages_pkey PRIMARY KEY (id);


--
-- Name: idx_auditoria_tabla; Type: INDEX; Schema: public; Owner: centro_user
--

CREATE INDEX idx_auditoria_tabla ON public.auditoria USING btree (tabla, registro_id);


--
-- Name: idx_auditoria_usuario; Type: INDEX; Schema: public; Owner: centro_user
--

CREATE INDEX idx_auditoria_usuario ON public.auditoria USING btree (usuario_id);


--
-- Name: idx_estudios_categoria; Type: INDEX; Schema: public; Owner: centro_user
--

CREATE INDEX idx_estudios_categoria ON public.estudios USING btree (categoria_id);


--
-- Name: idx_estudios_codigo; Type: INDEX; Schema: public; Owner: centro_user
--

CREATE INDEX idx_estudios_codigo ON public.estudios USING btree (codigo);


--
-- Name: idx_facturas_estado; Type: INDEX; Schema: public; Owner: centro_user
--

CREATE INDEX idx_facturas_estado ON public.facturas USING btree (estado);


--
-- Name: idx_facturas_fecha; Type: INDEX; Schema: public; Owner: centro_user
--

CREATE INDEX idx_facturas_fecha ON public.facturas USING btree (fecha_factura);


--
-- Name: idx_facturas_ncf; Type: INDEX; Schema: public; Owner: centro_user
--

CREATE INDEX idx_facturas_ncf ON public.facturas USING btree (ncf);


--
-- Name: idx_facturas_paciente; Type: INDEX; Schema: public; Owner: centro_user
--

CREATE INDEX idx_facturas_paciente ON public.facturas USING btree (paciente_id);


--
-- Name: idx_orden_detalles_orden; Type: INDEX; Schema: public; Owner: centro_user
--

CREATE INDEX idx_orden_detalles_orden ON public.orden_detalles USING btree (orden_id);


--
-- Name: idx_ordenes_estado; Type: INDEX; Schema: public; Owner: centro_user
--

CREATE INDEX idx_ordenes_estado ON public.ordenes USING btree (estado);


--
-- Name: idx_ordenes_fecha; Type: INDEX; Schema: public; Owner: centro_user
--

CREATE INDEX idx_ordenes_fecha ON public.ordenes USING btree (fecha_orden);


--
-- Name: idx_ordenes_paciente; Type: INDEX; Schema: public; Owner: centro_user
--

CREATE INDEX idx_ordenes_paciente ON public.ordenes USING btree (paciente_id);


--
-- Name: idx_pacientes_apellido; Type: INDEX; Schema: public; Owner: centro_user
--

CREATE INDEX idx_pacientes_apellido ON public.pacientes USING btree (apellido);


--
-- Name: idx_pacientes_cedula; Type: INDEX; Schema: public; Owner: centro_user
--

CREATE INDEX idx_pacientes_cedula ON public.pacientes USING btree (cedula);


--
-- Name: idx_pacientes_celular; Type: INDEX; Schema: public; Owner: centro_user
--

CREATE INDEX idx_pacientes_celular ON public.pacientes USING btree (celular);


--
-- Name: idx_pacientes_codigo; Type: INDEX; Schema: public; Owner: centro_user
--

CREATE INDEX idx_pacientes_codigo ON public.pacientes USING btree (codigo_paciente);


--
-- Name: idx_pacientes_nombre; Type: INDEX; Schema: public; Owner: centro_user
--

CREATE INDEX idx_pacientes_nombre ON public.pacientes USING btree (nombre, apellido);


--
-- Name: idx_pacientes_telefono; Type: INDEX; Schema: public; Owner: centro_user
--

CREATE INDEX idx_pacientes_telefono ON public.pacientes USING btree (telefono);


--
-- Name: idx_pagos_factura; Type: INDEX; Schema: public; Owner: centro_user
--

CREATE INDEX idx_pagos_factura ON public.pagos USING btree (factura_id);


--
-- Name: idx_pagos_fecha; Type: INDEX; Schema: public; Owner: centro_user
--

CREATE INDEX idx_pagos_fecha ON public.pagos USING btree (fecha_pago);


--
-- Name: idx_radiografias_medico; Type: INDEX; Schema: public; Owner: centro_user
--

CREATE INDEX idx_radiografias_medico ON public.radiografias USING btree (medico_id);


--
-- Name: idx_radiografias_paciente; Type: INDEX; Schema: public; Owner: centro_user
--

CREATE INDEX idx_radiografias_paciente ON public.radiografias USING btree (paciente_id);


--
-- Name: idx_resultados_orden_detalle; Type: INDEX; Schema: public; Owner: centro_user
--

CREATE INDEX idx_resultados_orden_detalle ON public.resultados USING btree (orden_detalle_id);


--
-- Name: idx_sonografias_medico; Type: INDEX; Schema: public; Owner: centro_user
--

CREATE INDEX idx_sonografias_medico ON public.sonografias USING btree (medico_id);


--
-- Name: idx_sonografias_paciente; Type: INDEX; Schema: public; Owner: centro_user
--

CREATE INDEX idx_sonografias_paciente ON public.sonografias USING btree (paciente_id);


--
-- Name: idx_whatsapp_fecha; Type: INDEX; Schema: public; Owner: centro_user
--

CREATE INDEX idx_whatsapp_fecha ON public.whatsapp_messages USING btree (fecha DESC);


--
-- Name: idx_whatsapp_telefono; Type: INDEX; Schema: public; Owner: centro_user
--

CREATE INDEX idx_whatsapp_telefono ON public.whatsapp_messages USING btree (telefono);


--
-- Name: vista_facturas_completa _RETURN; Type: RULE; Schema: public; Owner: centro_user
--

CREATE OR REPLACE VIEW public.vista_facturas_completa AS
 SELECT f.id,
    f.uuid,
    f.numero_factura,
    f.ncf,
    f.fecha_factura,
    f.total,
    f.estado,
    p.cedula AS paciente_cedula,
    concat(p.nombre, ' ', p.apellido) AS paciente_nombre,
    p.telefono AS paciente_telefono,
    u.username AS usuario_emision,
    COALESCE(sum(pag.monto), (0)::numeric) AS monto_pagado,
    (f.total - COALESCE(sum(pag.monto), (0)::numeric)) AS saldo_pendiente
   FROM (((public.facturas f
     JOIN public.pacientes p ON ((f.paciente_id = p.id)))
     LEFT JOIN public.usuarios u ON ((f.usuario_emision_id = u.id)))
     LEFT JOIN public.pagos pag ON ((pag.factura_id = f.id)))
  GROUP BY f.id, p.id, u.id;


--
-- Name: vista_ordenes_pendientes _RETURN; Type: RULE; Schema: public; Owner: centro_user
--

CREATE OR REPLACE VIEW public.vista_ordenes_pendientes AS
 SELECT o.id,
    o.numero_orden,
    o.fecha_orden,
    o.estado,
    concat(p.nombre, ' ', p.apellido) AS paciente,
    p.cedula,
    count(od.id) AS total_estudios,
    sum(
        CASE
            WHEN od.resultado_disponible THEN 1
            ELSE 0
        END) AS estudios_completados
   FROM ((public.ordenes o
     JOIN public.pacientes p ON ((o.paciente_id = p.id)))
     JOIN public.orden_detalles od ON ((od.orden_id = o.id)))
  WHERE (((o.estado)::text <> 'completada'::text) AND ((o.estado)::text <> 'cancelada'::text))
  GROUP BY o.id, p.id;


--
-- Name: pacientes trigger_generar_codigo_paciente; Type: TRIGGER; Schema: public; Owner: centro_user
--

CREATE TRIGGER trigger_generar_codigo_paciente BEFORE INSERT ON public.pacientes FOR EACH ROW EXECUTE FUNCTION public.generar_codigo_paciente();


--
-- Name: estudios update_estudios_updated_at; Type: TRIGGER; Schema: public; Owner: centro_user
--

CREATE TRIGGER update_estudios_updated_at BEFORE UPDATE ON public.estudios FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: facturas update_facturas_updated_at; Type: TRIGGER; Schema: public; Owner: centro_user
--

CREATE TRIGGER update_facturas_updated_at BEFORE UPDATE ON public.facturas FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: ordenes update_ordenes_updated_at; Type: TRIGGER; Schema: public; Owner: centro_user
--

CREATE TRIGGER update_ordenes_updated_at BEFORE UPDATE ON public.ordenes FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: pacientes update_pacientes_updated_at; Type: TRIGGER; Schema: public; Owner: centro_user
--

CREATE TRIGGER update_pacientes_updated_at BEFORE UPDATE ON public.pacientes FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: auditoria auditoria_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.auditoria
    ADD CONSTRAINT auditoria_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id);


--
-- Name: caja_movimientos caja_movimientos_caja_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.caja_movimientos
    ADD CONSTRAINT caja_movimientos_caja_id_fkey FOREIGN KEY (caja_id) REFERENCES public.cajas(id);


--
-- Name: caja_movimientos caja_movimientos_pago_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.caja_movimientos
    ADD CONSTRAINT caja_movimientos_pago_id_fkey FOREIGN KEY (pago_id) REFERENCES public.pagos(id);


--
-- Name: caja_movimientos caja_movimientos_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.caja_movimientos
    ADD CONSTRAINT caja_movimientos_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id);


--
-- Name: cajas cajas_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.cajas
    ADD CONSTRAINT cajas_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id);


--
-- Name: campanas_envios campanas_envios_campana_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.campanas_envios
    ADD CONSTRAINT campanas_envios_campana_id_fkey FOREIGN KEY (campana_id) REFERENCES public.campanas_whatsapp(id);


--
-- Name: campanas_envios campanas_envios_paciente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.campanas_envios
    ADD CONSTRAINT campanas_envios_paciente_id_fkey FOREIGN KEY (paciente_id) REFERENCES public.pacientes(id);


--
-- Name: campanas_whatsapp campanas_whatsapp_usuario_creador_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.campanas_whatsapp
    ADD CONSTRAINT campanas_whatsapp_usuario_creador_id_fkey FOREIGN KEY (usuario_creador_id) REFERENCES public.usuarios(id);


--
-- Name: estudios estudios_categoria_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.estudios
    ADD CONSTRAINT estudios_categoria_id_fkey FOREIGN KEY (categoria_id) REFERENCES public.categorias_estudios(id);


--
-- Name: factura_detalles factura_detalles_factura_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.factura_detalles
    ADD CONSTRAINT factura_detalles_factura_id_fkey FOREIGN KEY (factura_id) REFERENCES public.facturas(id) ON DELETE CASCADE;


--
-- Name: factura_detalles factura_detalles_orden_detalle_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.factura_detalles
    ADD CONSTRAINT factura_detalles_orden_detalle_id_fkey FOREIGN KEY (orden_detalle_id) REFERENCES public.orden_detalles(id);


--
-- Name: facturas facturas_anulada_por_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.facturas
    ADD CONSTRAINT facturas_anulada_por_id_fkey FOREIGN KEY (anulada_por_id) REFERENCES public.usuarios(id);


--
-- Name: facturas facturas_orden_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.facturas
    ADD CONSTRAINT facturas_orden_id_fkey FOREIGN KEY (orden_id) REFERENCES public.ordenes(id);


--
-- Name: facturas facturas_paciente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.facturas
    ADD CONSTRAINT facturas_paciente_id_fkey FOREIGN KEY (paciente_id) REFERENCES public.pacientes(id);


--
-- Name: facturas_qr facturas_qr_factura_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.facturas_qr
    ADD CONSTRAINT facturas_qr_factura_id_fkey FOREIGN KEY (factura_id) REFERENCES public.facturas(id);


--
-- Name: facturas facturas_usuario_emision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.facturas
    ADD CONSTRAINT facturas_usuario_emision_id_fkey FOREIGN KEY (usuario_emision_id) REFERENCES public.usuarios(id);


--
-- Name: orden_detalles orden_detalles_estudio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.orden_detalles
    ADD CONSTRAINT orden_detalles_estudio_id_fkey FOREIGN KEY (estudio_id) REFERENCES public.estudios(id);


--
-- Name: orden_detalles orden_detalles_orden_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.orden_detalles
    ADD CONSTRAINT orden_detalles_orden_id_fkey FOREIGN KEY (orden_id) REFERENCES public.ordenes(id) ON DELETE CASCADE;


--
-- Name: orden_detalles orden_detalles_tecnico_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.orden_detalles
    ADD CONSTRAINT orden_detalles_tecnico_id_fkey FOREIGN KEY (tecnico_id) REFERENCES public.usuarios(id);


--
-- Name: ordenes ordenes_paciente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.ordenes
    ADD CONSTRAINT ordenes_paciente_id_fkey FOREIGN KEY (paciente_id) REFERENCES public.pacientes(id);


--
-- Name: ordenes ordenes_usuario_registro_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.ordenes
    ADD CONSTRAINT ordenes_usuario_registro_id_fkey FOREIGN KEY (usuario_registro_id) REFERENCES public.usuarios(id);


--
-- Name: pagos pagos_factura_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_factura_id_fkey FOREIGN KEY (factura_id) REFERENCES public.facturas(id);


--
-- Name: pagos pagos_usuario_recibe_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_usuario_recibe_id_fkey FOREIGN KEY (usuario_recibe_id) REFERENCES public.usuarios(id);


--
-- Name: portal_paciente_accesos portal_paciente_accesos_paciente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.portal_paciente_accesos
    ADD CONSTRAINT portal_paciente_accesos_paciente_id_fkey FOREIGN KEY (paciente_id) REFERENCES public.pacientes(id);


--
-- Name: radiografias radiografias_medico_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.radiografias
    ADD CONSTRAINT radiografias_medico_id_fkey FOREIGN KEY (medico_id) REFERENCES public.usuarios(id);


--
-- Name: radiografias radiografias_orden_detalle_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.radiografias
    ADD CONSTRAINT radiografias_orden_detalle_id_fkey FOREIGN KEY (orden_detalle_id) REFERENCES public.orden_detalles(id);


--
-- Name: radiografias radiografias_paciente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.radiografias
    ADD CONSTRAINT radiografias_paciente_id_fkey FOREIGN KEY (paciente_id) REFERENCES public.pacientes(id);


--
-- Name: radiografias radiografias_radiologo_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.radiografias
    ADD CONSTRAINT radiografias_radiologo_id_fkey FOREIGN KEY (radiologo_id) REFERENCES public.usuarios(id);


--
-- Name: resultados resultados_orden_detalle_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.resultados
    ADD CONSTRAINT resultados_orden_detalle_id_fkey FOREIGN KEY (orden_detalle_id) REFERENCES public.orden_detalles(id);


--
-- Name: resultados resultados_validado_por_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.resultados
    ADD CONSTRAINT resultados_validado_por_id_fkey FOREIGN KEY (validado_por_id) REFERENCES public.usuarios(id);


--
-- Name: sonografias sonografias_medico_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.sonografias
    ADD CONSTRAINT sonografias_medico_id_fkey FOREIGN KEY (medico_id) REFERENCES public.usuarios(id);


--
-- Name: sonografias sonografias_orden_detalle_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.sonografias
    ADD CONSTRAINT sonografias_orden_detalle_id_fkey FOREIGN KEY (orden_detalle_id) REFERENCES public.orden_detalles(id);


--
-- Name: sonografias sonografias_paciente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.sonografias
    ADD CONSTRAINT sonografias_paciente_id_fkey FOREIGN KEY (paciente_id) REFERENCES public.pacientes(id);


--
-- Name: usuarios usuarios_rol_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: centro_user
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_rol_id_fkey FOREIGN KEY (rol_id) REFERENCES public.roles(id);


--
-- PostgreSQL database dump complete
--

\unrestrict SIK848qqJztzawh4OaZSxaOucnNVVZbgN5mWDWjKo9lOdfonOPuCQTFoZEK7vWX

