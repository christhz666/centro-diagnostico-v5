import React, { useState, useEffect } from 'react';
import { 
    FaUsers, FaCalendarAlt, FaFlask, FaFileInvoiceDollar,
    FaClock, FaCheckCircle, FaHourglassHalf, FaChartLine,
    FaUserPlus, FaSpinner, FaExclamationTriangle, FaSyncAlt
} from 'react-icons/fa';
import api from '../services/api';

const Dashboard = () => {
    const [stats, setStats] = useState(null);
    const [citasHoy, setCitasHoy] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const user = api.getUser();

    useEffect(() => {
        loadDashboard();
    }, []);

    const loadDashboard = async () => {
        setLoading(true);
        setError('');
        
        try {
            const [statsRes, citasRes] = await Promise.all([
                api.getDashboardStats(),
                api.getCitasHoy()
            ]);

            if (statsRes.success) setStats(statsRes.data);
            if (citasRes.success) setCitasHoy(citasRes.data);
        } catch (err) {
            console.error('Error cargando dashboard:', err);
            setError(err.message);
        } finally {
            setLoading(false);
        }
    };

    if (loading) {
        return (
            <div style={styles.loadingContainer}>
                <FaSpinner className="spin" style={{ fontSize: 40, color: '#3282b8' }} />
                <p style={{ marginTop: 15, color: '#666' }}>Cargando dashboard...</p>
            </div>
        );
    }

    if (error) {
        return (
            <div style={styles.errorContainer}>
                <FaExclamationTriangle style={{ fontSize: 40, color: '#e74c3c' }} />
                <p style={{ margin: '15px 0', color: '#666' }}>{error}</p>
                <button onClick={loadDashboard} style={styles.retryButton}>
                    <FaSyncAlt style={{ marginRight: 8 }} /> Reintentar
                </button>
            </div>
        );
    }

    const cards = [
        {
            title: 'Total Pacientes',
            value: stats?.pacientes?.total || 0,
            subtitle: `+${stats?.pacientes?.nuevosMes || 0} este mes`,
            icon: <FaUsers />,
            color: '#3498db',
            bg: 'linear-gradient(135deg, #3498db, #2980b9)'
        },
        {
            title: 'Citas Hoy',
            value: stats?.citas?.hoy || 0,
            subtitle: `${stats?.citas?.completadasHoy || 0} completadas`,
            icon: <FaCalendarAlt />,
            color: '#2ecc71',
            bg: 'linear-gradient(135deg, #2ecc71, #27ae60)'
        },
        {
            title: 'Resultados Pendientes',
            value: stats?.resultados?.pendientes || 0,
            subtitle: `${stats?.resultados?.completadosMes || 0} completados este mes`,
            icon: <FaFlask />,
            color: '#e67e22',
            bg: 'linear-gradient(135deg, #e67e22, #d35400)'
        },
        {
            title: 'Facturación Hoy',
            value: `RD$ ${(stats?.facturacion?.hoy?.total || 0).toLocaleString()}`,
            subtitle: `${stats?.facturacion?.hoy?.cantidad || 0} facturas`,
            icon: <FaFileInvoiceDollar />,
            color: '#9b59b6',
            bg: 'linear-gradient(135deg, #9b59b6, #8e44ad)'
        }
    ];

    const getEstadoStyle = (estado) => {
        const estilos = {
            programada: { bg: '#e3f2fd', color: '#1565c0', text: '?? Programada' },
            confirmada: { bg: '#e8f5e9', color: '#2e7d32', text: '? Confirmada' },
            en_sala: { bg: '#fff3e0', color: '#ef6c00', text: '?? En Sala' },
            en_proceso: { bg: '#fce4ec', color: '#c62828', text: '? En Proceso' },
            completada: { bg: '#e0f2f1', color: '#00695c', text: '?? Completada' },
            cancelada: { bg: '#fafafa', color: '#757575', text: '? Cancelada' },
            no_asistio: { bg: '#fff8e1', color: '#f57f17', text: '?? No Asistió' }
        };
        return estilos[estado] || estilos.programada;
    };

    return (
        <div style={styles.container}>
            {/* Header */}
            <div style={styles.header}>
                <div>
                    <h1 style={styles.headerTitle}>
                        ¡Bienvenido, {user?.nombre || 'Usuario'}! ??
                    </h1>
                    <p style={styles.headerSubtitle}>
                        {new Date().toLocaleDateString('es-DO', { 
                            weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' 
                        })}
                    </p>
                </div>
                <button onClick={loadDashboard} style={styles.refreshButton}>
                    <FaSyncAlt /> Actualizar
                </button>
            </div>

            {/* Cards de estadísticas */}
            <div style={styles.cardsGrid}>
                {cards.map((card, index) => (
                    <div key={index} style={{ ...styles.card, background: card.bg }}>
                        <div style={styles.cardIcon}>{card.icon}</div>
                        <div style={styles.cardInfo}>
                            <p style={styles.cardTitle}>{card.title}</p>
                            <h2 style={styles.cardValue}>{card.value}</h2>
                            <p style={styles.cardSubtitle}>{card.subtitle}</p>
                        </div>
                    </div>
                ))}
            </div>

            {/* Citas de hoy */}
            <div style={styles.section}>
                <h2 style={styles.sectionTitle}>
                    <FaCalendarAlt style={{ marginRight: 10, color: '#3282b8' }} />
                    Citas de Hoy ({citasHoy.length})
                </h2>
                
                {citasHoy.length === 0 ? (
                    <div style={styles.emptyState}>
                        <FaCalendarAlt style={{ fontSize: 40, color: '#ddd' }} />
                        <p style={{ color: '#999', marginTop: 10 }}>No hay citas programadas para hoy</p>
                    </div>
                ) : (
                    <div style={styles.tableContainer}>
                        <table style={styles.table}>
                            <thead>
                                <tr style={styles.tableHeader}>
                                    <th style={styles.th}>Hora</th>
                                    <th style={styles.th}>Paciente</th>
                                    <th style={styles.th}>Estudios</th>
                                    <th style={styles.th}>Estado</th>
                                </tr>
                            </thead>
                            <tbody>
                                {citasHoy.map((cita, index) => {
                                    const estadoStyle = getEstadoStyle(cita.estado);
                                    return (
                                        <tr key={cita._id || index} style={styles.tableRow}>
                                            <td style={styles.td}>
                                                <strong>{cita.horaInicio}</strong>
                                            </td>
                                            <td style={styles.td}>
                                                {cita.paciente?.nombre} {cita.paciente?.apellido}
                                                <br />
                                                <small style={{ color: '#999' }}>
                                                    {cita.paciente?.cedula}
                                                </small>
                                            </td>
                                            <td style={styles.td}>
                                                {cita.estudios?.map((e, i) => (
                                                    <span key={i} style={styles.estudioBadge}>
                                                        {e.estudio?.nombre || 'Estudio'}
                                                    </span>
                                                ))}
                                            </td>
                                            <td style={styles.td}>
                                                <span style={{
                                                    ...styles.estadoBadge,
                                                    background: estadoStyle.bg,
                                                    color: estadoStyle.color
                                                }}>
                                                    {estadoStyle.text}
                                                </span>
                                            </td>
                                        </tr>
                                    );
                                })}
                            </tbody>
                        </table>
                    </div>
                )}
            </div>

            {/* Resumen adicional */}
            <div style={styles.bottomGrid}>
                <div style={styles.infoCard}>
                    <h3 style={styles.infoTitle}>?? Resumen del Mes</h3>
                    <div style={styles.infoItem}>
                        <span>Citas totales:</span>
                        <strong>{stats?.citas?.mes || 0}</strong>
                    </div>
                    <div style={styles.infoItem}>
                        <span>Facturación mes:</span>
                        <strong>RD$ {(stats?.facturacion?.mes?.total || 0).toLocaleString()}</strong>
                    </div>
                    <div style={styles.infoItem}>
                        <span>Pacientes nuevos:</span>
                        <strong>{stats?.pacientes?.nuevosMes || 0}</strong>
                    </div>
                </div>

                <div style={styles.infoCard}>
                    <h3 style={styles.infoTitle}>?? Estado Actual</h3>
                    <div style={styles.infoItem}>
                        <span>Citas programadas:</span>
                        <strong style={{ color: '#3498db' }}>{stats?.citas?.programadas || 0}</strong>
                    </div>
                    <div style={styles.infoItem}>
                        <span>En proceso:</span>
                        <strong style={{ color: '#e67e22' }}>{stats?.citas?.enProceso || 0}</strong>
                    </div>
                    <div style={styles.infoItem}>
                        <span>Médicos activos:</span>
                        <strong style={{ color: '#2ecc71' }}>{stats?.personal?.medicos || 0}</strong>
                    </div>
                </div>
            </div>
        </div>
    );
};

const styles = {
    container: {
        padding: '20px',
        maxWidth: '1400px',
        margin: '0 auto',
    },
    loadingContainer: {
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        minHeight: '60vh',
    },
    errorContainer: {
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        minHeight: '60vh',
    },
    retryButton: {
        padding: '10px 25px',
        borderRadius: '8px',
        border: 'none',
        background: '#3282b8',
        color: 'white',
        cursor: 'pointer',
        fontSize: '14px',
        display: 'flex',
        alignItems: 'center',
    },
    header: {
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginBottom: '25px',
        flexWrap: 'wrap',
        gap: '15px',
    },
    headerTitle: {
        fontSize: '24px',
        color: '#1b262c',
        margin: 0,
    },
    headerSubtitle: {
        color: '#666',
        margin: '5px 0 0',
        fontSize: '14px',
        textTransform: 'capitalize',
    },
    refreshButton: {
        padding: '10px 20px',
        borderRadius: '8px',
        border: '2px solid #3282b8',
        background: 'white',
        color: '#3282b8',
        cursor: 'pointer',
        fontSize: '14px',
        display: 'flex',
        alignItems: 'center',
        gap: '8px',
        fontWeight: 'bold',
    },
    cardsGrid: {
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))',
        gap: '20px',
        marginBottom: '30px',
    },
    card: {
        borderRadius: '15px',
        padding: '25px',
        color: 'white',
        display: 'flex',
        alignItems: 'center',
        gap: '15px',
        boxShadow: '0 5px 20px rgba(0,0,0,0.15)',
        transition: 'transform 0.2s',
    },
    cardIcon: {
        fontSize: '40px',
        opacity: 0.9,
    },
    cardInfo: {
        flex: 1,
    },
    cardTitle: {
        margin: 0,
        fontSize: '13px',
        opacity: 0.9,
        textTransform: 'uppercase',
        letterSpacing: '0.5px',
    },
    cardValue: {
        margin: '5px 0',
        fontSize: '28px',
        fontWeight: 'bold',
    },
    cardSubtitle: {
        margin: 0,
        fontSize: '12px',
        opacity: 0.8,
    },
    section: {
        background: 'white',
        borderRadius: '15px',
        padding: '25px',
        boxShadow: '0 2px 10px rgba(0,0,0,0.08)',
        marginBottom: '20px',
    },
    sectionTitle: {
        fontSize: '18px',
        color: '#1b262c',
        margin: '0 0 20px',
        display: 'flex',
        alignItems: 'center',
    },
    emptyState: {
        textAlign: 'center',
        padding: '40px',
    },
    tableContainer: {
        overflowX: 'auto',
    },
    table: {
        width: '100%',
        borderCollapse: 'collapse',
    },
    tableHeader: {
        background: '#f8f9fa',
    },
    th: {
        padding: '12px 15px',
        textAlign: 'left',
        color: '#666',
        fontSize: '13px',
        textTransform: 'uppercase',
        letterSpacing: '0.5px',
        borderBottom: '2px solid #eee',
    },
    tableRow: {
        borderBottom: '1px solid #f0f0f0',
    },
    td: {
        padding: '12px 15px',
        fontSize: '14px',
    },
    estudioBadge: {
        display: 'inline-block',
        background: '#e8f4fd',
        color: '#1565c0',
        padding: '3px 8px',
        borderRadius: '4px',
        fontSize: '11px',
        margin: '2px',
    },
    estadoBadge: {
        display: 'inline-block',
        padding: '5px 12px',
        borderRadius: '20px',
        fontSize: '12px',
        fontWeight: 'bold',
    },
    bottomGrid: {
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))',
        gap: '20px',
    },
    infoCard: {
        background: 'white',
        borderRadius: '15px',
        padding: '25px',
        boxShadow: '0 2px 10px rgba(0,0,0,0.08)',
    },
    infoTitle: {
        fontSize: '16px',
        color: '#1b262c',
        margin: '0 0 15px',
    },
    infoItem: {
        display: 'flex',
        justifyContent: 'space-between',
        padding: '10px 0',
        borderBottom: '1px solid #f0f0f0',
        fontSize: '14px',
        color: '#555',
    },
};

export default Dashboard;
