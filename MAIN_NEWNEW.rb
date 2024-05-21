require "gtk3"
require "thread"
require_relative 'LCDController'
require_relative 'Rfid'
require 'json'
require 'net/http'

class MainWindow < Gtk::Window
  def initialize(lcd_controller)
    super("course_manager.rb")
    set_default_size(500, 200) # Configurar el tamaño de la ventana

    @lcd_controller = lcd_controller
    @thread = nil  # Inicializar el hilo como nulo al principio
    @timeout_id = nil

    signal_connect("destroy") do
      Gtk.main_quit
      @thread.kill if @thread # Detiene la ejecución del thread
    end

    @state = :inicio
    handle_event(:start)
  end

  def handle_event(event)
    case @state
    when :inicio
      case event
      when :start
        @lcd_controller.escribir_en_lcd(" Please, login with your university card")

        children.each { |widget| remove(widget) }

        @frame = Gtk::Frame.new
        @frame.set_border_width(10)
        @frame.override_background_color(:normal, Gdk::RGBA.new(0, 0, 1, 1))

        box = Gtk::Box.new(:vertical, 5)
        @frame.add(box)

        @label = Gtk::Label.new("Please, login with your university card")
        @label.override_color(:normal, Gdk::RGBA.new(1, 1, 1, 1))
        @label.set_halign(:center)
        box.pack_start(@label, expand: true, fill: true, padding: 10)

        add(@frame)
        show_all

        @state = :rfid
        handle_event(:read_uid)
      end
    when :rfid
      case event
      when :read_uid
        @rfid = Rfid.new
        @thread = Thread.new do
          @uid = @rfid.read_uid
          GLib::Idle.add do
            @state = :autenticacion
            handle_event(:authenticate)
            false
          end
        end
      end
    when :autenticacion
      case event
      when :authenticate
        @thread = Thread.new do
      response=Net::HTTP.get_response(URI("http://172.20.10.10:9000/students?student_id=#{@uid}"))
          datos = JSON.parse(response)
          student = datos["students"].first

          GLib::Idle.add do
            if datos["error"] || student.nil?
              @lcd_controller.escribir_en_lcd("Authentication error please try again.")
              @label.set_markup("Authentication error, please try again.")
              @frame.override_background_color(:normal, Gdk::RGBA.new(1, 0, 0, 1))
              puts "Authentication error, please try again."
              @state = :inicio
              handle_event(:start)
            else
              @nombre = student["name"]
              @state = :query
              handle_event(:show_query)
            end
            false
          end
        end
      end
    when :query
      case event
      when :show_query
        iniciar_timeout
        ip = '172.20.10.10'
        @frame.destroy

        @lcd_controller.escribir_en_lcd_centrado("Welcome #{@nombre}")

        @table = Gtk::Table.new(2, 2, true)
        @table.set_column_spacing(300)
        @table.set_row_spacings(10)

        @nombre_label = Gtk::Label.new("Welcome #{@nombre}")

        @query_entry = Gtk::Entry.new
        @query_entry.set_placeholder_text("Ingrese query (timetables, tasks, marks)")

        @button = Gtk::Button.new(label: 'logout')
        @button.set_size_request(50, 50)
        @button.signal_connect('clicked') do
          handle_event(:logout)
        end

        @table.attach(@nombre_label, 0, 1, 0, 1, Gtk::AttachOptions::SHRINK, Gtk::AttachOptions::SHRINK, 10, 10)
        @table.attach(@button, 1, 2, 0, 1, Gtk::AttachOptions::SHRINK, Gtk::AttachOptions::SHRINK, 10, 10)
        @table.attach(@query_entry, 0, 2, 1, 2, Gtk::AttachOptions::FILL, Gtk::AttachOptions::EXPAND, 10, 10)

        @query_entry.signal_connect("activate") do
          detener_timeout
          iniciar_timeout
          handle_event(:submit_query)
          @query_entry.text = ""
        end

        add(@table)
        show_all
      when :submit_query
        query_text = @query_entry.text.strip
        @thread = Thread.new do
          json_content = Net::HTTP.get_response(URI("http://172.20.10.10:9000/#{query_text}"))
          datos = JSON.parse(json_content)

          GLib::Idle.add do
            if datos["error"]
              puts "Consulta no valida"
              next
            end

            titulo = datos.keys.first

            if datos[titulo].empty?
              puts "Query vacia"
              next
            end

            headers = datos[titulo][0].keys
            headers.pop

            lista = datos[titulo]

            @tabla = Gtk::Window.new
            @tabla.set_title(titulo)
            @tabla.set_default_size(400, 300)

            grid = Gtk::Grid.new
            grid.set_row_spacing(5)
            grid.set_column_spacing(5)

            @tabla.add(grid)

            headers.each_with_index do |encabezado, index|
              header_label = Gtk::Label.new(encabezado)
              header_label.override_background_color(:normal, Gdk::RGBA.new(0.95, 0.95, 0.5, 1.0))
              grid.attach(header_label, index, 0, 1, 1)
              header_label.hexpand = true
            end

            lista.each_with_index do |item, row_index|
              item.each_with_index do |(key, value), column_index|
                next if column_index == item.size - 1

                tarea_label = Gtk::Label.new(value.to_s)
                grid.attach(tarea_label, column_index, row_index + 1, 1, 1)
                tarea_label.hexpand = true
                if row_index % 2 == 0
                  tarea_label.override_background_color(:normal, Gdk::RGBA.new(0.7, 0.7, 1.0, 1.0))
                else
                  tarea_label.override_background_color(:normal, Gdk::RGBA.new(0.5, 0.5, 1.0, 1.0))
                end
              end
            end
            @tabla.show_all
            false
          end
        end
      when :logout
        detener_timeout
        @state = :inicio
        handle_event(:start)
      end
    when :timeout
      case event
      when :timeout_exceeded
        @tabla.hide if @tabla
        @state = :inicio
        handle_event(:start)
      end
    else
      puts "Estado desconocido: #{@state}"
    end
  end

  def iniciar_timeout
    @timeout_id = GLib::Timeout.add_seconds(15) do
      handle_event(:timeout_exceeded)
      false
    end
  end

  def detener_timeout
    GLib::Source.remove(@timeout_id) if @timeout_id
  end
end

lcd_controller = LCDController.new # Crear una instancia de LCDController

# Ejecutar la aplicación
MainWindow.new(lcd_controller)
Gtk.main

