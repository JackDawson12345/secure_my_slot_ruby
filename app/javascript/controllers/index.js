// app/javascript/controllers/index.js

import { application } from "controllers/application"

import OpeningHoursController from "controllers/opening_hours_controller"
import NestedFormController from "controllers/nested_form_controller"
import FiltersController from "controllers/filters_controller"
import LogoPreviewController from "controllers/logo_preview_controller"
import DepositController from "controllers/deposit_controller"
import ImagePreviewController from "controllers/image_preview_controller"

application.register("opening-hours", OpeningHoursController)
application.register("nested-form", NestedFormController)
application.register("filters", FiltersController)
application.register("logo-preview", LogoPreviewController)
application.register("deposit", DepositController)
application.register("image-preview", ImagePreviewController)