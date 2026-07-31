// app/javascript/controllers/index.js

import { application } from "controllers/application"

import OpeningHoursController from "controllers/opening_hours_controller"
import NestedFormController from "controllers/nested_form_controller"
import FiltersController from "controllers/filters_controller"

application.register("opening-hours", OpeningHoursController)
application.register("nested-form", NestedFormController)
application.register("filters", FiltersController)