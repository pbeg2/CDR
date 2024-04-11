require 'gtk3'
require './puzzle1'
Gtk.init

window = Gtk::Window.new                                                              #Se obtiene la ventana con el tamaño predeterminado
window.set_title('Display LCD')
window.set_default_size(160, 120)

textview = Gtk::TextView.new                                                          #Se crea el widget textview para editar y mostrar texto
font_desc = Pango::FontDescription.new("Monospace 10")                                #Override de la fuente a monospace de tamaño 10
textview.override_font(font_desc)

button = Gtk::Button.new(label: 'Display')                                            #Se crea el botón "Display"
lcd = LCDController.new                                                               #Instanciamos la clase LCDController

button.signal_connect('clicked') do                                                   #Conectamos el boton con el lcd
        texto = textview.buffer.text.chomp
        lcd.escribir_en_lcd(texto)
end

box = Gtk::Box.new(:vertical, 5)                                                      #Contenedor que permite organizar los elementos del interfaz en disposiciones horizontales o verticales
box.pack_start(textview, expand: true, fill: true, padding: 5)
box.pack_start(button, expand: false, fill: true, padding: 5)

window.add(box)
window.show_all

Gtk.main
