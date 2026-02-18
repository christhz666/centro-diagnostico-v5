import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate, Link, useLocation } from 'react-router-dom';
import './App.css';

// Iconos
import { 
  FaHospital, 
  FaChartLine, 
  FaPlusCircle, 
  FaFileInvoice, 
  FaUserMd, 
  FaCogs, 
  FaSignOutAlt,
  FaBars,
  FaTimes,
  FaUserCircle
} from 'react-icons/fa';

import Login from './components/Login';
import Dashboard from './components/Dashboard';
import RegistroInteligente from './components/RegistroInteligente';
import Facturas from './components/Facturas';
import PortalMedico from './components/PortalMedico';
import AdminPanel from './components/AdminPanel';
import Perfil from './components/Perfil';
import BuscadorPacientes from './components/BuscadorPacientes';
import FormularioPaciente from './components/FormularioPaciente';
import FormularioOrden from './components/FormularioOrden';
import CrearFacturaCompleta from './components/CrearFacturaCompleta';

function NavBar({ user, onLogout }) {
  const [menuOpen, setMenuOpen] = useState(false);
  const location = useLocation();
  const isActive = (path) => location.pathname === path ? 'nav-link active' : 'nav-link';

  return (
    <nav className="navbar">
      <div className="nav-container">
        <Link to="/" className="nav-brand">
          <FaHospital style={{marginRight:'8px', marginBottom:'-2px'}}/> 
          Centro Diagnóstico
        </Link>

        <button className="nav-toggle" onClick={() => setMenuOpen(!menuOpen)}>
          {menuOpen ? <FaTimes /> : <FaBars />}
        </button>

        <div className={`nav-menu ${menuOpen ? 'nav-open' : ''}`}>
          <Link to="/" className={isActive('/')} onClick={() => setMenuOpen(false)}>
            <FaChartLine className="nav-icon"/> Inicio
          </Link>
          <Link to="/registro" className={isActive('/registro')} onClick={() => setMenuOpen(false)}>
            <FaPlusCircle className="nav-icon"/> Registro
          </Link>
          <Link to="/facturas" className={isActive('/facturas')} onClick={() => setMenuOpen(false)}>
            <FaFileInvoice className="nav-icon"/> Facturas
          </Link>
          <Link to="/portal-medico" className={isActive('/portal-medico')} onClick={() => setMenuOpen(false)}>
            <FaUserMd className="nav-icon"/> Médico
          </Link>
          
          {user?.rol === 'admin' && (
            <Link to="/admin" className={isActive('/admin')} onClick={() => setMenuOpen(false)}>
              <FaCogs className="nav-icon"/> Admin
            </Link>
          )}
          
          <div className="nav-user-section">
            <Link to="/perfil" className="nav-user" onClick={() => setMenuOpen(false)}>
              <FaUserCircle style={{marginRight:'5px'}}/> {user?.username}
            </Link>
            <button onClick={onLogout} className="btn-logout">
              <FaSignOutAlt /> Salir
            </button>
          </div>
        </div>
      </div>
    </nav>
  );
}

function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [user, setUser] = useState(null);

  useEffect(() => {
    const token = localStorage.getItem('token');
    const userData = localStorage.getItem('user');
    if (token && userData) {
      setIsAuthenticated(true);
      try { setUser(JSON.parse(userData)); } catch(e) { handleLogout(); }
    }
  }, []);

  const handleLogin = (token, userData) => {
    localStorage.setItem('token', token);
    localStorage.setItem('user', JSON.stringify(userData));
    setIsAuthenticated(true);
    setUser(userData);
  };

  const handleLogout = () => {
    localStorage.clear();
    setIsAuthenticated(false);
    setUser(null);
  };

  // Componente para rutas protegidas
  const ProtectedRoute = ({ children, adminOnly = false }) => {
    if (!isAuthenticated) return <Navigate to="/login" />;
    if (adminOnly && user?.rol !== 'admin') return <Navigate to="/" />;
    return children;
  };

  return (
    <Router>
      <div className="App">
        {isAuthenticated && <NavBar user={user} onLogout={handleLogout} />}
        <Routes>
          <Route path="/login" element={!isAuthenticated ? <Login onLogin={handleLogin} /> : <Navigate to="/" />} />
          
          {/* Rutas Protegidas */}
          <Route path="/" element={<ProtectedRoute><Dashboard user={user} /></ProtectedRoute>} />
          <Route path="/registro" element={<ProtectedRoute><RegistroInteligente /></ProtectedRoute>} />
          <Route path="/facturas" element={<ProtectedRoute><Facturas /></ProtectedRoute>} />
          <Route path="/portal-medico" element={<ProtectedRoute><PortalMedico /></ProtectedRoute>} />
          <Route path="/admin" element={<ProtectedRoute adminOnly><AdminPanel user={user} /></ProtectedRoute>} />
          <Route path="/perfil" element={<ProtectedRoute><Perfil user={user} /></ProtectedRoute>} />
          
          {/* Rutas legacy/específicas */}
          <Route path="/buscar" element={<ProtectedRoute><BuscadorPacientes /></ProtectedRoute>} />
          <Route path="/nuevo-paciente" element={<ProtectedRoute><FormularioPaciente /></ProtectedRoute>} />
          <Route path="/nueva-orden" element={<ProtectedRoute><FormularioOrden /></ProtectedRoute>} />
          <Route path="/crear-factura" element={<ProtectedRoute><CrearFacturaCompleta /></ProtectedRoute>} />
          <Route path="/crear-factura/:ordenId" element={<ProtectedRoute><CrearFacturaCompleta /></ProtectedRoute>} />

          <Route path="*" element={<Navigate to="/" />} />
        </Routes>
      </div>
    </Router>
  );
}

export default App;
