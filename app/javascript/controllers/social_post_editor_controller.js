import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["field", "preview", "counter"]

    update(event) {
        const field = event.currentTarget
        const key = field.dataset.socialPostEditorKey

        if (!key) return

        this.updateText(field, key)
        this.updateCounter(field, key)
    }


    updateText(field, key) {
        const elements = this.previewTarget.querySelectorAll(
            `[data-social-post-field="${key}"]`
        )

        elements.forEach((element) => {
            element.textContent = field.value
        })
    }


    updateCounter(field, key) {
        const counter = this.counterTargets.find(
            (element) => element.dataset.socialPostEditorKey === key
        )

        if (!counter) return

        if (field.maxLength > 0) {
            counter.textContent = `${field.value.length} / ${field.maxLength}`
        }
    }


    updateColour(event) {
        const input = event.currentTarget
        const key = input.dataset.socialPostStyleKey

        if (!key) return


        // Update hex input
        const textInput = this.element.querySelector(
            `[data-social-post-style-key="${key}"][type="text"]`
        )

        if (textInput) {
            textInput.value = input.value
        }


        this.previewTarget
            .querySelectorAll(`[data-social-post-style-background="${key}"]`)
            .forEach((element) => {
                element.style.backgroundColor = input.value
            })


        this.previewTarget
            .querySelectorAll(`[data-social-post-style-color="${key}"]`)
            .forEach((element) => {
                element.style.color = input.value
            })


        this.previewTarget
            .querySelectorAll(`[data-social-post-style-gradient="${key}"]`)
            .forEach((element) => {

                element.style.background = `
                linear-gradient(
                    to top,
                    ${input.value},
                    color-mix(in srgb, ${input.value}, transparent 80%),
                    transparent
                )
            `

            })
    }

    updateImage(event) {

        const input = event.currentTarget

        if (!input.files || !input.files[0]) {
            return
        }


        const reader = new FileReader()


        reader.onload = (event) => {

            const images = this.previewTarget.querySelectorAll(
                "[data-social-post-image]"
            )


            images.forEach((image) => {

                image.src = event.target.result
                image.classList.remove("hidden")

            })


            const placeholders = this.previewTarget.querySelectorAll(
                "[data-social-post-image-placeholder]"
            )


            placeholders.forEach((placeholder) => {

                placeholder.classList.add("hidden")

            })

        }


        reader.readAsDataURL(input.files[0])

    }

    updateLogo(event) {

        const input = event.currentTarget

        if (!input.files || !input.files[0]) {
            return
        }


        const reader = new FileReader()


        reader.onload = (event) => {

            const logos = this.previewTarget.querySelectorAll(
                "[data-social-post-logo]"
            )


            logos.forEach((logo) => {

                logo.src = event.target.result
                logo.classList.remove("hidden")

            })


            this.previewTarget
                .querySelectorAll("[data-social-post-logo-placeholder]")
                .forEach((placeholder) => {

                    placeholder.classList.add("hidden")

                })

        }


        reader.readAsDataURL(input.files[0])

    }

}