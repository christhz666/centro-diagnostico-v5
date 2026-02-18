import React, { useState, useEffect } from 'react';
import axios from 'axios';

const API_URL = 'http://192.9.135.84:5000/api';

function VisorResultados() {
  const [resultados, setResultados] = useState([]);
  const [filtro, setFiltro] = useState('');

  useEffect(() => {
    cargarResultados();
  }, []);

  const cargarResultados = async () => {
    try {
      const token = localStorage.getItem('token');
      const response = await axios.get(`${API_URL}/resultados/`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      setResultados(response.data.resultados || []);
    } catch (err) {
      console.error('Error cargando resultados:', err);
    }
  };

  return (
    <div className="container">
      <h1>?? Visor de Resultados</h1>
      <div className="resultados-grid">
        {resultados.length === 0 ? (
          <p>No hay resultados disponibles</p>
        ) : (
          resultados.map(r => (
            <div key={r.id} className="resultado-card">
              <h3>{r.tipo_archivo}</h3>
              <p><strong>Archivo:</strong> {r.nombre_archivo}</p>
              <p><strong>Fecha:</strong> {new Date(r.fecha).toLocaleString()}</p>
              <button className="btn-primary">Ver Detalles</button>
            </div>
          ))
        )}
      </div>
    </div>
  );
}

export default VisorResultados;
