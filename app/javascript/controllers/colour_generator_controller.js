import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [
        "input",
        "picker",
        "shade900",
        "shade700",
        "shade500",
        "shade300",
        "previewLight",
        "previewDarkLine",
        "previewLightLine",
        "previewPrimary"
    ]

    syncPicker() {
        const value = this.inputTarget.value

        if (/^#[0-9A-F]{6}$/i.test(value)) {
            this.pickerTarget.value = value
        }
    }

    syncInput() {
        this.inputTarget.value = this.pickerTarget.value.toUpperCase()
    }

    generate() {
        const colour = this.inputTarget.value

        if (!/^#[0-9A-F]{6}$/i.test(colour)) {
            return
        }

        fetch("/business/dashboard/settings/website-settings/generate-colours", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
            },
            body: JSON.stringify({
                colour: colour
            })
        })
            .then(response => {
                if (!response.ok) {
                    throw new Error("Failed to generate colours")
                }

                return response.json()
            })
            .then(data => {
                this.updateColour("shade900", data["900"])
                this.updateColour("shade700", data["700"])
                this.updateColour("shade500", data["500"])
                this.updateColour("shade300", data["300"])

                this.updateColour("previewLight", data["300"])
                this.updateColour("previewDarkLine", data["900"])
                this.updateColour("previewLightLine", data["300"])
                this.updateColour("previewPrimary", data["500"])
            })
            .catch(error => {
                console.error("Colour generation error:", error)
            })
    }

    updateColour(target, value) {
        if (!value) return

        this[`${target}Target`].style.backgroundColor = value
    }
}