import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

    static targets = [
        "checkbox",
        "stock"
    ]


    connect() {
        this.toggle()
    }


    toggle() {
        this.stockTarget.classList.toggle(
            "hidden",
            !this.checkboxTarget.checked
        )
    }

}