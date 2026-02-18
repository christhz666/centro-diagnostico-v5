const API_URL = '/api';

class ApiService {
    getToken() { return localStorage.getItem('token'); }

    getHeaders() {
        const headers = { 'Content-Type': 'application/json' };
        const token = this.getToken();
        if (token) headers['Authorization'] = 'Bearer ' + token;
        return headers;
    }

    async request(endpoint, options = {}) {
        const url = API_URL + endpoint;
        const config = { headers: this.getHeaders(), ...options };
        const response = await fetch(url, config);
        const raw = await response.json();

        if (response.status === 401) {
            localStorage.removeItem('token');
            localStorage.removeItem('user');
            window.location.href = '/';
            throw new Error('Sesion expirada');
        }

        if (!response.ok) {
            const error = new Error(raw.message || raw.error || 'Error ' + response.status);
            error.response = { data: raw, status: response.status };
            throw error;
        }

        // Normalizar respuestas del backend
        if (raw && typeof raw === 'object') {
            if ('facturas' in raw) return raw.facturas;
            if ('data' in raw && 'success' in raw) return raw.data;
            if ('usuarios' in raw) return raw.usuarios;
            if ('pacientes' in raw) return raw.pacientes;
            if ('resultados' in raw) return raw.resultados;
            if ('ordenes' in raw) return raw.ordenes;
            if ('estudios' in raw && Array.isArray(raw.estudios)) return raw.estudios;
        }
        return raw;
    }

    async login(credentials) {
        const body = {
            username: credentials.username || credentials.email,
            password: credentials.password
        };
        const response = await fetch(API_URL + '/auth/login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(body)
        });
        const data = await response.json();
        if (data.access_token) {
            localStorage.setItem('token', data.access_token);
            localStorage.setItem('user', JSON.stringify(data.usuario));
        }
        return data;
    }

    logout() {
        localStorage.removeItem('token');
        localStorage.removeItem('user');
        window.location.href = '/';
    }

    isAuthenticated() { return !!this.getToken(); }
    getUser() {
        const u = localStorage.getItem('user');
        return u ? JSON.parse(u) : null;
    }
    async getMe() { return this.request('/auth/me'); }

    // Dashboard endpoints: /api/dashboard/stats, /api/dashboard/citas-grafica, /api/dashboard/top-estudios
    // Citas hoy endpoint: /api/citas/hoy
    async getDashboardStats() { return this.request('/dashboard/stats'); }
    async getCitasHoy() { return this.request('/citas/hoy'); }
    async getCitasGrafica() { return this.request('/dashboard/citas-grafica'); }
    async getTopEstudios() { return this.request('/dashboard/top-estudios'); }

    // Pacientes endpoints: /api/pacientes
    async getPacientes(params = {}) {
        const query = new URLSearchParams(params).toString();
        return this.request('/pacientes/?' + query);
    }
    async getPaciente(id) { return this.request('/pacientes/' + id); }
    async createPaciente(data) {
        return this.request('/pacientes', { method: 'POST', body: JSON.stringify(data) });
    }
    async updatePaciente(id, data) {
        return this.request('/pacientes/' + id, { method: 'PUT', body: JSON.stringify(data) });
    }

    // Estudios endpoints: /api/estudios
    async getEstudios(params = {}) {
        const query = new URLSearchParams(params).toString();
        return this.request('/estudios/?' + query);
    }
    async getEstudio(id) { return this.request('/estudios/' + id); }
    async createEstudio(data) {
        return this.request('/estudios', { method: 'POST', body: JSON.stringify(data) });
    }
    async updateEstudio(id, data) {
        return this.request('/estudios/' + id, { method: 'PUT', body: JSON.stringify(data) });
    }
    async deleteEstudio(id) {
        return this.request('/estudios/' + id, { method: 'DELETE' });
    }
    async getCategorias() { return this.request('/estudios/categorias'); }

    // Citas endpoints: /api/citas
    async getCitas(params = {}) {
        const query = new URLSearchParams(params).toString();
        return this.request('/citas/?' + query);
    }
    async getCita(id) { return this.request('/citas/' + id); }
    // @deprecated Legacy alias for backward compatibility - use getCita() instead
    async getOrden(id) { return this.request('/citas/' + id); }

    async createCita(data) {
        const ordenData = {
            paciente: data.paciente,
            fecha: data.fecha || new Date().toISOString().split('T')[0],
            horaInicio: data.horaInicio || new Date().toTimeString().split(' ')[0].substring(0, 5),
            medico_referente: data.medico_referente || '',
            estado: data.estado || 'programada',
            metodoPago: data.metodoPago || 'pendiente',
            estudios: (data.estudios || []).map(e => ({
                estudio: e.estudio || e.id || e.estudio_id || e._id,
                precio: e.precio || 0,
                descuento: e.descuento || 0
            }))
        };
        return this.request('/citas/', {
            method: 'POST',
            body: JSON.stringify(ordenData)
        });
    }

    async updateCita(id, data) {
        return this.request('/citas/' + id, { method: 'PUT', body: JSON.stringify(data) });
    }

    async getFacturas(params = {}) {
        const query = new URLSearchParams(params).toString();
        return this.request('/facturas/?' + query);
    }
    async getFactura(id) { return this.request('/facturas/' + id); }

    async createFactura(data) {
        // If items are already provided, use direct invoice creation
        if (data.items && data.items.length > 0) {
            return this.request('/facturas', { method: 'POST', body: JSON.stringify(data) });
        }
        if (data.cita || data.orden_id) {
            const ordenId = data.cita || data.orden_id;
            // 1. Crear factura desde orden
            const facturaResp = await this.request('/facturas/crear-desde-orden/' + ordenId, {
                method: 'POST',
                body: JSON.stringify({
                    tipo_comprobante: 'B02',
                    forma_pago: data.metodoPago || 'efectivo',
                    descuento_global: data.descuento || 0,
                    incluir_itbis: false
                })
            });
            // El backend devuelve {success, factura} o directamente la factura
            const factura = facturaResp && facturaResp.factura ? facturaResp.factura : facturaResp;
            // 2. Registrar pago si hay monto pagado
            const montoPagado = data.montoPagado || 0;
            if (montoPagado > 0 && factura && factura.id) {
                try {
                    await this.request('/facturas/' + factura.id + '/pagar', {
                        method: 'POST',
                        body: JSON.stringify({
                            monto: montoPagado,
                            metodo_pago: data.metodoPago || 'efectivo'
                        })
                    });
                } catch(e) {
                    console.error('Error registrando pago:', e);
                }
            }
            return factura;
        }
        return this.request('/facturas', { method: 'POST', body: JSON.stringify(data) });
    }

    async anularFactura(id, motivo) {
        return this.request('/facturas/' + id + '/anular', {
            method: 'PATCH',
            body: JSON.stringify({ motivo })
        });
    }
    async imprimirFactura(id) { return this.request('/impresion/factura-termica/' + id); }

    // Resultados endpoints: /api/resultados
    async getResultados(params = {}) {
        const query = new URLSearchParams(params).toString();
        return this.request('/resultados/?' + query);
    }
    async getResultadosPorPaciente(pacienteId) {
        return this.request('/resultados/paciente/' + pacienteId);
    }
    async getResultadoPorCodigoMuestra(codigo) {
        return this.request('/resultados/muestra/' + codigo);
    }
    async getResultado(id) { return this.request('/resultados/' + id); }
    async createResultado(data) {
        return this.request('/resultados', { method: 'POST', body: JSON.stringify(data) });
    }
    async updateResultado(id, data) {
        return this.request('/resultados/' + id, { method: 'PUT', body: JSON.stringify(data) });
    }
    async validarResultado(id, data) {
        return this.request('/resultados/' + id + '/validar', {
            method: 'PATCH',
            body: JSON.stringify(data)
        });
    }

    // Admin endpoints: /api/admin/usuarios
    async getUsuarios(params = {}) {
        const query = new URLSearchParams(params).toString();
        return this.request('/admin/usuarios?' + query);
    }
    async getUsuario(id) { return this.request('/admin/usuarios/' + id); }
    async createUsuario(data) {
        return this.request('/admin/usuarios', { method: 'POST', body: JSON.stringify(data) });
    }
    async updateUsuario(id, data) {
        return this.request('/admin/usuarios/' + id, { method: 'PUT', body: JSON.stringify(data) });
    }
    async toggleUsuario(id) {
        return this.request('/admin/usuarios/' + id + '/toggle', { method: 'PATCH' });
    }
    async resetPasswordUsuario(id, newPassword) {
        return this.request('/admin/usuarios/' + id + '/reset-password', {
            method: 'PATCH',
            body: JSON.stringify({ newPassword })
        });
    }
    async getMedicos() { return this.request('/admin/medicos'); }
    async getRoles() { return this.request('/admin/roles'); }
    async healthCheck() { return this.request('/health'); }

    // Contabilidad
    async getMovimientosContables(params = {}) {
        const query = new URLSearchParams(params).toString();
        return this.request('/contabilidad?' + query);
    }
    async createMovimientoContable(data) {
        return this.request('/contabilidad', { method: 'POST', body: JSON.stringify(data) });
    }
    async getResumenContable() {
        return this.request('/contabilidad/resumen');
    }
    async getFlujoCaja() {
        return this.request('/contabilidad/flujo-caja');
    }
    async deleteMovimientoContable(id) {
        return this.request('/contabilidad/' + id, { method: 'DELETE' });
    }

    // Configuracion
    async getConfiguracion() {
        return this.request('/configuracion/');
    }
    async updateConfiguracion(data) {
        return this.request('/configuracion/', { method: 'PUT', body: JSON.stringify(data) });
    }
    async getEmpresaInfo() {
        return this.request('/configuracion/empresa');
    }

    // Deploy de Agentes
    async escanearRed() {
        return this.request('/deploy/scan');
    }
    async getAgentesInstalados() {
        return this.request('/deploy/agents');
    }
    async deployAgente(ip, hostname) {
        return this.request('/deploy/install', {
            method: 'POST',
            body: JSON.stringify({ ip, hostname })
        });
    }
    async verificarAgenteEstado(ip) {
        return this.request('/deploy/status/' + ip);
    }
}

const api = new ApiService();
export default api;
