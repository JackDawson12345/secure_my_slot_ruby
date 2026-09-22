import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

    static targets = [
        "platform",
        "tone",
        "button",
        "regenerateButton",
        "result",
        "counter",
        "hashtags",
        "hashtagButton",
        "copyButton"
    ]


    connect() {

        this.selectedPlatform = "facebook"
        this.selectedTone = "friendly"

    }


    selectPlatform(event) {

        this.selectedPlatform = event.currentTarget.dataset.platform


        this.platformTargets.forEach(button => {

            button.classList.remove(
                "border-2",
                "border-indigo-500",
                "bg-indigo-50",
                "text-indigo-700"
            )

            button.classList.add(
                "border",
                "border-slate-200",
                "bg-white",
                "text-slate-700"
            )

        })


        event.currentTarget.classList.remove(
            "border",
            "border-slate-200",
            "bg-white",
            "text-slate-700"
        )


        event.currentTarget.classList.add(
            "border-2",
            "border-indigo-500",
            "bg-indigo-50",
            "text-indigo-700"
        )

    }


    selectTone(event) {

        this.selectedTone = event.currentTarget.dataset.tone


        this.toneTargets.forEach(button => {

            button.classList.remove(
                "bg-indigo-600",
                "text-white"
            )

            button.classList.add(
                "border",
                "border-slate-200",
                "text-slate-600"
            )

        })


        event.currentTarget.classList.remove(
            "border",
            "border-slate-200",
            "text-slate-600"
        )


        event.currentTarget.classList.add(
            "bg-indigo-600",
            "text-white"
        )

    }


    generate() {

        this.buttonTarget.disabled = true

        this.resultTarget.textContent = "Generating caption..."


        fetch(this.element.dataset.socialCaptionUrl, {

            method: "POST",

            headers: {

                "X-CSRF-Token": document.querySelector("[name='csrf-token']").content,

                "Content-Type": "application/json",

                "Accept": "application/json"

            },


            body: JSON.stringify({

                platform: this.selectedPlatform,

                tone: this.selectedTone

            })

        })


            .then(response => response.json())


            .then(data => {

                this.resultTarget.textContent = data.caption

                this.updateCharacterCount()

                this.updateCopyButton()

            })


            .finally(() => {

                this.buttonTarget.disabled = false

            })

    }

    generateHashtags() {

        this.hashtagButtonTarget.disabled = true

        this.hashtagsTarget.textContent = "Generating hashtags..."


        fetch(this.element.dataset.socialHashtagUrl, {

            method: "POST",

            headers: {

                "X-CSRF-Token": document.querySelector("[name='csrf-token']").content,

                "Content-Type": "application/json",

                "Accept": "application/json"

            },


            body: JSON.stringify({

                platform: this.selectedPlatform

            })

        })


            .then(response => response.json())


            .then(data => {

                this.hashtagsTarget.textContent = data.hashtags

                this.updateCharacterCount()

                this.updateCopyButton()

            })


            .finally(() => {

                this.hashtagButtonTarget.disabled = false

            })

    }

    updateCharacterCount() {

        let total = 0


        if (this.hasResultTarget) {
            total += this.resultTarget.textContent.trim().length
        }


        if (this.hasHashtagsTarget) {
            total += this.hashtagsTarget.textContent.trim().length
        }


        if (this.hasCounterTarget) {

            this.counterTarget.textContent =
                `${total} characters`

        }

    }

    copy() {

        let content = []


        const caption = this.resultTarget.textContent.trim()

        const hashtags = this.hashtagsTarget.textContent.trim()


        if (
            caption &&
            !caption.includes("Click generate caption")
        ) {

            content.push(caption)

        }


        if (
            hashtags &&
            !hashtags.includes("Click generate to create")
        ) {

            content.push(hashtags)

        }


        if (!content.length) {
            return
        }


        navigator.clipboard.writeText(
            content.join("\n\n")
        )


        this.copyButtonTarget.textContent = "Copied!"


        setTimeout(() => {

            this.copyButtonTarget.innerHTML = `
          <i data-lucide="copy" class="h-3.5 w-3.5"></i>
          Copy Caption
        `

            lucide.createIcons()

        }, 2000)

    }

    updateCopyButton() {

        const caption =
            this.resultTarget.textContent.trim()


        const hashtags =
            this.hashtagsTarget.textContent.trim()


        const hasCaption =
            caption &&
            !caption.includes("Click generate caption")


        const hasHashtags =
            hashtags &&
            !hashtags.includes("Click generate to create")


        this.copyButtonTarget.disabled =
            !(hasCaption || hasHashtags)

    }

}