import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

    static targets = [
        "tab",
        "panel"
    ]

    connect() {
        this.show("general")
    }


    switch(event) {
        this.show(event.currentTarget.dataset.tab)
    }


    show(tabName) {

        this.tabTargets.forEach(tab => {

            if (tab.dataset.tab === tabName) {

                tab.classList.add(
                    "text-indigo-600",
                    "border-indigo-600"
                )

                tab.classList.remove(
                    "text-slate-500",
                    "border-transparent"
                )

            } else {

                tab.classList.remove(
                    "text-indigo-600",
                    "border-indigo-600"
                )

                tab.classList.add(
                    "text-slate-500",
                    "border-transparent"
                )

            }

        })


        this.panelTargets.forEach(panel => {

            panel.classList.toggle(
                "hidden",
                panel.dataset.panel !== tabName
            )

        })

    }

}