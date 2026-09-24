import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

    static targets = ["input"]


    increase() {

        this.inputTarget.value =
            parseInt(this.inputTarget.value || 1) + 1

    }


    decrease() {

        let value =
            parseInt(this.inputTarget.value || 1)


        if (value > 1) {

            this.inputTarget.value = value - 1

        }

    }


}