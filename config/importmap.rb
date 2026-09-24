# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "signature_pad" # @5.1.4
pin "html-to-image" # @1.11.13
pin "trix"
pin "@rails/actiontext", to: "actiontext.esm.js"
pin "sortablejs" # @1.15.7
