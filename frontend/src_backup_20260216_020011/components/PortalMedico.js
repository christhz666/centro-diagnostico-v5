import React, { useState } from 'react';
import axios from 'axios';
import { FaSearch, FaUserMd, FaHistory, FaFileMedical } from 'react-icons/fa';

const API = '/api';

function PortalMedico() {
  const [busqueda, setBusqueda] = useState('');
  const [resultados, setResultados] = useState([]);
  const [paciente, setPaciente] = useState(null);
  
  const token = localStorage.getItem('token');
  const headers = { Authorization: `Bearer ${token}` };

  const buscar = async (e) => {
    e.preventDefault();
    try {
      const res = await axios.get(`${API}/medico/buscar?q=${busqueda}`, { headers });
      setResultados(res.data.pacientes);
    } catch (err) {}
  };

  const verHistorial = async (id) => {
    try {
      const res = await axios.get(`${API}/medico/historial/${id}`, { headers });
      setPaciente(res.data);
    } catch (err) {}
  };

  return (
    <div className="page-container">
      <h2><FaUserMd /> Portal Médico</h2>
      
      {!paciente ? (
        <div className="form-card">
          <form onSubmit={buscar} style={{display:'flex', gap:'10px'}}>
            <input className="search-input" value={busqueda} onChange={e=>setBusqueda(e.target.value)} placeholder="Buscar paciente..." />
            <button className="btn btn-primary"><FaSearch /> Buscar</button>
          </form>

          <div className="result-list" style={{marginTop:'20px'}}>
            {resultados.map(p => (
              <div key={p.id} className="result-item-inline">
                <div><strong>{p.nombre}</strong><br/><small>{p.cedula}</small></div>
                <button className="btn btn-sm btn-primary" onClick={()=>verHistorial(p.id)}>Ver Historial</button>
              </div>
            ))}
          </div>
        </div>
      ) : (
        <div className="form-card">
          <button onClick={()=>setPaciente(null)} className="btn btn-outline" style={{marginBottom:'20px'}}>Volver</button>
          <h3><FaHistory /> Historial: {paciente.paciente.nombre}</h3>
          
          <h4>Últimas Órdenes</h4>
          <table className="data-table">
            <thead><tr><th>Fecha</th><th>Orden</th><th>Estado</th></tr></thead>
            <tbody>
              {paciente.ordenes.map(o => (
                <tr key={o.id}>
                  <td>{new Date(o.fecha_orden).toLocaleDateString()}</td>
                  <td>{o.numero_orden}</td>
                  <td><span className={`badge badge-${o.estado}`}>{o.estado}</span></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}

export default PortalMedico;
