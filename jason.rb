require 'json'

# Leer el contenido del archivo JSON
json_content = File.read('horario_clases.json')


# Parsear el JSON
datos = JSON.parse(json_content)

# Acceder a la lista de clases y mostrar información sobre cada una
datos['horario'].each do |clase|
  puts "Clase: #{clase['clase']}"
  puts "Hora: #{clase['hora']}"
  puts "Aula: #{clase['aula']}"
  puts "-" * 20
end
