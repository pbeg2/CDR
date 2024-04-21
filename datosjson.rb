require 'gtk3'
require 'json'
require 'net/http'

def mostrar_datos_json(url, titulo, headers)
  # Obtener los datos JSON desde la URL
  uri = URI(url)
  json_content = Net::HTTP.get(uri)

  if json_content.code == '200'
    # Parsear el JSON
    datos = JSON.parse(json_content)
  else
    puts "Error: #{json_content.code}"
    return
  end

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

  # Encabezados
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
        tarea_label.override_background_color(:normal, Gdk::RGBA.new(0.5, 0.5, 1.0, 1.0)) # Azul más oscuro
      end
    end
  end

  # Mostrar todo
  ventana.show_all
end

# Crear la ventana principal
window = Gtk::Window.new
window.set_title("Consulta de archivos JSON")
window.set_default_size(400, 100)
window.signal_connect("destroy") { Gtk.main_quit }

# Crear el campo de entrada para la query
query_entry = Gtk::Entry.new
query_entry.set_placeholder_text("Ingrese query (timetable, tasks, marks)")

# Manejar el evento 'activate' (presionar Enter)
query_entry.signal_connect("activate") do
  query = query_entry.text.strip.downcase

  case query
  when "timetables"
    mostrar_datos_json('http://172.20.10.10:9000/horario', 'horario', ['Día', 'Hora', 'Materia', 'Aula'])
  when "tasks"
    mostrar_datos_json('http://172.20.10.10:9000/tasks', 'tasks', ['Fecha', 'Materia', 'Nombre'])
  when "marks"
    mostrar_datos_json('http://172.20.10.10:9000/marks', 'marks', ['Asignatura', 'Nombre', 'Nota'])
  else
    puts "Consulta no válida: #{query}"
  end

  # Limpiar el campo de entrada después de la consulta
  query_entry.text = ""
end

# Agregar el campo de entrada a la ventana principal
window.add(Gtk::Box.new(:vertical, 5).add(query_entry))

# Mostrar la ventana principal
window.show_all

# Iniciar el ciclo principal de eventos
Gtk.main
