import requests
import time
import os
from datetime import datetime, timedelta,timezone
from dotenv import load_dotenv
from models import BusStop, BusPassage, get_session
from math import radians, sin, cos, sqrt, atan2
from geopy import distance

# Cargar variables de entorno
load_dotenv()

# ============ CONFIGURACIÓN DE MONITOREO ============
MONITORED_LINES = ["147", "148", "149", "151", "157", "174"]  # Líneas de bondis a monitorear
LINE_VARIANT_IDS = []
# LINE_VARIANT_IDS = [
#     "4420",
#     "4424",
#     "4426",
#     "4462",
#     "4467",
#     "4470",
#     "4824",
#     "8903",
#     "4543"
# ]  # IDs de variantes de línea (vacío = todas las variantes)
MONITORED_STOP_ID = 2071 # ID de la parada a monitorear
PROXIMITY_THRESHOLD_METERS = 100  # Distancia máxima para considerar que el bondi está en la parada
CHECK_INTERVAL_SECONDS = 15  # Intervalo entre consultas
COOLDOWN_MINUTES = 5  # Tiempo mínimo entre registros del mismo bondi en la misma parada
# ===================================================

# Configuración API
API_BASE_URL = "https://api.montevideo.gub.uy/api/transportepublico"
AUTH_URL = "https://mvdapi-auth.montevideo.gub.uy/token"
CLIENT_ID = os.getenv("CLIENT_ID", "").strip()
CLIENT_SECRET = os.getenv("CLIENT_SECRET", "").strip()

# Token de acceso
access_token = None
token_expiry = 0
api_session = requests.Session()


def obtener_token():
    """Obtiene un token de acceso OAuth2"""
    global access_token, token_expiry

    headers = {
        "Content-Type": "application/x-www-form-urlencoded",
        "User-Agent": "PostmanRuntime/7.50.0",
        "Accept": "*/*",
        "Cache-Control": "no-cache",
        "Accept-Encoding": "gzip, deflate, br",
        "Connection": "keep-alive",
    }

    payload = {"grant_type": "client_credentials"}

    try:
        print(f"🔍 Obteniendo token de acceso...")
        response = api_session.post(
            AUTH_URL,
            data=payload,
            auth=(CLIENT_ID, CLIENT_SECRET),
            headers=headers,
            timeout=10,
        )

        response.raise_for_status()
        token_data = response.json()
        access_token = token_data.get("access_token")
        expires_in = token_data.get("expires_in", 300)
        token_expiry = time.time() + expires_in - 30

        print(f"✓ Token obtenido (válido por {expires_in}s)")
        return True

    except requests.exceptions.RequestException as e:
        print(f"❌ Error al obtener token: {e}")
        return False


def verificar_token():
    """Verifica si el token es válido y lo renueva si es necesario"""
    if not access_token or time.time() >= token_expiry:
        return obtener_token()
    return True


def obtener_ubicaciones_bondis(lineas, line_variant_ids=None):
    """Obtiene las ubicaciones de todos los bondis de las líneas especificadas"""
    if not verificar_token():
        return None

    url = f"{API_BASE_URL}/buses"
    headers = {
        "Accept": "application/json",
        "Authorization": f"Bearer {access_token}",
        "User-Agent": "PostmanRuntime/7.50.0",
    }

    params = {"lines": ",".join(lineas) if isinstance(lineas, list) else lineas}
    if line_variant_ids:
        params["lineVariantIds"] = ",".join(line_variant_ids) if isinstance(line_variant_ids, list) else line_variant_ids

    try:
        response = api_session.get(url, params=params, headers=headers, timeout=10)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Error al consultar la API: {e}")
        return None


def calcular_distancia(lat1, lon1, lat2, lon2):
    """Calcula la distancia entre dos coordenadas en metros usando la fórmula de Haversine"""
    R = 6371000  # Radio de la Tierra en metros
    
    lat1_rad = radians(float(lat1))
    lat2_rad = radians(float(lat2))
    delta_lat = radians(float(lat2) - float(lat1))
    delta_lon = radians(float(lon2) - float(lon1))
    
    a = sin(delta_lat / 2) ** 2 + cos(lat1_rad) * cos(lat2_rad) * sin(delta_lon / 2) ** 2
    c = 2 * atan2(sqrt(a), sqrt(1 - a))
    
    return R * c


def obtener_paradas():
    """Obtiene todas las paradas de la API"""
    if not verificar_token():
        return None

    url = f"{API_BASE_URL}/buses/busstops"
    headers = {
        "Accept": "application/json",
        "Authorization": f"Bearer {access_token}",
        "User-Agent": "PostmanRuntime/7.50.0",
    }

    try:
        response = api_session.get(url, headers=headers, timeout=10)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Error al consultar la API: {e}")
        return None


def registrar_pasadas_por_proximidad():
    """
    Monitorea bondis por proximidad a una parada usando el endpoint de ubicaciones
    Registra cuando un bondi pasa cerca de la parada configurada
    """
    session = get_session()
    recent_passages = {}  # Diccionario para trackear pasadas recientes: {bus_code: datetime}
    
    try:
        # Buscar o crear la parada en la base de datos
        bus_stop = session.query(BusStop).filter_by(busstop_id=MONITORED_STOP_ID).first()
        
        if not bus_stop:
            print(f"⚠️  Parada {MONITORED_STOP_ID} no encontrada en la base de datos.")
            print("Intentando obtenerla de la API...")
            
            paradas = obtener_paradas()
            if paradas:
                parada_data = next((p for p in paradas if p.get("busstopId") == MONITORED_STOP_ID), None)
                if parada_data:
                    bus_stop = BusStop.find_or_create_from_api(session, parada_data)
                    print(f"✓ Parada creada: {bus_stop.street1} y {bus_stop.street2}")
                else:
                    print(f"❌ Parada {MONITORED_STOP_ID} no encontrada en la API")
                    return
            else:
                print("❌ No se pudo obtener las paradas de la API")
                return
        
        print(f"\n{'='*70}")
        print(f"  MONITOREANDO BONDIS POR PROXIMIDAD")
        print(f"  Parada: {MONITORED_STOP_ID} - {bus_stop.street1} y {bus_stop.street2}")
        print(f"  Coordenadas: {bus_stop.latitude}, {bus_stop.longitude}")
        print(f"  Líneas: {', '.join(MONITORED_LINES)}")
        print(f"  Distancia máxima: {PROXIMITY_THRESHOLD_METERS}m")
        print(f"  Intervalo: {CHECK_INTERVAL_SECONDS}s")
        print(f"  Cooldown: {COOLDOWN_MINUTES} minutos")
        print(f"{'='*70}\n")
        
        while True:
            buses_data = obtener_ubicaciones_bondis(MONITORED_LINES, LINE_VARIANT_IDS)
            
            if buses_data and isinstance(buses_data, list):
                detected_at = datetime.now(timezone.utc)
                registrados = 0
                cercanos = 0
                
                # Limpiar registros antiguos del diccionario de cooldown
                cutoff_time = detected_at - timedelta(minutes=COOLDOWN_MINUTES)
                recent_passages = {k: v for k, v in recent_passages.items() if v > cutoff_time}
                
                min_distancia = 10000000
                for bus_data in buses_data:
                    try:
                        bus_code = bus_data.get("busId")
                        if not bus_code:
                            continue
                        
                        coordinates = bus_data.get("location", {}).get("coordinates", [])
                        if len(coordinates) < 2:
                            continue
                        
                        bus_lon, bus_lat = coordinates[0], coordinates[1]

                        distancia= distance.distance((bus_stop.latitude, bus_stop.longitude), (bus_lat, bus_lon)).meters

                        min_distancia = min(min_distancia, distancia)
                        
                        if distancia <= PROXIMITY_THRESHOLD_METERS:
                            cercanos += 1
                            linea = bus_data.get("line", "N/A")
                            destino = bus_data.get("destination", "N/A")
                            
                            # Verificar si ya fue registrado recientemente
                            if bus_code in recent_passages:
                                print(f"  ⏭️  Bondi {bus_code} (Línea {linea}) ya registrado - en cooldown")
                                continue
                            
                            # Registrar la pasada
                            passage = BusPassage.create_from_bus_data(
                                session, 
                                bus_stop, 
                                bus_data, 
                                detected_at
                            )
                            recent_passages[bus_code] = detected_at
                            registrados += 1
                            
                            print(f"  ✓ REGISTRADO: Bondi {bus_code} | Línea {linea:6s} → {destino:25s} | Distancia: {distancia:.1f}m")
                        
                    except Exception as e:
                        print(f"  ❌ Error al procesar bondi: {e}")
                
                if cercanos > 0:
                    print(f"\n  📊 Bondis cercanos: {cercanos} | Nuevos registros: {registrados}")
                else:
                    print(f"  ℹ️  No hay bondis cerca de la parada en este momento")
                    print(f"  Distancia mínima detectada: {min_distancia:.1f}m")
                
                print(f"  ⏰ Próxima consulta en {CHECK_INTERVAL_SECONDS}s...\n")
            
            else:
                print(f"  ⚠️  No se obtuvieron datos de bondis")
            
            time.sleep(CHECK_INTERVAL_SECONDS)
    
    except KeyboardInterrupt:
        print("\n\n¡Monitoreo detenido! 👋")
    
    finally:
        session.close()


def main():
    print("=" * 70)
    print("  TRACKER DE BONDIS - MONITOREO POR PROXIMIDAD")
    print("=" * 70)
    
    if not CLIENT_ID or not CLIENT_SECRET:
        print("\n⚠️  ERROR: Faltan las credenciales de la API")
        print("\nCrea un archivo .env con:")
        print("  CLIENT_ID=tu_client_id")
        print("  CLIENT_SECRET=tu_client_secret")
        return
    
    if not obtener_token():
        print("\n❌ No se pudo obtener el token. Verifica tus credenciales.")
        return
    
    registrar_pasadas_por_proximidad()


if __name__ == "__main__":
    main()
