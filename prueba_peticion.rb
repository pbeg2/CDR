require 'json'
require 'net/http'

 uri = URI("http://192.168.150.128:9000/students?student_id=#{uid}")
 puts "prueba antes de hacer el response"
 response = Net::HTTP.get(uri)
 puts "prueba despues del response"
 if response.code == '200'
   datos = JSON.parse(response.body)
   puts "#{datos.name}"
 else
   puts "Error: #{response.code}"
 end
