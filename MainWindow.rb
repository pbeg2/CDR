require "thread"
require_relative 'LCDController'
require_relative 'Rfid'

class MainWindow < Gtk::Window
    def initialize(lcd_controller)
        @lcd_controller = lcd_controller # Crear la instancia de LCDController        
        @window = Gtk::Window.new("course_manager.rb")
        @window.set_default_size(500, 200) # Configurar el tamaño de la ventana   
        # Conectar la señal "destroy" para cerrar la aplicación cuando se cierra la ventana
        @window.signal_connect("destroy") do
            Gtk.main_quit
            @thread.kill if @thread #Detiene la ejecución del thread
        end 
        ventana_inicio # Crear el contenido de la ventana_inicio
    end   

    def ventana_inicio
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
        uri =URI("http://127.0.0.1:9000/students?student_id=#{uid}")
	response = NET::HTTP.get(uri)
        if response.code == '200'
            datos=JSON.parse(response.body)
	    puts "#{datos.name}"
            ventana_query 
        else 
            @lcd_controller.escribir_en_lcd("Authentication error please try again.")
            @label.set_markup("Authentication error, please try again.")
            @frame.override_background_color(:normal, Gdk::RGBA.new(1, 0, 0, 1)) # Color azul

            puts "Authentication error, please try again."
            @thread.kill if @thread
            rfid
            
        end    
    end

    def ventana_query
        #empezar timeout
	timeout
        @frame.destroy
        # Mostrar el mensaje en la LCD
        @lcd_controller.escribir_en_lcd_centrado("Welcome #{@nombre}")

        @nombre = Gtk::Label.new("Welcome #{@nombre}")
        
    
        # Crear el campo de entrada para el query
        @query_entry = Gtk::Entry.new
        @query_entry.set_placeholder_text("Ingrese query (timetable, tasks, marks)")
    
        # Crear el botón de logout
        @button = Gtk::Button.new(label: 'logout')
        @button.set_size_request(50, 50)
        @button.signal_connect('clicked') {ventana_inicio}
    
        # Manejar el evento 'activate' (presionar Enter)
        @query_entry.signal_connect("activate") do
            query = @query_entry.text.strip.downcase
        end

        @table = Gtk::Table.new(2,2,false) 
		@table.set_column_spacing(300) 
		@table.set_row_spacings(5) 

        @table.attach(@nombre, 0,  1,  0,  1, Gtk::AttachOptions::SHRINK, Gtk::AttachOptions::SHRINK, 10 , 0)
		@table.attach(@button, 1,  2,  0,  1, Gtk::AttachOptions::SHRINK, Gtk::AttachOptions::SHRINK, 30, 10)
		@table.attach(@query_entry, 0,  2,  1,  2, Gtk::AttachOptions::FILL, Gtk::AttachOptions::EXPAND, 10, 0)
		
		@window.add(@table)
        @window.show_all
    end
	
#    def timeout
#	GLib::Timeout.add_seconds(20) do
#          puts "Se han superado los 20 segundos."
#          ventana_inicio # Llamar al método ventana_inicio si se supera el tiempo límite
#          false 	          # Importante: Devolver false para que el temporizador no se repita
#	end
#    end

    def tabla_informacion(query)
        case query      
        when "timetables"
            mostrar_datos_json('http://ejemplo.com/horario', 'Timetables', ['Di­a', 'Hora', 'Materia', 'Aula'])
        when "tasks"
            mostrar_datos_json('http://ejemplo.com/tasks', 'Tasks', ['Fecha', 'Materia', 'Nombre'])
        when "marks"
            mostrar_datos_json('http://ejemplo.com/marks', 'Marks', ['Asignatura', 'Nombre', 'Nota'])
        else
#	    timeout
            puts "Consulta no valida: #{query}"
        end
      
        query_entry.text = "" # Limpiar el campo de entrada despues de la consulta
        #reiniciar timeout
#	timeout
    end
end

lcd_controller = LCDController.new # Crear una instancia de LCDController

# Ejecutar la aplicación
MainWindow.new(lcd_controller)
Gtk.main

    def ventana_query
        #empezar timeout
#	timeout
        @frame.destroy
        # Mostrar el mensaje en la LCD
        @lcd_controller.escribir_en_lcd_centrado("Welcome #{@nombre}")

        @nombre = Gtk::Label.new("Welcome #{@nombre}")
        
        # Crear el campo de entrada para el query
        @query_entry = Gtk::Entry.new
        @query_entry.set_placeholder_text("Ingrese query (timetable, tasks, marks)")
    
        # Crear el botón de logout
        @button = Gtk::Button.new(label: 'logout')
        @button.set_size_request(50, 50)
        @button.signal_connect('clicked') {ventana_inicio}
    
        # Manejar el evento 'activate' (presionar Enter)
        @query_entry.signal_connect("activate") do
            query = @query_entry.text.strip.downcase
        end

        @table = Gtk::Table.new(2,2,false) 
		@table.set_column_spacing(300) 
		@table.set_row_spacings(5) 

        @table.attach(@nombre, 0,  1,  0,  1, Gtk::AttachOptions::SHRINK, Gtk::AttachOptions::SHRINK, 10 , 0)
		@table.attach(@button, 1,  2,  0,  1, Gtk::AttachOptions::SHRINK, Gtk::AttachOptions::SHRINK, 30, 10)
		@table.attach(@query_entry, 0,  2,  1,  2, Gtk::AttachOptions::FILL, Gtk::AttachOptions::EXPAND, 10, 0)
		
		@window.add(@table)
        @window.show_all
    end
    
    def tabla_informacion(query)
        case query      
        when "timetables"
            mostrar_datos_json('http://ejemplo.com/horario', 'Timetables', ['Di­a', 'Hora', 'Materia', 'Aula'])
        when "tasks"
            mostrar_datos_json('http://ejemplo.com/tasks', 'Tasks', ['Fecha', 'Materia', 'Nombre'])
        when "marks"
            mostrar_datos_json('http://ejemplo.com/marks', 'Marks', ['Asignatura', 'Nombre', 'Nota'])
        else
	    timeout
            puts "Consulta no valida: #{query}"
        end
     
        query_entry.text = "" # Limpiar el campo de entrada despues de la consulta
        #reiniciar timeout
#	timeout
    end
end

lcd_controller = LCDController.new # Crear una instancia de LCDController

# Ejecutar la aplicación
MainWindow.new(lcd_controller)
Gtk.main
