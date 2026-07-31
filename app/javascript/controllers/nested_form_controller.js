// app/javascript/controllers/nested_form_controller.js

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    add(event) {
        const containerId = event.params.container
        const templateId = event.params.template

        const container = document.getElementById(containerId)
        const template = document.getElementById(templateId)

        if (!container || !template) return

        const uniqueId = Date.now().toString()

        const content = template.innerHTML.replaceAll(
            "NEW_RECORD",
            uniqueId
        )

        container.insertAdjacentHTML("beforeend", content)

        this.refreshIcons()
    }

    remove(event) {
        const item = event.currentTarget.closest(
            '[data-nested-form-target="item"]'
        )

        if (!item) return

        const idField = item.querySelector(
            'input[name$="[id]"]'
        )

        const destroyField = item.querySelector(
            'input[name$="[_destroy]"]'
        )

        if (idField && idField.value) {
            destroyField.value = "1"
            item.classList.add("hidden")
        } else {
            item.remove()
        }
    }

    refreshIcons() {
        if (window.lucide) {
            window.lucide.createIcons()
        }
    }
}