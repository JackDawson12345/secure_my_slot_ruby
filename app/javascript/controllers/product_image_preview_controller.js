import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

    static targets = ["preview"]


    preview(event) {

        const file = event.target.files[0]

        if (!file) return


        const reader = new FileReader()


        reader.onload = (e) => {

            this.previewTarget.src = e.target.result

        }


        reader.readAsDataURL(file)

    }

}