module BusinessSitesHelper

  def render_agreement_content(content, agreement_status)
    return if content.blank?

    content
      .gsub(/\n*\s*{{sign\\?_agreement name="([^"]+)"}}\s*\n*/) do

      name = Regexp.last_match(1)

      if agreement_status.status == "signed"
        signed_signature_image(agreement_status, name)
      else
        signature_field(name)
      end

    end
      .html_safe
  end

  def render_signed_agreement_content(content, agreement_status)
    return if content.blank?

    content
      .gsub(/\n*\s*{{sign\\?_agreement name="([^"]+)"}}\s*\n*/) do

      signed_signature_image(
        agreement_status,
        Regexp.last_match(1)
      )

    end
      .html_safe
  end


  def signed_signature_image(agreement_status, name)

    signature = agreement_status.signatures.find do |file|
      file.filename.to_s == "#{name}.png"
    end

    return "" unless signature


    image_tag(
      "data:image/png;base64,#{Base64.strict_encode64(signature.download)}",
      class: "max-w-xs"
    )

  end


  def signature_field(name)
    <<~HTML.squish
      <div
        data-controller="signature"
        class="my-4 rounded-2xl border border-slate-200 bg-white p-4 shadow-sm"
      >
        <div class="overflow-hidden rounded-xl border border-slate-300 bg-slate-50">
          <canvas
            data-signature-target="canvas"
            class="block w-full touch-none"
          ></canvas>
        </div>

        <input
          type="hidden"
          name="signature_data[#{name}]"
          data-signature-target="input"
        >

        <button
          type="button"
          data-action="signature#clear"
          class="mt-3 rounded-xl bg-slate-100 px-4 py-2 text-sm font-bold text-slate-700"
        >
          Clear signature
        </button>

      </div>
    HTML
  end

end