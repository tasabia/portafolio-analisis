###############################
# Proyecto: Cobranza          #
# Autor: Martin Tasabia       #
# Fecha: 04/10/2026           #
# Usuario: Varios             #
###############################
#-------------- 01. Carga de Librerias ----------------------------------------#
# Vector de librerías necesarias
Librerias <- c("dplyr", "readr", "Microsoft365R", "data.table",
               "scales", "here")

# Función que instala si no está y luego carga
cargar_librerias <- function(paquetes){
  for(p in paquetes){
    if(!require(p, character.only = TRUE)){
      install.packages(p, dependencies = TRUE)
      library(p, character.only = TRUE)
    }
  }
}

# Ejecutar
cargar_librerias(Librerias)

#-------------- 02. Ligas -----------------------------------------------------#
# Definir carpeta raíz del proyecto
Carpeta_raiz <- paste0(here(), "/portafolio-analisis/cobranza-automatizada")

# Subcarpetas relativas
Carpeta_input  <- file.path(Carpeta_raiz, "Input")
Carpeta_output <- file.path(Carpeta_raiz, "Output")
#-------------- 03. Funciones aux ---------------------------------------------#
#traer archivos recientes
Get_recent_file <- function(carpeta, patron = NULL, usar = "ctime") {
  # Listar archivos con patrón opcional
  archivos <- list.files(carpeta, pattern = patron, full.names = TRUE)
  if(length(archivos) == 0){
    stop("No se encontraron archivos en la carpeta con ese patrón.")
  }
  # Obtener metadatos de los archivos
  info <- file.info(archivos)
  # Seleccionar el archivo con la fecha más reciente según 'usar'
  archivo_reciente <- rownames(info)[which.max(info[[usar]])]
  return(archivo_reciente)
}

#Funcion de zipeado
zip_con_password <- function(archivo_csv, carpeta_salida, password,
                             zip_program = c("7zip", "winrar")){
  zip_program <- match.arg(zip_program)
  nombre_zip <- file.path(carpeta_salida,
                          paste0(tools::file_path_sans_ext(basename(archivo_csv)), ".zip"))
  if(zip_program == "7zip"){
    # Ruta completa a 7z.exe
    seven_zip <- '"C:/Program Files/7-Zip/7z.exe"'
    comando <- sprintf('%s a -p"%s" "%s" "%s"',
                       seven_zip, password, nombre_zip, archivo_csv)
  } else {
    # Ruta completa a rar.exe
    winrar <- '"C:/Program Files/WinRAR/rar.exe"'
    comando <- sprintf('%s a -p"%s" "%s" "%s"',
                       winrar, password, nombre_zip, archivo_csv)
  }
  system(comando)
  return(nombre_zip)
}

# Función que inserta nombre y tabla en la plantilla
crear_html_agente <- function(nombre_agente, resumen_agente){
  # Crear tabla HTML a partir del resumen
  tabla_html <- paste0(
    apply(resumen_agente, 1, function(fila){
      sprintf("<tr><td>%s</td><td>%.2f</td><td>%d</td></tr>",
              fila["Estatus"], as.numeric(fila["Prima_total"]), as.integer(fila["No_reg"]))
    }),
    collapse = "\n"
  )
  
  # Reemplazar marcadores en la plantilla (texto literal, no regex)
  html_final <- gsub("{{Nombre_agente}}", nombre_agente, plantilla_html, fixed = TRUE)
  html_final <- gsub("{{Tabla_resumen}}", tabla_html, html_final, fixed = TRUE)
  
  return(paste(html_final, collapse = "\n"))
}


#-------------- 04. Carga base de cobranza ------------------------------------#
# Buscar archivo de cobranza más reciente
archivo_cobranza <- Get_recent_file(
  Carpeta_input,
  patron = "^Cobranza_[0-9]{2}_[0-9]{4}\\.csv$",
  usar = "ctime"   # fecha de creación
)

# Cargar la base
Base_cobranza <- readr::read_csv(archivo_cobranza)

#-------------- 05. Carga base de agentes -------------------------------------#
archivo_agentes <- Get_recent_file(
  Carpeta_input,
  patron = "^Contacto_agentes\\.csv$",
  usar = "ctime"
)

Base_agentes <- readr::read_csv(archivo_agentes)

#-------------- 06. Integración -----------------------------------------------#
Base_integrada <- Base_cobranza  |> 
                  left_join(Base_agentes, by = "Numero_agente")

#-------------- 07. Transformacion de datos -----------------------------------#

Base_integrada_2 <- Base_integrada %>%
  mutate(
    Dias = as.integer(difftime(FECH_COBRO, Sys.Date(), units = "days")),
    Estatus = case_when(
      Dias <= -30 ~ "Morosa",
      Dias >= -29 & Dias <= 30 ~ "En gestión de cobro",
      Dias > 30 ~ "Futura"
    )
  )

#-------------- 08. Guardado de base completa ---------------------------------#
# Crear carpeta base si no existe
dir.create(file.path(Carpeta_output, "Base_completa"), showWarnings = FALSE)

# Nombre del subdirectorio con fecha actual
Nombre_dir <- file.path(
  Carpeta_output,
  "Base_completa",
  paste0("Cobranza_", format(Sys.Date(), "%d%m%Y"))
)

# Crear subdirectorio
dir.create(Nombre_dir, showWarnings = FALSE)

# Guardar la base transformada
write.csv(Base_integrada_2,
          file = file.path(Nombre_dir, "Base_cobranza.csv"),
          row.names = FALSE,
          fileEncoding = "Latin1")

#-------------- 09. Separa la base por agente ---------------------------------#

# Separar por agente
Bases_por_agente <- Base_integrada_2 %>%
  group_split(Numero_agente)

# Obtener los nombres correctos de cada grupo
nombres_agentes <- Base_integrada_2 %>%
  group_by(Numero_agente) %>%
  group_keys() %>%
  pull(Numero_agente)

# Asignar nombres a la lista
names(Bases_por_agente) <- nombres_agentes

# Ejemplo: acceder al agente AGT018
View(Bases_por_agente[["AGT018"]])

#-------------- 10. Guardado de base por agente -------------------------------#
# Crear carpeta base si no existe
dir.create(file.path(Carpeta_output, "Base_por_agente"), showWarnings = FALSE)

# Nombre del subdirectorio con fecha actual
Nombre_dir <- file.path(
  Carpeta_output,
  "Base_por_agente",
  paste0("Cobranza_", format(Sys.Date(), "%d%m%Y"))
)

# Crear subdirectorio
dir.create(Nombre_dir, showWarnings = FALSE)

# Guardar cada archivo CSV por agente con encoding Latin1
for(agente in names(Bases_por_agente)){
  archivo <- file.path(Nombre_dir, paste0("Cobranza_", agente, ".csv"))
  write.csv(Bases_por_agente[[agente]], archivo,
            row.names = FALSE,
            fileEncoding = "Latin1")
}

#-------------- 11. Carpeta final con fecha -----------------------------------#
# Crear carpeta base si no existe
dir.create(file.path(Carpeta_output, "Final_envio"), showWarnings = FALSE)

# Nombre del subdirectorio con fecha actual
Carpeta_final <- file.path(
  Carpeta_output,
  "Final_envio",
  paste0("Cobranza_", format(Sys.Date(), "%d%m%Y"))
)

# Crear subdirectorio
dir.create(Carpeta_final, showWarnings = FALSE)

# Ciclo de guardado y zipeo
for(agente in names(Bases_por_agente)){
  df_final <- Bases_por_agente[[agente]] %>%
    select(-Nombre, -Correo)
  
  archivo_csv <- file.path(Carpeta_final, paste0("Cobranza_", agente, ".csv"))
  write.csv(df_final, archivo_csv, row.names = FALSE, fileEncoding = "Latin1")
  
  # Crear zip con contraseña = Numero_agente
  zip_con_password(archivo_csv, Carpeta_final, agente)
  
  # Eliminar CSV temporal (quedará solo el ZIP)
  file.remove(archivo_csv)
}

#-------------- 11. Creamos resumen por agente --------------------------------#
#resumen por agente
Resumen_agente <- Base_integrada_2 |> 
  group_by(Numero_agente, Estatus) |> 
  summarise(Prima_total = sum(Prima_total),
            No_reg = n())

#carga datos de contacto
Resumen_agente_2 <- Resumen_agente  |> 
  left_join(Base_agentes, by = "Numero_agente")

# Crear tabla con rutas de ZIP por agente
Zip_paths <- tibble(
  Numero_agente = names(Bases_por_agente),
  Zip_url = file.path(Carpeta_final,
                      paste0("Cobranza_", names(Bases_por_agente), ".zip"))
)

# Unir al resumen
Resumen_agente_3 <- Resumen_agente_2 %>%
  left_join(Zip_paths, by = "Numero_agente") 

#-------------- 12. Envio de correos ------------------------------------------#
# Leer la plantilla HTML
plantilla_html <- readLines(file.path(Carpeta_input, "Plantilla.html"), encoding = "UTF-8")

# Autenticación con Outlook corporativo
outlook <- get_business_outlook()

# Tabla única de ZIP por agente
Zip_unicos <- Resumen_agente_3 %>%
  distinct(Numero_agente, Nombre, Correo, Zip_url)

for(agente in Zip_unicos$Numero_agente){
  # Filtrar resumen completo (todas las filas de estatus)
  resumen_agente <- Resumen_agente_3 %>%
    filter(Numero_agente == agente) %>%
    select(Estatus, Prima_total, No_reg)
  
  # Crear HTML personalizado
  cuerpo_html <- crear_html_agente(
    nombre_agente = Zip_unicos$Nombre[Zip_unicos$Numero_agente == agente][1],
    resumen_agente = resumen_agente
  )
  
  # Ruta única del ZIP
  archivo_zip <- Zip_unicos$Zip_url[Zip_unicos$Numero_agente == agente][1]
  
  # Crear correo con cuerpo HTML
  email <- outlook$create_email(
    to = Zip_unicos$Correo[Zip_unicos$Numero_agente == agente][1],
    subject = paste("Cobranza -", agente),
    body = cuerpo_html,
    content_type = "html"   # <-- clave para renderizar HTML
  )
  
  # Agregar adjunto
  email$add_attachment(archivo_zip)
  
  # Enviar
  email$send()
  
  Sys.sleep(50)  # pausa de 50 segundos entre correos
}


