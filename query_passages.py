from datetime import datetime, timedelta
from sqlalchemy import func, and_
from models import BusStop, BusPassage, get_session


def listar_paradas_monitoreadas():
    """Lista todas las paradas que tienen registros de pasadas"""
    session = get_session()
    
    try:
        paradas = session.query(
            BusStop,
            func.count(BusPassage.id).label('total_pasadas'),
            func.max(BusPassage.detected_at).label('ultima_pasada')
        ).join(BusPassage).group_by(BusStop.id).all()
        
        print("\n" + "="*80)
        print("  PARADAS MONITOREADAS")
        print("="*80)
        
        for stop, total, ultima in paradas:
            print(f"\nParada {stop.busstop_id}: {stop.street1} y {stop.street2}")
            print(f"  Total de pasadas registradas: {total}")
            print(f"  Última pasada: {ultima.strftime('%Y-%m-%d %H:%M:%S')}")
        
        print("\n" + "="*80 + "\n")
        
        return paradas
    
    finally:
        session.close()


def estadisticas_linea(linea, parada_id=None, dias=7):
    """Muestra estadísticas de una línea en una parada o en todas"""
    session = get_session()
    
    try:
        fecha_desde = datetime.utcnow() - timedelta(days=dias)
        
        query = session.query(BusPassage).filter(
            and_(
                BusPassage.line == linea,
                BusPassage.detected_at >= fecha_desde
            )
        )
        
        if parada_id:
            bus_stop = session.query(BusStop).filter_by(busstop_id=parada_id).first()
            if bus_stop:
                query = query.filter(BusPassage.bus_stop_id == bus_stop.id)
        
        pasadas = query.order_by(BusPassage.detected_at.desc()).all()
        
        print("\n" + "="*80)
        print(f"  ESTADÍSTICAS LÍNEA {linea}")
        if parada_id:
            print(f"  Parada: {parada_id}")
        print(f"  Últimos {dias} días")
        print("="*80)
        
        if not pasadas:
            print("\nNo hay registros para esta línea.")
            return
        
        print(f"\nTotal de pasadas registradas: {len(pasadas)}")
        
        # Agrupar por día
        pasadas_por_dia = {}
        for pasada in pasadas:
            dia = pasada.detected_at.date()
            if dia not in pasadas_por_dia:
                pasadas_por_dia[dia] = []
            pasadas_por_dia[dia].append(pasada)
        
        print(f"\nPasadas por día:")
        for dia, lista in sorted(pasadas_por_dia.items(), reverse=True):
            print(f"  {dia}: {len(lista)} pasadas")
        
        # Mostrar últimas 10 pasadas
        print(f"\n{'='*80}")
        print("  ÚLTIMAS 10 PASADAS")
        print("="*80)
        
        for pasada in pasadas[:10]:
            destino = pasada.destination or "N/A"
            eta = pasada.eta_minutes if pasada.eta_minutes else "N/A"
            print(f"{pasada.detected_at.strftime('%Y-%m-%d %H:%M:%S')} | "
                  f"→ {destino:25s} | ETA: {eta} min")
        
        print("\n" + "="*80 + "\n")
    
    finally:
        session.close()


def pasadas_hoy(parada_id):
    """Muestra todas las pasadas de hoy en una parada"""
    session = get_session()
    
    try:
        bus_stop = session.query(BusStop).filter_by(busstop_id=parada_id).first()
        
        if not bus_stop:
            print(f"\n❌ Parada {parada_id} no encontrada")
            return
        
        hoy_inicio = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
        
        pasadas = session.query(BusPassage).filter(
            and_(
                BusPassage.bus_stop_id == bus_stop.id,
                BusPassage.detected_at >= hoy_inicio
            )
        ).order_by(BusPassage.detected_at.desc()).all()
        
        print("\n" + "="*80)
        print(f"  PASADAS DE HOY - Parada {parada_id}")
        print(f"  {bus_stop.street1} y {bus_stop.street2}")
        print("="*80)
        
        if not pasadas:
            print("\nNo hay pasadas registradas hoy.")
            return
        
        print(f"\nTotal: {len(pasadas)} pasadas")
        print("\n" + "-"*80)
        
        for pasada in pasadas:
            linea = pasada.line or "N/A"
            destino = pasada.destination or "N/A"
            eta = pasada.eta_minutes if pasada.eta_minutes else "N/A"
            print(f"{pasada.detected_at.strftime('%H:%M:%S')} | "
                  f"Línea {linea:6s} | → {destino:25s} | ETA: {eta} min")
        
        print("-"*80 + "\n")
    
    finally:
        session.close()


def menu_principal():
    """Menú interactivo para consultar datos"""
    while True:
        print("\n" + "="*60)
        print("  CONSULTA DE PASADAS DE BONDIS")
        print("="*60)
        print("\n1. Listar paradas monitoreadas")
        print("2. Ver estadísticas de una línea")
        print("3. Ver pasadas de hoy en una parada")
        print("4. Salir")
        
        opcion = input("\nSelecciona una opción: ").strip()
        
        if opcion == "1":
            listar_paradas_monitoreadas()
        
        elif opcion == "2":
            linea = input("\nIngresa el número/código de línea: ").strip()
            parada = input("Ingresa ID de parada (Enter para todas): ").strip()
            dias = input("Días a consultar (default 7): ").strip()
            
            parada_id = int(parada) if parada else None
            dias_int = int(dias) if dias else 7
            
            estadisticas_linea(linea, parada_id, dias_int)
        
        elif opcion == "3":
            parada = input("\nIngresa el ID de la parada: ").strip()
            try:
                pasadas_hoy(int(parada))
            except ValueError:
                print("❌ ID de parada inválido")
        
        elif opcion == "4":
            print("\n¡Hasta luego! 👋\n")
            break
        
        else:
            print("\n❌ Opción inválida")


if __name__ == "__main__":
    menu_principal()
