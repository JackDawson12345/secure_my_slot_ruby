import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

    static targets = ["input"]


    increase() {

        this.inputTarget.value =
            parseInt(this.inputTarget.value || 0) + 1

        this.inputTarget.dispatchEvent(
            new Event("change")
        )

    }


    decrease() {

        let value =
            parseInt(this.inputTarget.value || 0)


        if (value > 1) {

            this.inputTarget.value = value - 1

            this.inputTarget.dispatchEvent(
                new Event("change")
            )

        }

    }


    update() {

        let value =
            parseInt(this.inputTarget.value)


        if (isNaN(value) || value < 1) {

            this.inputTarget.value = 1

        }

    }

}