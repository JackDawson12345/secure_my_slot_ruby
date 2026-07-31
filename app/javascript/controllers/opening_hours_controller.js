// app/javascript/controllers/opening_hours_controller.js

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [
        "day",
        "toggle",
        "status",
        "fields",
        "closedMessage"
    ]

    connect() {
        this.toggleTargets.forEach((toggle) => {
            this.updateDay(toggle)
        })
    }

    toggleDay(event) {
        this.updateDay(event.currentTarget)
    }

    updateDay(toggle) {
        const day = toggle.closest('[data-opening-hours-target="day"]')

        if (!day) return

        const status = day.querySelector(
            '[data-opening-hours-target="status"]'
        )

        const fields = day.querySelector(
            '[data-opening-hours-target="fields"]'
        )

        const closedMessage = day.querySelector(
            '[data-opening-hours-target="closedMessage"]'
        )

        if (toggle.checked) {
            day.classList.remove("bg-slate-50")

            status.textContent = "Open"
            status.classList.remove("text-slate-500")
            status.classList.add("text-emerald-600")

            fields.classList.remove("hidden")
            closedMessage.classList.add("hidden")
        } else {
            day.classList.add("bg-slate-50")

            status.textContent = "Closed"
            status.classList.remove("text-emerald-600")
            status.classList.add("text-slate-500")

            fields.classList.add("hidden")
            closedMessage.classList.remove("hidden")
        }
    }
}