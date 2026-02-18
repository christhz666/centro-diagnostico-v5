import React, { useEffect } from 'react';
import Barcode from 'react-barcode';

// Importar el logo local
const logoLocal = '/logo-centro.svg'; // Usar desde public folder para mejor compatibilidad

const FacturaTermica = ({ factura, paciente, estudios, onClose }) => {
  const usuario = JSON.parse(localStorage.getItem('user') || '{}');
  const fecha = new Date();

  useEffect(() => {
    if (!factura || !paciente) {
      console.error('Datos incompletos:', { factura, paciente, estudios });
    }
  }, [factura, paciente, estudios]);

  if (!factura || !paciente) {
    return (
      <div style={{ padding: 20, textAlign: 'center' }}>
        <h3>Error: Datos incompletos para generar la factura</h3>
        <button onClick={onClose} style={{ marginTop: 20, padding: '10px 20px', background: '#6c757d', color: 'white', border: 'none', borderRadius: 8, cursor: 'pointer' }}>
          Cerrar
        </button>
      </div>
    );
  }

  const estudiosArray = Array.isArray(estudios) ? estudios : [];
  const subtotal = estudiosArray.reduce((sum, e) => sum + (e.precio || e.precioUnitario || 0), 0);
  const cobertura = estudiosArray.reduce((sum, e) => sum + (e.cobertura || 0), 0);
  const totalPagar = subtotal - cobertura;
  const montoPagado = factura?.montoPagado || factura?.monto_pagado || 0;
  const pendiente = totalPagar - montoPagado;
  const cambio = montoPagado > totalPagar ? montoPagado - totalPagar : 0;

  const codigoPaciente = 'PAC' + (paciente?._id || paciente?.id || '000000').toString().slice(-8).toUpperCase();
  const numeroFactura = factura?.numero || factura?.numero_factura || 'F-' + Date.now().toString().slice(-8);

  const colores = {
    azulCielo: '#87CEEB',
    azulOscuro: '#1a3a5c',
    blanco: '#FFFFFF',
    negro: '#000000'
  };

  const getTexto = (valor) => {
    if (!valor) return '';
    if (typeof valor === 'string') return valor;
    if (typeof valor === 'number') return valor.toString();
    if (typeof valor === 'object') return valor.nombre || valor.tipo || valor.descripcion || '';
    return String(valor);
  };

  const getSeguroNombre = () => {
    if (!paciente?.seguro) return 'Sin seguro';
    if (typeof paciente.seguro === 'string') return paciente.seguro || 'Sin seguro';
    if (typeof paciente.seguro === 'object') return paciente.seguro.nombre || 'Sin seguro';
    return 'Sin seguro';
  };

  const getSeguroAfiliado = () => {
    if (!paciente?.seguro) return 'N/A';
    if (typeof paciente.seguro === 'object') {
      return paciente.seguro.numeroAfiliado || paciente.seguro.numeroPoliza || 'N/A';
    }
    return 'N/A';
  };

  const calcularEdad = (fechaNac) => {
    if (!fechaNac) return '';
    try {
      const hoy = new Date();
      const nacimiento = new Date(fechaNac);
      let edad = hoy.getFullYear() - nacimiento.getFullYear();
      const mes = hoy.getMonth() - nacimiento.getMonth();
      if (mes < 0 || (mes === 0 && hoy.getDate() < nacimiento.getDate())) edad--;
      return edad + ' anos';
    } catch (e) {
      return '';
    }
  };

  const getSexo = () => {
    const sexo = paciente?.sexo || paciente?.genero || '';
    if (sexo === 'M' || sexo === 'masculino' || sexo === 'Masculino') return 'Masculino';
    if (sexo === 'F' || sexo === 'femenino' || sexo === 'Femenino') return 'Femenino';
    return sexo || '';
  };

  const handlePrint = () => {
    window.print();
  };

  const edad = calcularEdad(paciente?.fechaNacimiento || paciente?.fecha_nacimiento);
  const sexo = getSexo();
  const nacionalidad = paciente?.nacionalidad || 'Dominicano';
  const nombreCompleto = `${getTexto(paciente?.nombre)} ${getTexto(paciente?.apellido)}`.trim() || paciente?.nombre_completo || 'N/A';

  return (
    <div style={{ padding: '10px', maxWidth: '80mm', margin: '0 auto', fontFamily: 'Arial, sans-serif', fontSize: '12px' }}>
      <style>
        {`@media print {
          body * { visibility: hidden; }
          .factura-termica, .factura-termica * { visibility: visible; }
          .factura-termica { position: absolute; left: 0; top: 0; width: 80mm; }
          .no-print { display: none !important; }
        }`}
      </style>

      <div className="factura-termica">
        <div style={{ textAlign: 'center', borderBottom: '3px solid ' + colores.azulOscuro, paddingBottom: '10px', marginBottom: '10px' }}>
          <img 
            src={logoLocal}
            alt="Mi Esperanza Lab" 
            style={{ maxWidth: '70mm', height: 'auto', marginBottom: '5px' }}
            onError={(e) => {
              // Fallback a URL remota si la local falla
              e.target.onerror = null;
              e.target.src = "https://miesperanzalab.com/wp-content/uploads/2024/10/Logo-Mie-esperanza-Lab-Color-400x190-1.png";
            }}
          />
          <div style={{ fontSize: '10px', lineHeight: '1.4', color: colores.azulOscuro }}>
            <p style={{ margin: '2px 0' }}>C/ Camino de Cancino #24</p>
            <p style={{ margin: '2px 0' }}>Cancino Adentro, Santo Domingo Este, Rep. Dom.</p>
            <p style={{ margin: '2px 0' }}>Tel: 849-288-9790 / 809-986-9970</p>
            <p style={{ margin: '2px 0' }}>miesperanzalab@gmail.com</p>
          </div>
        </div>

        <div style={{ marginBottom: '10px', fontSize: '11px', background: colores.azulCielo, padding: '8px', borderRadius: '5px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between' }}>
            <span><strong>Factura:</strong> {numeroFactura}</span>
            <span>{fecha.toLocaleDateString('es-DO')}</span>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between' }}>
            <span><strong>Hora:</strong> {fecha.toLocaleTimeString('es-DO')}</span>
            <span><strong>Cajero:</strong> {getTexto(usuario.nombre)}</span>
          </div>
        </div>

        <div style={{ borderTop: '2px solid ' + colores.azulOscuro, borderBottom: '2px solid ' + colores.azulOscuro, padding: '8px 0', marginBottom: '10px' }}>
          <p style={{ margin: '3px 0', fontSize: '11px' }}>
            <strong>Paciente:</strong> {nombreCompleto}
          </p>
          <p style={{ margin: '3px 0', fontSize: '11px' }}>
            <strong>Cedula:</strong> {getTexto(paciente?.cedula)}
          </p>
          <div style={{ display: 'flex', justifyContent: 'space-between', margin: '3px 0', fontSize: '11px' }}>
            {edad && <span><strong>Edad:</strong> {edad}</span>}
            {sexo && <span><strong>Sexo:</strong> {sexo}</span>}
          </div>
          <p style={{ margin: '3px 0', fontSize: '11px' }}>
            <strong>Nacionalidad:</strong> {nacionalidad}
          </p>
          <p style={{ margin: '3px 0', fontSize: '11px' }}>
            <strong>Telefono:</strong> {getTexto(paciente?.telefono)}
          </p>
        </div>

        <div style={{ borderBottom: '2px solid ' + colores.azulOscuro, padding: '8px', marginBottom: '10px', background: '#f0f8ff' }}>
          <p style={{ margin: '0 0 5px 0', fontSize: '11px', fontWeight: 'bold', textAlign: 'center', color: colores.azulOscuro }}>
            DATOS DEL SEGURO
          </p>
          <p style={{ margin: '3px 0', fontSize: '11px' }}>
            <strong>Seguro:</strong> {getSeguroNombre()}
          </p>
          <p style={{ margin: '3px 0', fontSize: '11px' }}>
            <strong># Afiliado:</strong> {getSeguroAfiliado()}
          </p>
          <p style={{ margin: '3px 0', fontSize: '11px' }}>
            <strong># Autorizacion:</strong> {getTexto(factura?.autorizacion) || 'N/A'}
          </p>
        </div>

        <table style={{ width: '100%', borderCollapse: 'collapse', marginBottom: '10px' }}>
          <thead>
            <tr style={{ background: colores.azulOscuro, color: colores.blanco }}>
              <th style={{ padding: '6px', textAlign: 'left', fontSize: '10px' }}>Descripcion</th>
              <th style={{ padding: '6px', textAlign: 'right', fontSize: '10px' }}>Cobertura</th>
              <th style={{ padding: '6px', textAlign: 'right', fontSize: '10px' }}>Valor</th>
            </tr>
          </thead>
          <tbody>
            {estudiosArray.map((estudio, i) => (
              <tr key={i} style={{ borderBottom: '1px solid ' + colores.azulCielo }}>
                <td style={{ padding: '5px', fontSize: '10px' }}>
                  {getTexto(estudio.nombre || estudio.estudioId?.nombre || estudio.descripcion || 'Estudio')}
                </td>
                <td style={{ padding: '5px', textAlign: 'right', fontSize: '10px' }}>
                  ${(estudio.cobertura || 0).toFixed(2)}
                </td>
                <td style={{ padding: '5px', textAlign: 'right', fontSize: '10px' }}>
                  ${(estudio.precio || estudio.precioUnitario || 0).toFixed(2)}
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        <div style={{ borderTop: '3px solid ' + colores.azulOscuro, paddingTop: '10px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '11px', marginBottom: '3px' }}>
            <span>Subtotal:</span>
            <span>${subtotal.toFixed(2)}</span>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '11px', marginBottom: '3px', color: cobertura > 0 ? '#27ae60' : '#666' }}>
            <span>Cobertura Seguro:</span>
            <span>-${cobertura.toFixed(2)}</span>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', fontWeight: 'bold', fontSize: '14px', padding: '8px', background: colores.azulOscuro, color: colores.blanco, borderRadius: '5px', margin: '5px 0' }}>
            <span>TOTAL A PAGAR:</span>
            <span>${totalPagar.toFixed(2)}</span>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '11px', marginBottom: '3px' }}>
            <span>Monto Pagado:</span>
            <span>${montoPagado.toFixed(2)}</span>
          </div>
          {cambio > 0 && (
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '11px', marginBottom: '3px' }}>
              <span>Cambio:</span>
              <span>${cambio.toFixed(2)}</span>
            </div>
          )}
          {pendiente > 0 && (
            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '8px', background: '#fff3cd', border: '2px solid #ffc107', borderRadius: '5px', fontWeight: 'bold', fontSize: '12px', color: '#856404', marginTop: '5px' }}>
              <span>PENDIENTE:</span>
              <span>${pendiente.toFixed(2)}</span>
            </div>
          )}
        </div>

        <div style={{ marginTop: '15px', textAlign: 'center', borderTop: '2px solid ' + colores.azulCielo, paddingTop: '10px' }}>
          <p style={{ margin: '0 0 5px 0', fontSize: '10px', fontWeight: 'bold', color: colores.azulOscuro }}>CODIGO DE PACIENTE</p>
          <Barcode value={codigoPaciente} width={1.5} height={40} fontSize={12} margin={5} />
        </div>

        <div style={{ marginTop: '15px', textAlign: 'center', fontSize: '9px', background: colores.azulOscuro, color: colores.blanco, padding: '10px', borderRadius: '5px' }}>
          <p style={{ margin: '3px 0', fontWeight: 'bold' }}>Gracias por confiar en nosotros!</p>
          <p style={{ margin: '3px 0' }}>Conserve este comprobante para retirar sus resultados</p>
          <p style={{ margin: '5px 0 0 0', fontStyle: 'italic', color: colores.azulCielo }}>Su salud es nuestra prioridad</p>
        </div>
      </div>

      <div className="no-print" style={{ marginTop: '20px', display: 'flex', gap: '10px', justifyContent: 'center' }}>
        <button onClick={handlePrint} style={{ padding: '12px 30px', backgroundColor: colores.azulOscuro, color: 'white', border: 'none', borderRadius: '8px', cursor: 'pointer', fontWeight: 'bold' }}>
          Imprimir
        </button>
        <button onClick={onClose} style={{ padding: '12px 30px', backgroundColor: '#6c757d', color: 'white', border: 'none', borderRadius: '8px', cursor: 'pointer', fontWeight: 'bold' }}>
          Cerrar
        </button>
      </div>
    </div>
  );
};

export default FacturaTermica;
