import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';

const API_URL = 'http://192.9.135.84:5000/api';

function CrearFacturaCompleta() {
  const navigate = useNavigate();
  const [ordenesPendientes, setOrdenesPendientes] = useState([]);
  const [ordenSeleccionada, setOrdenSeleccionada] = useState(null);
  const [formData, setFormData] = useState({
    tipo_comprobante: 'B02',
    forma_pago: 'efectivo',
    incluir_itbis: false,
    descuento_global: 0
  });

  useEffect(() => {
    cargarOrdenesPendientes();
  }, []);

  const cargarOrdenesPendientes = async () => {
    try {
      const token = localStorage.getItem('token');
      const response = await axios.get(`${API_URL}/ordenes/pendientes`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      setOrdenesPendientes(response.data.ordenes || []);
    } catch (err) {
      console.error('Error:', err);
    }
  };

  const crearFactura = async () => {
    if (!ordenSeleccionada) {
      alert('Seleccione una orden');
      return;
    }

    try {
      const token = localStorage.getItem('token');
      const response = await axios.post(
        `${API_URL}/facturas/crear-desde-orden/${ordenSeleccionada.id}`,
        formData,
        { headers: { Authorization: `Bearer ${token}` } }
      );

      alert('Factura creada exitosamente');
      navigate('/facturas');
    } catch (err) {
      alert('Error al crear factura: ' + (err.response?.data?.error || err.message));
    }
  };

  return (
    <div className="container">
      <h1>?? Crear Nueva Factura</h1>

      <div className="form-section">
        <h3>1. Seleccionar Orden</h3>
        <div className="ordenes-grid">
          {ordenesPendientes.length === 0 ? (
            <p>No hay órdenes pendientes de facturación</p>
          ) : (
            ordenesPendientes.map(o => (
              <div
                key={o.id}
                className={`orden-card ${ordenSeleccionada?.id === o.id ? 'selected' : ''}`}
                onClick={() => setOrdenSeleccionada(o)}
              >
                <strong>{o.numero_orden}</strong>
                <p>Paciente ID: {o.paciente_id}</p>
                <p>Fecha: {new Date(o.fecha_orden).toLocaleDateString()}</p>
              </div>
            ))
          )}
        </div>
      </div>

      <div className="form-section">
        <h3>2. Datos de Facturación</h3>
        <div className="form-row">
          <div className="form-group">
            <label>Tipo de Comprobante</label>
            <select value={formData.tipo_comprobante} onChange={e => setFormData({...formData, tipo_comprobante: e.target.value})}>
              <option value="B01">B01 - Crédito Fiscal</option>
              <option value="B02">B02 - Consumidor Final</option>
              <option value="B14">B14 - Regímenes Especiales</option>
              <option value="B15">B15 - Gubernamental</option>
            </select>
          </div>

          <div className="form-group">
            <label>Forma de Pago</label>
            <select value={formData.forma_pago} onChange={e => setFormData({...formData, forma_pago: e.target.value})}>
              <option value="efectivo">Efectivo</option>
              <option value="tarjeta">Tarjeta</option>
              <option value="transferencia">Transferencia</option>
              <option value="cheque">Cheque</option>
            </select>
          </div>

          <div className="form-group">
            <label>Descuento Global</label>
            <input
              type="number"
              value={formData.descuento_global}
              onChange={e => setFormData({...formData, descuento_global: parseFloat(e.target.value)})}
              min="0"
            />
          </div>
        </div>

        <div className="form-group">
          <label>
            <input
              type="checkbox"
              checked={formData.incluir_itbis}
              onChange={e => setFormData({...formData, incluir_itbis: e.target.checked})}
            />
            Incluir ITBIS (18%)
          </label>
        </div>
      </div>

      <div className="form-actions">
        <button onClick={() => navigate('/facturas')} className="btn-secondary">Cancelar</button>
        <button onClick={crearFactura} className="btn-primary" disabled={!ordenSeleccionada}>
          Crear Factura
        </button>
      </div>
    </div>
  );
}

export default CrearFacturaCompleta;
