import React, { useState } from 'react';
import axios from 'axios';

const API_URL = 'http://192.9.135.84:5000/api';

function CampanaWhatsApp() {
  const [mensaje, setMensaje] = useState('');
  const [enviando, setEnviando] = useState(false);

  const enviarCampana = async () => {
    if (!mensaje) {
      alert('Escribe un mensaje');
      return;
    }
    
    setEnviando(true);
    try {
      const token = localStorage.getItem('token');
      const response = await axios.post(
        `${API_URL}/whatsapp/campana`,
        { mensaje },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      alert('Campaña enviada exitosamente');
      setMensaje('');
    } catch (err) {
      alert('Error al enviar campaña: ' + (err.response?.data?.error || err.message));
    } finally {
      setEnviando(false);
    }
  };

  return (
    <div className="container">
      <h1>?? Campaña de WhatsApp</h1>
      <p className="info">Variables disponibles: {'{nombre}'}, {'{apellido}'}</p>
      
      <div className="form-group">
        <label>Mensaje</label>
        <textarea
          rows="5"
          value={mensaje}
          onChange={(e) => setMensaje(e.target.value)}
          placeholder="Ejemplo: ¡Hola {nombre}! Tenemos ofertas especiales..."
        />
      </div>

      <button onClick={enviarCampana} disabled={enviando} className="btn-primary">
        {enviando ? 'Enviando...' : 'Enviar Campaña'}
      </button>

      <div className="alert alert-info">
        <strong>Nota:</strong> Para activar el envío real de WhatsApp, configura tus credenciales de Twilio en el archivo .env
      </div>
    </div>
  );
}

export default CampanaWhatsApp;
