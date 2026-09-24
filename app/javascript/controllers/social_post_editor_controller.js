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


        if (key === "customer_name") {

            const initial = this.previewTarget.querySelector(
                "[data-social-post-customer-initial]"
            )

            if (initial) {
                initial.textContent = field.value.charAt(0).toUpperCase()
            }

        }
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
            .querySelectorAll(`[data-social-post-style-background-opacity="${key}"]`)
            .forEach((element) => {
                element.style.backgroundColor = `${input.value}15`
            })

        this.previewTarget
            .querySelectorAll(`[data-social-post-style-fill="${key}"]`)
            .forEach((element) => {
                element.setAttribute("fill", input.value)
                element.style.fill = input.value
            })

        this.previewTarget
            .querySelectorAll(`[data-social-post-style-border="${key}"]`)
            .forEach((element) => {
                element.style.borderColor = input.value
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

    updateRating(event) {

        const rating = parseInt(event.currentTarget.value)

        const primaryColourInput = this.element.querySelector(
            '[data-social-post-style-key="primary_colour"]'
        )

        const primaryColour = primaryColourInput
            ? primaryColourInput.value
            : "#f59e0b"


        this.previewTarget
            .querySelectorAll("[data-social-post-star]")
            .forEach((star) => {

                const starNumber = parseInt(
                    star.dataset.socialPostStar
                )

                const path = star.querySelector("path")

                if (!path) return


                if (starNumber <= rating) {
                    path.setAttribute(
                        "fill",
                        primaryColour
                    )
                } else {
                    path.setAttribute(
                        "fill",
                        "#e2e8f0"
                    )
                }

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