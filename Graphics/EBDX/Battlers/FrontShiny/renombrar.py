import os
import json
import urllib.request

# Diccionario completo con tus excepciones y nombres personalizados
EXCEPCIONES = {
    29: "NIDORANfE",
    32: "NIDORANmA",
    83: "FARFETCHD",
    122: "MRMIME",
    250: "HOOH",
    439: "MIMEJR",
    474: "PORYGONZ",
    669: "FLABEBE",
    782: "JANGMOO",
    783: "HAKAMOO",
    784: "KOMMOO",
    785: "TAPUKOKO",
    786: "TAPULELE",
    787: "TAPUBULU",
    788: "TAPUFINI",
    793: "TYPENULL",
    865: "SIRFETCHD",
    866: "MRRIME",
    983: "GREATTUSK",
    984: "WOCHIEN",
    985: "CHIENPAO",
    986: "TINGLU",
    987: "CHIYU",
    988: "ROARINGMOON",
    989: "SCREAMTAIL",
    990: "BRUTEBONNET",
    991: "FLUTTERMANE",
    992: "SLITHERWING",
    993: "SANDYSHOCKS",
    1009: "WALKINGWAKE",
    1010: "RAGINGBOLT",
    1020: "GOUGINGFIRE"
}

def obtener_nombre_procesado(nacional_id):
    if nacional_id in EXCEPCIONES:
        return EXCEPCIONES[nacional_id]
    
    try:
        url = f"https://pokeapi.co/api/v2/pokemon-species/{nacional_id}"
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode())
            for name_info in data['names']:
                if name_info['language']['name'] == 'en':
                    nombre_original = name_info['name'].upper()
                    return (nombre_original
                            .replace(" ", "")
                            .replace("-", "")
                            .replace(".", "")
                            .replace("'", ""))
    except Exception as e:
        print(f"-> Advertencia: No se pudo conectar a la API para el ID {nacional_id} ({e})")
    return None

def procesar_carpeta():
    carpeta_actual = os.getcwd()
    print(f"Buscando archivos PNG en la carpeta: {carpeta_actual}")
    
    # MODIFICADO: Ahora busca archivos que terminen en .png (compatible con mayúsculas y minúsculas)
    archivos = [f for f in os.listdir(carpeta_actual) if f.lower().endswith(".png")]
    print(f"Se encontraron {len(archivos)} archivos .png en total.\n")
    
    if len(archivos) == 0:
        print("¡OJO! No hay archivos .png aquí. Asegúrate de poner el script en la carpeta correcta.")
        return

    for archivo in archivos:
        nombre_base, extension = os.path.splitext(archivo)
        
        try:
            if "_" in nombre_base:
                id_str = nombre_base.split("_")[0]
                id_principal = int(id_str)
                sufijo = "_".join(nombre_base.split("_")[1:])
            else:
                id_principal = int(nombre_base)
                sufijo = None
        except ValueError:
            print(f"Saltando archivo ya renombrado o no numérico: {archivo}")
            continue
            
        nombre_pokemon = obtener_nombre_procesado(id_principal)
        if not nombre_pokemon:
            print(f"No se pudo procesar el archivo: {archivo}")
            continue
            
        if sufijo:
            nuevo_nombre = f"{nombre_pokemon}_{sufijo}{extension}"
        else:
            nuevo_nombre = f"{nombre_pokemon}{extension}"
            
        ruta_antigua = os.path.join(carpeta_actual, archivo)
        ruta_nueva = os.path.join(carpeta_actual, nuevo_nombre)
        
        try:
            os.rename(ruta_antigua, ruta_nueva)
            print(f"Éxito: {archivo} -> {nuevo_nombre}")
        except Exception as e:
            print(f"Error al renombrar {archivo}: {e}")

    print("\n¡Proceso finalizado!")

if __name__ == "__main__":
    procesar_carpeta()