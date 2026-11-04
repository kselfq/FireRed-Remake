#===============================================================================
# Datos del juego dentro de una pantalla.
#
# PARA QUE SIRVE
#   Sin esto, un texto solo puede decir algo fijo. Con esto puede decir el nombre
#   del jugador, su dinero, la vida del primer Pokemon del equipo... o sea que se
#   pueden construir pantallas DE VERDAD (una ficha, un HUD, una caja de datos de
#   combate) y no solo menus de botones.
#
#   En el diseño se escriben entre llaves y se sustituyen al abrir la pantalla:
#
#     "texto": "{jugador} tiene {dinero}$"
#     "texto": "{equipo.1.nombre}  Nv{equipo.1.nivel}"
#     "texto": "{equipo.1.hp}/{equipo.1.hp_max}"
#
# LA REGLA QUE NO SE PUEDE ROMPER
#   PEDIR UN DATO NUNCA PUEDE TIRAR EL JUEGO. Una pantalla se puede abrir sin
#   partida empezada, con el equipo vacio, desde el menu de debug o en mitad de
#   un combate, y en cualquiera de esos casos la mitad de estos datos no existen.
#   Todo va envuelto y lo que no se puede saber devuelve un hueco visible ("---"),
#   que ademas se ve raro en pantalla y por eso se detecta enseguida.
#
# COMO AÑADIR UNO NUEVO
#   Una linea en FUENTES. El bloque recibe los trozos de despues del primer punto
#   ("equipo.1.hp" -> ["1", "hp"]) y devuelve lo que sea; se convierte a texto.
#===============================================================================

module Interfaces
  module Datos
    HUECO = "---"          # lo que se ve cuando un dato no esta disponible

    #---------------------------------------------------------------------------
    # QUE BOTON ESTA ELEGIDO AHORA MISMO.
    #
    # POR QUE ES UN DATO Y NO UNA PROPIEDAD NUEVA DEL ELEMENTO
    #   Lo que hace falta en una pantalla de equipo es "esta ficha se ve distinta
    #   cuando es la elegida". Se podria haber inventado una propiedad, pero
    #   publicandolo como DATO sale gratis y sale mejor: se combina con las
    #   condiciones que ya existen y con el {n} de las listas repetidas, o sea que
    #   cada copia puede preguntar por si misma sin sintaxis nueva:
    #
    #     ficha normal    "mostrar_si": { "dato": "{seleccion}", "no_es": "{n}" }
    #     ficha marcada   "mostrar_si": { "dato": "{seleccion}", "es": "{n}" }
    #
    #   Y de paso vale para cualquier otra cosa: un texto de ayuda que cambie
    #   segun donde estes, un retrato que solo salga en la tercera opcion...
    #
    #     {seleccion}     el numero de copia del boton elegido (1, 2, 3...)
    #     {seleccion.id}  su nombre entero, para los botones que no se repiten
    #
    # SE GUARDA TAMBIEN EL NOMBRE DE ORIGEN, y no es un adorno: si el boton se
    # repite, la copia elegida se llama "opcion_3" pero en el diseño ese boton se
    # llama "opcion". Una condicion "cuando este elegido opcion" tiene que
    # cumplirse igual, porque es el unico nombre que el editor puede ofrecer.
    #---------------------------------------------------------------------------
    def self.fijar_seleccion(numero, id, origen = nil)
      @seleccion_n      = numero
      @seleccion_id     = id.to_s
      @seleccion_origen = origen.nil? ? id.to_s : origen.to_s
    end

    def self.olvidar_seleccion
      @seleccion_n      = nil
      @seleccion_id     = nil
      @seleccion_origen = nil
    end

    # ¿Es "nombre" el boton elegido ahora mismo? Vale tanto el nombre de la copia
    # como el del elemento del diseño.
    #
    # Esta suelto en un metodo, y no dentro del proc de {seleccion}, para que el
    # editor pueda hacer la misma cuenta con el mismo nombre y no se separen. Es
    # el mismo motivo por el que existe tools/test-interfaces.mjs.
    def self.es_el_elegido?(nombre)
      n = nombre.to_s.downcase
      return false if n.empty?
      return true if @seleccion_id.to_s.downcase == n
      return true if @seleccion_origen.to_s.downcase == n
      return false
    end

    # Las barras necesitan numeros, no textos. Un dato que no se puede saber vale
    # 0 aqui, para que una barra rota se vea vacia en vez de reventar.
    def self.numero(clave)
      v = valor(clave)
      return 0.0 if v.nil? || v == HUECO
      return v.to_f
    end

    #---------------------------------------------------------------------------
    # El valor de un dato, ya en texto.
    #---------------------------------------------------------------------------
    def self.valor(clave)
      partes = clave.to_s.strip.split(".")
      raiz = partes.shift.to_s.downcase
      fuente = FUENTES[raiz]
      return HUECO if fuente.nil?
      begin
        v = fuente.call(partes)
        return HUECO if v.nil?
        return v.to_s
      rescue Exception => e
        raise if e.is_a?(SystemExit) || e.is_a?(Interrupt) || e.is_a?(NoMemoryError)
        # Que un dato no este (sin partida, equipo vacio, fuera de combate) es
        # normal, no es un fallo del que haya que enterarse a gritos.
        return HUECO
      end
    end

    # Sustituye todas las {llaves} de un texto.
    def self.rellenar(texto)
      t = texto.to_s
      return t if !t.include?("{")
      return t.gsub(/\{([^{}]+)\}/) { valor($1) }
    end

    # ¿Este texto depende de algo que puede cambiar mientras la pantalla esta
    # abierta? Si es que si, hay que volver a pintarlo cada cierto tiempo.
    def self.tiene_datos?(texto)
      return texto.to_s.include?("{")
    end

    #---------------------------------------------------------------------------
    # CONDICIONES: enseñar algo solo cuando se cumple algo.
    #
    #   "mostrar_si": { "dato": "{equipo.total}", "mayor_que": 3 }
    #   "mostrar_si": { "dato": "{interruptor.20}", "es": 1 }
    #   "mostrar_si": { "dato": "{equipo.{n}.nombre}", "existe": true }
    #
    # El ultimo es el que hace util una lista repetida: pon seis fichas y las de
    # los huecos vacios se esconden solas.
    #
    # NUNCA PUEDE TIRAR EL JUEGO NI ESCONDERLO TODO EN SILENCIO. Una condicion que
    # no se entiende devuelve true (se ve) y avisa. Preferir enseñar de mas a que
    # alguien se quede mirando una pantalla vacia sin saber por que.
    #---------------------------------------------------------------------------
    COMPARADORES = ["es", "no_es", "mayor_que", "menor_que", "mayor_o_igual",
                    "menor_o_igual", "existe", "contiene"]

    def self.cumple?(cond, avisar = nil)
      return true if cond.nil?
      if !cond.is_a?(Hash)
        avisar&.call("una condicion tiene que ser un objeto { }")
        return true
      end
      clave = cond["dato"].to_s.strip
      if clave.empty?
        avisar&.call("una condicion no dice que dato mira")
        return true
      end
      izq = valor(clave.gsub(/\A\{|\}\z/, ""))

      # "existe" es el unico que mira el hueco: todo lo demas compara valores.
      if cond.key?("existe")
        hay = !(izq.nil? || izq == HUECO || izq.to_s.empty?)
        return cond["existe"] ? hay : !hay
      end

      comp = COMPARADORES.find { |c| cond.key?(c) }
      if comp.nil?
        avisar&.call("la condicion sobre #{clave} no dice que comparar " \
                     "(#{COMPARADORES.join(", ")})")
        return true
      end
      der = cond[comp]

      # Si los dos lados parecen numeros se comparan como numeros; si no, como
      # texto. Asi "3" y 3 son lo mismo, que es lo que espera cualquiera.
      a, b = como_numeros(izq, der)
      begin
        case comp
        when "es"            then return a == b
        when "no_es"         then return a != b
        when "mayor_que"     then return a > b
        when "menor_que"     then return a < b
        when "mayor_o_igual" then return a >= b
        when "menor_o_igual" then return a <= b
        when "contiene"      then return izq.to_s.downcase.include?(der.to_s.downcase)
        end
      rescue StandardError => e
        avisar&.call("no puedo comparar #{izq.inspect} con #{der.inspect}: #{e.message}")
        return true
      end
      return true
    end

    # Devuelve los dos lados como numero si los dos lo parecen, y si no como texto.
    def self.como_numeros(izq, der)
      return [0.0, 0.0] if izq.nil? || izq == HUECO
      si = izq.to_s.strip
      sd = der.to_s.strip
      num = /\A-?\d+(\.\d+)?\z/
      if si =~ num && sd =~ num
        return [si.to_f, sd.to_f]
      end
      # true/false de un interruptor comparado contra 1/0.
      return [si == "true" ? 1.0 : 0.0, sd.to_f] if ["true", "false"].include?(si) && sd =~ num
      return [si.downcase, sd.downcase]
    end

    #---------------------------------------------------------------------------
    # Un Pokemon del equipo por su numero (1 es el primero, como lo cuenta
    # cualquiera; el codigo cuenta desde 0, y esa resta se hace aqui una vez).
    #---------------------------------------------------------------------------
    def self.del_equipo(numero)
      return nil if !$player
      i = numero.to_i - 1
      return nil if i < 0
      party = $player.party
      return nil if party.nil? || i >= party.length
      return party[i]
    end

    # Los datos de un Pokemon concreto.
    def self.de_pokemon(pkmn, campo)
      return nil if pkmn.nil?
      case campo.to_s.downcase
      when "nombre"    then pkmn.name
      when "especie"   then pkmn.species_data.name
      when "nivel"     then pkmn.level
      when "hp"        then pkmn.hp
      when "hp_max"    then pkmn.totalhp
      when "hp_pct"    then (pkmn.totalhp > 0) ? ((pkmn.hp * 100.0) / pkmn.totalhp).round : 0
      when "exp"       then pkmn.exp
      when "exp_max"   then pkmn.growth_rate.minimum_exp_for_level(pkmn.level + 1)
      when "naturaleza" then pkmn.nature.name
      when "objeto"    then pkmn.item ? pkmn.item.name : ""
      when "estado"
        return "" if pkmn.status == :NONE
        return GameData::Status.get(pkmn.status).name
      when "genero"
        return "" if pkmn.genderless?
        return pkmn.male? ? "M" : "F"
      when "ataque"    then pkmn.attack
      when "defensa"   then pkmn.defense
      when "velocidad" then pkmn.speed
      when "at_esp"    then pkmn.spatk
      when "def_esp"   then pkmn.spdef
      when "felicidad" then pkmn.happiness
      when "vivo"      then pkmn.able? ? 1 : 0
      end
    end

    #---------------------------------------------------------------------------
    # EL REGISTRO. Añadir un dato nuevo es añadir una linea aqui.
    #
    # Cada bloque recibe los trozos que van despues del primer punto.
    #---------------------------------------------------------------------------
    FUENTES = {
      # --- El jugador ---
      "jugador"   => proc { |_p| $player ? $player.name : nil },
      "dinero"    => proc { |_p| $player ? $player.money : nil },
      "insignias" => proc { |_p| $player ? $player.badge_count : nil },
      "id"        => proc { |_p| $player ? sprintf("%05d", $player.public_ID) : nil },
      "horas"     => proc { |_p| $stats ? ($stats.play_time / 3600).to_i : nil },
      "minutos"   => proc { |_p| $stats ? (($stats.play_time / 60) % 60).to_i : nil },
      "pokedex"   => proc { |_p| $player ? $player.pokedex.owned_count : nil },
      "vistos"    => proc { |_p| $player ? $player.pokedex.seen_count : nil },

      # --- Donde esta ---
      "mapa"      => proc { |_p| $game_map ? $game_map.name : nil },

      # --- Que hay elegido en esta misma pantalla ---
      # {seleccion}            el numero de copia del boton elegido
      # {seleccion.id}         su nombre entero
      # {seleccion.boton_1}    1 si ESE boton es el elegido, 0 si no
      #
      # LA TERCERA FORMA ES UN ARREGLO, NO UN ADORNO. Alguien probando el editor
      # escribio "seleccion.boton_1" dando por hecho que preguntaba por ese boton,
      # y antes eso devolvia el numero de copia en silencio: la condicion no
      # fallaba, simplemente comparaba otra cosa. Cuando la intuicion de quien lo
      # usa es razonable, lo que hay que cambiar es el codigo.
      "seleccion" => proc { |p|
        sub = p[0].to_s
        next Interfaces::Datos.instance_variable_get(:@seleccion_n) if sub.empty?
        next Interfaces::Datos.instance_variable_get(:@seleccion_id) if sub.downcase == "id"
        # Cualquier otra cosa se trata como el nombre de un elemento.
        #
        # Valen los DOS nombres: el de la copia elegida ("opcion_3") y el del
        # elemento del diseño del que salio ("opcion"). El segundo es el unico que
        # el editor puede ofrecer en su desplegable, asi que sin el, "cuando este
        # elegido tal boton" no se cumplia nunca con un boton repetido.
        #
        # Se comparan sin distinguir mayusculas, porque los ids los escribe una
        # persona.
        next 1 if Interfaces::Datos.es_el_elegido?(sub)
        next 0
      },

      # --- El equipo ---
      # {equipo.total}          cuantos lleva
      # {equipo.1.nombre}       el primero
      "equipo" => proc { |p|
        if p[0].to_s.downcase == "total"
          next ($player && $player.party) ? $player.party.length : 0
        end
        Interfaces::Datos.de_pokemon(Interfaces::Datos.del_equipo(p[0]), p[1])
      },

      # --- Interruptores y variables del juego, los de los eventos ---
      "variable"    => proc { |p| $game_variables ? $game_variables[p[0].to_i] : nil },
      "interruptor" => proc { |p| $game_switches ? ($game_switches[p[0].to_i] ? 1 : 0) : nil },

      # --- El combate, cuando lo hay ---
      # Solo valen con un combate en marcha; fuera dan hueco, que es lo correcto.
      "combate" => proc { |p|
        b = $game_temp.respond_to?(:in_battle) && $game_temp.in_battle ? $battle : nil
        next nil if b.nil?
        case p[0].to_s.downcase
        when "turno" then b.turnCount
        when "mio"   then Interfaces::Datos.de_pokemon(b.battlers[0]&.pokemon, p[1])
        when "rival" then Interfaces::Datos.de_pokemon(b.battlers[1]&.pokemon, p[1])
        end
      }
    }

    #---------------------------------------------------------------------------
    # La lista para el editor: que datos hay y un ejemplo de cada uno.
    #
    # Vive aqui, junto a las fuentes, para que añadir un dato y que salga en el
    # editor sea el mismo sitio y no se puedan desincronizar.
    #---------------------------------------------------------------------------
    CATALOGO = [
      ["jugador",             "El nombre del jugador",            "ENTRENADOR"],
      ["dinero",              "El dinero que lleva",              "1500"],
      ["insignias",           "Cuantas medallas tiene",           "3"],
      ["id",                  "Su numero de entrenador",          "04213"],
      ["horas",               "Horas jugadas",                    "12"],
      ["minutos",             "Minutos (de la hora en curso)",    "34"],
      ["pokedex",             "Pokemon capturados",               "27"],
      ["vistos",              "Pokemon vistos",                   "58"],
      ["mapa",                "Donde esta ahora",                 "Pueblo Rumh"],
      ["seleccion",           "Que copia esta elegida ahora",     "1"],
      ["seleccion.id",        "El nombre del elemento elegido",   "boton_1"],
      ["seleccion.NOMBRE",    "1 si ese boton es el elegido",     "1"],
      ["equipo.total",        "Cuantos Pokemon lleva",            "4"],
      ["equipo.1.nombre",     "Nombre del Pokemon 1",             "PIKACHU"],
      ["equipo.1.especie",    "Su especie",                       "Pikachu"],
      ["equipo.1.nivel",      "Su nivel",                         "24"],
      ["equipo.1.hp",         "Su vida ahora",                    "31"],
      ["equipo.1.hp_max",     "Su vida maxima",                   "45"],
      ["equipo.1.hp_pct",     "Su vida en porcentaje",            "69"],
      ["equipo.1.exp",        "Su experiencia",                   "8420"],
      ["equipo.1.exp_max",    "La que necesita para subir",       "9261"],
      ["equipo.1.estado",     "Envenenado, dormido...",           "PSN"],
      ["equipo.1.genero",     "M o F",                            "M"],
      ["equipo.1.objeto",     "Lo que lleva puesto",              "Baya Aranja"],
      ["equipo.1.naturaleza", "Su naturaleza",                    "Alegre"],
      ["equipo.1.ataque",     "Su ataque",                        "52"],
      ["equipo.1.defensa",    "Su defensa",                       "40"],
      ["equipo.1.velocidad",  "Su velocidad",                     "90"],
      ["variable.5",          "El valor de la variable 5",        "7"],
      ["interruptor.20",      "1 si el interruptor 20 esta on",   "1"],
      ["combate.turno",       "En que turno va el combate",       "3"],
      ["combate.mio.nombre",  "Mi Pokemon en combate",            "PIKACHU"],
      ["combate.mio.hp",      "Su vida",                          "31"],
      ["combate.mio.hp_max",  "Su vida maxima",                   "45"],
      ["combate.rival.nombre", "El Pokemon rival",                "RATTATA"],
      ["combate.rival.hp_pct", "Su vida en porcentaje",           "80"]
    ]
  end
end
