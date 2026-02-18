import React, { useState, useEffect, useRef } from 'react';
import { FaBarcode, FaSearch, FaUser, FaFlask, FaPrint, FaCheckCircle, FaClock, FaTimes, FaSpinner } from 'react-icons/fa';
import api from '../services/api';

const ConsultaRapida = () => {
  const [codigo, setCodigo] = useState('');
  const [paciente, setPaciente] = useState(null);
  const [resultados, setResultados] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [resultadoSeleccionado, setResultadoSeleccionado] = useState(null);
  const [empresaConfig, setEmpresaConfig] = useState({});
  const inputRef = useRef(null);

  const colores = {
    azulCielo: '#87CEEB',
    azulOscuro: '#1a3a5c',
    blanco: '#FFFFFF',
    negro: '#000000'
  };

  useEffect(() => {
    inputRef.current?.focus();
    const interval = setInterval(() => {
      if (document.activeElement !== inputRef.current) {
        inputRef.current?.focus();
      }
    }, 2000);
    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    const token = localStorage.getItem('token');
    fetch('/api/configuracion/', {
      headers: { 'Authorization': `Bearer ${token}` }
    })
      .then(res => res.json())
      .then(data => setEmpresaConfig(data.configuracion || data || {}))
      .catch(() => {});
  }, []);

  useEffect(() => {
    if (codigo.length >= 11 && codigo.startsWith('PAC')) {
      buscarPaciente();
    }
  }, [codigo]);

  const buscarPaciente = async () => {
    if (!codigo.trim()) return;
    try {
      setLoading(true);
      setError('');
      setPaciente(null);
      setResultados([]);

      const idParcial = codigo.replace('PAC', '').toLowerCase();
      const response = await api.getPacientes({ search: '' });
      const pacientes = response.data || response || [];
      
      const pacienteEncontrado = pacientes.find(p => {
        const pacId = (p._id || p.id || '').toLowerCase();
        return pacId.endsWith(idParcial) || pacId.includes(idParcial);
      });

      if (!pacienteEncontrado) {
        setError('Paciente no encontrado con codigo: ' + codigo);
        setTimeout(() => { setCodigo(''); setError(''); }, 3000);
        return;
      }

      setPaciente(pacienteEncontrado);
      
      try {
        const pacienteId = pacienteEncontrado._id || pacienteEncontrado.id;
        const resResponse = await api.getResultados({ paciente: pacienteId, limit: 5 });
        const allResults = Array.isArray(resResponse) ? resResponse : (resResponse.data || resResponse || []);
        // For barcode search, show only the most recent order's results
        if (allResults.length > 0) {
          const latestCita = allResults[0].cita;
          if (latestCita) {
            const latestResults = allResults.filter(r => {
              const citaId = r.cita?._id || r.cita;
              return citaId === latestCita._id || citaId === latestCita;
            });
            setResultados(latestResults);
          } else {
            // If no cita reference, show only the most recent result
            setResultados(allResults.slice(0, 1));
          }
        } else {
          setResultados([]);
        }
      } catch (e) {
        setResultados([]);
      }
    } catch (err) {
      setError('Error: ' + err.message);
      setTimeout(() => { setCodigo(''); setError(''); }, 3000);
    } finally {
      setLoading(false);
    }
  };

  const limpiar = () => {
    setCodigo('');
    setPaciente(null);
    setResultados([]);
    setError('');
    setResultadoSeleccionado(null);
    inputRef.current?.focus();
  };

  const calcularEdad = (fecha) => {
    if (!fecha) return 'N/A';
    const hoy = new Date();
    const nac = new Date(fecha);
    let edad = hoy.getFullYear() - nac.getFullYear();
    const m = hoy.getMonth() - nac.getMonth();
    if (m < 0 || (m === 0 && hoy.getDate() < nac.getDate())) edad--;
    return edad;
  };

  const getSeguroNombre = (pac) => {
    if (!pac?.seguro) return 'Sin seguro';
    if (typeof pac.seguro === 'string') return pac.seguro;
    if (typeof pac.seguro === 'object') return pac.seguro.nombre || 'Sin seguro';
    return 'Sin seguro';
  };

  // IMPRESION A4 - UNA SOLA PAGINA
  const imprimirResultado = (resultado) => {
    const ventana = window.open('', 'Resultado', 'width=800,height=1000');
    
    const valoresHTML = (resultado.valores || []).map(v => {
      const estadoColor = v.estado === 'normal' ? '#d4edda' : v.estado === 'alto' ? '#f8d7da' : '#fff3cd';
      const estadoTexto = v.estado === 'normal' ? '#155724' : v.estado === 'alto' ? '#721c24' : '#856404';
      return '<tr>' +
        '<td style="padding:10px;border:1px solid #87CEEB;">' + (v.parametro || v.nombre || '') + '</td>' +
        '<td style="padding:10px;border:1px solid #87CEEB;text-align:center;font-weight:bold;color:#1a3a5c;">' + (v.valor || '') + ' ' + (v.unidad || '') + '</td>' +
        '<td style="padding:10px;border:1px solid #87CEEB;text-align:center;font-size:12px;color:#666;">' + (v.valorReferencia || '-') + '</td>' +
        '<td style="padding:10px;border:1px solid #87CEEB;text-align:center;">' +
          '<span style="padding:4px 12px;border-radius:12px;font-size:11px;background:' + estadoColor + ';color:' + estadoTexto + ';">' + (v.estado || 'N/A') + '</span>' +
        '</td>' +
      '</tr>';
    }).join('');

    const edadPaciente = calcularEdad(paciente?.fechaNacimiento);
    const nombreEstudio = resultado.estudio?.nombre || resultado.nombreEstudio || 'ESTUDIO CLINICO';
    const fechaResultado = new Date(resultado.createdAt || resultado.fecha).toLocaleDateString('es-DO');
    const doctorNombre = resultado.validadoPor?.nombre || resultado.medico?.nombre || '________________';
    
    let htmlContent = '<!DOCTYPE html><html><head>';
    htmlContent += '<title>Resultado - ' + (paciente?.nombre || 'Paciente') + '</title>';
    htmlContent += '<style>';
    htmlContent += '@page { size: A4; margin: 10mm 15mm; }';
    htmlContent += 'body { font-family: Arial, sans-serif; margin: 0; padding: 10px; color: #1a3a5c; font-size: 12px; }';
    htmlContent += '.header { text-align: center; border-bottom: 3px solid #1a3a5c; padding-bottom: 10px; margin-bottom: 15px; }';
    htmlContent += '.header img { max-width: 180px; }';
    htmlContent += '.section-title { background: #1a3a5c; color: white; padding: 8px 15px; border-radius: 5px; margin: 15px 0 10px; font-size: 13px; font-weight: bold; }';
    htmlContent += '.info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 5px; background: #f0f8ff; padding: 12px; border-radius: 8px; border-left: 4px solid #1a3a5c; margin-bottom: 15px; }';
    htmlContent += 'table { width: 100%; border-collapse: collapse; margin: 10px 0; }';
    htmlContent += 'th { background: #1a3a5c; color: white; padding: 10px; text-align: left; font-size: 11px; }';
    htmlContent += '.firma { margin-top: 50px; text-align: center; }';
    htmlContent += '.firma-linea { border-top: 2px solid #1a3a5c; width: 200px; margin: 0 auto; padding-top: 8px; }';
    htmlContent += '.footer { background: #1a3a5c; color: white; padding: 10px; text-align: center; border-radius: 5px; margin-top: 15px; font-size: 10px; }';
    htmlContent += '@media print { .no-print { display: none; } }';
    htmlContent += '</style></head><body>';
    
    htmlContent += '<div class="header">';
    htmlContent += '<img src="' + (empresaConfig.logo_resultados || '/logo-centro.png') + '" alt="' + (empresaConfig.empresa_nombre || 'Centro Diagnóstico') + '" onerror="this.onerror=null;this.src=\'/logo-centro.png\';" />';
    htmlContent += '<div style="font-size:10px;margin-top:5px;">' + (empresaConfig.empresa_direccion || '') + '<br/>Tel: ' + (empresaConfig.empresa_telefono || '') + (empresaConfig.empresa_email ? ' | ' + empresaConfig.empresa_email : '') + '</div>';
    htmlContent += '</div>';
    
    htmlContent += '<div class="section-title">INFORMACION DEL PACIENTE</div>';
    
    htmlContent += '<div class="info-grid">';
    htmlContent += '<div><strong>Paciente:</strong> ' + (paciente?.nombre || '') + ' ' + (paciente?.apellido || '') + '</div>';
    htmlContent += '<div><strong>Cedula:</strong> ' + (paciente?.cedula || 'N/A') + '</div>';
    htmlContent += '<div><strong>Edad:</strong> ' + edadPaciente + ' años</div>';
    htmlContent += '<div><strong>Sexo:</strong> ' + (paciente?.sexo === 'M' ? 'Masculino' : 'Femenino') + '</div>';
    htmlContent += '<div><strong>Nacionalidad:</strong> ' + (paciente?.nacionalidad || 'Dominicano') + '</div>';
    htmlContent += '<div><strong>Fecha:</strong> ' + fechaResultado + '</div>';
    htmlContent += '</div>';
    
    htmlContent += '<div class="section-title">RESULTADO: ' + nombreEstudio + '</div>';
    
    htmlContent += '<table><thead><tr>';
    htmlContent += '<th style="width:35%;">Parametro</th>';
    htmlContent += '<th style="width:25%;text-align:center;">Resultado</th>';
    htmlContent += '<th style="width:25%;text-align:center;">Valor Referencia</th>';
    htmlContent += '<th style="width:15%;text-align:center;">Estado</th>';
    htmlContent += '</tr></thead><tbody>';
    htmlContent += valoresHTML || '<tr><td colspan="4" style="padding:20px;text-align:center;color:#999;">Sin valores registrados</td></tr>';
    htmlContent += '</tbody></table>';
    
    if (resultado.interpretacion) {
      htmlContent += '<div style="background:#e6f3ff;border-left:4px solid #1a3a5c;padding:10px;border-radius:5px;margin:10px 0;">';
      htmlContent += '<strong>INTERPRETACION:</strong><p style="margin:5px 0 0;">' + resultado.interpretacion + '</p></div>';
    }
    
    if (resultado.conclusion) {
      htmlContent += '<div style="background:#e8f5e9;border-left:4px solid #27ae60;padding:10px;border-radius:5px;margin:10px 0;">';
      htmlContent += '<strong>CONCLUSION:</strong><p style="margin:5px 0 0;">' + resultado.conclusion + '</p></div>';
    }
    
    htmlContent += '<div class="firma"><div class="firma-linea">Dr(a). ' + doctorNombre + '</div>';
    htmlContent += '<div style="font-size:10px;color:#666;margin-top:3px;">Firma y Sello</div></div>';
    
    htmlContent += '<div class="footer"><strong>Gracias por confiar en nosotros!</strong> | <span style="color:#87CEEB;">Su salud es nuestra prioridad</span></div>';
    
    htmlContent += '<div class="no-print" style="text-align:center;padding:20px;">';
    htmlContent += '<button onclick="window.print()" style="padding:15px 40px;background:#1a3a5c;color:white;border:none;border-radius:8px;cursor:pointer;font-weight:bold;">Imprimir</button></div>';
    
    htmlContent += '</body></html>';
    
    ventana.document.write(htmlContent);
    ventana.document.close();
  };

  return (
    <div style={{ padding: 20, maxWidth: 1200, margin: '0 auto' }}>
      <div style={{
        background: loading ? 'linear-gradient(135deg, #87CEEB 0%, #1a3a5c 100%)' : 
                    error ? 'linear-gradient(135deg, #ff6b6b 0%, #ee5a6f 100%)' :
                    paciente ? 'linear-gradient(135deg, #87CEEB 0%, #5fa8d3 100%)' :
                    'linear-gradient(135deg, #1a3a5c 0%, #2d5a87 100%)',
        padding: 40, borderRadius: 20, marginBottom: 30, boxShadow: '0 15px 35px rgba(26,58,92,0.3)'
      }}>
        <div style={{ textAlign: 'center', color: 'white', marginBottom: 25 }}>
          <FaBarcode style={{ fontSize: 50, marginBottom: 15 }} />
          <h1 style={{ margin: 0, fontSize: 32 }}>
            {loading ? 'Buscando...' : error ? 'Error' : paciente ? 'Paciente Encontrado' : 'Escanee el Codigo de Barras'}
          </h1>
          <p style={{ margin: '10px 0 0', opacity: 0.95, fontSize: 16 }}>
            {loading ? 'Consultando...' : error ? error : paciente ? `${paciente.nombre}` : 'Acerque el lector al codigo'}
          </p>
        </div>

        <div style={{ maxWidth: 600, margin: '0 auto' }}>
          <input
            ref={inputRef}
            type="text"
            value={codigo}
            onChange={e => setCodigo(e.target.value.toUpperCase())}
            onKeyPress={e => e.key === 'Enter' && buscarPaciente()}
            placeholder="PAC########"
            autoFocus
            style={{
              width: '100%', padding: '20px', fontSize: 28, fontFamily: 'Courier New, monospace',
              fontWeight: 'bold', textAlign: 'center', border: '3px solid ' + colores.azulCielo,
              borderRadius: 15, background: 'rgba(255,255,255,0.95)', color: colores.azulOscuro, letterSpacing: 4
            }}
          />
          <button onClick={buscarPaciente} disabled={loading || codigo.length < 5} style={{
            width: '100%', marginTop: 15, padding: '15px', background: colores.azulCielo,
            border: 'none', borderRadius: 10, color: colores.azulOscuro, cursor: 'pointer', fontSize: 16, fontWeight: 'bold'
          }}>
            {loading ? <FaSpinner className="spin" /> : <><FaSearch /> Buscar</>}
          </button>
        </div>

        {paciente && (
          <div style={{ textAlign: 'center', marginTop: 20 }}>
            <button onClick={limpiar} style={{
              padding: '12px 30px', background: 'rgba(255,255,255,0.2)', border: '2px solid white',
              borderRadius: 10, color: 'white', cursor: 'pointer', fontSize: 16, fontWeight: 'bold'
            }}>Nueva Busqueda</button>
          </div>
        )}
      </div>

      {paciente && (
        <div style={{ display: 'grid', gridTemplateColumns: '350px 1fr', gap: 25 }}>
          <div style={{
            background: 'white', padding: 25, borderRadius: 15, boxShadow: '0 5px 20px rgba(0,0,0,0.08)',
            borderTop: '5px solid ' + colores.azulOscuro, height: 'fit-content'
          }}>
            <div style={{ textAlign: 'center', marginBottom: 20 }}>
              <div style={{
                width: 80, height: 80, background: 'linear-gradient(135deg, ' + colores.azulCielo + ' 0%, ' + colores.azulOscuro + ' 100%)',
                borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center',
                margin: '0 auto 15px', fontSize: 35, color: 'white'
              }}><FaUser /></div>
              <h2 style={{ margin: 0, color: colores.azulOscuro }}>{paciente.nombre} {paciente.apellido}</h2>
            </div>
            <div style={{ background: '#f0f8ff', padding: 15, borderRadius: 10, fontSize: 14 }}>
              <div style={{ marginBottom: 8 }}><strong>Cedula:</strong> {paciente.cedula}</div>
              <div style={{ marginBottom: 8 }}><strong>Telefono:</strong> {paciente.telefono}</div>
              <div style={{ marginBottom: 8 }}><strong>Edad:</strong> {calcularEdad(paciente.fechaNacimiento)} años</div>
              <div style={{ marginBottom: 8 }}><strong>Sexo:</strong> {paciente.sexo === 'M' ? 'Masculino' : 'Femenino'}</div>
              <div style={{ marginBottom: 8 }}><strong>Nacionalidad:</strong> {paciente.nacionalidad || 'Dominicano'}</div>
              <div><strong>Seguro:</strong> {getSeguroNombre(paciente)}</div>
            </div>
          </div>

          <div>
            <h3 style={{ marginBottom: 20, color: colores.azulOscuro }}>
              <FaFlask style={{ color: colores.azulCielo }} /> Resultados ({resultados.length})
            </h3>
            {resultados.length === 0 ? (
              <div style={{ textAlign: 'center', padding: 60, background: 'white', borderRadius: 15 }}>
                <FaFlask style={{ fontSize: 60, color: colores.azulCielo, marginBottom: 20 }} />
                <p style={{ color: '#999', fontSize: 18 }}>No hay resultados registrados</p>
              </div>
            ) : (
              <div style={{ display: 'grid', gap: 15 }}>
                {resultados.map(r => (
                  <div key={r._id || r.id} style={{
                    padding: 20, background: 'white', border: '2px solid ' + (r.estado === 'completado' ? '#27ae60' : colores.azulCielo),
                    borderRadius: 12, display: 'flex', justifyContent: 'space-between', alignItems: 'center'
                  }}>
                    <div>
                      <h4 style={{ margin: '0 0 8px', color: colores.azulOscuro }}>{r.estudio?.nombre || r.nombreEstudio || 'Estudio'}</h4>
                      <div style={{ fontSize: 13, color: '#666' }}>
                        {new Date(r.createdAt || r.fecha).toLocaleDateString('es-DO')}
                        {r.estado === 'completado' ? (
                          <span style={{ marginLeft: 15, color: '#27ae60' }}><FaCheckCircle /> Completado</span>
                        ) : (
                          <span style={{ marginLeft: 15, color: '#f39c12' }}><FaClock /> {r.estado || 'Pendiente'}</span>
                        )}
                      </div>
                    </div>
                    <div style={{ display: 'flex', gap: 10 }}>
                      {r.estado === 'completado' && (
                        <button onClick={() => imprimirResultado(r)} style={{
                          padding: '12px 25px', background: colores.azulOscuro, color: 'white',
                          border: 'none', borderRadius: 8, cursor: 'pointer', fontWeight: 'bold'
                        }}><FaPrint /> IMPRIMIR</button>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      )}

      {!paciente && !loading && (
        <div style={{ background: 'white', padding: 35, borderRadius: 20, borderTop: '5px solid ' + colores.azulOscuro }}>
          <h3 style={{ margin: '0 0 25px', color: colores.azulOscuro }}>Como usar la Consulta Rapida</h3>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 25 }}>
            {['Acerque el lector', 'Busqueda automatica', 'Imprima resultados'].map((t, i) => (
              <div key={i} style={{ display: 'flex', gap: 15 }}>
                <div style={{ width: 40, height: 40, background: colores.azulOscuro, color: 'white', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 'bold' }}>{i + 1}</div>
                <div><strong>{t}</strong></div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};

export default ConsultaRapida;
