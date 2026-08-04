import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["checkbox", "container", "input"]

    connect() {
        this.toggle()
    }

    toggle() {
        const enabled = this.checkboxTarget.checked

        this.containerTarget.classList.toggle("hidden", !enabled)
        this.inputTarget.disabled = !enabled

        if (!enabled) {
            this.inputTarget.value = ""
        }
    }
}