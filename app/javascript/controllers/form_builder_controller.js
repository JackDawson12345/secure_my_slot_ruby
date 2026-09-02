import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [
        "canvas",
        "structureInput",
        "previewModal",
        "previewContent"
    ]

    static values = {
        structure: Array
    }


    connect() {
        this.structure = this.hasStructureValue
            ? this.structureValue
            : []

        this.draggingExisting = false
        this.draggedExistingId = null
        this.draggedExistingType = null

        this.render()
    }


    // =========================================================
    // NEW ELEMENTS FROM LEFT SIDEBAR
    // =========================================================

    dragStart(event) {
        const type = event.currentTarget.dataset.builderType

        event.dataTransfer.setData(
            "application/x-form-builder",
            JSON.stringify({
                source: "palette",
                type: type
            })
        )

        event.dataTransfer.effectAllowed = "copy"

        this.draggingExisting = false
        this.draggedExistingId = null
        this.draggedExistingType = null
    }


    getDragData(event) {
        const customData =
            event.dataTransfer.getData(
                "application/x-form-builder"
            )

        if (customData) {
            try {
                return JSON.parse(customData)
            } catch {
                return null
            }
        }

        // Fallback for any older drag behaviour
        const legacyType =
            event.dataTransfer.getData("text/plain")

        if (legacyType) {
            return {
                source: "palette",
                type: legacyType
            }
        }

        return null
    }


    allowDrop(event) {
        event.preventDefault()
    }


    dropOnCanvas(event) {
        event.preventDefault()
        event.stopPropagation()

        const dragData = this.getDragData(event)

        if (!dragData) return

        // Existing rows are handled by their own drop targets.
        if (dragData.source === "existing") {
            return
        }

        if (dragData.type !== "row") {
            alert("Only rows can be dropped here.")
            return
        }

        this.structure.push(
            this.createElement("row")
        )

        this.update()
    }


    dropOnRow(event) {
        event.preventDefault()
        event.stopPropagation()

        const dragData = this.getDragData(event)

        if (!dragData) return

        // Existing items are handled separately.
        if (dragData.source === "existing") {
            return
        }

        const type = dragData.type
        const rowId = event.currentTarget.dataset.rowId

        if (type !== "column") {
            alert("Only columns can be placed inside a row.")
            return
        }

        const row = this.findItem(rowId)

        if (!row) return

        row.children ||= []

        row.children.push(
            this.createElement("column")
        )

        this.update()
    }


    dropOnColumn(event) {
        event.preventDefault()
        event.stopPropagation()

        const dragData = this.getDragData(event)

        if (!dragData) return

        /*
         * Existing fields can be dropped into an empty column.
         * Existing field to existing field reordering is handled
         * by dropExisting.
         */
        if (dragData.source === "existing") {
            if (dragData.type !== "field") return

            const columnId =
                event.currentTarget.dataset.columnId

            this.moveExistingFieldToColumn(
                dragData.id,
                columnId
            )

            return
        }

        const type = dragData.type
        const columnId =
            event.currentTarget.dataset.columnId

        if (type === "row" || type === "column") {
            alert(
                "Rows and columns cannot be placed inside a column."
            )
            return
        }

        const column = this.findItem(columnId)

        if (!column) return

        column.children ||= []

        column.children.push(
            this.createElement(type)
        )

        this.update()
    }


    // =========================================================
    // EXISTING ELEMENT DRAGGING
    // =========================================================

    existingDragStart(event) {
        event.stopPropagation()

        const handle = event.currentTarget

        const id = handle.dataset.existingId
        const type = handle.dataset.existingType

        this.draggingExisting = true
        this.draggedExistingId = id
        this.draggedExistingType = type

        event.dataTransfer.setData(
            "application/x-form-builder",
            JSON.stringify({
                source: "existing",
                id: id,
                type: type
            })
        )

        event.dataTransfer.effectAllowed = "move"

        const wrapper =
            handle.closest("[data-existing-wrapper]")

        if (wrapper) {
            wrapper.classList.add(
                "opacity-40",
                "ring-2",
                "ring-slate-300"
            )
        }
    }


    existingDragEnd(event) {
        const handle = event.currentTarget

        const wrapper =
            handle.closest("[data-existing-wrapper]")

        if (wrapper) {
            wrapper.classList.remove(
                "opacity-40",
                "ring-2",
                "ring-slate-300"
            )
        }

        this.clearDropIndicators()

        this.draggingExisting = false
        this.draggedExistingId = null
        this.draggedExistingType = null
    }


    existingDragOver(event) {
        const dragData = this.getDragData(event)

        if (!dragData) return
        if (dragData.source !== "existing") return

        const target = event.currentTarget

        const targetType =
            target.dataset.existingType

        /*
         * Rows can only be reordered against rows.
         * Columns can only be reordered against columns.
         * Fields can only be reordered against fields.
         */
        if (dragData.type !== targetType) {
            return
        }

        event.preventDefault()
        event.stopPropagation()

        event.dataTransfer.dropEffect = "move"

        this.clearDropIndicators()

        const position =
            this.getDropPosition(
                event,
                target,
                targetType
            )

        if (position === "before") {
            target.classList.add(
                "ring-2",
                "ring-blue-400",
                "ring-offset-2"
            )

            target.dataset.dropPosition = "before"
        } else {
            target.classList.add(
                "ring-2",
                "ring-blue-400",
                "ring-offset-2"
            )

            target.dataset.dropPosition = "after"
        }
    }


    existingDragLeave(event) {
        const target = event.currentTarget

        /*
         * Do not immediately clear if we are still
         * somewhere inside this same element.
         */
        if (
            event.relatedTarget &&
            target.contains(event.relatedTarget)
        ) {
            return
        }

        target.classList.remove(
            "ring-2",
            "ring-blue-400",
            "ring-offset-2"
        )

        delete target.dataset.dropPosition
    }


    dropExisting(event) {
        const dragData = this.getDragData(event)

        if (!dragData) return
        if (dragData.source !== "existing") return

        event.preventDefault()
        event.stopPropagation()

        const target = event.currentTarget

        const targetId =
            target.dataset.existingId

        const targetType =
            target.dataset.existingType

        const position =
            target.dataset.dropPosition || "after"

        if (!targetId) return
        if (dragData.id === targetId) return
        if (dragData.type !== targetType) return

        switch (dragData.type) {
            case "row":
                this.reorderRow(
                    dragData.id,
                    targetId,
                    position
                )
                break

            case "column":
                this.reorderColumn(
                    dragData.id,
                    targetId,
                    position
                )
                break

            case "field":
                this.reorderField(
                    dragData.id,
                    targetId,
                    position
                )
                break
        }

        this.clearDropIndicators()

        this.draggingExisting = false
        this.draggedExistingId = null
        this.draggedExistingType = null

        this.update()
    }


    getDropPosition(event, target, type) {
        const rect =
            target.getBoundingClientRect()

        /*
         * Columns appear horizontally, so determine
         * before/after using the mouse X position.
         *
         * Rows and fields are vertical, so use Y.
         */
        if (type === "column") {
            const middle =
                rect.left + rect.width / 2

            return event.clientX < middle
                ? "before"
                : "after"
        }

        const middle =
            rect.top + rect.height / 2

        return event.clientY < middle
            ? "before"
            : "after"
    }


    clearDropIndicators() {
        this.canvasTarget
            .querySelectorAll("[data-existing-wrapper]")
            .forEach(element => {
                element.classList.remove(
                    "ring-2",
                    "ring-blue-400",
                    "ring-offset-2"
                )

                delete element.dataset.dropPosition
            })
    }


    // =========================================================
    // ROW REORDERING
    // =========================================================

    reorderRow(sourceId, targetId, position) {
        const sourceIndex =
            this.structure.findIndex(
                item => item.id === sourceId
            )

        const targetIndex =
            this.structure.findIndex(
                item => item.id === targetId
            )

        if (
            sourceIndex === -1 ||
            targetIndex === -1
        ) {
            return
        }

        const [movedRow] =
            this.structure.splice(
                sourceIndex,
                1
            )

        let newTargetIndex =
            this.structure.findIndex(
                item => item.id === targetId
            )

        if (newTargetIndex === -1) {
            this.structure.push(movedRow)
            return
        }

        if (position === "after") {
            newTargetIndex += 1
        }

        this.structure.splice(
            newTargetIndex,
            0,
            movedRow
        )
    }


    // =========================================================
    // COLUMN REORDERING
    // =========================================================

    reorderColumn(sourceId, targetId, position) {
        const sourceLocation =
            this.findItemLocation(sourceId)

        const targetLocation =
            this.findItemLocation(targetId)

        if (
            !sourceLocation ||
            !targetLocation
        ) {
            return
        }

        /*
         * Keep columns inside their current row.
         * Fields can move between columns, but columns
         * themselves stay within their parent row.
         */
        if (
            sourceLocation.parent?.id !==
            targetLocation.parent?.id
        ) {
            return
        }

        const children =
            sourceLocation.parent.children

        const sourceIndex =
            children.findIndex(
                item => item.id === sourceId
            )

        if (sourceIndex === -1) return

        const [movedColumn] =
            children.splice(
                sourceIndex,
                1
            )

        let targetIndex =
            children.findIndex(
                item => item.id === targetId
            )

        if (targetIndex === -1) {
            children.push(movedColumn)
            return
        }

        if (position === "after") {
            targetIndex += 1
        }

        children.splice(
            targetIndex,
            0,
            movedColumn
        )
    }


    // =========================================================
    // FIELD REORDERING
    // =========================================================

    reorderField(sourceId, targetId, position) {
        const sourceLocation =
            this.findItemLocation(sourceId)

        const targetLocation =
            this.findItemLocation(targetId)

        if (
            !sourceLocation ||
            !targetLocation
        ) {
            return
        }

        const sourceParent =
            sourceLocation.parent

        const targetParent =
            targetLocation.parent

        if (
            !sourceParent ||
            !targetParent
        ) {
            return
        }

        if (
            sourceParent.type !== "column" ||
            targetParent.type !== "column"
        ) {
            return
        }

        const sourceChildren =
            sourceParent.children

        const targetChildren =
            targetParent.children

        const sourceIndex =
            sourceChildren.findIndex(
                item => item.id === sourceId
            )

        if (sourceIndex === -1) return

        const [movedField] =
            sourceChildren.splice(
                sourceIndex,
                1
            )

        let targetIndex =
            targetChildren.findIndex(
                item => item.id === targetId
            )

        if (targetIndex === -1) {
            targetChildren.push(movedField)
            return
        }

        if (position === "after") {
            targetIndex += 1
        }

        targetChildren.splice(
            targetIndex,
            0,
            movedField
        )
    }


    moveExistingFieldToColumn(
        fieldId,
        columnId
    ) {
        const sourceLocation =
            this.findItemLocation(fieldId)

        const targetColumn =
            this.findItem(columnId)

        if (!sourceLocation) return
        if (!targetColumn) return

        if (
            sourceLocation.item.type === "row" ||
            sourceLocation.item.type === "column"
        ) {
            return
        }

        if (targetColumn.type !== "column") {
            return
        }

        /*
         * If the field is already inside this column,
         * dropping into the general column area simply
         * moves it to the bottom.
         */
        const sourceParent =
            sourceLocation.parent

        if (!sourceParent) return

        const sourceIndex =
            sourceParent.children.findIndex(
                item => item.id === fieldId
            )

        if (sourceIndex === -1) return

        const [movedField] =
            sourceParent.children.splice(
                sourceIndex,
                1
            )

        targetColumn.children ||= []

        targetColumn.children.push(movedField)

        this.update()
    }


    // =========================================================
    // ELEMENT CREATION
    // =========================================================

    createElement(type) {
        const id = crypto.randomUUID()

        switch (type) {
            case "row":
                return {
                    id,
                    type: "row",
                    children: []
                }

            case "column":
                return {
                    id,
                    type: "column",
                    width: "full",
                    children: []
                }

            case "label":
                return {
                    id,
                    type: "label",
                    text: "Label"
                }

            case "text":
                return {
                    id,
                    type: "text",
                    name: `field_${Date.now()}`,
                    placeholder: "",
                    required: false
                }

            case "number":
                return {
                    id,
                    type: "number",
                    name: `field_${Date.now()}`,
                    placeholder: "",
                    required: false
                }

            case "textarea":
                return {
                    id,
                    type: "textarea",
                    name: `field_${Date.now()}`,
                    placeholder: "",
                    required: false
                }

            case "select":
                return {
                    id,
                    type: "select",
                    name: `field_${Date.now()}`,
                    options: [
                        "Option 1",
                        "Option 2"
                    ],
                    required: false
                }

            case "submit":
                return {
                    id,
                    type: "submit",
                    text: "Submit"
                }

            default:
                return null
        }
    }


    // =========================================================
    // FINDING ITEMS
    // =========================================================

    findItem(
        id,
        items = this.structure
    ) {
        for (const item of items) {
            if (item.id === id) {
                return item
            }

            if (item.children?.length) {
                const found =
                    this.findItem(
                        id,
                        item.children
                    )

                if (found) {
                    return found
                }
            }
        }

        return null
    }


    findItemLocation(
        id,
        items = this.structure,
        parent = null
    ) {
        for (
            let index = 0;
            index < items.length;
            index++
        ) {
            const item = items[index]

            if (item.id === id) {
                return {
                    item: item,
                    parent: parent,
                    items: items,
                    index: index
                }
            }

            if (item.children?.length) {
                const found =
                    this.findItemLocation(
                        id,
                        item.children,
                        item
                    )

                if (found) {
                    return found
                }
            }
        }

        return null
    }


    // =========================================================
    // REMOVE
    // =========================================================

    remove(event) {
        event.stopPropagation()

        const id =
            event.currentTarget.dataset.id

        this.structure =
            this.removeItem(
                this.structure,
                id
            )

        this.update()
    }


    removeItem(items, id) {
        return items
            .filter(item => item.id !== id)
            .map(item => {
                if (item.children) {
                    item.children =
                        this.removeItem(
                            item.children,
                            id
                        )
                }

                return item
            })
    }


    // =========================================================
    // FIELD SETTINGS
    // =========================================================

    updateLabelText(event) {
        const id =
            event.currentTarget.dataset.id

        const item =
            this.findItem(id)

        if (!item) return

        item.text =
            event.currentTarget.value

        this.syncStructure()
    }


    updatePlaceholder(event) {
        const id =
            event.currentTarget.dataset.id

        const item =
            this.findItem(id)

        if (!item) return

        item.placeholder =
            event.currentTarget.value

        this.syncStructure()
    }


    updateSubmitText(event) {
        const id =
            event.currentTarget.dataset.id

        const item =
            this.findItem(id)

        if (!item) return

        item.text =
            event.currentTarget.value

        this.syncStructure()
    }


    updateRequired(event) {
        const id =
            event.currentTarget.dataset.id

        const item =
            this.findItem(id)

        if (!item) return

        item.required =
            event.currentTarget.checked

        this.syncStructure()
    }


    // =========================================================
    // SYNC / UPDATE
    // =========================================================

    syncStructure() {
        this.structureInputTarget.value =
            JSON.stringify(this.structure)
    }


    update() {
        this.syncStructure()
        this.render()
    }


    // =========================================================
    // RENDER
    // =========================================================

    render() {
        this.canvasTarget.innerHTML = ""

        if (this.structure.length === 0) {
            this.canvasTarget.innerHTML = `
                <div class="flex min-h-[600px] items-center justify-center">
                    <div class="text-center">

                        <div class="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-2xl bg-slate-100 text-2xl text-slate-400">
                            +
                        </div>

                        <h3 class="text-base font-semibold text-slate-800">
                            Start with a row
                        </h3>

                        <p class="mt-2 text-sm text-slate-500">
                            Drag a row from the left into this area.
                        </p>

                    </div>
                </div>
            `

            this.syncStructure()

            return
        }

        this.structure.forEach(item => {
            this.canvasTarget.insertAdjacentHTML(
                "beforeend",
                this.elementHtml(item)
            )
        })

        this.syncStructure()
    }


    elementHtml(item) {
        switch (item.type) {
            case "row":
                return this.rowHtml(item)

            case "column":
                return this.columnHtml(item)

            case "label":
                return this.labelHtml(item)

            case "text":
                return this.textFieldHtml(item)

            case "number":
                return this.numberFieldHtml(item)

            case "textarea":
                return this.textareaHtml(item)

            case "select":
                return this.selectHtml(item)

            case "submit":
                return this.submitHtml(item)

            default:
                return ""
        }
    }


    // =========================================================
    // ROW
    // =========================================================

    rowHtml(row) {
        const columns =
            row.children || []

        return `
            <div
                data-existing-wrapper
                data-existing-id="${row.id}"
                data-existing-type="row"
                data-action="
                    dragover->form-builder#existingDragOver
                    dragleave->form-builder#existingDragLeave
                    drop->form-builder#dropExisting
                "
                class="group relative mb-5 rounded-xl border border-slate-300 bg-white p-4 shadow-sm transition"
            >

                <div class="mb-3 flex items-center gap-2">

    <div class="flex min-w-0 flex-1 items-center gap-2">

        ${this.dragHandleHtml(
            row.id,
            "row"
        )}

    </div>

    <button
                        type="button"
                        data-action="form-builder#remove"
                        data-id="${row.id}"
                        class="rounded-md px-2 py-1 text-xs font-medium text-red-600 hover:bg-red-50"
                    >
                        Delete row
                    </button>

                </div>

                <div
                    data-row-id="${row.id}"
                    data-action="
                        dragover->form-builder#allowDrop
                        drop->form-builder#dropOnRow
                    "
                    class="min-h-[120px] rounded-xl border-2 border-dashed border-slate-300 bg-slate-50 p-3"
                >

                    ${
            columns.length
                ? `
                                <div class="${this.columnGridClass(columns.length)}">
                                    ${
                    columns
                        .map(column =>
                            this.columnHtml(column)
                        )
                        .join("")
                }
                                </div>
                            `
                : `
                                <div class="flex min-h-[90px] items-center justify-center text-sm text-slate-400">
                                    Drag columns into this row
                                </div>
                            `
        }

                </div>

            </div>
        `
    }


    // =========================================================
    // COLUMN
    // =========================================================

    columnHtml(column) {
        const children =
            column.children || []

        return `
            <div
                data-existing-wrapper
                data-existing-id="${column.id}"
                data-existing-type="column"
                data-action="
                    dragover->form-builder#existingDragOver
                    dragleave->form-builder#existingDragLeave
                    drop->form-builder#dropExisting
                "
                class="group/column relative rounded-xl border border-blue-200 bg-white p-3 transition"
            >

                <div class="mb-3 flex items-center gap-2">

    <div class="flex min-w-0 flex-1 items-center gap-2">

        ${this.dragHandleHtml(
            column.id,
            "column"
        )}

    </div>

    <button
                        type="button"
                        data-action="form-builder#remove"
                        data-id="${column.id}"
                        class="rounded-md px-2 py-1 text-xs font-medium text-red-500 hover:bg-red-50"
                    >
                        Delete
                    </button>

                </div>

                <div
                    data-column-id="${column.id}"
                    data-action="
                        dragover->form-builder#allowDrop
                        drop->form-builder#dropOnColumn
                    "
                    class="min-h-[140px] rounded-lg border-2 border-dashed border-blue-200 bg-blue-50/30 p-3"
                >

                    ${
            children.length
                ? children
                    .map(child =>
                        this.elementHtml(child)
                    )
                    .join("")
                : `
                                <div class="pointer-events-none flex min-h-[110px] items-center justify-center px-4 text-center text-xs text-slate-400">
                                    Drag fields into this column
                                </div>
                            `
        }

                </div>

            </div>
        `
    }


    // =========================================================
    // LABEL
    // =========================================================

    labelHtml(item) {
        return this.fieldWrapper(
            item,
            `
                <div>
                    <label class="mb-2 block text-xs font-medium uppercase tracking-wide text-slate-400">
                        Label text
                    </label>

                    <input
                        type="text"
                        value="${this.escape(item.text)}"
                        data-action="input->form-builder#updateLabelText"
                        data-id="${item.id}"
                        class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2.5 text-sm text-slate-800 outline-none transition focus:border-slate-500 focus:ring-2 focus:ring-slate-200"
                    >
                </div>
            `
        )
    }


    // =========================================================
    // TEXT FIELD
    // =========================================================

    textFieldHtml(item) {
        return this.fieldWrapper(
            item,
            `
                <div class="space-y-3">

                    <div>
                        <label class="mb-1.5 block text-xs font-medium text-slate-500">
                            Placeholder
                        </label>

                        <input
                            type="text"
                            value="${this.escape(item.placeholder || "")}"
                            data-action="input->form-builder#updatePlaceholder"
                            data-id="${item.id}"
                            placeholder="Enter placeholder text"
                            class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-800 outline-none focus:border-slate-500 focus:ring-2 focus:ring-slate-200"
                        >
                    </div>

                    ${this.requiredHtml(item)}

                </div>
            `
        )
    }


    // =========================================================
    // NUMBER FIELD
    // =========================================================

    numberFieldHtml(item) {
        return this.fieldWrapper(
            item,
            `
                <div class="space-y-3">

                    <div>
                        <label class="mb-1.5 block text-xs font-medium text-slate-500">
                            Placeholder
                        </label>

                        <input
                            type="text"
                            value="${this.escape(item.placeholder || "")}"
                            data-action="input->form-builder#updatePlaceholder"
                            data-id="${item.id}"
                            placeholder="Enter placeholder text"
                            class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-800 outline-none focus:border-slate-500 focus:ring-2 focus:ring-slate-200"
                        >
                    </div>

                    ${this.requiredHtml(item)}

                </div>
            `
        )
    }


    // =========================================================
    // TEXTAREA
    // =========================================================

    textareaHtml(item) {
        return this.fieldWrapper(
            item,
            `
                <div class="space-y-3">

                    <div>
                        <label class="mb-1.5 block text-xs font-medium text-slate-500">
                            Placeholder
                        </label>

                        <input
                            type="text"
                            value="${this.escape(item.placeholder || "")}"
                            data-action="input->form-builder#updatePlaceholder"
                            data-id="${item.id}"
                            placeholder="Enter placeholder text"
                            class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-800 outline-none focus:border-slate-500 focus:ring-2 focus:ring-slate-200"
                        >
                    </div>

                    ${this.requiredHtml(item)}

                </div>
            `
        )
    }


    // =========================================================
    // SELECT
    // =========================================================

    selectHtml(item) {
        return this.fieldWrapper(
            item,
            `
                <div class="space-y-3">

                    <div>

                        <label class="mb-1.5 block text-xs font-medium text-slate-500">
                            Current options
                        </label>

                        <select
                            disabled
                            class="w-full rounded-lg border border-slate-300 bg-slate-50 px-3 py-2.5 text-sm text-slate-500"
                        >
                            ${
                (item.options || [])
                    .map(option => `
                                        <option>
                                            ${this.escape(option)}
                                        </option>
                                    `)
                    .join("")
            }
                        </select>

                    </div>

                    ${this.requiredHtml(item)}

                </div>
            `
        )
    }


    // =========================================================
    // SUBMIT
    // =========================================================

    submitHtml(item) {
        return this.fieldWrapper(
            item,
            `
                <div class="space-y-3">

                    <div>

                        <label class="mb-1.5 block text-xs font-medium text-slate-500">
                            Button text
                        </label>

                        <input
                            type="text"
                            value="${this.escape(item.text)}"
                            data-action="input->form-builder#updateSubmitText"
                            data-id="${item.id}"
                            class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-800 outline-none focus:border-slate-500 focus:ring-2 focus:ring-slate-200"
                        >

                    </div>

                    <button
                        type="button"
                        disabled
                        class="rounded-lg bg-slate-900 px-5 py-2.5 text-sm font-semibold text-white"
                    >
                        ${this.escape(item.text)}
                    </button>

                </div>
            `
        )
    }


    // =========================================================
    // REQUIRED
    // =========================================================

    requiredHtml(item) {
        return `
            <label class="flex items-center gap-2 text-sm text-slate-600">

                <input
                    type="checkbox"
                    ${item.required ? "checked" : ""}
                    data-action="change->form-builder#updateRequired"
                    data-id="${item.id}"
                    class="h-4 w-4 rounded border-slate-300 text-slate-900 focus:ring-slate-500"
                >

                Required field

            </label>
        `
    }


    // =========================================================
    // FIELD WRAPPER
    // =========================================================

    fieldWrapper(item, content) {
        return `
            <div
                data-existing-wrapper
                data-existing-id="${item.id}"
                data-existing-type="field"
                data-action="
                    dragover->form-builder#existingDragOver
                    dragleave->form-builder#existingDragLeave
                    drop->form-builder#dropExisting
                "
                class="relative mb-3 rounded-lg border border-slate-200 bg-white p-4 shadow-sm transition"
            >

                <div class="mb-3 flex items-center gap-2">

    ${this.dragHandleHtml(
            item.id,
            "field"
        )}

    <button
                        type="button"
                        data-action="form-builder#remove"
                        data-id="${item.id}"
                        class="rounded-md px-2 py-1 text-xs text-red-500 hover:bg-red-50"
                    >
                        Delete
                    </button>

                </div>

                <div>
                    ${content}
                </div>

            </div>
        `
    }


    // =========================================================
    // DRAG HANDLE
    // =========================================================

    dragHandleHtml(id, type) {
        let label = "Drag field"

        if (type === "row") {
            label = "Drag row"
        }

        if (type === "column") {
            label = "Drag column"
        }

        return `
        <div
            draggable="true"
            data-existing-id="${id}"
            data-existing-type="${type}"
            data-action="
                dragstart->form-builder#existingDragStart
                dragend->form-builder#existingDragEnd
            "
            class="
                group flex flex-1 cursor-grab items-center gap-2
                rounded-lg px-3 py-2
                text-slate-400
                transition
                hover:bg-slate-100
                hover:text-slate-700
                active:cursor-grabbing
            "
            title="${label}"
        >

            <svg
                class="h-5 w-5 shrink-0"
                xmlns="http://www.w3.org/2000/svg"
                fill="currentColor"
                viewBox="0 0 24 24"
            >
                <circle cx="8" cy="7" r="1.4"></circle>
                <circle cx="16" cy="7" r="1.4"></circle>

                <circle cx="8" cy="12" r="1.4"></circle>
                <circle cx="16" cy="12" r="1.4"></circle>

                <circle cx="8" cy="17" r="1.4"></circle>
                <circle cx="16" cy="17" r="1.4"></circle>
            </svg>

            <span class="text-xs font-medium">
                ${label}
            </span>

        </div>
    `
    }


    // =========================================================
    // COLUMN GRID
    // =========================================================

    columnGridClass(count) {
        switch (count) {
            case 1:
                return "grid grid-cols-1 gap-3"

            case 2:
                return "grid grid-cols-2 gap-3"

            case 3:
                return "grid grid-cols-3 gap-3"

            case 4:
                return "grid grid-cols-4 gap-3"

            default:
                return "grid grid-cols-1 gap-3"
        }
    }


    // =========================================================
    // CLEAR
    // =========================================================

    clear() {
        if (
            !confirm(
                "Are you sure you want to clear the form?"
            )
        ) {
            return
        }

        this.structure = []

        this.update()
    }


    // =========================================================
    // PREVIEW
    // =========================================================

    preview() {
        if (!this.hasPreviewModalTarget) {
            console.log(this.structure)
            return
        }

        if (this.hasPreviewContentTarget) {
            this.previewContentTarget.innerHTML =
                this.previewHtml()
        }

        this.previewModalTarget.classList.remove(
            "hidden"
        )

        document.body.classList.add(
            "overflow-hidden"
        )
    }


    closePreview() {
        if (!this.hasPreviewModalTarget) {
            return
        }

        this.previewModalTarget.classList.add(
            "hidden"
        )

        document.body.classList.remove(
            "overflow-hidden"
        )
    }


    previewHtml() {
        if (this.structure.length === 0) {
            return `
                <div class="py-12 text-center text-sm text-slate-500">
                    Your consultation form is empty.
                </div>
            `
        }

        return this.structure
            .map(row =>
                this.previewRowHtml(row)
            )
            .join("")
    }


    previewRowHtml(row) {
        const columns =
            row.children || []

        if (columns.length === 0) {
            return ""
        }

        return `
            <div class="mb-6 ${this.columnGridClass(columns.length)}">
                ${
            columns
                .map(column =>
                    this.previewColumnHtml(column)
                )
                .join("")
        }
            </div>
        `
    }


    previewColumnHtml(column) {
        const children =
            column.children || []

        return `
            <div class="space-y-4">
                ${
            children
                .map(item =>
                    this.previewElementHtml(item)
                )
                .join("")
        }
            </div>
        `
    }


    previewElementHtml(item) {
        switch (item.type) {
            case "label":
                return `
                    <div class="text-sm font-semibold text-slate-900">
                        ${this.escape(item.text)}
                    </div>
                `

            case "text":
                return `
                    <input
                        type="text"
                        placeholder="${this.escape(item.placeholder || "")}"
                        ${item.required ? "required" : ""}
                        class="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm"
                    >
                `

            case "number":
                return `
                    <input
                        type="number"
                        placeholder="${this.escape(item.placeholder || "")}"
                        ${item.required ? "required" : ""}
                        class="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm"
                    >
                `

            case "textarea":
                return `
                    <textarea
                        placeholder="${this.escape(item.placeholder || "")}"
                        ${item.required ? "required" : ""}
                        rows="4"
                        class="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm"
                    ></textarea>
                `

            case "select":
                return `
                    <select
                        ${item.required ? "required" : ""}
                        class="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm"
                    >
                        ${
                    (item.options || [])
                        .map(option => `
                                    <option>
                                        ${this.escape(option)}
                                    </option>
                                `)
                        .join("")
                }
                    </select>
                `

            case "submit":
                return `
                    <button
                        type="button"
                        class="rounded-lg bg-slate-900 px-5 py-2.5 text-sm font-semibold text-white"
                    >
                        ${this.escape(item.text)}
                    </button>
                `

            default:
                return ""
        }
    }


    // =========================================================
    // ESCAPE HTML
    // =========================================================

    escape(value = "") {
        const div =
            document.createElement("div")

        div.textContent = value

        return div.innerHTML
    }
}