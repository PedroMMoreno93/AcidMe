# AcidMe! — Guía para agentes y desarrolladores

Documento de contexto técnico y resumen de requisitos. El detalle completo está en `REQUIREMENTS.MD` (SRS) y `PLAN.MD` (plan e historias de usuario).

## Qué es el producto

**AcidMe!** es un sintetizador de bajos **monofónico** para **iPad**, inspirado en la experiencia **Roland TB-303 / Behringer TD-3**: síntesis sustractiva, secuenciador de **16 pasos** e interfaz **skeuomórfica** (knobs, switches) orientada a un flujo tipo hardware, con baja latencia.

## Stack y tecnologías

| Área | Elección |
|------|----------|
| Plataforma | iPad, **iPadOS 16+** |
| Orientación UI | **Solo landscape** (requisito) |
| UI | **SwiftUI** |
| Estado y efectos secundarios | **The Composable Architecture (TCA)** |
| Audio | **AudioKit 5** (sobre AVFoundation) |
| Dependencias | **Swift Package Manager** — TCA y AudioKit |
| Persistencia de sesión | **UserDefaults** o **filesystem** — estado del reducer TCA |
| Reloj del secuenciador | **AudioClient** que exponga un **AsyncStream** de ticks desde el motor de audio hacia TCA |

Convención de trabajo (ver `PLAN.MD`): ramas `main` ← `develop` ← `feat/...`; **rama por defecto en GitHub:** `develop`. PRs con tests (**Swift Testing** en `AcidMeTests`, y snapshot cuando aplique).

## Cadena de audio (orden fijo)

Serie lineal: **Oscilador (sierra/cuadrado)** → **Filtro ladder** (cutoff, resonancia, accent) → **VCA** (envolvente de amplitud) → **Distorsión** (incl. profundidad de bits) → **Reverb** (tiempo/mezcla) → **salida master** (volumen).

## Resumen de requisitos funcionales

- **Síntesis:** una voz; onda cuadrada o diente de sierra; filtro paso bajo tipo **ladder 4 polos**; envolvente de **decaimiento** en filtro y amplitud; **accent** que suba volumen y abra el filtro.
- **Secuenciación:** 16 pasos, **BPM**; entrada de notas por **teclado en pantalla** o **Piano Roll**; transposición **±3 octavas**; función **Clear** del patrón.
- **FX:** distorsión con control de **bitcrush/profundidad de bits**; **reverb** con tiempo y mezcla.

## Resumen de requisitos no funcionales

- UI solo en **horizontal**.
- Latencia E/S de audio **≤ 10 ms**.
- CPU **≤ 25 %** en iPad con chip **A12 o superior** (referencia de estabilidad).
- Controles táctiles optimizados; apariencia de **hardware** (knobs/switches).

## Proyecto Xcode (HU 0)

- La definición del target vive en **`project.yml`** ([XcodeGen](https://github.com/yonaskolb/XcodeGen)). Tras cambiar el YAML: `xcodegen generate` en la raíz del repo.
- Abre **`AcidMe.xcodeproj`** en Xcode, deja que resuelva los paquetes (**File → Packages → Resolve Package Versions**) y compila el esquema **AcidMe** con destino **iPad** (simulador o dispositivo).
- Tests: **`AcidMe.xctestplan`** (referenciado por el esquema); **code coverage** del target **AcidMe** (definido en el plan y reflejado en `project.yml` vía XcodeGen).
- Estructura de código: `AcidMe/App` (entrada SwiftUI), `AcidMe/Core` (TCA raíz, enganche AudioKit), `AcidMe/Features/Components` (controles reutilizables: **AcidKnob**, **AcidToggle**, **AcidButton**, **AcidPianoRoll**, **AcidKeyboard** una octava + octava ±3), `AcidMe/Resources` (Assets).

## Fuentes de verdad

- **Requisitos y especificación:** `REQUIREMENTS.MD`
- **Plan, HUs y flujo de desarrollo:** `PLAN.MD`

Al implementar, priorizar coherencia con el SRS, la cadena de señal anterior y los patrones TCA (reducers, efectos, tests).
