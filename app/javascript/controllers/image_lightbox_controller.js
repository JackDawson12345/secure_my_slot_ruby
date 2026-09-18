import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

    static targets = [
        "modal",
        "image"
    ]


    open(event) {

        const url = event.currentTarget.dataset.imageLightboxUrlValue

        this.imageTarget.src = url

        this.modalTarget.classList.remove("hidden")
        this.modalTarget.classList.add("flex")

    }


    close() {

        this.modalTarget.classList.add("hidden")
        this.modalTarget.classList.remove("flex")

        this.imageTarget.src = ""

    }

}