import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
// Importamos los iconos
import { 
  FaUserPlus, 
  FaFileInvoiceDollar, 
  FaSearch, 
  FaUsers, 
  FaClipboardList, 
  FaMoneyBillWave, 
  FaHandHoldingHeart,
  FaCogs
} from 'react-icons/fa';

const API = '/api';

function Dashboard({ user }) {
  const navigate = useNavigate();
  const [stats, setStats] = useState(null);
  const isAdmin = user?.rol === 'admin';

  useEffect(() => {
    const fetchDashboard = async () => {
      try {
        const token = localStorage.getItem('token');
        const res = await axios.get(`${API}/reportes/dashboard`, {
          headers: { Authorization: `Bearer ${token}` }
        });
        setStats(res.data);
      } catch (err) {
        console.error("Error dashboard", err);
      }
    };
    fetchDashboard();
  }, []);

  const formatMoney = (n) => `RD$ ${Number(n).toLocaleString('es-DO', { minimumFractionDigits: 2 })}`;

  return (
    <div className="page-container">
      <div className="dashboard-header">
        <h1><FaHandHoldingHeart className="icon-title" /> Hola, {user?.nombre}</h1>
        <p className="subtitle">Panel de Control General</p>
      </div>

      {/* --- ACCIONES RÁPIDAS (BOTONES GRANDES) --- */}
      <div className="quick-actions">
        <button className="action-btn action-primary" onClick={() => navigate('/registro')}>
          <FaUserPlus size={24} />
          <div>
            <strong>Nuevo Registro</strong>
            <div style={{fontSize:'0.8rem', opacity:0.9}}>Paciente y Orden</div>
          </div>
        </button>

        <button className="action-btn action-success" onClick={() => navigate('/facturas')}>
          <FaFileInvoiceDollar size={24} />
          <div>
            <strong>Caja / Facturas</strong>
            <div style={{fontSize:'0.8rem', opacity:0.9}}>Cobros y Recibos</div>
          </div>
        </button>

        <button className="action-btn action-warning" onClick={() => navigate('/portal-medico')}>
          <FaSearch size={24} />
          <div>
            <strong>Resultados</strong>
            <div style={{fontSize:'0.8rem', opacity:0.9}}>Buscar historial</div>
          </div>
        </button>

        {isAdmin && (
          <button className="action-btn action-purple" onClick={() => navigate('/admin')}>
            <FaCogs size={24} />
            <div>
              <strong>Admin</strong>
              <div style={{fontSize:'0.8rem'}}>Configuración</div>
            </div>
          </button>
        )}
      </div>

      {/* --- ESTADÍSTICAS (TARJETAS) --- */}
      {stats && (
        <div className="stats-grid">
          <div className="stat-card stat-blue">
            <div className="stat-icon"><FaUsers /></div>
            <div className="stat-info">
              <h3>{stats.pacientes?.hoy || 0}</h3>
              <p>Pacientes Hoy</p>
            </div>
          </div>
          <div className="stat-card stat-orange">
            <div className="stat-icon"><FaClipboardList /></div>
            <div className="stat-info">
              <h3>{stats.ordenes?.pendientes || 0}</h3>
              <p>Órdenes Pendientes</p>
            </div>
          </div>
          <div className="stat-card stat-green">
            <div className="stat-icon"><FaMoneyBillWave /></div>
            <div className="stat-info">
              <h3>{formatMoney(stats.ingresos?.hoy || 0)}</h3>
              <p>Ventas de Hoy</p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default Dashboard;
