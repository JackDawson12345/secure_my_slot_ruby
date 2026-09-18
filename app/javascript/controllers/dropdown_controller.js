import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["menu", "icon"]

    toggle() {
        this.menuTarget.classList.toggle("hidden")
        this.iconTarget.classList.toggle("rotate-180")
    }
}