import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"


export default class extends Controller {

    static targets = ["preview"]


    connect() {

        Sortable.create(this.previewTarget, {
            animation: 150
        })

    }


    preview(event) {

        Array.from(event.target.files)
            .forEach(file => {

                const reader = new FileReader()


                reader.onload = (e) => {

                    const wrapper = document.createElement("div")

                    wrapper.className = "relative cursor-move"


                    wrapper.innerHTML = `

            <img src="${e.target.result}"
                 class="rounded-lg border border-slate-200 aspect-square object-cover">


            <button type="button"
                    class="absolute top-1 right-1 rounded-full bg-white px-2 text-red-600"
                    data-action="click->product-gallery-preview#remove">

              ×

            </button>

          `


                    this.previewTarget.appendChild(wrapper)

                }


                reader.readAsDataURL(file)

            })

    }


    remove(event) {

        event.preventDefault()

        event.target.closest(".relative").remove()

    }


}