require "gtk3"
require "thread"
require_relative 'LCDController'
require_relative 'Rfid'
require 'json'
require 'net/http'

class MainWindow < Gtk::Window
    def initialize(lcd_controller)
        @lcd_controller = lcd_controller # Crear la instancia de LCDController
        
        @window = Gtk::Window.new("course_manager.rb")
        @window.set_default_size(500, 200) # Configurar el tamaño de la ventana
        
        
        @thread = nil  # Inicializar el hilo como nulo al principio
        # Conectar la señal "destroy" para cerrar la aplicación cuando se cierra la ventana
        @window.signal_connect("destroy") do
            Gtk.main_quit
            @thread.kill if @thread #Detiene la ejecución del thread
            Gtk.main_quit
        end 
        ventana_inicio # Crear el contenido de la ventana_inicio
    end   

    def ventana_inicio
        @window.children.each{|widget| @window.remove(widget)} #eliminar widgets
        # Crear un marco para enmarcar el mensaje
        @frame = Gtk::Frame.new
        @frame.set_border_width(10)
        @frame.override_background_color(:normal, Gdk::RGBA.new(0, 0, 1, 1)) # Color azul
       
        # Crear un contenedor Gtk::Box dentro del marco para organizar verticalmente
        box = Gtk::Box.new(:vertical, 5)
        @frame.add(box)

        # Mensaje antes de la autenticación
        @label = Gtk::Label.new("Please, login with your university card")
        @label.override_color(:normal, Gdk::RGBA.new(1, 1, 1, 1)) # Color blanco
        @label.set_halign(:center) # Centrar el texto horizontalmente en la etiqueta
        box.pack_start(@label, expand: true, fill: true, padding: 10)

        @lcd_controller.escribir_en_lcd(" Please, login with your university card") # Mostrar el mensaje inicial en la LCD
        @window.add(@frame) # Agregar el marco a la ventana

        @window.show_all
        rfid
    end   

    def rfid
        @rfid = Rfid.new
        iniciar_lectura_rfid # Iniciar lectura RFID
    end

    def iniciar_lectura_rfid
        # Crea un thread para leer el uid
        thread = Thread.new do
            @uid = @rfid.read_uid
            GLib::Idle.add do
                autenticacion(@uid)
                false # Para detener la repetición de la llamada a la función
            end
        end
    end

    def autenticacion(uid)

        uri = URI("http://172.20.10.10:9000/students?student_id=#{uid}")
        puts "prueba antes de hacer el response"
        response = Net::HTTP.get(uri)
        puts "prueba despues del response"
        datos = JSON.parse(response)
        student = datos["students"].first
        puts student["name"]
        
        if datos["error"]
            @lcd_controller.escribir_en_lcd("Authentication error please try again.")
            @label.set_markup("Authentication error, please try again.")
            @frame.override_background_color(:normal, Gdk::RGBA.new(1, 0, 0, 1)) # Color azul

            puts "Authentication error, please try again."
            @thread.kill if @thread
            rfid
        else 
            @nombre = student["name"]
            ventana_query 
        end    
    end

    def ventana_query
        # Empezar timeout
    
        @frame.destroy
        # Mostrar el mensaje en la LCD
        @lcd_controller.escribir_en_lcd_centrado("Welcome #{@nombre}")    
        @nombre = Gtk::Label.new("Welcome #{@nombre}")
    
        # Crear el campo de entrada para el query
        @query_entry = Gtk::Entry.new
        @query_entry.set_placeholder_text("Ingrese query (timetables, tasks, marks)")
    
        # Crear el botón de logout
        @button = Gtk::Button.new(label: 'logout')
        @button.set_size_request(50, 50)
        @button.signal_connect('clicked') { ventana_inicio }

        @table = Gtk::Table.new(20,4,false)
	@table.set_column_spacing(10) 
	@table.set_row_spacings(5) 

        @table.attach(@nombre, 0,  1,  0,  1, Gtk::AttachOptions::SHRINK, Gtk::AttachOptions::SHRINK, 10 , 0)
	@table.attach(@button, 3,  4,  0,  1, Gtk::AttachOptions::SHRINK, Gtk::AttachOptions::SHRINK, 30, 10)
	@table.attach(@query_entry, 0,  4,  1,  2, Gtk::AttachOptions::FILL, Gtk::AttachOptions::EXPAND, 10, 0)
	
	@window.add(@table)
	    
        # Manejar el evento 'activate' (presionar Enter)
        @query_entry.signal_connect("activate") do
            query = @query_entry.text.strip.downcase
            #tabla_informacion(query) # Llamar a tabla_informacion con el query ingresado
            case query
            when "timetables"
                mostrar_datos_json('http://172.20.10.10:9000/timetables', 'timetables', ['Day', 'Hour', 'Subject', 'Room'],@table)
            when "tasks"
                mostrar_datos_json('http://172.20.10.10:9000/tasks', 'tasks', ['Date', 'Subject', 'Name'], @table)
            when "marks"
                mostrar_datos_json('http://172.20.10.10:9000/marks', 'marks', ['Subject', 'Name', 'Mark'], @table)
            else
		@query_error = Gtk::Label.new("Consulta no válida")
		@query_error.override_color(:normal, Gdk::RGBA.new(1.0, 0.0, 0.0, 1.0)) #color rojo
		@table.attach(@query_error, 1,  3,  2,  3, Gtk::AttachOptions::FILL, Gtk::AttachOptions::EXPAND, 10, 0)	#se añade el error en la tabla
                puts "Consulta no válida: #{query}"
            end  
            @query_entry.text = "" # Limpiar el campo de entrada después de la consulta
        end
        @window.show_all
    end

    def mostrar_datos_json(url, titulo, headers,tabla)
        # Obtener los datos JSON desde la URL
        uri = URI(url)
        json_content = Net::HTTP.get(uri)
        
        datos = JSON.parse(json_content)

        if datos["error"]
            @texto_error = Gtk::Label.new("No hay información")
        end

	#añadir titulo en la tabla
        tabla.attach(titulo, 1,  3,  2,  3, Gtk::AttachOptions::FILL, Gtk::AttachOptions::EXPAND, 10, 0)
	# Obtener la lista correspondiente según el título	
        lista = datos[titulo]
        
        # Recorremos encabezados y lo añadimos a la ventana como labels
        headers.each_with_index do |encabezado, index|
            header_label = Gtk::Label.new(encabezado)
            header_label.override_background_color(:normal, Gdk::RGBA.new(0.95, 0.95, 0.5, 1.0)) # amarillo claro
            tabla.attach(header_label, index, index+1, 3, 4)
        end
      
        # Acceder a los datos y mostrar información sobre cada uno
        lista.each_with_index do |item, row_index|
            item.each_with_index do |(key, value), column_index|
                    next if column_index == item.size - 1 #eliminamos columna de id
                    tarea_label = Gtk::Label.new(value.to_s)
                    tabla.attach(tarea_label,  column_index, column_index + 1, row_index + 4, row_index + 5)
                    if row_index % 2 == 0 #si es par --> azul claro , si es impar -->azul oscuro
                        tarea_label.override_background_color(:normal, Gdk::RGBA.new(0.7, 0.7, 1.0, 1.0)) # Azul claro
                    else
                        tarea_label.override_background_color(:normal, Gdk::RGBA.new(0.5, 0.5, 1.0, 1.0)) # Azul más oscuro
                    end
            end
        end
      
    end
    
end

lcd_controller = LCDController.new # Crear una instancia de LCDController

# Ejecutar la aplicación
MainWindow.new(lcd_controller)
Gtk.main
