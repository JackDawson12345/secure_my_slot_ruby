class OpenAiCaptionGenerator

  def initialize(social_post, platform:, tone:)

    @social_post = social_post
    @platform = platform
    @tone = tone

  end


  def call

    response = client.chat(
      parameters: {
        model: "gpt-5-mini",
        messages: [
          {
            role: "system",
            content: system_prompt
          },
          {
            role: "user",
            content: user_prompt
          }
        ]
      }
    )


    caption = response.dig(
      "choices",
      0,
      "message",
      "content"
    )


    "#{caption.strip}\n\nBook online: #{booking_link}"

  end


  private


  def booking_link

    "https://#{@social_post.business.page_address}.securemyslot.co.uk"

  end


  def client

    OpenAI::Client.new(
      access_token: Rails.application.credentials.openai[:api_key]
    )

  end


  def system_prompt

    <<~PROMPT
      You create social media captions for small businesses.

      Use UK English.
      Make captions engaging and natural.
      Write only the main caption text.

      Do not include hashtags.
      Do not include a hashtag section.
      Do not mention AI.

      Keep the caption suitable for the selected platform and tone.
    PROMPT

  end


  def user_prompt

    content = @social_post.content


    <<~PROMPT
      Create a #{@platform} caption.

      Tone:
      #{@tone}

      Business:
      #{content["business_name"]}

      Heading:
      #{content["heading"]}

      Description:
      #{content["description"]}

      Call to action:
      #{content["button_text"]}

      Important:
      Return only the caption.
      Do not include hashtags.
    PROMPT

  end

end