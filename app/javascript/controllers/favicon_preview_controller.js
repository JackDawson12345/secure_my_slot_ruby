import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [
        "input",
        "preview",
        "error",
        "buttonText",
        "clearButton"
    ]

    connect() {
        this.originalImage = this.previewTarget.getAttribute("src")
        this.originalButtonText = this.buttonTextTarget.textContent.trim()
    }


    preview() {
        const file = this.inputTarget.files[0]

        this.hideError()

        if (!file) {
            this.restoreOriginal()
            return
        }


        const allowedTypes = [
            "image/png",
            "image/jpeg",
            "image/webp",
            "image/x-icon"
        ]


        if (!allowedTypes.includes(file.type)) {
            this.showError("Please select a PNG, JPG, WebP or ICO image.")
            this.inputTarget.value = ""
            this.restoreOriginal()
            return
        }


        const maximumSize = 2 * 1024 * 1024


        if (file.size > maximumSize) {
            this.showError("The favicon must be smaller than 2 MB.")
            this.inputTarget.value = ""
            this.restoreOriginal()
            return
        }


        const reader = new FileReader()


        reader.onload = event => {

            this.previewTarget.src = event.target.result
            this.previewTarget.classList.remove("hidden")

            this.fileNameTarget.textContent = file.name

            this.clearButtonTarget.classList.remove("hidden")
            this.clearButtonTarget.classList.add("inline-flex")

            this.buttonTextTarget.textContent = "Choose another favicon"


        }


        reader.onerror = () => {
            this.showError("The selected favicon could not be previewed.")
            this.inputTarget.value = ""
            this.restoreOriginal()
        }


        reader.readAsDataURL(file)
    }


    clear() {
        this.inputTarget.value = ""
        this.hideError()
        this.restoreOriginal()
    }


    restoreOriginal() {


        this.clearButtonTarget.classList.add("hidden")
        this.clearButtonTarget.classList.remove("inline-flex")

        this.buttonTextTarget.textContent = this.originalButtonText


        if (this.originalImage) {

            this.previewTarget.src = this.originalImage
            this.previewTarget.classList.remove("hidden")

        } else {

            this.previewTarget.removeAttribute("src")
            this.previewTarget.classList.add("hidden")

        }
    }


    showError(message) {

        this.errorTarget.textContent = message
        this.errorTarget.classList.remove("hidden")

    }


    hideError() {

        this.errorTarget.textContent = ""
        this.errorTarget.classList.add("hidden")

    }
}