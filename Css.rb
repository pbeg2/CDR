require 'gtk3'

class Ventana

  def iniciar(titulo, headers)
# Crear la ventana para mostrar los datos
    ventana = Gtk::Window.new
    ventana.set_title(titulo)
    ventana.set_default_size(400, 300)
# Crear un contenedor de tipo Grid
    grid = Gtk::Grid.new
    grid.set_row_spacing(5)
    grid.set_column_spacing(5)
    ventana.add(grid)
# Encabezados
    headers.each_with_index do |encabezado, index|
      header_label = Gtk::Label.new(encabezado)
      grid.attach(header_label, index, 0, 1, 1)
    end
    return grid
    
  end

  def mostrar_ventana(ventana)
    ventana.show_all
  end
end
  


