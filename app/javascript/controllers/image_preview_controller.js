import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["input", "image", "placeholder"]

    show() {
        const file = this.inputTarget.files[0]

        if (!file) return

        const reader = new FileReader()

        reader.onload = event => {
            this.imageTarget.src = event.target.result
            this.imageTarget.classList.remove("hidden")

            if (this.hasPlaceholderTarget) {
                this.placeholderTarget.classList.add("hidden")
            }
        }

        reader.readAsDataURL(file)
    }
}