#PRUEBA PARA VERIFICAR LA CONEXIÓN CON LA UID

require 'mfrc522' #libreria necesaria para interectuar con el lector RFID-RC522
require 'json'
require 'net/http'
require_relative 'datosjson'

class Rfid
        def read_uid
        #puts "Por favor, acerque su tarjeta al lector" #pedimos al usuario que acerque su tarjeta para identificarse

        #intentamos leer la UID de la tarjeta
        begin
                r = MFRC522.new #creamos una nueva instancia de MFRC522
                r.picc_request(MFRC522::PICC_REQA) #enviamos una solicitud a la RFID para establecer comunicación
                uid_dec, _ = r.picc_select #intentamos leer la UID y almacenamos a la variable "uid_dec"
                rescue CommunicationError #capturamos la excepcion en caso de error de lectura o timeout
                        retry #volvemos a intentarlo
                end

        #convertimos el UID obtenido en hexadecimal y lo concatenamos en una cadena
        uid = Array.new
                uid_dec.length.times do |i|
                        uid[i]=uid_dec[i].to_s(16)
                end

                return uid.join().upcase #retornamos la UID en mayusculas
        end
end

if __FILE__ == $0 #para inicializar el programa

        rf = Rfid.new #creamos una nueva instancia de Rfid
        uid = rf.read_uid #método para leer la UID de la tarjeta
        puts "UID: #{uid}"
        ejecutar_todo  
end

######################################

require 'gtk3'
require 'json'
require 'net/http'

def mostrar_datos_json(url, titulo, headers)
  # Obtener los datos JSON desde la URL
  uri = URI(url) 
  #peticion 
  json_content = Net::HTTP.get(uri)
  if  json_content.code == '200'
    # Parsear el JSON
      datos = JSON.parse(json_content)
  else
      puts "Error: #{response.code}"   
  end
  # Obtener la lista correspondiente segÃºn el tÃ­tulo
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

  # Acceder a los datos y mostrar informaciÃ³n sobre cada uno
  lista.each_with_index do |item, row_index|
    item.each_with_index do |(_, value), column_index|
      tarea_label = Gtk::Label.new(value.to_s)
      grid.attach(tarea_label, column_index, row_index + 1, 1, 1)
    end
  end

  # Mostrar todo
  ventana.show_all
end

def ejecutar_todo
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
  when "timetables"
    mostrar_datos_json('http://192.168.150.128:9000/horario', 'Horario', ['Di­a', 'Hora', 'Materia', 'Aula'])
  when "tasks"
    mostrar_datos_json('http://192.168.150.128:9000/tasks', 'Tasks', ['Fecha', 'Materia', 'Nombre'])
  when "marks"
    mostrar_datos_json('http://192.168.150.128:9000/marks', 'Marks', ['Asignatura', 'Nombre', 'Nota'])
  else
    puts "Consulta no valida: #{query}"
  end

  # Limpiar el campo de entrada despuÃ©s de la consulta
  query_entry.text = ""
end

# Agregar el campo de entrada a la ventana principal
window.add(Gtk::Box.new(:vertical, 5).add(query_entry))
window.show_all

# Iniciar el ciclo principal de eventos
Gtk.main

end
