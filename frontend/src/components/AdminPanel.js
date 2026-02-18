import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { FaPalette, FaSave, FaSpinner, FaImage, FaBuilding, FaMapMarkerAlt, FaCheckCircle } from 'react-icons/fa';

const API = '/api';

function AdminPanel() {
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState('');
  const [config, setConfig] = useState({
    empresa_nombre: '',
    empresa_direccion: '',
    empresa_telefono: '',
    empresa_rnc: '',
    empresa_email: '',
    logo_factura: '',
    logo_resultados: '',
    logo_login: ''
  });

  const token = localStorage.getItem('token');
  const headers = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };

  useEffect(() => {
    loadConfig();
  }, []);

  const loadConfig = async () => {
    setLoading(true);
    try {
      const res = await axios.get(`${API}/configuracion/`, { headers });
      const data = res.data.configuracion || res.data || {};
      setConfig(prev => ({ ...prev, ...data }));
    } catch (err) {
      console.error('Error cargando configuración:', err);
    } finally {
      setLoading(false);
    }
  };

  const saveConfig = async () => {
    setSaving(true);
    setMessage('');
    try {
      await axios.put(`${API}/configuracion/`, config, { headers });
      setMessage('Configuración guardada exitosamente');
      setTimeout(() => setMessage(''), 3000);
    } catch (err) {
      setMessage('Error al guardar: ' + (err.response?.data?.error || err.message));
    } finally {
      setSaving(false);
    }
  };

  const handleLogoUpload = (field, file) => {
    if (!file) return;
    const reader = new FileReader();
    reader.onloadend = () => {
      setConfig(prev => ({ ...prev, [field]: reader.result }));
    };
    reader.readAsDataURL(file);
  };

  if (loading) {
    return (
      <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '60vh', flexDirection: 'column' }}>
        <FaSpinner className="spin" style={{ fontSize: 40, color: '#3282b8' }} />
        <p style={{ marginTop: 15, color: '#666' }}>Cargando configuración...</p>
      </div>
    );
  }

  return (
    <div style={{ padding: 20, maxWidth: 900, margin: '0 auto' }}>
      <h2 style={{ display: 'flex', alignItems: 'center', gap: 10, color: '#1b262c', marginBottom: 25 }}>
        <FaPalette style={{ color: '#9b59b6' }} /> Personalización del Sistema
      </h2>

      {message && (
        <div style={{
          padding: '12px 20px',
          borderRadius: 8,
          marginBottom: 20,
          background: message.includes('Error') ? '#f8d7da' : '#d4edda',
          color: message.includes('Error') ? '#721c24' : '#155724',
          display: 'flex',
          alignItems: 'center',
          gap: 10
        }}>
          <FaCheckCircle /> {message}
        </div>
      )}

      {/* Datos del Centro */}
      <div style={styles.section}>
        <h3 style={styles.sectionTitle}>
          <FaBuilding style={{ color: '#3282b8' }} /> Datos del Centro
        </h3>
        <div style={styles.formGrid}>
          <div style={styles.formGroup}>
            <label style={styles.label}>Nombre del Centro</label>
            <input
              type="text"
              value={config.empresa_nombre}
              onChange={e => setConfig({ ...config, empresa_nombre: e.target.value })}
              placeholder="Ej: Mi Esperanza Lab"
              style={styles.input}
            />
            <small style={styles.hint}>Aparece en el login, dashboard, facturas y resultados</small>
          </div>
          <div style={styles.formGroup}>
            <label style={styles.label}>RNC</label>
            <input
              type="text"
              value={config.empresa_rnc}
              onChange={e => setConfig({ ...config, empresa_rnc: e.target.value })}
              placeholder="Ej: 131-12345-6"
              style={styles.input}
            />
          </div>
          <div style={styles.formGroup}>
            <label style={styles.label}>Teléfono</label>
            <input
              type="text"
              value={config.empresa_telefono}
              onChange={e => setConfig({ ...config, empresa_telefono: e.target.value })}
              placeholder="Ej: 809-555-1234"
              style={styles.input}
            />
          </div>
          <div style={styles.formGroup}>
            <label style={styles.label}>Email</label>
            <input
              type="email"
              value={config.empresa_email || ''}
              onChange={e => setConfig({ ...config, empresa_email: e.target.value })}
              placeholder="Ej: info@micentro.com"
              style={styles.input}
            />
          </div>
        </div>
        <div style={styles.formGroup}>
          <label style={styles.label}>
            <FaMapMarkerAlt style={{ marginRight: 5 }} /> Dirección del Centro
          </label>
          <textarea
            value={config.empresa_direccion}
            onChange={e => setConfig({ ...config, empresa_direccion: e.target.value })}
            placeholder="Ej: C/ Principal #24, Santo Domingo, Rep. Dom."
            style={{ ...styles.input, minHeight: 60, resize: 'vertical' }}
          />
          <small style={styles.hint}>Aparece en facturas y resultados impresos</small>
        </div>
      </div>

      {/* Logos */}
      <div style={styles.section}>
        <h3 style={styles.sectionTitle}>
          <FaImage style={{ color: '#e67e22' }} /> Logos del Sistema
        </h3>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', gap: 20 }}>
          {/* Logo Facturas */}
          <div style={styles.logoCard}>
            <h4 style={styles.logoTitle}>Logo de Facturas</h4>
            <div style={styles.logoPreview}>
              {config.logo_factura ? (
                <img src={config.logo_factura} alt="Logo Factura" style={styles.logoImg} />
              ) : (
                <div style={styles.logoPlaceholder}><FaImage style={{ fontSize: 40, color: '#ccc' }} /><span>Sin logo</span></div>
              )}
            </div>
            <input
              type="file"
              accept="image/*"
              onChange={e => handleLogoUpload('logo_factura', e.target.files[0])}
              style={styles.fileInput}
              id="logo-factura"
            />
            <label htmlFor="logo-factura" style={styles.uploadBtn}>Seleccionar imagen</label>
            {config.logo_factura && (
              <button onClick={() => setConfig({ ...config, logo_factura: '' })} style={styles.removeBtn}>Quitar</button>
            )}
          </div>

          {/* Logo Resultados */}
          <div style={styles.logoCard}>
            <h4 style={styles.logoTitle}>Logo de Resultados</h4>
            <div style={styles.logoPreview}>
              {config.logo_resultados ? (
                <img src={config.logo_resultados} alt="Logo Resultados" style={styles.logoImg} />
              ) : (
                <div style={styles.logoPlaceholder}><FaImage style={{ fontSize: 40, color: '#ccc' }} /><span>Sin logo</span></div>
              )}
            </div>
            <input
              type="file"
              accept="image/*"
              onChange={e => handleLogoUpload('logo_resultados', e.target.files[0])}
              style={styles.fileInput}
              id="logo-resultados"
            />
            <label htmlFor="logo-resultados" style={styles.uploadBtn}>Seleccionar imagen</label>
            {config.logo_resultados && (
              <button onClick={() => setConfig({ ...config, logo_resultados: '' })} style={styles.removeBtn}>Quitar</button>
            )}
          </div>

          {/* Logo Login */}
          <div style={styles.logoCard}>
            <h4 style={styles.logoTitle}>Logo de Inicio de Sesión</h4>
            <div style={styles.logoPreview}>
              {config.logo_login ? (
                <img src={config.logo_login} alt="Logo Login" style={styles.logoImg} />
              ) : (
                <div style={styles.logoPlaceholder}><FaImage style={{ fontSize: 40, color: '#ccc' }} /><span>Sin logo</span></div>
              )}
            </div>
            <input
              type="file"
              accept="image/*"
              onChange={e => handleLogoUpload('logo_login', e.target.files[0])}
              style={styles.fileInput}
              id="logo-login"
            />
            <label htmlFor="logo-login" style={styles.uploadBtn}>Seleccionar imagen</label>
            {config.logo_login && (
              <button onClick={() => setConfig({ ...config, logo_login: '' })} style={styles.removeBtn}>Quitar</button>
            )}
          </div>
        </div>
      </div>

      {/* Save Button */}
      <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: 20 }}>
        <button
          onClick={saveConfig}
          disabled={saving}
          style={{
            padding: '14px 35px',
            background: saving ? '#a0aec0' : 'linear-gradient(135deg, #27ae60, #2ecc71)',
            color: 'white',
            border: 'none',
            borderRadius: 10,
            cursor: saving ? 'not-allowed' : 'pointer',
            fontSize: 16,
            fontWeight: 'bold',
            display: 'flex',
            alignItems: 'center',
            gap: 10,
            boxShadow: '0 4px 15px rgba(39,174,96,0.3)'
          }}
        >
          {saving ? <FaSpinner className="spin" /> : <FaSave />}
          {saving ? 'Guardando...' : 'Guardar Configuración'}
        </button>
      </div>
    </div>
  );
}

const styles = {
  section: {
    background: 'white',
    borderRadius: 12,
    padding: 25,
    marginBottom: 20,
    boxShadow: '0 2px 10px rgba(0,0,0,0.05)'
  },
  sectionTitle: {
    margin: '0 0 20px',
    color: '#1b262c',
    fontSize: 18,
    display: 'flex',
    alignItems: 'center',
    gap: 10
  },
  formGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
    gap: 15,
    marginBottom: 15
  },
  formGroup: {
    marginBottom: 10
  },
  label: {
    display: 'block',
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 5,
    fontSize: 14
  },
  input: {
    width: '100%',
    padding: '10px 12px',
    border: '2px solid #e2e8f0',
    borderRadius: 8,
    fontSize: 14,
    outline: 'none',
    transition: 'border-color 0.3s',
    boxSizing: 'border-box'
  },
  hint: {
    fontSize: 12,
    color: '#999',
    marginTop: 4,
    display: 'block'
  },
  logoCard: {
    background: '#f8f9fa',
    borderRadius: 10,
    padding: 20,
    textAlign: 'center',
    border: '2px dashed #ddd'
  },
  logoTitle: {
    margin: '0 0 12px',
    color: '#333',
    fontSize: 14
  },
  logoPreview: {
    width: '100%',
    height: 120,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 12,
    background: 'white',
    borderRadius: 8,
    overflow: 'hidden'
  },
  logoImg: {
    maxWidth: '100%',
    maxHeight: '100%',
    objectFit: 'contain'
  },
  logoPlaceholder: {
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    gap: 8,
    color: '#999',
    fontSize: 13
  },
  fileInput: {
    display: 'none'
  },
  uploadBtn: {
    display: 'inline-block',
    padding: '8px 16px',
    background: '#3282b8',
    color: 'white',
    borderRadius: 6,
    cursor: 'pointer',
    fontSize: 13,
    fontWeight: 'bold'
  },
  removeBtn: {
    display: 'inline-block',
    padding: '6px 12px',
    background: 'none',
    color: '#e74c3c',
    border: '1px solid #e74c3c',
    borderRadius: 6,
    cursor: 'pointer',
    fontSize: 12,
    marginLeft: 8,
    marginTop: 5
  }
};

export default AdminPanel;
