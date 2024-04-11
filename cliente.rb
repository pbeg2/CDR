require "gtk3"
require "thread"
require_relative "puzzle1"
require_relative "lcd"

class Window < Gtk::Window
  def initialize
    super
    set_title 'rfid_gtk.rb' 
    set_border_width 10
    set_size_request 500, 200

    #Conecta la señal "destroy" de la ventana para cerrar la aplicación
    signal_connect("destroy") do
      Gtk.main_quit
  ##    @thread.kill if @thread #Detiene la ejecución del thread 
    end

    #Crea un contenedor vertical para organizar los objetos
    @hbox = Gtk::Box.new(:vertical, 6)
    add(@hbox)

    #Crea un Label con el mensaje 
    @label = Gtk::Label.new("Por favor, acerque su tarjeta al lector")
    @label.override_background_color(0, Gdk::RGBA.new(0, 0, 1, 1))
    @label.override_color(0, Gdk::RGBA.new(1, 1, 1, 1))
    @label.set_size_request 100, 200
    @hbox.pack_start(@label)

    lcd = LCDController.new
    texto = @label.text
    lcd.escribir_en_lcd(texto)
    
  end  
end
#Crea una instancia de la clase ventana
win = Window.new
#Muestra todos los objetos de la ventana
win.show_all
#Inicia el método rfid
#win.rfid
Gtk.main