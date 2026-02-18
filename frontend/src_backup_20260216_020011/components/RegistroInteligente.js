import React, { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import { FaSearch, FaUserPlus, FaCheck, FaTrash, FaPlus, FaMoneyBillWave, FaArrowLeft, FaNotesMedical, FaUser } from 'react-icons/fa';

const API = '/api';

function RegistroInteligente() {
  const navigate = useNavigate();
  const [paso, setPaso] = useState(1);
  const [busqueda, setBusqueda] = useState('');
  const [resultadosBusqueda, setResultadosBusqueda] = useState([]);
  const [buscando, setBuscando] = useState(false);
  const [pacienteSeleccionado, setPacienteSeleccionado] = useState(null);
  const [pacienteNuevo, setPacienteNuevo] = useState(false);
  const timeoutRef = useRef(null);
  
  const [form, setForm] = useState({
    cedula: '', nombre: '', apellido: '', fecha_nacimiento: '',
    sexo: '', telefono: '', celular: '', email: '', direccion: '',
    ciudad: '', seguro_medico: '', numero_poliza: '', tipo_sangre: '', alergias: ''
  });

  const [estudios, setEstudios] = useState([]);
  const [categorias, setCategorias] = useState([]);
  const [estudiosSeleccionados, setEstudiosSeleccionados] = useState([]);
  const [categoriaFiltro, setCategoriaFiltro] = useState('');
  const [buscarEstudio, setBuscarEstudio] = useState('');
  const [medicoReferente, setMedicoReferente] = useState('');
  const [prioridad, setPrioridad] = useState('normal');

  const [mensaje, setMensaje] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const token = localStorage.getItem('token');
  const headers = { Authorization: `Bearer ${token}` };

  useEffect(() => { fetchEstudios(); fetchCategorias(); }, []);

  useEffect(() => {
    if (timeoutRef.current) clearTimeout(timeoutRef.current);
    if (busqueda.length < 2) { setResultadosBusqueda([]); return; }
    timeoutRef.current = setTimeout(buscarPaciente, 300);
    return () => clearTimeout(timeoutRef.current);
  }, [busqueda]);

  const buscarPaciente = async () => {
    setBuscando(true);
    try {
      const res = await axios.get(`${API}/pacientes/?buscar=${encodeURIComponent(busqueda)}&per_page=10`, { headers });
      setResultadosBusqueda(res.data.pacientes);
    } catch (err) { console.error(err); } finally { setBuscando(false); }
  };

  const fetchEstudios = async () => {
    try { const res = await axios.get(`${API}/estudios/`, { headers }); setEstudios(res.data.estudios); } catch (err) {}
  };

  const fetchCategorias = async () => {
    try { const res = await axios.get(`${API}/estudios/categorias`, { headers }); setCategorias(res.data.categorias); } catch (err) {}
  };

  const handleChange = (e) => setForm({ ...form, [e.target.name]: e.target.value });

  const seleccionarPaciente = (p) => {
    setPacienteSeleccionado(p); setPacienteNuevo(false);
    setBusqueda(''); setResultadosBusqueda([]); setPaso(2);
  };

  const registrarPaciente = async () => {
    if (!form.nombre || !form.apellido) { setError('Nombre y Apellido requeridos'); return; }
    setLoading(true); setError('');
    try {
      const res = await axios.post(`${API}/pacientes/`, form, { headers });
      setPacienteSeleccionado(res.data.paciente); setPacienteNuevo(false); setPaso(2);
      setMensaje(`Paciente registrado: ${res.data.paciente.nombre}`);
    } catch (err) { setError('Error al registrar'); } finally { setLoading(false); }
  };

  const agregarEstudio = (e) => {
    if (!estudiosSeleccionados.find(s => s.estudio_id === e.id)) {
      setEstudiosSeleccionados([...estudiosSeleccionados, { estudio_id: e.id, nombre: e.nombre, codigo: e.codigo, precio: e.precio, descuento: 0 }]);
    }
  };

  const crearOrden = async () => {
    if (estudiosSeleccionados.length === 0) return setError('Seleccione estudios');
    setLoading(true);
    try {
      const res = await axios.post(`${API}/ordenes/`, {
        paciente_id: pacienteSeleccionado.id, medico_referente: medicoReferente, prioridad,
        estudios: estudiosSeleccionados.map(e => ({ estudio_id: e.estudio_id, descuento: e.descuento }))
      }, { headers });
      
      if (window.confirm('Orden creada. ¿Desea facturar ahora?')) {
        navigate(`/crear-factura/${res.data.orden.id}`);
      } else {
        navigate('/');
      }
    } catch (err) { setError('Error al crear orden'); } finally { setLoading(false); }
  };

  const formatMoney = (n) => `RD$ ${Number(n).toLocaleString('es-DO', { minimumFractionDigits: 2 })}`;
  const total = estudiosSeleccionados.reduce((acc, curr) => acc + (curr.precio - curr.descuento), 0);

  return (
    <div className="page-container">
      <div className="progress-steps">
        <div className={`step ${paso >= 1 ? 'active' : ''}`}><span className="step-number">1</span> Paciente</div>
        <div className="step-line"></div>
        <div className={`step ${paso >= 2 ? 'active' : ''}`}><span className="step-number">2</span> Estudios</div>
      </div>

      {mensaje && <div className="alert alert-success"><FaCheck /> {mensaje}</div>}
      {error && <div className="alert alert-error">{error}</div>}

      {paso === 1 && !pacienteNuevo && (
        <div className="form-card">
          <h2><FaSearch /> Buscar Paciente</h2>
          <div className="search-box">
            <input type="text" placeholder="Nombre, Cédula, Teléfono..." value={busqueda} onChange={e => setBusqueda(e.target.value)} className="search-input" autoFocus />
          </div>
          
          {resultadosBusqueda.map(p => (
            <div key={p.id} className="result-item-inline" onClick={() => seleccionarPaciente(p)}>
              <div className="result-avatar"><FaUser /></div>
              <div className="result-info"><strong>{p.nombre} {p.apellido}</strong><span>{p.cedula}</span></div>
              <button className="btn btn-sm btn-success"><FaCheck /> Seleccionar</button>
            </div>
          ))}

          <div className="no-results-action">
            <button className="btn btn-primary" onClick={() => setPacienteNuevo(true)}><FaUserPlus /> Nuevo Paciente</button>
          </div>
        </div>
      )}

      {paso === 1 && pacienteNuevo && (
        <div className="form-card">
          <div className="card-header-flex">
            <h2><FaUserPlus /> Nuevo Paciente</h2>
            <button className="btn btn-outline" onClick={() => setPacienteNuevo(false)}><FaArrowLeft /> Volver</button>
          </div>
          <div className="form-grid">
            <div className="form-group"><label>Nombre *</label><input name="nombre" value={form.nombre} onChange={handleChange} /></div>
            <div className="form-group"><label>Apellido *</label><input name="apellido" value={form.apellido} onChange={handleChange} /></div>
            <div className="form-group"><label>Cédula</label><input name="cedula" value={form.cedula} onChange={handleChange} /></div>
            <div className="form-group"><label>Teléfono</label><input name="telefono" value={form.telefono} onChange={handleChange} /></div>
            <div className="form-group"><label>Seguro</label>
              <select name="seguro_medico" value={form.seguro_medico} onChange={handleChange}>
                <option value="">Privado</option><option value="Senasa">Senasa</option><option value="Humano">Humano</option>
              </select>
            </div>
          </div>
          <button className="btn btn-primary btn-block" onClick={registrarPaciente} disabled={loading}>{loading ? 'Guardando...' : 'Guardar y Continuar'}</button>
        </div>
      )}

      {paso === 2 && (
        <div className="estudios-grid">
          <div className="form-card">
            <h3><FaSearch /> Catálogo</h3>
            <input type="text" placeholder="Buscar estudio..." value={buscarEstudio} onChange={e => setBuscarEstudio(e.target.value)} className="search-input" />
            <div className="estudios-list">
              {estudios.filter(e => e.nombre.toLowerCase().includes(buscarEstudio.toLowerCase())).map(e => (
                <div key={e.id} className="estudio-item" onClick={() => agregarEstudio(e)}>
                  <span className="estudio-codigo">{e.codigo}</span>
                  <span className="estudio-nombre">{e.nombre}</span>
                  <span className="estudio-precio">{formatMoney(e.precio)}</span>
                  <FaPlus />
                </div>
              ))}
            </div>
          </div>

          <div className="form-card">
            <h3><FaNotesMedical /> Orden Actual</h3>
            <div className="paciente-info-box">
              <strong>{pacienteSeleccionado.nombre} {pacienteSeleccionado.apellido}</strong>
              <button className="btn-link" onClick={() => setPaso(1)}>Cambiar</button>
            </div>
            
            <div className="estudios-seleccionados">
              {estudiosSeleccionados.map(s => (
                <div key={s.estudio_id} className="estudio-sel-item">
                  <div className="estudio-sel-info"><strong>{s.nombre}</strong><span>{formatMoney(s.precio)}</span></div>
                  <button onClick={() => setEstudiosSeleccionados(estudiosSeleccionados.filter(x => x.estudio_id !== s.estudio_id))} className="btn-remove"><FaTrash /></button>
                </div>
              ))}
            </div>

            <div className="orden-total"><span>Total:</span> <span className="total-amount">{formatMoney(total)}</span></div>
            <button className="btn btn-success btn-block" onClick={crearOrden} disabled={loading}><FaCheck /> Finalizar Orden</button>
          </div>
        </div>
      )}
    </div>
  );
}

export default RegistroInteligente;
