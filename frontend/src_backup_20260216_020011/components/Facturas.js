import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { Link } from 'react-router-dom';
import { FaFileInvoice, FaPlus, FaEye, FaPrint, FaMoneyBillWave, FaDownload } from 'react-icons/fa';

const API = '/api';

function Facturas() {
  const [facturas, setFacturas] = useState([]);
  const [loading, setLoading] = useState(true);
  const [detalle, setDetalle] = useState(null);
  
  const token = localStorage.getItem('token');
  const headers = { Authorization: `Bearer ${token}` };

  useEffect(() => { fetchFacturas(); }, []);

  const fetchFacturas = async () => {
    try {
      const res = await axios.get(`${API}/facturas/`, { headers });
      setFacturas(res.data.facturas);
    } catch (err) { console.error(err); } finally { setLoading(false); }
  };

  const verDetalle = async (id) => {
    try {
      const res = await axios.get(`${API}/facturas/${id}`, { headers });
      setDetalle(res.data);
    } catch (err) {}
  };

  const formatMoney = (n) => `RD$ ${Number(n).toLocaleString('es-DO', { minimumFractionDigits: 2 })}`;

  return (
    <div className="page-container">
      <div className="page-header">
        <h2><FaFileInvoice /> Gestión de Facturas</h2>
      </div>

      <div className="form-card">
        {loading ? <p>Cargando...</p> : (
          <table className="data-table">
            <thead><tr><th>Nº</th><th>Paciente</th><th>Fecha</th><th>Total</th><th>Estado</th><th>Acciones</th></tr></thead>
            <tbody>
              {facturas.map(f => (
                <tr key={f.id}>
                  <td><strong>{f.numero_factura}</strong></td>
                  <td>{f.paciente?.nombre} {f.paciente?.apellido}</td>
                  <td>{new Date(f.fecha_factura).toLocaleDateString()}</td>
                  <td><strong>{formatMoney(f.total)}</strong></td>
                  <td><span className={`badge badge-${f.estado}`}>{f.estado}</span></td>
                  <td>
                    <button className="btn btn-sm btn-primary" onClick={() => verDetalle(f.id)}><FaEye /> Ver</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {detalle && (
        <div className="modal-overlay">
          <div className="modal-content">
            <button className="close-btn" onClick={() => setDetalle(null)}>?</button>
            <h3>Factura {detalle.numero_factura}</h3>
            
            <div className="info-grid">
              <span><strong>Paciente:</strong> {detalle.paciente?.nombre} {detalle.paciente?.apellido}</span>
              <span><strong>NCF:</strong> {detalle.ncf || 'N/A'}</span>
              <span><strong>Estado:</strong> {detalle.estado}</span>
            </div>

            <table className="data-table" style={{marginTop:'20px'}}>
              <thead><tr><th>Descripción</th><th>Total</th></tr></thead>
              <tbody>
                {detalle.detalles?.map(d => (
                  <tr key={d.id}><td>{d.descripcion}</td><td>{formatMoney(d.total)}</td></tr>
                ))}
              </tbody>
            </table>

            <div className="orden-total" style={{marginTop:'20px', background:'#eee', color:'#333'}}>
              <span>Total a Pagar:</span> <strong>{formatMoney(detalle.total)}</strong>
            </div>

            <div className="btn-group" style={{marginTop:'20px'}}>
              <a href={`${API}/facturas/${detalle.id}/pdf`} target="_blank" className="btn btn-primary"><FaDownload /> PDF</a>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default Facturas;
