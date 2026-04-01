Development Plan - AcidMe!
1. Estrategia de Git y Calidad
Repositorio: GitHub.

Ramas: main <- develop <- feat/HUN-X_descripcion.

Protocolo: Las ramas nacen de develop. Se requiere Unit Test y Snapshot Test (si aplica) para abrir PR.

Gestión: GitHub Project con etiquetas Enhancement.

2. Fase 1: Infraestructura y Setup (Bloqueantes)
Tarea 0.1 [Setup]: Repo GitHub, ramas main/develop y GitHub Project con etiquetas.

Tarea 0.2 [Setup]: Proyecto Xcode (iOS 16, iPad, Landscape). Hito: Debe compilar.

Tarea 0.3 [Setup]: Instalación de SPM (TCA y AudioKit).

Tarea 0.4 [Setup]: Estructura modular de carpetas.

HU 0: Creación y configuración del proyecto Xcode
Descripción: Proyecto Xcode (iPad, iOS 16+, Landscape) que compile; SPM con TCA y AudioKit; estructura modular de carpetas. Cubre las tareas 0.2–0.4.

Gherkin:

Given el entorno de desarrollo y el repositorio clonado.

When se abre el proyecto y se resuelven los paquetes SPM.

Then el proyecto compila para iPad en landscape, TCA y AudioKit están enlazados al target, y la estructura de carpetas modulares está definida.

3. Fase 2: Historias de Usuario (HUN) - Componentes Atómicos
HUN-1: Componente Reutilizable "AcidKnob"
Descripción: Crear un control rotatorio táctil con estética metálica para los parámetros de síntesis.

Gherkin:

Given que el usuario interactúa con la interfaz.

When el usuario desliza el dedo verticalmente sobre el AcidKnob.

Then el componente debe transformar el gesto en un valor flotante (0.0 a 1.0) y rotar visualmente el dial.

HUN-2: Componente Reutilizable "AcidToggle"
Descripción: Crear un interruptor vertical para la selección de formas de onda y encendido de FX.

Gherkin:

Given que el componente está en una posición inicial.

When el usuario pulsa sobre el AcidToggle.

Then el componente debe cambiar su estado visual (On/Off o Posición A/B) y emitir una acción de cambio.

HUN-3: Componente Reutilizable "AcidButton"
Descripción: Crear botones con efecto metálico para funciones de transporte y limpieza.

Gherkin:

Given que el botón está visible.

When el usuario presiona el AcidButton.

Then el componente debe mostrar un estado visual de "pulsado" y disparar la acción correspondiente al soltarlo.

HUN-4: Componente de Rejilla "Piano Roll"
Descripción: Implementar la matriz de 16x12 para la edición de pasos.

Gherkin:

Given una rejilla de 16 pasos por 12 notas.

When el usuario pulsa una celda de la rejilla.

Then la celda debe cambiar de estado (Activo/Inactivo) y actualizar el mapa de notas en el estado local.

HUN-5: Componente "AcidKeyboard"
Descripción: Implementar el teclado musical táctil para interpretación en vivo.

Gherkin:

Given el teclado en pantalla.

When el usuario toca una tecla.

Then la tecla debe iluminarse y el sistema debe emitir una acción de "Note On" con la frecuencia correspondiente.

4. Fase 3: Historias de Usuario (HUN) - Lógica y Audio
HUN-6: Integración del AudioClient (TCA + AudioKit)
Descripción: Configurar el puente entre el estado de la app y el motor de sonido.

Gherkin:

Given que la app se ha iniciado.

When se inicializa el AppReducer.

Then se debe arrancar el motor de AudioKit y prepararlo para recibir comandos.

HUN-7: Conexión de Parámetros de Síntesis
Descripción: Vincular los componentes atómicos (HUN-1 y HUN-2) con el motor de audio.

Gherkin:

Given que el motor de audio está reproduciendo.

When el usuario mueve el AcidKnob de Cutoff.

Then el valor del filtro en AudioKit debe actualizarse instantáneamente sin clics de audio.

HUN-8: Lógica del Secuenciador y Transporte
Descripción: El motor que mueve el puntero por los 16 pasos.

Gherkin:

Given que el transporte está en "Start".

When transcurre el tiempo definido por el BPM.

Then el secuenciador debe avanzar al siguiente paso y disparar el AudioClient si el paso tiene una nota activa.

5. Fase 4: Layout Final y Pulido
Tarea UI-1: Ensamblar el MainLayout usando el color amarillo industrial y la distribución de 3 filas del SRS.

Tarea UI-2: Implementar el sistema de pestañas para alternar entre HUN-4 (Piano Roll) y HUN-5 (Keyboard).

Tarea UI-3: Añadir sección de ayuda y tutorial (?).

6. Fase 5: Testing Final
Tarea T-1: Unit Tests de Reducers (validar lógica de estados).

Tarea T-2: Tests de integración (asegurar que el Knob realmente cambia el audio).