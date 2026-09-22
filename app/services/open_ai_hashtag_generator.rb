class OpenAiHashtagGenerator

  def initialize(social_post, platform:)
    @social_post = social_post
    @platform = platform
  end


  def call

    response = client.chat(
      parameters: {
        model: "gpt-5-mini",
        messages: [
          {
            role: "system",
            content: "Generate relevant social media hashtags for small businesses. Return hashtags only."
          },
          {
            role: "user",
            content: prompt
          }
        ]
      }
    )


    response.dig(
      "choices",
      0,
      "message",
      "content"
    )

  end


  private


  def prompt

    content = @social_post.content

    <<~PROMPT
      Create hashtags for #{@platform}.

      Business:
      #{content["business_name"]}

      Service:
      #{content["heading"]}

      Description:
      #{content["description"]}

      Return 8 to 12 relevant hashtags.
    PROMPT

  end


  def client

    OpenAI::Client.new(
      access_token: Rails.application.credentials.openai[:api_key]
    )

  end

end