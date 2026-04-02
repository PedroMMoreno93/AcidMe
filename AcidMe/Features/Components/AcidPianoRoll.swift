import SwiftUI

// MARK: - Modelo

struct PianoRollNote: Equatable, Identifiable {
    let id: UUID
    var row: Int
    var startStep: Int
    var lengthSteps: Int
}

// MARK: - Lógica (testeable)

enum PianoRollGridMath {
    static let rowCount = 12
    /// Un compás completo = 16 subdivisiones; la rejilla muestra como máximo esto (sin scroll horizontal).
    static let stepsPerBar = 16
    /// Fracciones de compás visibles: 4 = ¼, 8 = ½, 16 = 1 compás.
    static let allowedGridSteps: [Int] = [4, 8, 16]

    static func normalizedGridSteps(_ steps: Int) -> Int {
        if allowedGridSteps.contains(steps) { return steps }
        if steps <= 4 { return 4 }
        if steps <= 8 { return 8 }
        return 16
    }

    /// Nombres cromáticos desde la fila inferior (C) hasta la superior (B).
    static let chromaticFromBottom = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    /// Índices (desde abajo) que son teclas negras.
    static let blackKeyIndicesFromBottom: Set<Int> = [1, 3, 6, 8, 10]

    static func isValid(row: Int, step: Int, stepCount: Int) -> Bool {
        row >= 0 && row < rowCount && step >= 0 && step < stepCount
    }

    /// Fila 0 = arriba (B); fila 11 = abajo (C).
    static func noteLabel(forRow r: Int) -> String {
        guard r >= 0 && r < rowCount else { return "?" }
        let fromBottom = rowCount - 1 - r
        return chromaticFromBottom[fromBottom]
    }

    static func isBlackKeyRow(forRow r: Int) -> Bool {
        guard r >= 0 && r < rowCount else { return false }
        let fromBottom = rowCount - 1 - r
        return blackKeyIndicesFromBottom.contains(fromBottom)
    }

    static func covers(_ n: PianoRollNote, row: Int, step: Int) -> Bool {
        n.row == row && step >= n.startStep && step < n.startStep + n.lengthSteps
    }

    static func noteCovering(notes: [PianoRollNote], row: Int, step: Int) -> PianoRollNote? {
        notes.first { covers($0, row: row, step: step) }
    }

    /// Longitud máxima desde `startStep` hasta el siguiente compañero en la fila o fin de rejilla.
    static func maxLength(for note: PianoRollNote, in notes: [PianoRollNote], stepCount: Int) -> Int {
        let nextStart = notes
            .filter { $0.row == note.row && $0.id != note.id && $0.startStep > note.startStep }
            .map(\.startStep)
            .min() ?? stepCount
        return max(1, nextStart - note.startStep)
    }

    static func clampedLength(
        startStep: Int,
        desiredLength: Int,
        stepCount: Int,
        noteId: UUID,
        notesOnRow: [PianoRollNote]
    ) -> Int {
        let cap = (stepCount - startStep)
        let nextStart = notesOnRow
            .filter { $0.id != noteId && $0.startStep > startStep }
            .map(\.startStep)
            .min() ?? stepCount
        let byNeighbor = max(1, nextStart - startStep)
        return max(1, min(desiredLength, cap, byNeighbor))
    }

    /// Arrastre del **borde izquierdo**: el borde derecho (fin de la nota) queda fijo; `deltaSteps` negativo extiende hacia la izquierda.
    static func clampedLeadingResize(
        initialStart: Int,
        initialLength: Int,
        deltaSteps: Int,
        noteId: UUID,
        notesOnRow: [PianoRollNote],
        stepCount: Int
    ) -> (start: Int, length: Int) {
        let rightExclusive = initialStart + initialLength
        var newStart = initialStart + deltaSteps
        newStart = min(newStart, rightExclusive - 1)
        newStart = max(0, newStart)

        let minStartFromLeft = notesOnRow
            .filter { $0.id != noteId && $0.startStep + $0.lengthSteps <= initialStart }
            .map { $0.startStep + $0.lengthSteps }
            .max() ?? 0
        newStart = max(newStart, minStartFromLeft)

        var newLength = rightExclusive - newStart
        if newLength < 1 {
            newStart = max(minStartFromLeft, rightExclusive - 1)
            newLength = rightExclusive - newStart
        }
        if newStart + newLength > stepCount {
            newLength = stepCount - newStart
        }
        newLength = max(1, newLength)
        return (newStart, newLength)
    }

    /// Aplica inicio y longitud finales; elimina otras notas de la misma fila que solapen el nuevo rango.
    static func applyNoteSpan(
        notes: [PianoRollNote],
        id: UUID,
        newStart: Int,
        newLength: Int,
        stepCount: Int
    ) -> [PianoRollNote] {
        guard newLength >= 1,
              newStart >= 0,
              newStart + newLength <= stepCount,
              let idx = notes.firstIndex(where: { $0.id == id })
        else { return notes }
        let row = notes[idx].row
        let newRange = newStart ..< (newStart + newLength)
        var out = notes.filter { n in
            if n.id == id { return true }
            if n.row != row { return true }
            let er = n.startStep ..< (n.startStep + n.lengthSteps)
            return !newRange.overlaps(er)
        }
        guard let j = out.firstIndex(where: { $0.id == id }) else { return notes }
        out[j].startStep = newStart
        out[j].lengthSteps = newLength
        return out
    }

    /// Delta en pasos a partir del desplazamiento horizontal (misma lógica a izquierda y derecha; evita que `Int` trunque a 0 al acortar).
    static func strideStepDelta(translationWidth: CGFloat, stride: CGFloat) -> Int {
        guard stride > 0 else { return 0 }
        let eps = stride * 0.12
        if translationWidth >= 0 {
            return Int(floor((translationWidth + eps) / stride))
        }
        return -Int(floor((-translationWidth + eps) / stride))
    }

    static func addingNote(
        notes: [PianoRollNote],
        row: Int,
        start: Int,
        length: Int,
        stepCount: Int
    ) -> [PianoRollNote] {
        guard length >= 1,
              start >= 0, start < stepCount,
              start + length <= stepCount,
              row >= 0, row < rowCount
        else { return notes }

        let newRange = start ..< (start + length)
        let filtered = notes.filter { n in
            if n.row != row { return true }
            let existing = n.startStep ..< (n.startStep + n.lengthSteps)
            return !existing.overlaps(newRange)
        }
        var out = filtered
        out.append(PianoRollNote(id: UUID(), row: row, startStep: start, lengthSteps: length))
        return out
    }

    /// Tap: si hay nota en el paso, la elimina; si no, añade nota de 1 paso.
    static func togglingStep(notes: [PianoRollNote], row: Int, step: Int, stepCount: Int) -> [PianoRollNote] {
        guard isValid(row: row, step: step, stepCount: stepCount) else { return notes }
        if let hit = noteCovering(notes: notes, row: row, step: step) {
            return notes.filter { $0.id != hit.id }
        }
        return addingNote(notes: notes, row: row, start: step, length: 1, stepCount: stepCount)
    }

    /// Arrastre en celdas vacías: crea una nota desde el paso menor al mayor (inclusive).
    static func paintSteps(
        notes: [PianoRollNote],
        row: Int,
        fromStep: Int,
        toStep: Int,
        stepCount: Int
    ) -> [PianoRollNote] {
        guard row >= 0, row < rowCount else { return notes }
        let a = max(0, min(fromStep, toStep))
        let b = min(stepCount - 1, max(fromStep, toStep))
        guard a < stepCount, b >= 0, a <= b else { return notes }
        return addingNote(notes: notes, row: row, start: a, length: b - a + 1, stepCount: stepCount)
    }

    static func resizingNote(
        notes: [PianoRollNote],
        id: UUID,
        newLength: Int,
        stepCount: Int
    ) -> [PianoRollNote] {
        guard let i = notes.firstIndex(where: { $0.id == id }) else { return notes }
        let n = notes[i]
        let rowSiblings = notes.filter { $0.row == n.row }
        let len = clampedLength(
            startStep: n.startStep,
            desiredLength: newLength,
            stepCount: stepCount,
            noteId: id,
            notesOnRow: rowSiblings
        )
        return applyNoteSpan(notes: notes, id: id, newStart: n.startStep, newLength: len, stepCount: stepCount)
    }

    /// Al reducir compases: recorta o elimina notas fuera de rango.
    static func clampedNotes(_ notes: [PianoRollNote], stepCount: Int) -> [PianoRollNote] {
        notes.compactMap { n in
            guard n.startStep < stepCount else { return nil }
            var n2 = n
            let maxLen = stepCount - n.startStep
            n2.lengthSteps = min(max(n2.lengthSteps, 1), maxLen)
            return n2.lengthSteps >= 1 ? n2 : nil
        }
    }
}

// MARK: - Teclado lateral (vista lateral tipo piano: blancas a ancho completo, negras retradas)

private struct PianoRollKeyStrip: View {
    let rowCount: Int
    let cellHeight: CGFloat
    let rowSpacing: CGFloat
    /// Ancho total de la tira; las negras ocupan ~58 % y quedan alineadas al borde de la rejilla.
    let stripWidth: CGFloat

    private var blackKeyWidth: CGFloat { max(20, stripWidth * 0.58) }

    var body: some View {
        VStack(spacing: rowSpacing) {
            ForEach(0 ..< rowCount, id: \.self) { r in
                keyRow(forRow: r)
                    .frame(width: stripWidth, height: cellHeight)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Teclas de piano, una octava cromática")
    }

    @ViewBuilder
    private func keyRow(forRow r: Int) -> some View {
        let black = PianoRollGridMath.isBlackKeyRow(forRow: r)
        let label = PianoRollGridMath.noteLabel(forRow: r)
        if black {
            HStack(alignment: .bottom, spacing: 0) {
                Spacer(minLength: 0)
                ZStack {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(white: 0.18), Color(white: 0.04)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .strokeBorder(Color(white: 0.45), lineWidth: 0.5)
                        )
                    Text(label)
                        .font(.system(size: 8, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white.opacity(0.92))
                        .minimumScaleFactor(0.65)
                }
                .frame(width: blackKeyWidth, height: cellHeight * 0.88)
            }
            .frame(width: stripWidth, height: cellHeight)
        } else {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.99), Color(white: 0.78)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .strokeBorder(Color(white: 0.42), lineWidth: 0.75)
                    )
                Text(label)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(white: 0.12))
                    .minimumScaleFactor(0.65)
                    .padding(.leading, 3)
            }
            .frame(width: stripWidth, height: cellHeight)
        }
    }
}

// MARK: - Bloque de nota (solo dibujo; redimensionar y tap los gestiona la fila)

private struct PianoRollNoteBlock: View {
    let note: PianoRollNote
    let cellWidth: CGFloat
    let rowHeight: CGFloat
    let spacing: CGFloat
    /// Vista previa (inicio, longitud) durante el arrastre a nivel de fila.
    let previewSpan: (start: Int, length: Int)?

    private var stride: CGFloat { cellWidth + spacing }

    var body: some View {
        let start = previewSpan?.start ?? note.startStep
        let visualLength = previewSpan?.length ?? note.lengthSteps
        let width = stride * CGFloat(visualLength) - spacing

        RoundedRectangle(cornerRadius: 5, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.88, blue: 0.18),
                        Color(red: 0.72, green: 0.58, blue: 0.04),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .strokeBorder(Color(white: 0.45), lineWidth: 1.5)
            )
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.28))
                    .frame(width: 6, height: rowHeight * 0.55)
                    .padding(.leading, 3)
                    .accessibilityHidden(true)
            }
            .overlay(alignment: .trailing) {
                Capsule()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 6, height: rowHeight * 0.55)
                    .padding(.trailing, 3)
                    .accessibilityLabel("Bordes: arrastrar en la fila para alargar o acortar por izquierda o derecha")
            }
            .frame(width: max(width, cellWidth), height: rowHeight)
            .offset(x: CGFloat(start - note.startStep) * stride)
            .allowsHitTesting(false)
    }
}

private enum NoteResizeEdge: Equatable {
    /// Borde izquierdo: arrastrar a la izquierda alarga hacia pasos anteriores.
    case leading
    /// Borde derecho: misma lógica que antes (solo longitud).
    case trailing
}

/// Redimensionado activo a nivel de fila (el gesto sigue aunque el dedo salga del bloque amarillo).
private struct ActiveNoteResize: Equatable {
    var row: Int
    var noteId: UUID
    var edge: NoteResizeEdge
    var initialStart: Int
    var initialLength: Int
    var previewStart: Int
    var previewLength: Int
}

// MARK: - Vista principal

struct AcidPianoRoll: View {
    var gridSteps: Int
    var notes: [PianoRollNote]
    var onGridStepsChange: (Int) -> Void
    var onStepTap: (Int, Int) -> Void
    var onStepsPainted: (Int, Int, Int) -> Void
    var onNoteRemove: (UUID) -> Void
    var onNoteResize: (UUID, Int, Int) -> Void

    private let rowHeight: CGFloat = 28
    private let spacing: CGFloat = 2
    private let gridPaddingTop: CGFloat = 8
    private let gridPaddingTrailing: CGFloat = 8
    private let gridPaddingBottom: CGFloat = 8
    /// Pegado a la leyenda: padding mínimo entre teclas y rejilla.
    private let gridPaddingLeading: CGFloat = 2
    private let stepHeaderHeight: CGFloat = 12
    private let pianoStripWidth: CGFloat = 44

    private var stepCount: Int { PianoRollGridMath.normalizedGridSteps(gridSteps) }

    private var keyStripTopInset: CGFloat {
        gridPaddingTop + stepHeaderHeight + spacing
    }

    /// Borrador de pintura por arrastre en fila vacía (fila, inicio, actual).
    @State private var paintDrag: (row: Int, start: Int, current: Int)?
    @State private var activeNoteResize: ActiveNoteResize?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Piano roll")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("Resolución", selection: Binding(
                    get: { stepCount },
                    set: { onGridStepsChange($0) }
                )) {
                    Text("¼ compás (4)").tag(4)
                    Text("½ compás (8)").tag(8)
                    Text("1 compás (16)").tag(16)
                }
                .pickerStyle(.menu)
                .font(.caption)
            }

            HStack(alignment: .top, spacing: 0) {
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: keyStripTopInset)
                    PianoRollKeyStrip(
                        rowCount: PianoRollGridMath.rowCount,
                        cellHeight: rowHeight,
                        rowSpacing: spacing,
                        stripWidth: pianoStripWidth
                    )
                    Spacer(minLength: 0)
                }
                .frame(width: pianoStripWidth, height: gridMinHeight, alignment: .top)

                GeometryReader { geo in
                    let innerW = max(
                        1,
                        geo.size.width - gridPaddingLeading - gridPaddingTrailing
                    )
                    let cellWidth = max(
                        8,
                        (innerW - CGFloat(stepCount - 1) * spacing) / CGFloat(stepCount)
                    )
                    let stride = cellWidth + spacing

                    VStack(alignment: .leading, spacing: spacing) {
                        HStack(spacing: spacing) {
                            ForEach(0 ..< stepCount, id: \.self) { s in
                                Text("\(s + 1)")
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color(white: 0.94))
                                    .shadow(color: .black.opacity(0.45), radius: 0, x: 0, y: 0.5)
                                    .frame(width: cellWidth, height: stepHeaderHeight)
                            }
                        }

                        VStack(spacing: spacing) {
                            ForEach(0 ..< PianoRollGridMath.rowCount, id: \.self) { row in
                                rowView(
                                    row: row,
                                    cellWidth: cellWidth,
                                    stride: stride
                                )
                            }
                        }
                    }
                    .padding(.init(
                        top: gridPaddingTop,
                        leading: gridPaddingLeading,
                        bottom: gridPaddingBottom,
                        trailing: gridPaddingTrailing
                    ))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(white: 0.22).opacity(0.55))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color(white: 0.35), lineWidth: 1)
                    )
                }
                .frame(maxWidth: .infinity, minHeight: gridMinHeight, maxHeight: gridMinHeight)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Piano roll, \(stepCount) pasos, teclado a la izquierda")
    }

    private var gridMinHeight: CGFloat {
        let rows = CGFloat(PianoRollGridMath.rowCount)
        return gridPaddingTop + stepHeaderHeight + spacing
            + rows * rowHeight + (rows - 1) * spacing
            + gridPaddingBottom
    }

    private func stepFromX(_ x: CGFloat, cellWidth: CGFloat, stride: CGFloat) -> Int {
        guard stride > 0, stepCount > 0 else { return 0 }
        let s = Int((x / stride).rounded(.down))
        return min(stepCount - 1, max(0, s))
    }

    private func noteResizePreviewSpan(noteId: UUID, row: Int) -> (start: Int, length: Int)? {
        guard let ar = activeNoteResize, ar.row == row, ar.noteId == noteId else { return nil }
        return (ar.previewStart, ar.previewLength)
    }

    private func resizeEdgeForTouch(locationX: CGFloat, note: PianoRollNote, stride: CGFloat, cellWidth: CGFloat) -> NoteResizeEdge {
        let noteOrigin = CGFloat(note.startStep) * stride
        let rel = locationX - noteOrigin
        let noteWidth = max(stride * CGFloat(note.lengthSteps) - spacing, cellWidth)
        let leadingZone = min(max(cellWidth * 0.95, 16), noteWidth * 0.42)
        return rel <= leadingZone ? .leading : .trailing
    }

    @ViewBuilder
    private func rowView(row: Int, cellWidth: CGFloat, stride: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            HStack(spacing: spacing) {
                ForEach(0 ..< stepCount, id: \.self) { step in
                    emptyCell(row: row, step: step, cellWidth: cellWidth)
                }
            }

            if let draft = paintDrag, draft.row == row {
                let a = min(draft.start, draft.current)
                let b = max(draft.start, draft.current)
                let len = b - a + 1
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color(red: 0.98, green: 0.88, blue: 0.18).opacity(0.45))
                    .frame(width: CGFloat(len) * stride - spacing, height: rowHeight)
                    .offset(x: CGFloat(a) * stride)
                    .allowsHitTesting(false)
            }

            ForEach(notes.filter { $0.row == row }) { note in
                PianoRollNoteBlock(
                    note: note,
                    cellWidth: cellWidth,
                    rowHeight: rowHeight,
                    spacing: spacing,
                    previewSpan: noteResizePreviewSpan(noteId: note.id, row: row)
                )
                .offset(x: CGFloat(note.startStep) * stride)
            }
        }
        .frame(height: rowHeight)
        .contentShape(Rectangle())
        // Un solo gesto en la fila: redimensionar nota (dedo puede salir del bloque) o pintar en vacío.
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { g in
                    let s0 = stepFromX(g.startLocation.x, cellWidth: cellWidth, stride: stride)
                    let s1 = stepFromX(g.location.x, cellWidth: cellWidth, stride: stride)
                    let moved = hypot(g.translation.width, g.translation.height)

                    var ar = activeNoteResize
                    if ar == nil, paintDrag == nil,
                       let hit = PianoRollGridMath.noteCovering(notes: notes, row: row, step: s0)
                    {
                        let edge = resizeEdgeForTouch(
                            locationX: g.startLocation.x,
                            note: hit,
                            stride: stride,
                            cellWidth: cellWidth
                        )
                        ar = ActiveNoteResize(
                            row: row,
                            noteId: hit.id,
                            edge: edge,
                            initialStart: hit.startStep,
                            initialLength: hit.lengthSteps,
                            previewStart: hit.startStep,
                            previewLength: hit.lengthSteps
                        )
                    }

                    if var active = ar, active.row == row {
                        let delta = PianoRollGridMath.strideStepDelta(
                            translationWidth: g.translation.width,
                            stride: stride
                        )
                        let rowSiblings = notes.filter { $0.row == row }
                        switch active.edge {
                        case .trailing:
                            let proposed = active.initialLength + delta
                            let clampedLen = PianoRollGridMath.clampedLength(
                                startStep: active.initialStart,
                                desiredLength: proposed,
                                stepCount: stepCount,
                                noteId: active.noteId,
                                notesOnRow: rowSiblings
                            )
                            active.previewStart = active.initialStart
                            active.previewLength = clampedLen
                        case .leading:
                            let pair = PianoRollGridMath.clampedLeadingResize(
                                initialStart: active.initialStart,
                                initialLength: active.initialLength,
                                deltaSteps: delta,
                                noteId: active.noteId,
                                notesOnRow: rowSiblings,
                                stepCount: stepCount
                            )
                            active.previewStart = pair.start
                            active.previewLength = pair.length
                        }
                        activeNoteResize = active
                        paintDrag = nil
                        return
                    }

                    guard PianoRollGridMath.noteCovering(notes: notes, row: row, step: s0) == nil else {
                        return
                    }
                    guard moved >= 10 else { return }
                    paintDrag = (row, s0, s1)
                }
                .onEnded { g in
                    if let ar = activeNoteResize, ar.row == row {
                        let moved = hypot(g.translation.width, g.translation.height)
                        activeNoteResize = nil
                        paintDrag = nil
                        if moved < 12 {
                            onNoteRemove(ar.noteId)
                        } else {
                            onNoteResize(ar.noteId, ar.previewStart, ar.previewLength)
                        }
                        return
                    }
                    defer { paintDrag = nil }
                    let moved = hypot(g.translation.width, g.translation.height)
                    if moved < 12 { return }
                    let s0 = stepFromX(g.startLocation.x, cellWidth: cellWidth, stride: stride)
                    let s1 = stepFromX(g.location.x, cellWidth: cellWidth, stride: stride)
                    if PianoRollGridMath.noteCovering(notes: notes, row: row, step: s0) != nil {
                        return
                    }
                    onStepsPainted(row, s0, s1)
                }
        )
    }

    private func emptyCell(row: Int, step: Int, cellWidth: CGFloat) -> some View {
        let covered = PianoRollGridMath.noteCovering(notes: notes, row: row, step: step) != nil
        return RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color(white: 0.38), Color(white: 0.26)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(Color(white: 0.18), lineWidth: 1)
            )
            .frame(width: cellWidth, height: rowHeight)
            .contentShape(Rectangle())
            .opacity(covered ? 0.25 : 1)
            .allowsHitTesting(!covered)
            .onTapGesture {
                onStepTap(row, step)
            }
            .accessibilityLabel("Paso \(step + 1), \(PianoRollGridMath.noteLabel(forRow: row))")
            .accessibilityAddTraits(.isButton)
    }
}


#Preview("AcidPianoRoll") {
    struct Host: View {
        @State private var gridSteps = 16
        @State private var notes: [PianoRollNote] = []
        private var stepCount: Int { PianoRollGridMath.normalizedGridSteps(gridSteps) }
        var body: some View {
            AcidPianoRoll(
                gridSteps: gridSteps,
                notes: notes,
                onGridStepsChange: { gridSteps = $0 },
                onStepTap: { r, s in
                    notes = PianoRollGridMath.togglingStep(
                        notes: notes,
                        row: r,
                        step: s,
                        stepCount: stepCount
                    )
                },
                onStepsPainted: { r, a, b in
                    notes = PianoRollGridMath.paintSteps(
                        notes: notes,
                        row: r,
                        fromStep: a,
                        toStep: b,
                        stepCount: stepCount
                    )
                },
                onNoteRemove: { id in notes.removeAll { $0.id == id } },
                onNoteResize: { id, start, len in
                    notes = PianoRollGridMath.applyNoteSpan(
                        notes: notes,
                        id: id,
                        newStart: start,
                        newLength: len,
                        stepCount: stepCount
                    )
                }
            )
            .padding()
        }
    }
    return Host()
}
