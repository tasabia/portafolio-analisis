# Cobranza Automatizada

Este proyecto implementa un flujo completo de **automatización de cobranza** en R.  
Integra bases de datos de pólizas y agentes, genera archivos protegidos por contraseña y envía correos personalizados en HTML con adjuntos.

---

## 🎯 Objetivo
- Automatizar la preparación y envío de reportes de cobranza por agente.
- Reducir errores manuales y ahorrar tiempo en la gestión de pólizas.
- Generar un resumen claro y visual para cada agente.

---

## ⚙️ Tecnologías utilizadas
- **R**: procesamiento y automatización.
- Librerías: `dplyr`, `readr`, `data.table`, `scales`, `Microsoft365R`.
- **7zip / WinRAR**: compresión con contraseña.
- **Outlook corporativo (Microsoft365R)**: envío de correos.

---

## 📂 Estructura del proyecto

<img width="540" height="246" alt="image" src="https://github.com/user-attachments/assets/72e280ce-35f0-4a94-9aff-2c5ae2c4e99a" />

---

## 🚀 Flujo del script
1. **Carga de librerías y funciones auxiliares**.  
2. **Integración de bases** de cobranza y agentes.  
3. **Transformación de datos**: cálculo de días y clasificación en estatus (`Morosa`, `En gestión`, `Futura`).  
4. **Separación por agente** y guardado de archivos CSV.  
5. **Compresión con contraseña** (ZIP por agente).  
6. **Generación de resumen** por agente.  
7. **Creación de plantilla HTML** personalizada.  
8. **Envío de correos** con adjunto y tabla de resumen.

---

## 📧 Ejemplo de salida
Correo HTML con saludo personalizado y tabla de resumen:

<img width="974" height="523" alt="image" src="https://github.com/user-attachments/assets/bea091c6-ad04-42fe-84b3-bad8a6650700" />

---

## ▶️ Cómo ejecutar
```bash
Rscript src/Notificacion_Cobranza.r



