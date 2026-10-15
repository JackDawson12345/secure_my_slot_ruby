import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [
        "checkbox",
        "container",
        "input",
        "price"
    ]

    connect() {
        if (!this.hasCheckboxTarget || !this.hasContainerTarget || !this.hasInputTarget) {
            return
        }

        this.toggle()
        this.updateMax()
    }

    toggle() {
        if (!this.hasCheckboxTarget || !this.hasContainerTarget || !this.hasInputTarget) {
            return
        }

        const enabled = this.checkboxTarget.checked

        this.containerTarget.classList.toggle("hidden", !enabled)
        this.inputTarget.disabled = !enabled

        if (!enabled) {
            this.inputTarget.value = ""
        }
    }

    updateMax() {
        if (!this.hasPriceTarget || !this.hasInputTarget) {
            return
        }

        const price = this.priceTarget.value

        if (price === "") {
            this.inputTarget.removeAttribute("max")
            return
        }

        this.inputTarget.max = price

        if (
            this.inputTarget.value &&
            Number(this.inputTarget.value) > Number(price)
        ) {
            this.inputTarget.value = price
        }
    }
}