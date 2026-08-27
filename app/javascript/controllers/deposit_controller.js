import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [
        "checkbox",
        "container",
        "input",
        "price"
    ]

    connect() {
        this.toggle()
        this.updateMax()
    }

    toggle() {
        const enabled = this.checkboxTarget.checked

        this.containerTarget.classList.toggle("hidden", !enabled)
        this.inputTarget.disabled = !enabled

        if (!enabled) {
            this.inputTarget.value = ""
        }
    }

    updateMax() {
        if (!this.hasPriceTarget) return

        const price = this.priceTarget.value

        this.inputTarget.max = price

        if (this.inputTarget.value && Number(this.inputTarget.value) > Number(price)) {
            this.inputTarget.value = price
        }
    }
}