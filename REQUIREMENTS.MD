Software Requirements Specification (SRS) - AcidMe!
1. Identificación del Proyecto
Nombre del Proyecto: AcidMe!

Tipo de Producto: Sintetizador de bajos monofónico (Software Instrument).

Plataforma de Destino: iPad (iPadOS 16.0 o superior).

Arquitectura de Software: The Composable Architecture (TCA).

Motor de Audio: AudioKit 5.

2. Descripción del Producto
AcidMe! es una aplicación diseñada para emular la experiencia sonora y operativa del sintetizador clásico Roland TB-303 / Behringer TD-3. El producto se centra en la síntesis sustractiva agresiva y la secuenciación rítmica de 16 pasos.

Busca resolver la necesidad de un instrumento portátil, estable y con baja latencia que permita la creación de música "Acid" mediante una interfaz skeuomórfica que evite la complejidad de las apps de música genéricas, ofreciendo un flujo de trabajo de hardware físico en un entorno digital.

3. Requisitos Funcionales (RF)
3.1. Motor de Síntesis
RF-101: El sistema debe generar una única voz (monofónica) con selección de onda cuadrada o diente de sierra.

RF-102: El sistema debe implementar un filtro paso-bajo de 4 polos (Ladder Filter) con controles de corte (Cutoff) y resonancia.

RF-103: El sistema debe aplicar una envolvente de decaimiento (Decay) al filtro y a la amplitud.

RF-104: El sistema debe permitir la acentuación de notas (Accent), afectando al volumen y a la apertura del filtro simultáneamente.

3.2. Secuenciación y Control
RF-201: El sistema debe ejecutar un secuenciador de 16 pasos con control de tiempo (BPM).

RF-202: El sistema debe permitir la entrada de notas mediante un teclado virtual o una rejilla de Piano Roll.

RF-203: El sistema debe ofrecer transposición de octavas en un rango de +/- 3 octavas.

RF-204: El sistema debe permitir la limpieza total de los pasos del secuenciador mediante una función "Clear".

3.3. Procesamiento de Audio (FX)
RF-301: El sistema debe procesar la señal a través de una etapa de distorsión con control de profundidad de bits.

RF-302: El sistema debe incluir una etapa de reverberación con control de tiempo y mezcla.

4. Requisitos No Funcionales (RNF)
RNF-01: La interfaz debe ser exclusivamente en orientación Landscape.

RNF-02: La latencia de audio de entrada/salida no debe superar los 10ms.

RNF-03: El consumo de CPU no debe exceder el 25% en modelos de iPad con chip A12 o superior para garantizar estabilidad.

RNF-04: La interfaz debe utilizar elementos visuales que imiten controles físicos (Knobs y Switches) con respuesta táctil optimizada.

5. Especificaciones Técnicas
UI Framework: SwiftUI para toda la capa de presentación.

Gestión de Estado: TCA (The Composable Architecture) para manejar la lógica del secuenciador, la navegación y los parámetros de los efectos de forma predecible y testable.

Audio Engine: AudioKit 5 actuando como wrapper de AVFoundation.

Persistencia: UserDefaults o FileSystem para almacenar el estado del Reducer de TCA, permitiendo recuperar la sesión al reiniciar.

Sincronización: Uso de un AudioClient que proporcione un AsyncStream para emitir los "ticks" del secuenciador desde el motor de audio hacia TCA.

6. Diagrama de Flujo de Señal
El flujo de audio de AcidMe! sigue una ruta lineal serie para garantizar el sonido clásico:

Oscilador (Saw/Square)

-> Filtro Ladder (Cutoff/Res/Accent)

-> VCA (Envolvente de Amplitud)

-> Distorsión (Bitcrush/Drive)

-> Reverb (Space/Mix)

-> Master Output (Volume)