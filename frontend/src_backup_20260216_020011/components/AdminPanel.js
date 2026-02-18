import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { FaUserCog, FaNotesMedical, FaChartPie, FaEdit, FaTrash, FaCheck, FaBan, FaKey } from 'react-icons/fa';

const API = '/api';

function AdminPanel({ user }) {
  const [tab, setTab] = useState('usuarios');
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(false);
  const token = localStorage.getItem('token');
  const headers = { Authorization: `Bearer ${token}` };

  useEffect(() => {
    setLoading(true);
    const url = tab === 'usuarios' ? `${API}/admin/usuarios` : `${API}/estudios/`;
    axios.get(url, { headers })
      .then(res => setData(res.data.usuarios || res.data.estudios || []))
      .catch(console.error)
      .finally(() => setLoading(false));
  }, [tab]);

  const formatMoney = (n) => `RD$ ${Number(n).toLocaleString('es-DO', { minimumFractionDigits: 2 })}`;

  return (
    <div className="page-container">
      <h2><FaUserCog /> Administración</h2>
      
      <div className="admin-tabs">
        <button className={`tab ${tab==='usuarios'?'active':''}`} onClick={()=>setTab('usuarios')}><FaUserCog /> Usuarios</button>
        <button className={`tab ${tab==='estudios'?'active':''}`} onClick={()=>setTab('estudios')}><FaNotesMedical /> Estudios</button>
      </div>

      <div className="form-card">
        {loading ? <p>Cargando...</p> : (
          <table className="data-table">
            <thead>
              {tab === 'usuarios' ? (
                <tr><th>Usuario</th><th>Nombre</th><th>Rol</th><th>Estado</th><th>Acciones</th></tr>
              ) : (
                <tr><th>Código</th><th>Nombre</th><th>Precio</th><th>Estado</th><th>Acciones</th></tr>
              )}
            </thead>
            <tbody>
              {data.map(item => (
                <tr key={item.id}>
                  {tab === 'usuarios' ? (
                    <>
                      <td>{item.username}</td><td>{item.nombre}</td>
                      <td><span className={`badge badge-${item.rol}`}>{item.rol}</span></td>
                      <td>{item.activo ? <FaCheck color="green"/> : <FaBan color="red"/>}</td>
                      <td>
                        <button className="btn btn-sm btn-outline"><FaEdit /></button>
                        <button className="btn btn-sm btn-outline"><FaKey /></button>
                      </td>
                    </>
                  ) : (
                    <>
                      <td>{item.codigo}</td><td>{item.nombre}</td>
                      <td>{formatMoney(item.precio)}</td>
                      <td>{item.activo ? <FaCheck color="green"/> : <FaBan color="red"/>}</td>
                      <td><button className="btn btn-sm btn-outline"><FaEdit /></button></td>
                    </>
                  )}
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}

export default AdminPanel;
