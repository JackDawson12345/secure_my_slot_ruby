import { Controller } from "@hotwired/stimulus"
import SignaturePad from "signature_pad"

export default class extends Controller {

  static targets = [
    "canvas",
    "input"
  ]


  connect() {

    this.signaturePad = new SignaturePad(this.canvasTarget)

    this.resizeCanvas()

  }


  resizeCanvas() {

    const ratio = Math.max(window.devicePixelRatio || 1, 1)

    this.canvasTarget.width =
        this.canvasTarget.offsetWidth * ratio

    this.canvasTarget.height =
        128 * ratio

    this.canvasTarget.style.height = "128px"

    this.canvasTarget
        .getContext("2d")
        .scale(ratio, ratio)

    this.signaturePad.clear()

  }


  clear() {

    this.signaturePad.clear()

  }


  save() {

    if (this.signaturePad.isEmpty()) {
      this.inputTarget.value = ""
      return
    }

    this.inputTarget.value =
        this.signaturePad.toDataURL("image/png")

  }

}