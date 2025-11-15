import requests
import time
import os
from datetime import datetime
from dotenv import load_dotenv

# Cargar variables de entorno
load_dotenv()

# Configuración
API_BASE_URL = "https://api.montevideo.gub.uy/api/transportepublico"
AUTH_URL = "https://mvdapi-auth.montevideo.gub.uy/token"
CLIENT_ID = os.getenv("CLIENT_ID", "").strip()
CLIENT_SECRET = os.getenv("CLIENT_SECRET", "").strip()
PARADA_ID = None  # Se configurará al inicio
INTERVALO_ACTUALIZACION = 15  # segundos

# Token de acceso (se renovará automáticamente)
access_token = None
token_expiry = 0

# Sesión global para mantener cookies
api_session = requests.Session()


def obtener_token():
    """
    Obtiene un token de acceso OAuth2 usando client credentials
    """
    global access_token, token_expiry, api_session

    # Headers exactos que usa Postman
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

        # Usar sesión para manejar cookies automáticamente (F5 load balancer)
        response = api_session.post(
            AUTH_URL,
            data=payload,
            auth=(CLIENT_ID, CLIENT_SECRET),
            headers=headers,
            timeout=10,
        )

        print(f"Status: {response.status_code}")

        response.raise_for_status()

        token_data = response.json()
        access_token = token_data.get("access_token")
        expires_in = token_data.get("expires_in", 300)  # 300s por defecto
        token_expiry = time.time() + expires_in - 30  # Renovar 30s antes

        print(f"✓ Token obtenido (válido por {expires_in}s)")
        return True

    except requests.exceptions.RequestException as e:
        print(f"❌ Error al obtener token: {e}")
        if hasattr(e, "response") and e.response is not None:
            print(f"Status Code: {e.response.status_code}")
            content_type = e.response.headers.get("Content-Type", "")
            if "html" not in content_type.lower():
                print(f"Response: {e.response.text[:500]}")
            else:
                print("Respuesta HTML (posible bloqueo WAF)")
        return False


def verificar_token():
    """
    Verifica si el token es válido y lo renueva si es necesario
    """
    if not access_token or time.time() >= token_expiry:
        return obtener_token()
    return True


def limpiar_pantalla():
    """Limpia la pantalla de la terminal"""
    os.system("cls" if os.name == "nt" else "clear")


def obtener_buses_proximos(parada_id, lineas=None):
    """
    Obtiene los buses próximos a llegar a una parada
    """
    # Verificar/renovar token
    if not verificar_token():
        return None

    url = f"{API_BASE_URL}/buses/busstops/{parada_id}/upcomingbuses"

    # Headers con token de acceso
    headers = {
        "Accept": "application/json",
        "Authorization": f"Bearer {access_token}",
        "User-Agent": "PostmanRuntime/7.50.0",
    }

    params = {"amountperline": 3}  # Mostrar los próximos 3 buses por línea

    # Si se especifican líneas, agregarlas al filtro
    if lineas:
        params["lines"] = ",".join(lineas)

    try:
        # Usar la misma sesión que tiene las cookies
        response = api_session.get(url, params=params, headers=headers, timeout=10)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Error al consultar la API: {e}")
        if hasattr(e, "response") and e.response is not None:
            print(f"Status: {e.response.status_code}")
            print(f"Respuesta: {e.response.text[:300]}")
        return None


def mostrar_buses(buses_data):
    """
    Muestra la información de buses de forma organizada
    """
    if not buses_data:
        print("No hay información de buses disponible.")
        return

    print(f"\n{'=' * 60}")
    print(f"  PRÓXIMOS BUSES - Parada {PARADA_ID}")
    print(f"  Actualizado: {datetime.now().strftime('%H:%M:%S')}")
    print(f"{'=' * 60}\n")

    if isinstance(buses_data, list):
        if len(buses_data) == 0:
            print("  No hay buses próximos en este momento.")
        else:
            for bus in buses_data:
                linea = bus.get("line", "N/A")
                destino = bus.get("destination", "N/A")
                eta = bus.get("eta", {})

                # Extraer tiempo estimado
                if isinstance(eta, dict):
                    minutos = eta.get("minutes", "N/A")
                    tiempo_str = (
                        f"{minutos} min" if minutos != "N/A" else "Calculando..."
                    )
                else:
                    tiempo_str = str(eta) if eta else "Calculando..."

                print(f"  🚌 Línea {linea:6s} → {destino:20s} | ⏱️  {tiempo_str}")
    else:
        print(f"  Respuesta inesperada: {buses_data}")

    print(f"\n{'=' * 60}")
    print(f"  Próxima actualización en {INTERVALO_ACTUALIZACION} segundos...")
    print(f"  Presiona Ctrl+C para salir")
    print(f"{'=' * 60}\n")


def buscar_parada():
    """
    Ayuda al usuario a encontrar su parada
    """
    print("\n¿Conoces el ID de tu parada? (s/n): ", end="")
    respuesta = input().lower()

    if respuesta == "s":
        parada = input("Ingresa el ID de tu parada: ")
        return parada
    else:
        print("\nPara encontrar tu parada, puedes:")
        print("1. Usar la app 'Cómo Ir' y buscar tu parada")
        print("2. Visitar el sitio web de la Intendencia")
        print("3. Consultar en la parada física (suele tener un código)")
        parada = input("\nIngresa el ID de tu parada cuando lo tengas: ")
        return parada


def configurar_lineas():
    """
    Permite al usuario filtrar por líneas específicas
    """
    print("\n¿Quieres filtrar por líneas específicas? (s/n): ", end="")
    respuesta = input().lower()

    if respuesta == "s":
        lineas_str = input("Ingresa las líneas separadas por comas (ej: 21,D10,L20): ")
        return [l.strip() for l in lineas_str.split(",") if l.strip()]
    return None


def main():
    global PARADA_ID

    limpiar_pantalla()
    print("=" * 60)
    print("  MONITOR DE BUSES - TRANSPORTE PÚBLICO MONTEVIDEO")
    print("=" * 60)

    # Verificar credenciales
    if not CLIENT_ID or not CLIENT_SECRET:
        print("\n⚠️  ERROR: Faltan las credenciales de la API")
        print("\nCrea un archivo .env en la misma carpeta con:")
        print("  CLIENT_ID=tu_client_id")
        print("  CLIENT_SECRET=tu_client_secret")
        print("\nObtén tus credenciales en:")
        print("  https://www.montevideo.gub.uy/aplicacionesWeb/api")
        return

    # Obtener token inicial
    print("\nObteniendo token de acceso...")
    if not obtener_token():
        print("\n❌ No se pudo obtener el token. Verifica tus credenciales.")
        return

    # Configuración inicial
    PARADA_ID = buscar_parada()
    lineas_filtro = configurar_lineas()

    print(f"\n✓ Configuración completa")
    print(f"  Parada: {PARADA_ID}")
    if lineas_filtro:
        print(f"  Líneas: {', '.join(lineas_filtro)}")
    print("\nIniciando monitoreo...")
    time.sleep(2)

    # Loop principal
    try:
        while True:
            limpiar_pantalla()
            buses = obtener_buses_proximos(PARADA_ID, lineas_filtro)
            mostrar_buses(buses)
            time.sleep(INTERVALO_ACTUALIZACION)
    except KeyboardInterrupt:
        print("\n\n¡Hasta luego! 👋")


if __name__ == "__main__":
    main()
