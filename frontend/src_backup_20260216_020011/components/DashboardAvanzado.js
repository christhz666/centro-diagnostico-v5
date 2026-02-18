import React, { useState, useEffect } from 'react';
import axios from 'axios';

const API_URL = 'http://192.9.135.84:5000/api';

function DashboardAvanzado() {
  const [metricas, setMetricas] = useState({
    ventas_mes: 0, facturas_mes: 0, facturas_pendientes: 0,
    ordenes_pendientes: 0, total_pacientes: 0
  });

  useEffect(() => {
    cargarMetricas();
  }, []);

  const cargarMetricas = async () => {
    try {
      const token = localStorage.getItem('token');
      const response = await axios.get(`${API_URL}/reportes/dashboard`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      setMetricas(response.data);
    } catch (err) {
      console.error('Error:', err);
    }
  };

  return (
    <div className="container">
      <h1>?? Dashboard Avanzado</h1>
      
      <div className="metricas-grid">
        <div className="metrica-card verde">
          <div className="metrica-icon">??</div>
          <div className="metrica-info">
            <h2>RD$ {metricas.ventas_mes?.toLocaleString('es-DO', {minimumFractionDigits: 2})}</h2>
            <p>Ventas del Mes</p>
          </div>
        </div>

        <div className="metrica-card azul">
          <div className="metrica-icon">??</div>
          <div className="metrica-info">
            <h2>{metricas.facturas_mes}</h2>
            <p>Facturas Emitidas</p>
          </div>
        </div>

        <div className="metrica-card amarillo">
          <div className="metrica-icon">?</div>
          <div className="metrica-info">
            <h2>{metricas.facturas_pendientes}</h2>
            <p>Facturas Pendientes</p>
          </div>
        </div>

        <div className="metrica-card rojo">
          <div className="metrica-icon">??</div>
          <div className="metrica-info">
            <h2>{metricas.ordenes_pendientes}</h2>
            <p>Órdenes Pendientes</p>
          </div>
        </div>

        <div className="metrica-card morado">
          <div className="metrica-icon">??</div>
          <div className="metrica-info">
            <h2>{metricas.total_pacientes}</h2>
            <p>Pacientes Activos</p>
          </div>
        </div>
      </div>

      <div className="acciones-rapidas">
        <h2>? Acciones Rápidas</h2>
        <div className="acciones-grid">
          <a href="/nuevo-paciente" className="accion-btn">? Nuevo Paciente</a>
          <a href="/nueva-orden" className="accion-btn">?? Nueva Orden</a>
          <a href="/facturas" className="accion-btn">?? Ver Facturas</a>
          <button onClick={cargarMetricas} className="accion-btn">?? Actualizar</button>
        </div>
      </div>
    </div>
  );
}

export default DashboardAvanzado;
