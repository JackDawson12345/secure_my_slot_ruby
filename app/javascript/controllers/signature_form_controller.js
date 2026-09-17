import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  submit(event) {

    document.querySelectorAll(
        '[data-controller="signature"]'
    ).forEach((element) => {

      const controller =
          this.application.getControllerForElementAndIdentifier(
              element,
              "signature"
          )

      controller.save()

    })

  }

}