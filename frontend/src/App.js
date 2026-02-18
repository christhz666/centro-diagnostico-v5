import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate, Link } from 'react-router-dom';
import './App.css';

import { 
  FaHeartbeat, FaChartPie, FaPlusCircle, FaFileInvoiceDollar, 
  FaUserMd, FaCogs, FaSignOutAlt, FaBars, FaTimes, FaUsers, 
  FaFlask, FaClipboardList, FaBarcode, FaChevronDown, FaChevronRight,
  FaBalanceScale, FaPalette
} from 'react-icons/fa';

import Login from './components/Login';
import Dashboard from './components/Dashboard';
import RegistroInteligente from './components/RegistroInteligente';
import Facturas from './components/Facturas';
import PortalMedico from './components/PortalMedico';
import AdminPanel from './components/AdminPanel';
import AdminUsuarios from './components/AdminUsuarios';
import GestionEstudios from './components/GestionEstudios';
import Resultados from './components/Resultados';
import ConsultaRapida from './components/ConsultaRapida';
import AdminEquipos from './components/AdminEquipos';
import Contabilidad from './components/Contabilidad';

function App() {
  const [user, setUser] = useState(null);
  const [token, setToken] = useState(null);
  const [loading, setLoading] = useState(true);
  const [sidebarOpen, setSidebarOpen] = useState(window.innerWidth > 768);
  const [isMobile, setIsMobile] = useState(window.innerWidth <= 768);
  const [adminMenuOpen, setAdminMenuOpen] = useState(false);
  const [empresaNombre, setEmpresaNombre] = useState('');

  useEffect(() => {
    const handleResize = () => {
      const mobile = window.innerWidth <= 768;
      setIsMobile(mobile);
      if (mobile) {
        setSidebarOpen(false);
      }
    };
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  useEffect(() => {
    const savedToken = localStorage.getItem('token');
    const savedUser = localStorage.getItem('user');
    
    if (savedToken && savedUser) {
      try {
        setToken(savedToken);
        setUser(JSON.parse(savedUser));
      } catch (e) {
        localStorage.removeItem('token');
        localStorage.removeItem('user');
      }
    }
    setLoading(false);
  }, []);

  useEffect(() => {
    fetch('/api/configuracion/empresa')
      .then(res => res.json())
      .then(data => { if (data.nombre) setEmpresaNombre(data.nombre); })
      .catch(() => {});
  }, []);

  const handleLogin = (userData, userToken) => {
    localStorage.setItem('token', userToken);
    localStorage.setItem('user', JSON.stringify(userData));
    setToken(userToken);
    setUser(userData);
  };

  const handleLogout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    setUser(null);
    setToken(null);
  };

  if (loading) {
    return (
      <div style={{
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
        height: '100vh',
        background: '#1b262c'
      }}>
        <FaHeartbeat style={{ fontSize: 60, color: '#e74c3c', animation: 'pulse 1s infinite' }} />
      </div>
    );
  }

  if (!user || !token) {
    return <Login onLogin={handleLogin} />;
  }

  const menuItems = [
    { path: '/', icon: <FaChartPie />, label: 'Dashboard', roles: ['admin', 'medico', 'recepcion', 'laboratorio'] },
    { path: '/registro', icon: <FaPlusCircle />, label: 'Nuevo Registro', roles: ['admin', 'recepcion'] },
    { path: '/consulta', icon: <FaBarcode />, label: 'Consulta Rápida', roles: ['admin', 'recepcion', 'laboratorio'] },
    { path: '/facturas', icon: <FaFileInvoiceDollar />, label: 'Facturas', roles: ['admin', 'recepcion'] },
    { path: '/medico', icon: <FaUserMd />, label: 'Portal Médico', roles: ['admin', 'medico'] },
    { path: '/resultados', icon: <FaFlask />, label: 'Resultados', roles: ['admin', 'medico', 'laboratorio'] },
  ];

  const adminSubItems = [
    { path: '/admin', icon: <FaPalette />, label: 'Personalización', roles: ['admin'] },
    { path: '/admin/usuarios', icon: <FaUsers />, label: 'Usuarios', roles: ['admin'] },
    { path: '/admin/equipos', icon: <FaCogs />, label: 'Equipos', roles: ['admin'] },
    { path: '/admin/estudios', icon: <FaClipboardList />, label: 'Catálogo Estudios', roles: ['admin'] },
    { path: '/contabilidad', icon: <FaBalanceScale />, label: 'Contabilidad', roles: ['admin'] },
  ];

  const filteredMenu = menuItems.filter(item => item.roles.includes(user.rol));
  const filteredAdminSub = adminSubItems.filter(item => item.roles.includes(user.rol));
  const showAdminMenu = filteredAdminSub.length > 0;

  return (
    <Router>
      <div style={{ display: 'flex', minHeight: '100vh' }}>
        {/* Mobile overlay */}
        {sidebarOpen && isMobile && (
          <div
            className="sidebar-overlay"
            onClick={() => setSidebarOpen(false)}
          />
        )}
        <aside className={`app-sidebar${sidebarOpen ? ' open' : ''}`} style={{
          width: sidebarOpen ? '250px' : '70px',
          background: 'linear-gradient(180deg, #1b262c 0%, #0f4c75 100%)',
          transition: 'width 0.3s, transform 0.3s',
          position: 'fixed',
          height: '100vh',
          zIndex: 1000,
          boxShadow: '2px 0 10px rgba(0,0,0,0.2)',
          overflowY: 'auto'
        }}>
          <div style={{
            padding: '20px',
            borderBottom: '1px solid rgba(255,255,255,0.1)',
            display: 'flex',
            alignItems: 'center',
            gap: '10px'
          }}>
            <FaHeartbeat style={{ fontSize: 30, color: '#e74c3c' }} />
            {sidebarOpen && <span style={{ color: 'white', fontWeight: 'bold' }}>{empresaNombre || 'Mi Esperanza'}</span>}
          </div>

          <nav style={{ padding: '10px 0' }}>
            {filteredMenu.map((item, index) => (
              <Link
                key={index}
                to={item.path}
                onClick={() => { if (isMobile) setSidebarOpen(false); }}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '12px',
                  padding: '12px 20px',
                  color: 'rgba(255,255,255,0.8)',
                  textDecoration: 'none',
                  transition: 'all 0.2s'
                }}
                onMouseEnter={(e) => {
                  e.currentTarget.style.background = 'rgba(255,255,255,0.1)';
                  e.currentTarget.style.color = 'white';
                }}
                onMouseLeave={(e) => {
                  e.currentTarget.style.background = 'transparent';
                  e.currentTarget.style.color = 'rgba(255,255,255,0.8)';
                }}
              >
                <span style={{ fontSize: 18 }}>{item.icon}</span>
                {sidebarOpen && <span className="sidebar-label">{item.label}</span>}
              </Link>
            ))}

            {/* Admin Panel Dropdown */}
            {showAdminMenu && (
              <>
                <div
                  onClick={() => setAdminMenuOpen(!adminMenuOpen)}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '12px',
                    padding: '12px 20px',
                    color: 'rgba(255,255,255,0.8)',
                    cursor: 'pointer',
                    transition: 'all 0.2s',
                    borderTop: '1px solid rgba(255,255,255,0.1)',
                    marginTop: '5px'
                  }}
                  onMouseEnter={(e) => {
                    e.currentTarget.style.background = 'rgba(255,255,255,0.1)';
                    e.currentTarget.style.color = 'white';
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.background = 'transparent';
                    e.currentTarget.style.color = 'rgba(255,255,255,0.8)';
                  }}
                >
                  <span style={{ fontSize: 18 }}><FaCogs /></span>
                  {sidebarOpen && (
                    <>
                      <span className="sidebar-label" style={{ flex: 1 }}>Admin Panel</span>
                      <span style={{ fontSize: 12 }}>
                        {adminMenuOpen ? <FaChevronDown /> : <FaChevronRight />}
                      </span>
                    </>
                  )}
                </div>
                {adminMenuOpen && sidebarOpen && filteredAdminSub.map((item, index) => (
                  <Link
                    key={`admin-${index}`}
                    to={item.path}
                    onClick={() => { if (isMobile) setSidebarOpen(false); }}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: '12px',
                      padding: '10px 20px 10px 40px',
                      color: 'rgba(255,255,255,0.7)',
                      textDecoration: 'none',
                      transition: 'all 0.2s',
                      fontSize: '14px'
                    }}
                    onMouseEnter={(e) => {
                      e.currentTarget.style.background = 'rgba(255,255,255,0.08)';
                      e.currentTarget.style.color = 'white';
                    }}
                    onMouseLeave={(e) => {
                      e.currentTarget.style.background = 'transparent';
                      e.currentTarget.style.color = 'rgba(255,255,255,0.7)';
                    }}
                  >
                    <span style={{ fontSize: 15 }}>{item.icon}</span>
                    <span className="sidebar-label">{item.label}</span>
                  </Link>
                ))}
              </>
            )}
          </nav>

          <div style={{ position: 'absolute', bottom: 20, left: 0, right: 0, padding: '0 20px' }}>
            <button
              onClick={handleLogout}
              style={{
                width: '100%',
                padding: '12px',
                background: 'rgba(231,76,60,0.2)',
                border: '1px solid #e74c3c',
                borderRadius: '8px',
                color: '#e74c3c',
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: '8px'
              }}
            >
              <FaSignOutAlt />
              {sidebarOpen && 'Cerrar Sesión'}
            </button>
          </div>
        </aside>

        <main className="app-main" style={{
          flex: 1,
          marginLeft: sidebarOpen ? '250px' : '70px',
          transition: 'margin-left 0.3s',
          background: '#f5f6fa',
          minHeight: '100vh'
        }}>
          <header className="app-header" style={{
            background: 'white',
            padding: '15px 25px',
            boxShadow: '0 2px 10px rgba(0,0,0,0.05)',
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center'
          }}>
            <button
              onClick={() => setSidebarOpen(!sidebarOpen)}
              style={{
                background: 'none',
                border: 'none',
                fontSize: '20px',
                cursor: 'pointer',
                color: '#1b262c'
              }}
            >
              {sidebarOpen ? <FaTimes /> : <FaBars />}
            </button>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
              <span style={{ color: '#666' }}>Hola, <strong>{user.nombre}</strong></span>
              <span style={{
                background: '#3282b8',
                color: 'white',
                padding: '4px 10px',
                borderRadius: '15px',
                fontSize: '12px',
                textTransform: 'uppercase'
              }}>{user.rol}</span>
            </div>
          </header>

          <div className="content-area" style={{ padding: '25px' }}>
            <Routes>
              <Route path="/" element={<Dashboard />} />
              <Route path="/registro" element={<RegistroInteligente />} />
              <Route path="/consulta" element={<ConsultaRapida />} />
              <Route path="/facturas" element={<Facturas />} />
              <Route path="/medico" element={<PortalMedico />} />
              <Route path="/admin" element={<AdminPanel />} />
              <Route path="/admin/usuarios" element={<AdminUsuarios />} />
              <Route path="/admin/equipos" element={<AdminEquipos />} />
              <Route path="/admin/estudios" element={<GestionEstudios />} />
              <Route path="/contabilidad" element={<Contabilidad />} />
              <Route path="/resultados" element={<Resultados />} />
              <Route path="/login" element={<Navigate to="/" />} />
              <Route path="*" element={<Navigate to="/" />} />
            </Routes>
          </div>
        </main>
      </div>
    </Router>
  );
}

export default App;
