require "thread"
require 'net/http'
require 'json'
require 'gtk3'
require_relative 'LCDController'
require_relative 'Rfid'

class MainWindow < Gtk::Window
  def initialize(lcd_controller)
      @lcd_controller = lcd_controller # Crear la instancia de LCDController        
      super("course_manager.rb")
      set_default_size(500, 200) # Configurar el tamaño de la ventana   
        # Conectar la señal "destroy" para cerrar la aplicación cuando se cierra la ventana
      signal_connect("destroy") do
          Gtk.main_quit
          @thread.kill if @thread #Detiene la ejecución del thread
      end 
      lcd_controller = LCDController.new # Crear una instancia de LCDController
      ventana_inicio # Crear el contenido de la ventana_inicio
  end   

  def ventana_inicio
        # Crear un marco para enmarcar el mensaje
      frame = Gtk::Frame.new
      frame.set_border_width(10)
      frame.override_background_color(:normal, Gdk::RGBA.new(0, 0, 1, 1)) # Color azul        
       # Crear un contenedor Gtk::Grid dentro del marco para organizar verticalmente
      grid = Gtk::Grid.new
      grid.set_row_spacing(5)
      grid.set_column_spacing(5)
      frame.add(grid)
      # Mensaje antes de la autenticación
      label = Gtk::Label.new("Please, login with your university card")
      label.override_color(:normal, Gdk::RGBA.new(1, 1, 1, 1)) # Color blanco
      label.set_halign(:center) # Centrar el texto horizontalmente en la etiqueta
       grid.attach(label, 0, 0, 1, 1)

      @lcd_controller.escribir_en_lcd(" Please, login with your university card") # Mostrar el mensaje inicial en la LCD
      add(@frame) # Agregar el marco a la ventana
      show_all
      rfid
  end

  def rfid
      @rfid = Rfid.new
      iniciar_lectura_rfid # Iniciar lectura RFID
  end

  def iniciar_lectura_rfid
        # Crea un thread para leer el uid
      @thread = Thread.new do
          @uid = @rfid.read_uid
          GLib::Idle.add do
              autenticacion(@uid)
              false # Para detener la repetición de la llamada a la función
          end
      end
  end

  def autenticacion(uid)
      uri = URI("http://172.20.10.10:9000/students?student_id=#{uid}") #peticion
      response = Net::HTTP.get(uri)
      datos=JSON.parse(response)
      student = datos["students"].first #accedemos a los datos
      puts student["name"]
      
      if student
          ventana_query 
      else
          children.each { |child| remove(child) } #limpiamos
          @lcd_controller.escribir_en_lcd("Authentication error please try again.")
          @label.set_markup("Authentication error, please try again.")
          @frame.override_background_color(:normal, Gdk::RGBA.new(1, 0, 0, 1)) # Color rojo
        
          puts "Authentication error, please try again."
          @thread.kill if @thread
          rfid  
          end    
  end

  def ventana_query
      #empezar timeout
      children.each { |child| remove(child) } #limpiamos
	    #timeout
      #@frame.destroy
        # Mostrar el mensaje en la LCD
      @lcd_controller.escribir_en_lcd_centrado("Welcome #{@nombre}")
      nombre_label = Gtk::Label.new("Welcome #{@nombre}")
      # Crear el campo de entrada para el query
      query_entry = Gtk::Entry.new
      query_entry.set_placeholder_text("Ingrese query (timetable, tasks, marks)")    
        # Crear el botón de logout
      button = Gtk::Button.new(label: 'logout')
      button.set_size_request(50, 50)
      button.signal_connect('clicked') {ventana_inicio}
    
        # Manejar el evento 'activate' (presionar Enter)
      query_entry.signal_connect("activate") do
          query = query_entry.text.strip.downcase
          case query
          when "timetables"
              mostrar_datos_json('http://172.20.10.10:9000/timetables', 'timetables', ['Day', 'Hour', 'Subject', 'Room'])
          when "tasks"
              mostrar_datos_json('http://172.20.10.10:9000/tasks', 'tasks', ['Date', 'Subject', 'Name'])
          when "marks"
              mostrar_datos_json('http://172.20.10.10:9000/marks', 'marks', ['Subject', 'Name', 'Mark'])
          else
              puts "Consulta no válida: #{query}"
          end
              query_entry.text = ""
    end

    grid = Gtk::Grid.new
    grid.set_row_spacing(5)
    grid.set_column_spacing(5)
    grid.attach(nombre_label, 0, 0, 1, 1)
    grid.attach(button, 1, 0, 1, 1)
    grid.attach(query_entry, 0, 1, 2, 1)
		
    add(grid)
    show_all
  end

  def mostrar_datos_json(url, titulo, headers)
  # Obtener los datos JSON desde la URL
    uri = URI(url)
    json_content = Net::HTTP.get(uri)
    datos = JSON.parse(json_content)
    # Obtener la lista correspondiente según el título
    lista = datos[titulo]
    # Crear la ventana para mostrar los datos
    ventana = Gtk::Window.new
    ventana.set_title(titulo)
    ventana.set_default_size(400, 300)
    # Crear un contenedor de tipo Grid
    grid = Gtk::Grid.new
    grid.set_row_spacing(5)
    grid.set_column_spacing(5)
    
    ventana.add(grid)
    # recorremos encabezados y añadimos
    headers.each_with_index do |encabezado, index|
        header_label = Gtk::Label.new(encabezado)
        header_label.override_background_color(:normal, Gdk::RGBA.new(0.0, 0.0, 0.5, 1.0)) # Azul oscuro
        grid.attach(header_label, index, 0, 1, 1)
    end
    # Acceder a los datos y mostrar información sobre cada uno
    lista.each_with_index do |item, row_index|
        item.each_with_index do |(_, value), column_index|
            tarea_label = Gtk::Label.new(value.to_s)
            grid.attach(tarea_label, column_index, row_index + 1, 1, 1)
            if row_index % 2 == 0
                tarea_label.override_background_color(:normal, Gdk::RGBA.new(0.7, 0.7, 1.0, 1.0)) # Azul claro
            else
                tarea_label.override_background_color(:normal, Gdk::RGBA.new(0.5, 0.5, 1.0, 1.0)) # Azul más o>
            end
        end
    end
    # Mostrar todo
    ventana.show_all
  end

##app

MainWindow.new
Gtk.main
