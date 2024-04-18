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



require 'net/http'
require 'json'

# URL del servidor y ruta al recurso
url = URI('http://tu_servidor.com/ruta/al/recurso')

# Crear una instancia de Net::HTTP con la URL del servidor
http = Net::HTTP.new(url.host, url.port)

# Realizar la solicitud HTTP GET
response = http.request(Net::HTTP::Get.new(url))

# Verificar el código de respuesta
if response.code == '200'
  # Convertir la respuesta JSON a un hash de Ruby
  data = JSON.parse(response.body)
  
  # Aquí puedes trabajar con los datos recibidos, por ejemplo, imprimirlos
  puts data
else
  puts "Error: #{response.code}"
end
