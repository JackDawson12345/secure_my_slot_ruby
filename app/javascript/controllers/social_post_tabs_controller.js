import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

    show(event) {

        const selectedTab = event.currentTarget.dataset.tab


        document
            .querySelectorAll("[data-social-post-tab]")
            .forEach((tab) => {

                if (tab.dataset.socialPostTab === selectedTab) {
                    tab.classList.remove("hidden")
                } else {
                    tab.classList.add("hidden")
                }

            })


        document
            .querySelectorAll(".social-tab")
            .forEach((button) => {

                button.classList.remove(
                    "border-indigo-600",
                    "text-indigo-600",
                    "font-semibold"
                )

                button.classList.add(
                    "border-transparent",
                    "text-slate-500",
                    "font-medium"
                )

            })


        event.currentTarget.classList.add(
            "border-indigo-600",
            "text-indigo-600",
            "font-semibold"
        )

        event.currentTarget.classList.remove(
            "border-transparent",
            "text-slate-500",
            "font-medium"
        )

    }

}