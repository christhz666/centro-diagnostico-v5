import React, { useState, useEffect } from 'react';
import { FaUsers, FaPlus, FaEdit, FaToggleOn, FaToggleOff, FaKey, FaSpinner } from 'react-icons/fa';
import api from '../services/api';

const AdminUsuarios = () => {
  const [usuarios, setUsuarios] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [roles, setRoles] = useState([]);
  const [formData, setFormData] = useState({
    nombre: '', 
    apellido: '', 
    email: '', 
    password: '', 
    username: '',
    rol: 'recepcion',
    telefono: ''
  });

  useEffect(() => {
    fetchUsuarios();
    fetchRoles();
  }, []);

  const fetchUsuarios = async () => {
    try {
      setLoading(true);
      const response = await api.getUsuarios();
      setUsuarios(response.data || response || []);
    } catch (err) {
      setError(err.message);
      setUsuarios([]);
    } finally {
      setLoading(false);
    }
  };

  const fetchRoles = async () => {
    try {
      const response = await api.getRoles();
      setRoles(response || []);
    } catch (err) {
      console.error('Error cargando roles:', err);
      // Roles por defecto si falla
      setRoles([
        { value: 'admin', label: 'Administrador' },
        { value: 'medico', label: 'Médico' },
        { value: 'recepcion', label: 'Recepcionista' },
        { value: 'tecnico', label: 'Técnico' },
        { value: 'cajero', label: 'Cajero' }
      ]);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      // Crear objeto con el formato correcto para el backend
      const userData = {
        username: formData.username || formData.email.split('@')[0],
        password: formData.password,
        nombre: formData.nombre,
        apellido: formData.apellido,
        email: formData.email,
        rol: formData.rol  // ? CORREGIDO: "rol" en vez de "role"
      };
      
      await api.createUsuario(userData);
      setShowModal(false);
      setFormData({ 
        nombre: '', 
        apellido: '', 
        email: '', 
        password: '', 
        username: '',
        rol: 'recepcion',
        telefono: '' 
      });
      fetchUsuarios();
      alert('Usuario creado exitosamente');
    } catch (err) {
      alert('Error: ' + err.message);
    }
  };

  const handleToggle = async (id) => {
    try {
      await api.toggleUsuario(id);
      fetchUsuarios();
    } catch (err) {
      alert('Error: ' + err.message);
    }
  };

  const handleResetPassword = async (id) => {
    const newPass = prompt('Nueva contraseña (mínimo 6 caracteres):');
    if (newPass && newPass.length >= 6) {
      try {
        await api.resetPasswordUsuario(id, newPass);
        alert('Contraseña actualizada');
      } catch (err) {
        alert('Error: ' + err.message);
      }
    }
  };

  if (loading) {
    return (
      <div style={{ display: 'flex', justifyContent: 'center', padding: 50 }}>
        <FaSpinner style={{ fontSize: 40, animation: 'spin 1s linear infinite' }} />
      </div>
    );
  }

  return (
    <div style={{ padding: 20 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <h1 style={{ margin: 0, display: 'flex', alignItems: 'center', gap: 10 }}>
          <FaUsers /> Gestión de Usuarios
        </h1>
        <button
          onClick={() => setShowModal(true)}
          style={{
            padding: '10px 20px',
            background: '#27ae60',
            color: 'white',
            border: 'none',
            borderRadius: 8,
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            gap: 8
          }}
        >
          <FaPlus /> Nuevo Usuario
        </button>
      </div>

      {error && <div style={{ background: '#fee', padding: 15, borderRadius: 8, marginBottom: 20, color: '#c00' }}>{error}</div>}

      <div style={{ background: 'white', borderRadius: 10, overflow: 'hidden', boxShadow: '0 2px 10px rgba(0,0,0,0.1)' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr style={{ background: '#f8f9fa' }}>
              <th style={{ padding: 15, textAlign: 'left' }}>Usuario</th>
              <th style={{ padding: 15, textAlign: 'left' }}>Nombre</th>
              <th style={{ padding: 15, textAlign: 'left' }}>Email</th>
              <th style={{ padding: 15, textAlign: 'left' }}>Rol</th>
              <th style={{ padding: 15, textAlign: 'center' }}>Estado</th>
              <th style={{ padding: 15, textAlign: 'center' }}>Acciones</th>
            </tr>
          </thead>
          <tbody>
            {usuarios.length === 0 ? (
              <tr><td colSpan="6" style={{ padding: 30, textAlign: 'center', color: '#999' }}>No hay usuarios</td></tr>
            ) : (
              usuarios.map((u) => (
                <tr key={u._id || u.id} style={{ borderBottom: '1px solid #eee' }}>
                  <td style={{ padding: 15, fontWeight: 'bold' }}>{u.username}</td>
                  <td style={{ padding: 15 }}>{u.nombre} {u.apellido}</td>
                  <td style={{ padding: 15 }}>{u.email}</td>
                  <td style={{ padding: 15 }}>
                    <span style={{
                      background: u.rol === 'admin' ? '#e74c3c' : u.rol === 'medico' ? '#3498db' : '#27ae60',
                      color: 'white',
                      padding: '4px 10px',
                      borderRadius: 15,
                      fontSize: 12,
                      textTransform: 'uppercase'
                    }}>{u.rol}</span>
                  </td>
                  <td style={{ padding: 15, textAlign: 'center' }}>
                    <span style={{ color: u.activo ? '#27ae60' : '#e74c3c' }}>
                      {u.activo ? '? Activo' : '? Inactivo'}
                    </span>
                  </td>
                  <td style={{ padding: 15, textAlign: 'center' }}>
                    <button onClick={() => handleToggle(u._id || u.id)} style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 18, marginRight: 10 }}>
                      {u.activo ? <FaToggleOn style={{ color: '#27ae60' }} /> : <FaToggleOff style={{ color: '#999' }} />}
                    </button>
                    <button onClick={() => handleResetPassword(u._id || u.id)} style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 16 }}>
                      <FaKey style={{ color: '#f39c12' }} />
                    </button>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {/* Modal */}
      {showModal && (
        <div style={{
          position: 'fixed', top: 0, left: 0, right: 0, bottom: 0,
          background: 'rgba(0,0,0,0.5)', display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 1000
        }}>
          <div style={{ background: 'white', padding: 30, borderRadius: 15, width: '100%', maxWidth: 500 }}>
            <h2 style={{ marginTop: 0 }}>Nuevo Usuario</h2>
            <form onSubmit={handleSubmit}>
              <div style={{ display: 'grid', gap: 15 }}>
                <input 
                  placeholder="Usuario (ej: jperez)" 
                  value={formData.username} 
                  onChange={e => setFormData({...formData, username: e.target.value})} 
                  required 
                  style={{ padding: 12, borderRadius: 8, border: '1px solid #ddd' }} 
                />
                <input 
                  placeholder="Nombre" 
                  value={formData.nombre} 
                  onChange={e => setFormData({...formData, nombre: e.target.value})} 
                  required 
                  style={{ padding: 12, borderRadius: 8, border: '1px solid #ddd' }} 
                />
                <input 
                  placeholder="Apellido" 
                  value={formData.apellido} 
                  onChange={e => setFormData({...formData, apellido: e.target.value})} 
                  required 
                  style={{ padding: 12, borderRadius: 8, border: '1px solid #ddd' }} 
                />
                <input 
                  placeholder="Email" 
                  type="email" 
                  value={formData.email} 
                  onChange={e => setFormData({...formData, email: e.target.value})} 
                  required 
                  style={{ padding: 12, borderRadius: 8, border: '1px solid #ddd' }} 
                />
                <input 
                  placeholder="Contraseña (mínimo 6 caracteres)" 
                  type="password" 
                  value={formData.password} 
                  onChange={e => setFormData({...formData, password: e.target.value})} 
                  required 
                  minLength="6"
                  style={{ padding: 12, borderRadius: 8, border: '1px solid #ddd' }} 
                />
                <select 
                  value={formData.rol} 
                  onChange={e => setFormData({...formData, rol: e.target.value})} 
                  style={{ padding: 12, borderRadius: 8, border: '1px solid #ddd' }}
                >
                  {roles.map(r => (
                    <option key={r.value} value={r.value}>
                      {r.label}
                    </option>
                  ))}
                </select>
              </div>
              <div style={{ display: 'flex', gap: 10, marginTop: 20 }}>
                <button type="submit" style={{ flex: 1, padding: 12, background: '#27ae60', color: 'white', border: 'none', borderRadius: 8, cursor: 'pointer' }}>
                  Crear Usuario
                </button>
                <button type="button" onClick={() => setShowModal(false)} style={{ flex: 1, padding: 12, background: '#ccc', border: 'none', borderRadius: 8, cursor: 'pointer' }}>
                  Cancelar
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default AdminUsuarios;
