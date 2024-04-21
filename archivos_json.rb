require 'gtk3'
require 'json'

def mostrar_datos_json(nombre_archivo, titulo, headers)
  # Leer el contenido del archivo JSON
  json_content = File.read(nombre_archivo)

  # Parsear el JSON
  datos = JSON.parse(json_content)

  # Obtener la lista correspondiente segun el titulo
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
    grid.attach(header_label, index, 0, 1, 1)
  end

  # Acceder a los datos y mostrar informacion sobre cada uno
  lista.each_with_index do |item, row_index|
    item.each_with_index do |(_, value), column_index|
      tarea_label = Gtk::Label.new(value.to_s)
      grid.attach(tarea_label, column_index, row_index + 1, 1, 1)
    end
  end

  # Mostrar todo
  ventana.show_all
end

# Crear la ventana principal
window = Gtk::Window.new
window.set_title("Consulta de archivos JSON")
window.set_default_size(400, 100)
window.signal_connect("destroy"){Gtk.main_quit}

# Crear el campo de entrada para el query
query_entry = Gtk::Entry.new
query_entry.set_placeholder_text("Ingrese query (timetable, tasks, marks)")

# Manejar el evento 'activate' (presionar Enter)
query_entry.signal_connect("activate") do
  query = query_entry.text.strip.downcase

  case query
  when "timetable"
    mostrar_datos_json('horario2.json', 'horario', ['DÃ­a', 'Hora', 'Materia', 'Aula'])
  when "tasks"
    mostrar_datos_json('tasks.json', 'Tasks', ['Fecha', 'Materia', 'Nombre'])
  when "marks"
    mostrar_datos_json('marks.json', 'Marks', ['Asignatura', 'Nombre', 'Nota'])
  else
    puts "Consulta no vÃ¡lida: #{query}"
  end

  # Limpiar el campo de entrada despues de la consulta
  query_entry.text = ""
end

# Agregar el campo de entrada a la ventana principal
window.add(Gtk::Box.new(:vertical, 5).add(query_entry))
window.show_all

# Iniciar el ciclo principal de eventos
Gtk.main
