import React, { useState, useEffect } from 'react';
import axios from 'axios';

const AdminEquipos = () => {
  const [equipos, setEquipos] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Log para debug
  console.log('AdminEquipos: Componente renderizado');

  useEffect(() => {
    console.log('AdminEquipos: useEffect ejecutado');
    cargarEquipos();
  }, []);

  const cargarEquipos = async () => {
    console.log('AdminEquipos: Cargando equipos...');
    try {
      setLoading(true);
      setError(null);
      
      const response = await axios.get('/api/equipos');
      console.log('AdminEquipos: Respuesta:', response.data);
      
      let listaEquipos = [];
      if (Array.isArray(response.data)) {
        listaEquipos = response.data;
      } else if (response.data.equipos) {
        listaEquipos = response.data.equipos;
      } else if (response.data.data) {
        listaEquipos = response.data.data;
      }
      
      console.log('AdminEquipos: Equipos procesados:', listaEquipos.length);
      setEquipos(listaEquipos);
    } catch (err) {
      console.error('AdminEquipos: Error:', err);
      setError(err.message || 'Error al cargar equipos');
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div style={{ padding: 50, textAlign: 'center' }}>
        <h2>? Cargando equipos...</h2>
        <p>Por favor espere...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div style={{ padding: 50, textAlign: 'center', background: '#fee', borderRadius: 10 }}>
        <h2>? Error</h2>
        <p>{error}</p>
        <button onClick={cargarEquipos} style={{ padding: '10px 20px', cursor: 'pointer' }}>
          Reintentar
        </button>
      </div>
    );
  }

  return (
    <div style={{ padding: 20 }}>
      <h1 style={{ color: '#1a3a5c', marginBottom: 20 }}>
        ?? Equipos de Laboratorio ({equipos.length})
      </h1>
      
      {equipos.length === 0 ? (
        <div style={{ padding: 50, textAlign: 'center', background: '#f5f5f5', borderRadius: 10 }}>
          <h3>?? No hay equipos</h3>
          <p>Verifica que el backend esté funcionando</p>
          <button onClick={cargarEquipos} style={{ padding: '10px 20px', cursor: 'pointer', marginTop: 10 }}>
            ?? Recargar
          </button>
        </div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: 20 }}>
          {equipos.map((equipo, index) => (
            <div key={equipo._id || index} style={{
              background: 'white',
              padding: 20,
              borderRadius: 10,
              boxShadow: '0 2px 10px rgba(0,0,0,0.1)',
              borderLeft: '4px solid #1a3a5c'
            }}>
              <h3 style={{ margin: '0 0 10px 0', color: '#1a3a5c' }}>
                {equipo.nombre}
              </h3>
              <p><strong>Marca:</strong> {equipo.marca}</p>
              <p><strong>Modelo:</strong> {equipo.modelo}</p>
              <p><strong>Tipo:</strong> {equipo.tipo}</p>
              <p><strong>Protocolo:</strong> {equipo.protocolo}</p>
              <span style={{
                display: 'inline-block',
                padding: '5px 10px',
                background: equipo.estado === 'activo' ? '#27ae60' : '#95a5a6',
                color: 'white',
                borderRadius: 5,
                fontSize: 12
              }}>
                {equipo.estado || 'INACTIVO'}
              </span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default AdminEquipos;
