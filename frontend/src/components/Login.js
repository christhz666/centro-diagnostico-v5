import React, { useState, useEffect } from 'react';
import { FaUser, FaLock } from 'react-icons/fa';
import api from '../services/api';

const Login = ({ onLogin }) => {
    const [username, setUsername] = useState('');
    const [password, setPassword] = useState('');
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [empresaConfig, setEmpresaConfig] = useState({});

    useEffect(() => {
        // Load public company info for the login screen
        fetch('/api/configuracion/empresa')
            .then(res => res.json())
            .then(data => setEmpresaConfig(data))
            .catch(() => {});
    }, []);

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');
        setLoading(true);

        try {
            const data = await api.login({ username, password });
            if (data.access_token) {
                localStorage.setItem('token', data.access_token);
                localStorage.setItem('user', JSON.stringify(data.usuario));
                window.location.href = '/';
                onLogin(data.usuario, data.access_token);
            }
        } catch (err) {
            setError('Usuario o contraseña incorrectos');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div style={{
            minHeight: '100vh',
            background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            padding: '20px'
        }}>
            <div style={{
                background: 'white',
                borderRadius: '20px',
                boxShadow: '0 20px 60px rgba(0,0,0,0.3)',
                overflow: 'hidden',
                maxWidth: '900px',
                width: '100%',
                display: 'flex'
            }}>
                <div style={{
                    flex: '1',
                    background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                    padding: '60px 40px',
                    color: 'white',
                    display: 'flex',
                    flexDirection: 'column',
                    justifyContent: 'center'
                }}>
                    <div style={{textAlign: 'center', marginBottom: '30px'}}>
                        <img 
                            src={empresaConfig.logo_login || "/logo-centro.png"}
                            alt={empresaConfig.nombre || "Centro Diagnóstico"}
                            style={{
                                maxWidth: '100%', 
                                height: 'auto', 
                                marginBottom: '20px',
                                filter: 'brightness(1.2)'
                            }}
                            onError={(e) => {
                                e.target.onerror = null;
                                e.target.src = "/logo-centro.png";
                            }}
                        />
                        {empresaConfig.nombre && (
                            <h2 style={{ color: 'white', margin: '10px 0 0', fontSize: '22px' }}>
                                {empresaConfig.nombre}
                            </h2>
                        )}
                    </div>
                    <div style={{marginTop: '30px'}}>
                        <p style={{fontSize: '16px', lineHeight: '1.6', opacity: 0.9}}>
                            Sistema integral de gestión médica para centros de diagnóstico.
                        </p>
                    </div>
                </div>

                <div style={{flex: '1', padding: '60px 40px'}}>
                    <div style={{marginBottom: '40px'}}>
                        <h2 style={{fontSize: '28px', fontWeight: '700', color: '#2d3748', marginBottom: '10px'}}>
                            Iniciar Sesión
                        </h2>
                        <p style={{color: '#718096'}}>Ingresa tus credenciales</p>
                    </div>

                    <form onSubmit={handleSubmit}>
                        <div style={{marginBottom: '25px'}}>
                            <label style={{display: 'block', marginBottom: '8px', color: '#4a5568', fontWeight: '600'}}>
                                <FaUser style={{marginRight: '8px'}}/>
                                Usuario
                            </label>
                            <input
                                type="text"
                                placeholder="Ingresa tu usuario"
                                value={username}
                                onChange={(e) => setUsername(e.target.value)}
                                required
                                style={{
                                    width: '100%',
                                    padding: '12px 15px',
                                    border: '2px solid #e2e8f0',
                                    borderRadius: '10px',
                                    fontSize: '16px',
                                    transition: 'all 0.3s',
                                    outline: 'none'
                                }}
                            />
                        </div>

                        <div style={{marginBottom: '30px'}}>
                            <label style={{display: 'block', marginBottom: '8px', color: '#4a5568', fontWeight: '600'}}>
                                <FaLock style={{marginRight: '8px'}}/>
                                Contraseña
                            </label>
                            <input
                                type="password"
                                placeholder="Ingresa tu contraseña"
                                value={password}
                                onChange={(e) => setPassword(e.target.value)}
                                required
                                style={{
                                    width: '100%',
                                    padding: '12px 15px',
                                    border: '2px solid #e2e8f0',
                                    borderRadius: '10px',
                                    fontSize: '16px',
                                    transition: 'all 0.3s',
                                    outline: 'none'
                                }}
                            />
                        </div>

                        {error && (
                            <div style={{
                                padding: '12px',
                                background: '#fed7d7',
                                color: '#c53030',
                                borderRadius: '10px',
                                marginBottom: '20px',
                                fontSize: '14px'
                            }}>
                                {error}
                            </div>
                        )}

                        <button
                            type="submit"
                            disabled={loading}
                            style={{
                                width: '100%',
                                padding: '14px',
                                background: loading ? '#a0aec0' : 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                                color: 'white',
                                border: 'none',
                                borderRadius: '10px',
                                fontSize: '16px',
                                fontWeight: '600',
                                cursor: loading ? 'not-allowed' : 'pointer',
                                transition: 'all 0.3s'
                            }}
                        >
                            {loading ? 'Iniciando...' : 'Iniciar Sesión'}
                        </button>
                    </form>

                    <div style={{marginTop: '30px', textAlign: 'center'}}>
                        <p style={{color: '#718096', fontSize: '14px', marginBottom: '10px'}}>Credenciales de prueba:</p>
                        <p style={{margin: '5px 0 0', fontSize: '12px', fontFamily: 'monospace', color: '#4a5568'}}>
                            admin / admin123
                        </p>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default Login;
