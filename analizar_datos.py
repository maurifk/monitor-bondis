import pandas as pd
from datetime import datetime, timedelta

def leer_datos_stm(archivo_csv):
    """Lee el archivo CSV de datos STM"""
    print("Cargando datos...")
    df = pd.read_csv(archivo_csv, sep=';', dtype={
        'tipo_dia': int,
        'cod_variante': str,
        'frecuencia': int,
        'cod_ubic_parada': str,
        'ordinal': int,
        'hora': int,
        'dia_anterior': str
    })
    print(f"Datos cargados: {len(df)} registros")
    return df

def convertir_hora_a_minutos(hora_int):
    """Convierte formato hmm a minutos desde medianoche
    Ejemplos: 830 -> 8:30 -> 510 minutos
              1545 -> 15:45 -> 945 minutos
    """
    if pd.isna(hora_int):
        return None
    
    hora_str = str(int(hora_int)).zfill(3)  # Asegura 3 dígitos mínimo
    horas = int(hora_str[:-2])
    minutos = int(hora_str[-2:])
    
    return horas * 60 + minutos

def obtener_tipo_dia(fecha=None):
    """Obtiene el tipo de día según la fecha
    1: Hábil (Lunes a Viernes)
    2: Sábado
    3: Domingo
    """
    if fecha is None:
        fecha = datetime.now()
    
    dia_semana = fecha.weekday()  # 0=Lunes, 6=Domingo
    
    if dia_semana == 6:  # Domingo
        return 3
    elif dia_semana == 5:  # Sábado
        return 2
    else:  # Lunes a Viernes
        return 1

def buscar_proximo_omnibus(df, cod_parada, variantes=None, tipo_dia=None, hora_actual=None):
    """
    Busca el próximo ómnibus que pasa por una parada
    
    Args:
        df: DataFrame con los datos STM
        cod_parada: Código de la parada (str)
        variantes: Lista de códigos de variantes a considerar (None = todas)
        tipo_dia: Tipo de día (1=Hábil, 2=Sábado, 3=Domingo, None=detectar automáticamente)
        hora_actual: Hora actual en formato "HH:MM" (None = usar hora del sistema)
    
    Returns:
        DataFrame con los próximos ómnibus ordenados por hora
    """
    # Determinar tipo de día
    if tipo_dia is None:
        tipo_dia = obtener_tipo_dia()
    
    # Obtener hora actual en minutos
    if hora_actual is None:
        ahora = datetime.now()
        minutos_actuales = ahora.hour * 60 + ahora.minute
        hora_str = ahora.strftime("%H:%M")
    else:
        h, m = map(int, hora_actual.split(':'))
        minutos_actuales = h * 60 + m
        hora_str = hora_actual
    
    print(f"\nBuscando próximos ómnibus...")
    print(f"Parada: {cod_parada}")
    print(f"Tipo de día: {tipo_dia} ({'Hábil' if tipo_dia==1 else 'Sábado' if tipo_dia==2 else 'Domingo'})")
    print(f"Hora actual: {hora_str}")
    if variantes:
        print(f"Variantes: {', '.join(variantes)}")
    
    # Filtrar por parada y tipo de día
    filtro = (df['cod_ubic_parada'] == cod_parada) & (df['tipo_dia'] == tipo_dia)
    
    # Filtrar por variantes si se especifican
    if variantes:
        filtro = filtro & (df['cod_variante'].isin(variantes))
    
    df_filtrado = df[filtro].copy()
    
    if len(df_filtrado) == 0:
        print("No se encontraron horarios para los criterios especificados")
        return pd.DataFrame()
    
    # Convertir hora a minutos
    df_filtrado['minutos'] = df_filtrado['hora'].apply(convertir_hora_a_minutos)
    
    # Ajustar horarios del día anterior (agregar 24 horas)
    df_filtrado.loc[df_filtrado['dia_anterior'] == 'S', 'minutos'] += 24 * 60
    
    # Encontrar próximos ómnibus (mismas 24 horas)
    df_proximos = df_filtrado[df_filtrado['minutos'] >= minutos_actuales].copy()
    
    # Si no hay más ómnibus hoy, buscar en el día siguiente
    if len(df_proximos) == 0:
        print("No hay más ómnibus hoy. Mostrando primeros del día siguiente...")
        df_proximos = df_filtrado.copy()
        df_proximos['minutos'] += 24 * 60
    
    # Calcular minutos hasta el próximo ómnibus
    df_proximos['minutos_espera'] = df_proximos['minutos'] - minutos_actuales
    
    # Formatear hora legible
    def formato_hora(mins):
        mins_dia = mins % (24 * 60)
        h = mins_dia // 60
        m = mins_dia % 60
        return f"{h:02d}:{m:02d}"
    
    df_proximos['hora_formato'] = df_proximos['minutos'].apply(formato_hora)
    
    # Ordenar por tiempo de espera
    df_proximos = df_proximos.sort_values('minutos_espera')
    
    # Seleccionar columnas relevantes
    resultado = df_proximos[['cod_variante', 'hora_formato', 'minutos_espera', 'dia_anterior']].head(10)
    
    return resultado

# Ejemplo de uso
if __name__ == "__main__":
    # Cargar datos
    df = leer_datos_stm('datos_stm.csv')
    
    # Ejemplo 1: Buscar próximo ómnibus en una parada específica (todas las variantes)
    cod_parada = "2164"  # Cambiar por el código de tu parada
    resultado = buscar_proximo_omnibus(df, cod_parada)
    
    if len(resultado) > 0:
        print("\n" + "="*70)
        print("PRÓXIMOS ÓMNIBUS:")
        print("="*70)
        for idx, row in resultado.iterrows():
            espera_mins = int(row['minutos_espera'])
            if espera_mins < 60:
                espera_str = f"{espera_mins} min"
            else:
                horas = espera_mins // 60
                mins = espera_mins % 60
                espera_str = f"{horas}h {mins}min"
            
            print(f"Variante: {row['cod_variante']:10} | Hora: {row['hora_formato']} | Espera: {espera_str:10}")
    
    # Ejemplo 2: Buscar en variantes específicas
    print("\n" + "="*70)
    variantes_especificas = [
        "4420",
        "4424",
        "4426",
        "4462",
        "4467",
        "4470",
        "4824",
        "8903",
        "4543"
    ]
    resultado2 = buscar_proximo_omnibus(df, cod_parada, variantes=variantes_especificas)
    
    if len(resultado2) > 0:
        print(f"\nPRÓXIMOS ÓMNIBUS (Variantes {', '.join(variantes_especificas)}):")
        print("="*70)
        for idx, row in resultado2.iterrows():
            espera_mins = int(row['minutos_espera'])
            espera_str = f"{espera_mins} min" if espera_mins < 60 else f"{espera_mins//60}h {espera_mins%60}min"
            print(f"Variante: {row['cod_variante']:10} | Hora: {row['hora_formato']} | Espera: {espera_str:10}")
    
    # Ejemplo 3: Buscar para un horario específico
    print("\n" + "="*70)
    resultado3 = buscar_proximo_omnibus(df, cod_parada, hora_actual="14:30", tipo_dia=1)
    
    if len(resultado3) > 0:
        print("\nPRÓXIMOS ÓMNIBUS (desde las 14:30 en día hábil):")
        print("="*70)
        for idx, row in resultado3.head(5).iterrows():
            espera_mins = int(row['minutos_espera'])
            espera_str = f"{espera_mins} min" if espera_mins < 60 else f"{espera_mins//60}h {espera_mins%60}min"
            print(f"Variante: {row['cod_variante']:10} | Hora: {row['hora_formato']} | Espera: {espera_str:10}")
