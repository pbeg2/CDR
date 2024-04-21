#PRUEBA PARA VERIFICAR LA CONEXIÓN CON LA UID

require 'mfrc522' #libreria necesaria para interectuar con el lector RFID-RC522
require 'json'
require 'net/http'

class Rfid
        def read_uid
        #puts "Por favor, acerque su tarjeta al lector" #pedimos al usuario que acerque su tarjeta par>

        #intentamos leer la UID de la tarjeta
        begin

                r = MFRC522.new #creamos una nueva instancia de MFRC522

                r.picc_request(MFRC522::PICC_REQA) #enviamos una solicitud a la RFID para establecer c>

                uid_dec, _ = r.picc_select #intentamos leer la UID y almacenamos a la variable "uid_de>

                rescue CommunicationError #capturamos la excepcion en caso de error de lectura o timeo>

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
        #inicializar datosjson
        uri = URI("http://172.20.10.10:9000/students?student_id=#{uid}")
        puts "prueba antes de hacer el response"
        response = Net::HTTP.get(uri)
        puts "prueba despues del response"
        datos = JSON.parse(response)
        student = datos["students"].first
        puts student["name"]
