import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["slider", "label"]

    connect() {
        console.log("filters controller connected", this.element)
        if (this.hasSliderTarget) {
            this.updateLabel()
        }
        this.refreshIcons()
    }

    updateLabel() {
        const steps = [5, 10, 25, 50, 100, "Unlimited"]
        const value = steps[Number(this.sliderTarget.value)]
        this.labelTarget.textContent = value === "Unlimited" ? "Unlimited" : `${value} mi`
    }

    submitOnChange() {
        this.updateLabel()
        this.element.requestSubmit()
    }

    refreshIcons() {
        console.log("refreshIcons called, window.lucide is:", window.lucide)
        if (window.lucide && typeof window.lucide.createIcons === "function") {
            window.lucide.createIcons()
        }
    }
}