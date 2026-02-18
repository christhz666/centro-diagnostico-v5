import React, { useState } from 'react';
import axios from 'axios';

const API_URL = 'http://192.9.135.84:5000/api';

function PortalPaciente() {
  const [autenticado, setAutenticado] = useState(false);
  const [paciente, setPaciente] = useState(null);
  const [loginForm, setLoginForm] = useState({ usuario: '', password: '' });

  const login = async (e) => {
    e.preventDefault();
    try {
      const response = await axios.post(`${API_URL}/portal-paciente/login`, loginForm);
      setPaciente(response.data.paciente);
      setAutenticado(true);
    } catch (err) {
      alert('Credenciales inválidas');
    }
  };

  if (!autenticado) {
    return (
      <div className="portal-login">
        <h1>?? Portal del Paciente</h1>
        <form onSubmit={login}>
          <input
            type="text"
            placeholder="Usuario"
            value={loginForm.usuario}
            onChange={(e) => setLoginForm({...loginForm, usuario: e.target.value})}
            required
          />
          <input
            type="password"
            placeholder="Contraseña"
            value={loginForm.password}
            onChange={(e) => setLoginForm({...loginForm, password: e.target.value})}
            required
          />
          <button type="submit">Ingresar</button>
        </form>
      </div>
    );
  }

  return (
    <div className="portal-paciente">
      <h1>Bienvenido/a {paciente.nombre}</h1>
      <p>Código: {paciente.codigo}</p>
      <div className="alert alert-info">
        Portal del paciente en desarrollo
      </div>
    </div>
  );
}

export default PortalPaciente;
