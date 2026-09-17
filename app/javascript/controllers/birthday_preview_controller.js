import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

    static targets = [
        "input",
        "preview"
    ]


    connect() {
        this.update()
    }


    update() {

        let message = this.inputTarget.value

        if (!message) {
            message = "Your birthday message will appear here..."
        }


        message = message.replace(
            "{{customer_name}}",
            "Sarah"
        )


        this.previewTarget.innerText = message

    }

}