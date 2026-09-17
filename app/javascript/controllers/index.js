import { application } from "controllers/application"

import OpeningHoursController from "controllers/opening_hours_controller"
import NestedFormController from "controllers/nested_form_controller"
import FiltersController from "controllers/filters_controller"
import LogoPreviewController from "controllers/logo_preview_controller"
import FaviconPreviewController from "controllers/favicon_preview_controller"
import DepositController from "controllers/deposit_controller"
import ImagePreviewController from "controllers/image_preview_controller"
import ColourGeneratorController from "controllers/colour_generator_controller"
import FormBuilderController from "controllers/form_builder_controller"
import BirthdayPreviewController from "controllers/birthday_preview_controller"
import SignatureController from "controllers/signature_controller"
import SignatureFormController from "controllers/signature_form_controller"

application.register("opening-hours", OpeningHoursController)
application.register("nested-form", NestedFormController)
application.register("filters", FiltersController)
application.register("logo-preview", LogoPreviewController)
application.register("favicon-preview", FaviconPreviewController)
application.register("deposit", DepositController)
application.register("image-preview", ImagePreviewController)
application.register("colour-generator", ColourGeneratorController)
application.register("form-builder", FormBuilderController)
application.register("birthday-preview", BirthdayPreviewController)
application.register("signature", SignatureController)
application.register("signature-form", SignatureFormController)