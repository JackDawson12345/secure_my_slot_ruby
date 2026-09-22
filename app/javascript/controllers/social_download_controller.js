import { Controller } from "@hotwired/stimulus"
import { toPng } from "html-to-image"


export default class extends Controller {

    static targets = [
        "post",
        "button"
    ]


    async download() {

        this.buttonTargets.forEach(button => {
            button.disabled = true
        })


        try {

            const original = this.postTarget


            const clone = document.createElement("div")

            clone.innerHTML = original.innerHTML


            clone.style.position = "fixed"
            clone.style.left = "0"
            clone.style.top = "0"
            clone.style.width = "1080px"
            clone.style.height = "1080px"
            clone.style.display = "block"
            clone.style.overflow = "hidden"
            clone.style.zIndex = "-50"
            clone.style.containerType = "inline-size"


            document.body.appendChild(clone)


            await new Promise(resolve =>
                setTimeout(resolve, 500)
            )

            clone.querySelectorAll("img").forEach(img => {

                if (!img.src) {
                    img.remove()
                }

            })


            const dataUrl = await toPng(
                clone,
                {
                    width: 1080,
                    height: 1080,
                    pixelRatio: 1,
                    cacheBust: true,
                    backgroundColor: "#ffffff",
                    skipFonts: false
                }
            )


            const link = document.createElement("a")

            link.download = "social-post.png"
            link.href = dataUrl

            document.body.appendChild(link)

            link.click()

            document.body.removeChild(link)


            clone.remove()


        } finally {

            this.buttonTargets.forEach(button => {
                button.disabled = false
            })

        }

    }

}