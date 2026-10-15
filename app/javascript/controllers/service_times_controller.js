import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [
        "checkbox",
        "container",
        "input"
    ]

    connect() {
        if (!this.hasCheckboxTarget || !this.hasContainerTarget) {
            return
        }

        this.toggle()
    }

    toggle() {
        if (!this.hasCheckboxTarget || !this.hasContainerTarget) {
            return
        }

        const enabled = this.checkboxTarget.checked

        this.containerTarget.classList.toggle("hidden", !enabled)

        this.inputTargets.forEach((input) => {
            input.disabled = !enabled
        })
    }
}