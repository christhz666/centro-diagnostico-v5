import React, { useState, useEffect } from 'react';
import { FaWindows, FaApple, FaLinux, FaDownload, FaNetworkWired, FaDesktop, FaEye, FaRocket, FaCheckCircle } from 'react-icons/fa';

const DescargarApp = () => {
  const [downloadInfo, setDownloadInfo] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const colores = {
    primary: '#1a3a5c',
    secondary: '#87CEEB',
    success: '#28a745',
    light: '#f0f8ff'
  };

  useEffect(() => {
    fetchDownloadInfo();
  }, []);

  const fetchDownloadInfo = async () => {
    try {
      const response = await fetch('/api/downloads/info');
      const data = await response.json();
      
      if (data.success) {
        setDownloadInfo(data);
      } else {
        setError('No se pudo obtener información de descargas');
      }
    } catch (err) {
      console.error('Error fetching download info:', err);
      setError('Error al conectar con el servidor');
    } finally {
      setLoading(false);
    }
  };

  const getPlatformIcon = (platform) => {
    switch (platform) {
      case 'windows':
        return <FaWindows />;
      case 'mac':
        return <FaApple />;
      case 'linux':
        return <FaLinux />;
      default:
        return <FaDesktop />;
    }
  };

  const getPlatformName = (platform) => {
    switch (platform) {
      case 'windows':
        return 'Windows';
      case 'mac':
        return 'macOS';
      case 'linux':
        return 'Linux';
      default:
        return platform;
    }
  };

  const handleDownload = (platform) => {
    window.location.href = `/api/downloads/${platform}`;
  };

  const features = [
    {
      icon: <FaNetworkWired />,
      title: 'Escaneo de Red Local',
      description: 'Detecta automáticamente todos los equipos médicos en tu red LAN'
    },
    {
      icon: <FaRocket />,
      title: 'Deploy de Agentes',
      description: 'Instala y gestiona agentes en PCs del laboratorio de forma remota'
    },
    {
      icon: <FaEye />,
      title: 'Monitoreo en Tiempo Real',
      description: 'Supervisa el estado de los equipos médicos conectados'
    },
    {
      icon: <FaDesktop />,
      title: 'Sin Navegador',
      description: 'Aplicación nativa que no requiere conexión a internet constante'
    },
    {
      icon: <FaCheckCircle />,
      title: 'Auto-detección',
      description: 'Identifica automáticamente los equipos compatibles en la red'
    }
  ];

  return (
    <div style={{ padding: '20px', backgroundColor: colores.light, minHeight: '100vh' }}>
      {/* Header */}
      <div style={{
        background: `linear-gradient(135deg, ${colores.primary} 0%, ${colores.secondary} 100%)`,
        padding: '40px',
        borderRadius: '10px',
        marginBottom: '30px',
        color: 'white',
        textAlign: 'center'
      }}>
        <FaDownload style={{ fontSize: '60px', marginBottom: '20px' }} />
        <h1 style={{ margin: '0 0 15px 0', fontSize: '36px' }}>
          Descargar Aplicación de Escritorio
        </h1>
        <p style={{ margin: 0, fontSize: '18px', opacity: 0.9 }}>
          Accede a todas las funcionalidades del Centro Diagnóstico, incluyendo el deploy de agentes en red local
        </p>
        {downloadInfo && (
          <p style={{ margin: '15px 0 0 0', fontSize: '14px', opacity: 0.8 }}>
            Versión {downloadInfo.version}
          </p>
        )}
      </div>

      {/* Mensaje informativo */}
      <div style={{
        backgroundColor: '#fff3cd',
        border: '1px solid #ffc107',
        borderRadius: '10px',
        padding: '20px',
        marginBottom: '30px',
        color: '#856404'
      }}>
        <h3 style={{ marginTop: 0, display: 'flex', alignItems: 'center', gap: '10px' }}>
          ℹ️ ¿Por qué descargar la aplicación?
        </h3>
        <p style={{ marginBottom: 0 }}>
          La funcionalidad de <strong>Deploy de Agentes</strong> requiere acceso a la red local del laboratorio 
          para escanear y gestionar equipos. Esta funcionalidad solo está disponible en la aplicación de escritorio, 
          no en la versión web.
        </p>
      </div>

      {/* Tarjetas de descarga */}
      <div style={{
        backgroundColor: 'white',
        borderRadius: '10px',
        padding: '30px',
        marginBottom: '30px',
        boxShadow: '0 2px 4px rgba(0,0,0,0.1)'
      }}>
        <h2 style={{ marginTop: 0, color: colores.primary, textAlign: 'center' }}>
          Selecciona tu Plataforma
        </h2>

        {loading ? (
          <div style={{ textAlign: 'center', padding: '40px', color: '#666' }}>
            <p>Cargando información de descargas...</p>
          </div>
        ) : error ? (
          <div style={{ textAlign: 'center', padding: '40px', color: '#dc3545' }}>
            <p>{error}</p>
          </div>
        ) : downloadInfo && downloadInfo.platforms.length === 0 ? (
          <div style={{
            textAlign: 'center',
            padding: '40px',
            backgroundColor: '#f8d7da',
            borderRadius: '10px',
            color: '#721c24',
            border: '1px solid #f5c6cb'
          }}>
            <h3>No hay instaladores disponibles</h3>
            <p>Los archivos de instalación aún no han sido cargados al servidor.</p>
            <p style={{ fontSize: '14px', marginTop: '15px' }}>
              Contacte al administrador del sistema para más información.
            </p>
          </div>
        ) : (
          <div style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))',
            gap: '20px',
            marginTop: '30px'
          }}>
            {['windows', 'mac', 'linux'].map((platform) => {
              const platformData = downloadInfo.platforms.find(p => p.platform === platform);
              const available = !!platformData;

              return (
                <div
                  key={platform}
                  style={{
                    border: `2px solid ${available ? colores.primary : '#ddd'}`,
                    borderRadius: '10px',
                    padding: '25px',
                    textAlign: 'center',
                    backgroundColor: available ? 'white' : '#f8f8f8',
                    opacity: available ? 1 : 0.6,
                    transition: 'all 0.3s'
                  }}
                >
                  <div style={{
                    fontSize: '60px',
                    color: available ? colores.primary : '#999',
                    marginBottom: '15px'
                  }}>
                    {getPlatformIcon(platform)}
                  </div>
                  <h3 style={{ margin: '0 0 10px 0', color: colores.primary }}>
                    {getPlatformName(platform)}
                  </h3>
                  {available ? (
                    <>
                      <p style={{ color: '#666', fontSize: '14px', margin: '0 0 15px 0' }}>
                        Tamaño: {platformData.sizeFormatted}
                      </p>
                      <button
                        onClick={() => handleDownload(platform)}
                        style={{
                          padding: '12px 24px',
                          backgroundColor: colores.primary,
                          color: 'white',
                          border: 'none',
                          borderRadius: '5px',
                          cursor: 'pointer',
                          fontSize: '16px',
                          fontWeight: 'bold',
                          display: 'inline-flex',
                          alignItems: 'center',
                          gap: '10px',
                          width: '100%',
                          justifyContent: 'center',
                          transition: 'background-color 0.3s'
                        }}
                        onMouseEnter={(e) => e.currentTarget.style.backgroundColor = colores.secondary}
                        onMouseLeave={(e) => e.currentTarget.style.backgroundColor = colores.primary}
                      >
                        <FaDownload /> Descargar
                      </button>
                    </>
                  ) : (
                    <p style={{ color: '#999', fontSize: '14px', margin: '15px 0 0 0' }}>
                      No disponible
                    </p>
                  )}
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Características de la Desktop App */}
      <div style={{
        backgroundColor: 'white',
        borderRadius: '10px',
        padding: '30px',
        marginBottom: '30px',
        boxShadow: '0 2px 4px rgba(0,0,0,0.1)'
      }}>
        <h2 style={{ marginTop: 0, color: colores.primary, textAlign: 'center', marginBottom: '30px' }}>
          Características de la Aplicación de Escritorio
        </h2>
        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))',
          gap: '25px'
        }}>
          {features.map((feature, index) => (
            <div
              key={index}
              style={{
                display: 'flex',
                gap: '15px',
                padding: '20px',
                border: `1px solid ${colores.secondary}`,
                borderRadius: '10px',
                backgroundColor: colores.light
              }}
            >
              <div style={{
                fontSize: '30px',
                color: colores.primary,
                flexShrink: 0
              }}>
                {feature.icon}
              </div>
              <div>
                <h4 style={{ margin: '0 0 8px 0', color: colores.primary }}>
                  {feature.title}
                </h4>
                <p style={{ margin: 0, fontSize: '14px', color: '#666' }}>
                  {feature.description}
                </p>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Instrucciones de instalación */}
      <div style={{
        backgroundColor: 'white',
        borderRadius: '10px',
        padding: '30px',
        boxShadow: '0 2px 4px rgba(0,0,0,0.1)'
      }}>
        <h2 style={{ marginTop: 0, color: colores.primary }}>
          Instrucciones de Instalación
        </h2>

        <div style={{ marginTop: '20px' }}>
          <h3 style={{ color: colores.primary, display: 'flex', alignItems: 'center', gap: '10px' }}>
            <FaWindows /> Windows
          </h3>
          <ol style={{ lineHeight: '1.8' }}>
            <li>Descarga el archivo <code>.exe</code></li>
            <li>Ejecuta el instalador (puede requerir permisos de administrador)</li>
            <li>Sigue las instrucciones del asistente de instalación</li>
            <li>Una vez instalado, ejecuta la aplicación desde el menú de inicio</li>
          </ol>

          <h3 style={{ color: colores.primary, display: 'flex', alignItems: 'center', gap: '10px', marginTop: '25px' }}>
            <FaApple /> macOS
          </h3>
          <ol style={{ lineHeight: '1.8' }}>
            <li>Descarga el archivo <code>.dmg</code></li>
            <li>Abre el archivo DMG descargado</li>
            <li>Arrastra el icono de la aplicación a la carpeta de Aplicaciones</li>
            <li>La primera vez, haz clic derecho y selecciona "Abrir" para autorizar la app</li>
          </ol>

          <h3 style={{ color: colores.primary, display: 'flex', alignItems: 'center', gap: '10px', marginTop: '25px' }}>
            <FaLinux /> Linux
          </h3>
          <ol style={{ lineHeight: '1.8' }}>
            <li>Descarga el archivo <code>.AppImage</code></li>
            <li>Dale permisos de ejecución: <code>chmod +x CentroDiagnostico-*.AppImage</code></li>
            <li>Ejecuta el archivo haciendo doble clic o desde la terminal</li>
            <li>Opcionalmente, integra la app con AppImageLauncher</li>
          </ol>
        </div>
      </div>
    </div>
  );
};

export default DescargarApp;
