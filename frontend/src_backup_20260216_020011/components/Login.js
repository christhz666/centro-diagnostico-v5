import React, { useState } from 'react';
import axios from 'axios';

function Login({ onLogin }) {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');

    if (!username.trim() || !password.trim()) {
      setError('Usuario y contraseña son requeridos');
      return;
    }

    setLoading(true);
    try {
      const res = await axios.post('/api/auth/login', { username: username.trim(), password });
      onLogin(res.data.access_token, res.data.usuario);
    } catch (err) {
      if (err.response?.status === 429) {
        setError('Demasiados intentos. Espere 5 minutos.');
      } else if (err.response?.status === 401) {
        setError('Usuario o contraseña incorrectos');
      } else {
        setError('Error de conexión con el servidor');
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-container">
      <div className="login-card">
        <h2>?? Centro Diagnóstico</h2>
        <p className="subtitle">Sistema de Gestión Integral</p>

        {error && <div className="alert alert-error">{error}</div>}

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label>Usuario</label>
            <input
              type="text"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              placeholder="Ingrese su usuario"
              autoFocus
              autoComplete="username"
              disabled={loading}
            />
          </div>

          <div className="form-group">
            <label>Contraseña</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Ingrese su contraseña"
              autoComplete="current-password"
              disabled={loading}
            />
          </div>

          <button type="submit" className="btn btn-primary" disabled={loading}>
            {loading ? '? Verificando...' : '?? Iniciar Sesión'}
          </button>
        </form>
      </div>
    </div>
  );
}

export default Login;
