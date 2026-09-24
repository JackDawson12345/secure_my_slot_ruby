import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

    static targets = [
        "status",
        "visibility",
        "publish"
    ]


    toggle(event) {

        const section = event.currentTarget.dataset.section

        this[`${section}Target`].classList.toggle("hidden")

    }

}