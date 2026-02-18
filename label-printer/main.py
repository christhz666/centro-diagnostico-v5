#!/usr/bin/env python3
"""
Label Printer - Impresión de Etiquetas para Laboratorio
Centro Diagnóstico v5

Aplicación GUI para imprimir etiquetas adhesivas para tubos/frascos de laboratorio.
Características:
- Interfaz gráfica bonita y fácil de usar
- Búsqueda automática por ID de paciente
- Auto-agrega prefijo L para estudios de laboratorio
- Impresión de etiquetas con código de barras
- Configuración de impresora
- Timeout automático de 30 segundos
"""

import tkinter as tk
from tkinter import ttk, messagebox, font as tkfont
import requests
import json
import os
from datetime import datetime
from PIL import Image, ImageDraw, ImageFont, ImageTk
import barcode
from barcode.writer import ImageWriter
import io
import threading
import sys

# Configuración por defecto
DEFAULT_CONFIG = {
    'server_url': 'http://192.9.135.84:5000/api',
    'printer_model': 'Zebra GK420',
    'label_width_mm': 50,
    'label_height_mm': 25
}

# Categorías de laboratorio
LAB_CATEGORIES = [
    'hematologia', 'quimica', 'orina', 'coagulacion',
    'inmunologia', 'microbiologia', 'laboratorio clinico'
]


class LabelPrinterApp:
    """Aplicación principal de impresión de etiquetas."""
    
    def __init__(self, root):
        self.root = root
        self.root.title("Centro Diagnóstico - Impresión de Etiquetas")
        self.root.geometry("800x600")
        self.root.configure(bg='#f0f8ff')  # Alice Blue
        
        # Configuración
        self.config = self.load_config()
        
        # Variables
        self.paciente_id = tk.StringVar()
        self.paciente_data = None
        self.estudios_lab = []
        self.timeout_id = None
        
        # Colores
        self.colors = {
            'primary': '#1a3a5c',      # Azul oscuro
            'secondary': '#87CEEB',    # Azul cielo
            'success': '#28a745',      # Verde
            'danger': '#dc3545',       # Rojo
            'light': '#f0f8ff',        # Azul claro
            'white': '#ffffff',
            'text': '#333333'
        }
        
        # Crear interfaz
        self.create_widgets()
        
        # Centrar ventana
        self.center_window()
        
        # Enfocar campo de entrada
        self.id_entry.focus()
    
    def load_config(self):
        """Carga la configuración desde archivo o crea una por defecto."""
        config_file = 'config.json'
        
        if os.path.exists(config_file):
            try:
                with open(config_file, 'r', encoding='utf-8') as f:
                    return json.load(f)
            except Exception as e:
                print(f"Error cargando config: {e}")
                return DEFAULT_CONFIG.copy()
        else:
            # Crear config por defecto
            self.save_config(DEFAULT_CONFIG)
            return DEFAULT_CONFIG.copy()
    
    def save_config(self, config=None):
        """Guarda la configuración en archivo."""
        if config is None:
            config = self.config
        
        try:
            with open('config.json', 'w', encoding='utf-8') as f:
                json.dump(config, f, indent=2)
        except Exception as e:
            print(f"Error guardando config: {e}")
    
    def center_window(self):
        """Centra la ventana en la pantalla."""
        self.root.update_idletasks()
        width = self.root.winfo_width()
        height = self.root.winfo_height()
        x = (self.root.winfo_screenwidth() // 2) - (width // 2)
        y = (self.root.winfo_screenheight() // 2) - (height // 2)
        self.root.geometry(f'{width}x{height}+{x}+{y}')
    
    def create_widgets(self):
        """Crea todos los widgets de la interfaz."""
        # Frame principal
        main_frame = tk.Frame(self.root, bg=self.colors['light'])
        main_frame.pack(fill=tk.BOTH, expand=True, padx=20, pady=20)
        
        # Header
        self.create_header(main_frame)
        
        # Área de búsqueda (pantalla inicial)
        self.search_frame = tk.Frame(main_frame, bg=self.colors['light'])
        self.search_frame.pack(fill=tk.BOTH, expand=True)
        self.create_search_screen()
        
        # Área de resultados (oculta inicialmente)
        self.results_frame = tk.Frame(main_frame, bg=self.colors['light'])
        self.create_results_screen()
        
        # Botón de configuración (esquina superior derecha)
        self.create_config_button()
    
    def create_header(self, parent):
        """Crea el encabezado de la aplicación."""
        header_frame = tk.Frame(parent, bg=self.colors['primary'], height=80)
        header_frame.pack(fill=tk.X, pady=(0, 20))
        header_frame.pack_propagate(False)
        
        # Título
        title_font = tkfont.Font(family='Arial', size=24, weight='bold')
        title = tk.Label(
            header_frame,
            text='🏥 Impresión de Etiquetas de Laboratorio',
            font=title_font,
            bg=self.colors['primary'],
            fg=self.colors['white']
        )
        title.pack(expand=True)
    
    def create_search_screen(self):
        """Crea la pantalla de búsqueda."""
        # Contenedor centrado
        center_frame = tk.Frame(self.search_frame, bg=self.colors['white'], 
                               relief=tk.RAISED, borderwidth=2)
        center_frame.place(relx=0.5, rely=0.5, anchor=tk.CENTER, 
                          width=500, height=300)
        
        # Título
        title_font = tkfont.Font(family='Arial', size=18, weight='bold')
        title = tk.Label(
            center_frame,
            text='Ingrese el ID del Paciente',
            font=title_font,
            bg=self.colors['white'],
            fg=self.colors['text']
        )
        title.pack(pady=(30, 10))
        
        # Subtítulo
        subtitle = tk.Label(
            center_frame,
            text='(Solo números, ej: 1328)',
            font=('Arial', 11),
            bg=self.colors['white'],
            fg='#666666'
        )
        subtitle.pack(pady=(0, 30))
        
        # Campo de entrada
        entry_font = tkfont.Font(family='Arial', size=20)
        self.id_entry = tk.Entry(
            center_frame,
            textvariable=self.paciente_id,
            font=entry_font,
            justify=tk.CENTER,
            width=15
        )
        self.id_entry.pack(pady=10, ipady=10)
        self.id_entry.bind('<Return>', lambda e: self.buscar_paciente())
        
        # Botón de búsqueda
        btn_font = tkfont.Font(family='Arial', size=14, weight='bold')
        search_btn = tk.Button(
            center_frame,
            text='🔍 Buscar',
            font=btn_font,
            bg=self.colors['primary'],
            fg=self.colors['white'],
            activebackground=self.colors['secondary'],
            command=self.buscar_paciente,
            cursor='hand2',
            relief=tk.FLAT,
            padx=40,
            pady=10
        )
        search_btn.pack(pady=20)
        
        # Mensaje de estado
        self.status_label = tk.Label(
            center_frame,
            text='',
            font=('Arial', 10),
            bg=self.colors['white'],
            fg=self.colors['danger']
        )
        self.status_label.pack()
    
    def create_results_screen(self):
        """Crea la pantalla de resultados con lista de estudios."""
        # Info del paciente
        info_frame = tk.Frame(self.results_frame, bg=self.colors['white'],
                             relief=tk.RAISED, borderwidth=1)
        info_frame.pack(fill=tk.X, pady=(0, 20))
        
        self.paciente_info_label = tk.Label(
            info_frame,
            text='',
            font=('Arial', 14, 'bold'),
            bg=self.colors['white'],
            fg=self.colors['text'],
            pady=15
        )
        self.paciente_info_label.pack()
        
        # Instrucciones
        instruc_frame = tk.Frame(self.results_frame, bg=self.colors['light'])
        instruc_frame.pack(fill=tk.X, pady=(0, 10))
        
        instruc = tk.Label(
            instruc_frame,
            text='Presione el número del estudio para imprimir, o 0 para imprimir todos',
            font=('Arial', 12),
            bg=self.colors['light'],
            fg=self.colors['text']
        )
        instruc.pack()
        
        # Lista de estudios
        self.estudios_listbox = tk.Listbox(
            self.results_frame,
            font=('Arial', 12),
            selectmode=tk.SINGLE,
            height=10,
            relief=tk.FLAT,
            borderwidth=1,
            highlightthickness=1,
            highlightcolor=self.colors['primary']
        )
        self.estudios_listbox.pack(fill=tk.BOTH, expand=True, pady=10)
        self.estudios_listbox.bind('<<ListboxSelect>>', self.on_estudio_select)
        
        # Botón para volver
        btn_frame = tk.Frame(self.results_frame, bg=self.colors['light'])
        btn_frame.pack(fill=tk.X, pady=10)
        
        back_btn = tk.Button(
            btn_frame,
            text='← Volver',
            font=('Arial', 12, 'bold'),
            bg=self.colors['secondary'],
            fg=self.colors['text'],
            command=self.volver_busqueda,
            cursor='hand2',
            relief=tk.FLAT,
            padx=20,
            pady=8
        )
        back_btn.pack(side=tk.LEFT)
        
        self.timeout_label = tk.Label(
            btn_frame,
            text='',
            font=('Arial', 10),
            bg=self.colors['light'],
            fg='#666666'
        )
        self.timeout_label.pack(side=tk.RIGHT, padx=20)
    
    def create_config_button(self):
        """Crea el botón de configuración."""
        config_btn = tk.Button(
            self.root,
            text='⚙',
            font=('Arial', 16),
            bg=self.colors['secondary'],
            fg=self.colors['text'],
            command=self.abrir_configuracion,
            cursor='hand2',
            relief=tk.FLAT,
            width=3,
            height=1
        )
        config_btn.place(x=10, y=10)
    
    def buscar_paciente(self):
        """Busca el paciente por ID."""
        pid = self.paciente_id.get().strip()
        
        if not pid:
            self.status_label.config(text='Por favor ingrese un ID')
            return
        
        if not pid.isdigit():
            self.status_label.config(text='El ID debe contener solo números')
            return
        
        self.status_label.config(text='Buscando...', fg=self.colors['text'])
        self.root.update()
        
        # Buscar en servidor (con prefijo L automático)
        codigo = f'L{pid}'
        
        try:
            url = f"{self.config['server_url']}/resultados/muestra/{codigo}"
            response = requests.get(url, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                resultado = data.get('data', data)
                
                # Obtener info del paciente
                paciente = resultado.get('paciente', {})
                estudio = resultado.get('estudio', {})
                
                # Verificar si es estudio de laboratorio
                if self.es_estudio_laboratorio(estudio):
                    # Obtener todos los estudios del paciente
                    self.cargar_estudios_paciente(paciente, codigo)
                else:
                    self.status_label.config(
                        text='Este resultado no es de laboratorio',
                        fg=self.colors['danger']
                    )
            else:
                self.status_label.config(
                    text=f'Paciente no encontrado con ID: {pid}',
                    fg=self.colors['danger']
                )
        
        except requests.RequestException as e:
            self.status_label.config(
                text=f'Error de conexión: {str(e)[:50]}',
                fg=self.colors['danger']
            )
        except Exception as e:
            self.status_label.config(
                text=f'Error: {str(e)[:50]}',
                fg=self.colors['danger']
            )
    
    def es_estudio_laboratorio(self, estudio):
        """Verifica si un estudio es de laboratorio."""
        if not estudio:
            return False
        
        # Verificar código
        codigo = estudio.get('codigo', '')
        if codigo and codigo.upper().startswith('LAB'):
            return True
        
        # Verificar categoría
        categoria = estudio.get('categoria', '').lower()
        return any(cat in categoria for cat in LAB_CATEGORIES)
    
    def cargar_estudios_paciente(self, paciente, codigo_inicial):
        """Carga todos los estudios de laboratorio del paciente."""
        try:
            paciente_id = paciente.get('_id') or paciente.get('id')
            url = f"{self.config['server_url']}/resultados/paciente/{paciente_id}"
            response = requests.get(url, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                resultados = data.get('data', [])
                
                # Filtrar solo estudios de laboratorio pendientes
                self.estudios_lab = []
                for res in resultados:
                    estudio = res.get('estudio', {})
                    estado = res.get('estado', '')
                    
                    if self.es_estudio_laboratorio(estudio) and estado == 'pendiente':
                        self.estudios_lab.append({
                            'id': res.get('_id') or res.get('id'),
                            'codigo': res.get('codigoMuestra'),
                            'nombre': estudio.get('nombre', 'Sin nombre'),
                            'categoria': estudio.get('categoria', ''),
                            'paciente': paciente
                        })
                
                if self.estudios_lab:
                    self.paciente_data = paciente
                    self.mostrar_resultados()
                else:
                    self.status_label.config(
                        text='No hay estudios de laboratorio pendientes',
                        fg=self.colors['danger']
                    )
            else:
                self.status_label.config(
                    text='Error cargando estudios del paciente',
                    fg=self.colors['danger']
                )
        
        except Exception as e:
            self.status_label.config(
                text=f'Error: {str(e)[:50]}',
                fg=self.colors['danger']
            )
    
    def mostrar_resultados(self):
        """Muestra la pantalla de resultados."""
        # Ocultar búsqueda, mostrar resultados
        self.search_frame.pack_forget()
        self.results_frame.pack(fill=tk.BOTH, expand=True)
        
        # Mostrar info del paciente
        pac = self.paciente_data
        nombre = f"{pac.get('nombre', '')} {pac.get('apellido', '')}"
        cedula = pac.get('cedula', '')
        info_text = f"Paciente: {nombre} - Cédula: {cedula}"
        self.paciente_info_label.config(text=info_text)
        
        # Llenar listbox con estudios
        self.estudios_listbox.delete(0, tk.END)
        self.estudios_listbox.insert(0, '0 - Imprimir TODOS los labels')
        
        for i, est in enumerate(self.estudios_lab, 1):
            self.estudios_listbox.insert(tk.END, f"{i} - {est['nombre']}")
        
        # Vincular teclas numéricas
        self.root.bind('<Key>', self.on_key_press)
        
        # Iniciar timeout de 30 segundos
        self.start_timeout()
    
    def on_estudio_select(self, event):
        """Maneja la selección de un estudio."""
        selection = self.estudios_listbox.curselection()
        if selection:
            index = selection[0]
            self.imprimir_labels(index)
    
    def on_key_press(self, event):
        """Maneja la presión de teclas numéricas."""
        if event.char.isdigit():
            num = int(event.char)
            if 0 <= num <= len(self.estudios_lab):
                self.imprimir_labels(num)
    
    def imprimir_labels(self, index):
        """Imprime las etiquetas."""
        self.cancel_timeout()
        
        if index == 0:
            # Imprimir todos
            for i, est in enumerate(self.estudios_lab, 1):
                self.generar_e_imprimir_label(est)
            messagebox.showinfo('Éxito', f'Se imprimieron {len(self.estudios_lab)} etiquetas')
        else:
            # Imprimir uno específico
            est = self.estudios_lab[index - 1]
            self.generar_e_imprimir_label(est)
            messagebox.showinfo('Éxito', f'Etiqueta impresa: {est["nombre"]}')
        
        # Iniciar timeout de nuevo
        self.start_timeout()
    
    def generar_e_imprimir_label(self, estudio):
        """Genera e imprime una etiqueta."""
        try:
            # Crear imagen de etiqueta
            width_px = int(self.config['label_width_mm'] * 11.8)  # ~300 DPI
            height_px = int(self.config['label_height_mm'] * 11.8)
            
            img = Image.new('RGB', (width_px, height_px), 'white')
            draw = ImageDraw.Draw(img)
            
            # Fuente (usar fuente por defecto si no hay disponible)
            try:
                font_large = ImageFont.truetype("arial.ttf", 16)
                font_small = ImageFont.truetype("arial.ttf", 12)
            except:
                font_large = ImageFont.load_default()
                font_small = ImageFont.load_default()
            
            # Contenido
            pac = estudio['paciente']
            nombre = f"{pac.get('nombre', '')} {pac.get('apellido', '')}"
            cedula = pac.get('cedula', '')
            codigo = estudio['codigo']
            nombre_estudio = estudio['nombre']
            fecha = datetime.now().strftime('%d/%m/%Y')
            
            y = 10
            draw.text((10, y), nombre[:30], fill='black', font=font_large)
            y += 25
            draw.text((10, y), f"Cédula: {cedula}", fill='black', font=font_small)
            y += 20
            draw.text((10, y), f"ID: {codigo}", fill='black', font=font_large)
            y += 25
            draw.text((10, y), nombre_estudio[:35], fill='black', font=font_small)
            y += 20
            draw.text((10, y), fecha, fill='black', font=font_small)
            
            # Generar código de barras
            try:
                CODE128 = barcode.get_barcode_class('code128')
                barcode_img = CODE128(codigo, writer=ImageWriter())
                
                # Renderizar código de barras a imagen
                buffer = io.BytesIO()
                barcode_img.write(buffer, {'write_text': False})
                buffer.seek(0)
                bc_img = Image.open(buffer)
                
                # Redimensionar y pegar
                bc_width = width_px - 20
                bc_height = 60
                bc_img = bc_img.resize((bc_width, bc_height))
                img.paste(bc_img, (10, height_px - bc_height - 10))
            except Exception as e:
                print(f"Error generando código de barras: {e}")
            
            # Guardar temporalmente
            temp_file = f'temp_label_{codigo}.png'
            img.save(temp_file)
            
            # Imprimir (esto depende del sistema y la impresora)
            # En Windows, se puede usar win32print
            # Por ahora solo guardamos el archivo
            print(f"Etiqueta generada: {temp_file}")
            
            # En producción, aquí iría el código para enviar a la impresora
            # self.enviar_a_impresora(temp_file)
            
        except Exception as e:
            print(f"Error generando etiqueta: {e}")
            messagebox.showerror('Error', f'Error generando etiqueta: {str(e)}')
    
    def enviar_a_impresora(self, image_file):
        """Envía la imagen a la impresora configurada."""
        # TODO: Implementar según el modelo de impresora
        # Esto varía según el fabricante y modelo
        pass
    
    def start_timeout(self):
        """Inicia el timeout de 30 segundos."""
        self.timeout_seconds = 30
        self.update_timeout_label()
        self.timeout_id = self.root.after(1000, self.update_timeout)
    
    def update_timeout(self):
        """Actualiza el contador de timeout."""
        self.timeout_seconds -= 1
        
        if self.timeout_seconds <= 0:
            self.volver_busqueda()
        else:
            self.update_timeout_label()
            self.timeout_id = self.root.after(1000, self.update_timeout)
    
    def update_timeout_label(self):
        """Actualiza la etiqueta del timeout."""
        self.timeout_label.config(
            text=f'Volviendo en {self.timeout_seconds}s...'
        )
    
    def cancel_timeout(self):
        """Cancela el timeout."""
        if self.timeout_id:
            self.root.after_cancel(self.timeout_id)
            self.timeout_id = None
    
    def volver_busqueda(self):
        """Vuelve a la pantalla de búsqueda."""
        self.cancel_timeout()
        
        # Desvincularteclas
        self.root.unbind('<Key>')
        
        # Limpiar datos
        self.paciente_id.set('')
        self.paciente_data = None
        self.estudios_lab = []
        self.status_label.config(text='', fg=self.colors['danger'])
        
        # Ocultar resultados, mostrar búsqueda
        self.results_frame.pack_forget()
        self.search_frame.pack(fill=tk.BOTH, expand=True)
        
        # Enfocar entrada
        self.id_entry.focus()
    
    def abrir_configuracion(self):
        """Abre la ventana de configuración."""
        config_window = tk.Toplevel(self.root)
        config_window.title("Configuración")
        config_window.geometry("500x400")
        config_window.configure(bg=self.colors['light'])
        
        # Centrar
        config_window.transient(self.root)
        config_window.grab_set()
        
        # Frame principal
        frame = tk.Frame(config_window, bg=self.colors['light'])
        frame.pack(fill=tk.BOTH, expand=True, padx=20, pady=20)
        
        # Título
        title = tk.Label(
            frame,
            text='⚙ Configuración',
            font=('Arial', 18, 'bold'),
            bg=self.colors['light'],
            fg=self.colors['text']
        )
        title.pack(pady=(0, 20))
        
        # URL del servidor
        tk.Label(frame, text='URL del Servidor:', font=('Arial', 11),
                bg=self.colors['light']).pack(anchor=tk.W)
        server_var = tk.StringVar(value=self.config['server_url'])
        server_entry = tk.Entry(frame, textvariable=server_var, font=('Arial', 11))
        server_entry.pack(fill=tk.X, pady=(5, 15))
        
        # Modelo de impresora
        tk.Label(frame, text='Modelo de Impresora:', font=('Arial', 11),
                bg=self.colors['light']).pack(anchor=tk.W)
        printer_var = tk.StringVar(value=self.config['printer_model'])
        printer_combo = ttk.Combobox(
            frame,
            textvariable=printer_var,
            font=('Arial', 11),
            state='readonly',
            values=[
                'Zebra GK420',
                'Zebra ZD220',
                'Zebra ZD420',
                'Brother QL-800',
                'Brother QL-820NWB',
                'DYMO LabelWriter',
                'TSC TTP-225',
                'Godex G500',
                'Impresora genérica térmica',
                'Impresora genérica USB'
            ]
        )
        printer_combo.pack(fill=tk.X, pady=(5, 15))
        
        # Tamaño de etiqueta
        tk.Label(frame, text='Tamaño de Etiqueta (mm):', font=('Arial', 11),
                bg=self.colors['light']).pack(anchor=tk.W)
        
        size_frame = tk.Frame(frame, bg=self.colors['light'])
        size_frame.pack(fill=tk.X, pady=(5, 15))
        
        tk.Label(size_frame, text='Ancho:', bg=self.colors['light']).pack(side=tk.LEFT)
        width_var = tk.IntVar(value=self.config['label_width_mm'])
        width_spin = tk.Spinbox(size_frame, from_=20, to=100, textvariable=width_var, width=10)
        width_spin.pack(side=tk.LEFT, padx=5)
        
        tk.Label(size_frame, text='Alto:', bg=self.colors['light']).pack(side=tk.LEFT, padx=(20, 0))
        height_var = tk.IntVar(value=self.config['label_height_mm'])
        height_spin = tk.Spinbox(size_frame, from_=10, to=80, textvariable=height_var, width=10)
        height_spin.pack(side=tk.LEFT, padx=5)
        
        # Botones
        btn_frame = tk.Frame(frame, bg=self.colors['light'])
        btn_frame.pack(fill=tk.X, pady=20)
        
        def guardar():
            self.config['server_url'] = server_var.get()
            self.config['printer_model'] = printer_var.get()
            self.config['label_width_mm'] = width_var.get()
            self.config['label_height_mm'] = height_var.get()
            self.save_config()
            messagebox.showinfo('Éxito', 'Configuración guardada')
            config_window.destroy()
        
        save_btn = tk.Button(
            btn_frame,
            text='Guardar',
            font=('Arial', 12, 'bold'),
            bg=self.colors['success'],
            fg=self.colors['white'],
            command=guardar,
            cursor='hand2',
            relief=tk.FLAT,
            padx=20,
            pady=8
        )
        save_btn.pack(side=tk.LEFT, padx=5)
        
        cancel_btn = tk.Button(
            btn_frame,
            text='Cancelar',
            font=('Arial', 12),
            bg=self.colors['secondary'],
            fg=self.colors['text'],
            command=config_window.destroy,
            cursor='hand2',
            relief=tk.FLAT,
            padx=20,
            pady=8
        )
        cancel_btn.pack(side=tk.LEFT, padx=5)


def main():
    """Función principal."""
    root = tk.Tk()
    app = LabelPrinterApp(root)
    root.mainloop()


if __name__ == '__main__':
    main()
