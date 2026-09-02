import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [
        "canvas",
        "structureInput"
    ]

    static values = {
        structure: Array
    }

    connect() {
        this.structure = this.hasStructureValue ? this.structureValue : []

        this.render()
    }

    dragStart(event) {
        const type = event.currentTarget.dataset.builderType

        event.dataTransfer.setData("text/plain", type)
        event.dataTransfer.effectAllowed = "copy"
    }

    allowDrop(event) {
        event.preventDefault()
        event.stopPropagation()
    }

    dropOnCanvas(event) {
        event.preventDefault()
        event.stopPropagation()

        const type = event.dataTransfer.getData("text/plain")

        if (type !== "row") {
            alert("Only rows can be dropped here.")
            return
        }

        this.structure.push(this.createElement("row"))

        this.update()
    }

    dropOnRow(event) {
        event.preventDefault()
        event.stopPropagation()

        const type = event.dataTransfer.getData("text/plain")
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

        const type = event.dataTransfer.getData("text/plain")
        const columnId = event.currentTarget.dataset.columnId

        if (type === "row" || type === "column") {
            alert("Rows and columns cannot be placed inside a column.")
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

    findItem(id, items = this.structure) {
        for (const item of items) {
            if (item.id === id) {
                return item
            }

            if (item.children?.length) {
                const found = this.findItem(id, item.children)

                if (found) {
                    return found
                }
            }
        }

        return null
    }

    remove(event) {
        const id = event.currentTarget.dataset.id

        this.structure = this.removeItem(
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
                    item.children = this.removeItem(
                        item.children,
                        id
                    )
                }

                return item
            })
    }

    updateLabelText(event) {
        const id = event.currentTarget.dataset.id
        const item = this.findItem(id)

        if (!item) return

        item.text = event.currentTarget.value

        this.syncStructure()
    }

    updatePlaceholder(event) {
        const id = event.currentTarget.dataset.id
        const item = this.findItem(id)

        if (!item) return

        item.placeholder = event.currentTarget.value

        this.syncStructure()
    }

    updateSubmitText(event) {
        const id = event.currentTarget.dataset.id
        const item = this.findItem(id)

        if (!item) return

        item.text = event.currentTarget.value

        this.syncStructure()
    }

    updateRequired(event) {
        const id = event.currentTarget.dataset.id
        const item = this.findItem(id)

        if (!item) return

        item.required = event.currentTarget.checked

        this.syncStructure()
    }

    syncStructure() {
        this.structureInputTarget.value =
            JSON.stringify(this.structure)
    }

    update() {
        this.syncStructure()

        this.render()
    }

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

        this.structure.forEach((item) => {
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

    rowHtml(row) {
        const columns = row.children || []

        return `
      <div
        class="group relative mb-5 rounded-xl border border-slate-300 bg-white p-4 shadow-sm"
      >

        <div class="mb-3 flex items-center justify-between">

          <div class="text-xs font-semibold uppercase tracking-wide text-slate-400">
            Row
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
                  ${columns.map(column => this.columnHtml(column)).join("")}
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

    columnHtml(column) {
        const children = column.children || []

        return `
      <div
        class="group/column relative rounded-xl border border-blue-200 bg-white p-3"
      >

        <div class="mb-3 flex items-center justify-between">

          <span class="text-xs font-semibold uppercase tracking-wide text-blue-500">
            Column
          </span>

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
                ? children.map(child => this.elementHtml(child)).join("")
                : `
                <div class="flex min-h-[110px] items-center justify-center px-4 text-center text-xs text-slate-400">
                  Drag fields into this column
                </div>
              `
        }

        </div>

      </div>
    `
    }

    labelHtml(item) {
        return this.fieldWrapper(item, `
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
    `)
    }

    textFieldHtml(item) {
        return this.fieldWrapper(item, `
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
  `)
    }

    numberFieldHtml(item) {
        return this.fieldWrapper(item, `
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
  `)
    }

    textareaHtml(item) {
        return this.fieldWrapper(item, `
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
  `)
    }

    selectHtml(item) {
        return this.fieldWrapper(item, `
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
            item.options.map(option => `
              <option>${this.escape(option)}</option>
            `).join("")
        }
        </select>
      </div>

      ${this.requiredHtml(item)}

    </div>
  `)
    }

    submitHtml(item) {
        return this.fieldWrapper(item, `
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
    `)
    }

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

    fieldWrapper(item, content) {
        return `
      <div class="relative mb-3 rounded-lg border border-slate-200 bg-white p-4 shadow-sm">

        <button
          type="button"
          data-action="form-builder#remove"
          data-id="${item.id}"
          class="absolute right-2 top-2 rounded-md px-2 py-1 text-xs text-red-500 hover:bg-red-50"
        >
          Delete
        </button>

        <div class="pr-14">
          ${content}
        </div>

      </div>
    `
    }

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

    clear() {
        if (!confirm("Are you sure you want to clear the form?")) {
            return
        }

        this.structure = []

        this.update()
    }

    preview() {
        console.log(this.structure)
    }

    escape(value = "") {
        const div = document.createElement("div")

        div.textContent = value

        return div.innerHTML
    }
}