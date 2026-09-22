class BusinessPortal::SocialMediaController < BusinessPortal::BaseController
  def index
    @social_posts = current_user.business.social_posts
  end

  def new
    @social_post_templates = SocialPostTemplate
                               .where(status: "active")
                               .order(:name)

    if params[:template_id].present?
      @social_post_template = SocialPostTemplate
                                .where(status: "active")
                                .find(params[:template_id])

      @social_post = current_user.business.social_posts.new(
        social_post_template: @social_post_template,
        content: default_content_for(@social_post_template),
        settings: @social_post_template.settings.deep_dup
      )
    end
  end

  def create

    @social_post = current_user.business.social_posts.new(
      social_post_params
    )

    @social_post.status = "draft"

    if @social_post.save
      redirect_to business_show_social_media_post_path(@social_post)
    else
      @social_post_template = @social_post.social_post_template
      @social_post_templates = SocialPostTemplate
                                 .where(status: "active")
                                 .order(:name)

      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @social_post = current_user.business.social_posts.find(params[:id])

    @social_post_template = @social_post.social_post_template
  end

  def update

    @social_post = current_user.business.social_posts.find(params[:id])


    if @social_post.update(social_post_params)

      redirect_to business_show_social_media_post_path(@social_post)

    else

      @template = @social_post.social_post_template

      render :edit, status: :unprocessable_entity

    end

  end

  def show
    @social_post = current_user.business.social_posts.find(params[:id])

  end

  def generate_caption

    @social_post = current_user.business.social_posts.find(params[:id])


    caption = OpenAiCaptionGenerator.new(
      @social_post,
      platform: params[:platform],
      tone: params[:tone]
    ).call


    @social_post.update!(
      caption: caption
    )


    render json: {
      caption: caption,
      characters: caption.length
    }

  end

  def generate_hashtags

    @social_post = current_user.business.social_posts.find(params[:id])


    hashtags = OpenAiHashtagGenerator.new(
      @social_post,
      platform: params[:platform]
    ).call


    render json: {
      hashtags: hashtags
    }

  end

  def duplicate
    original = current_user.business.social_posts.find(params[:id])

    duplicate = original.dup

    duplicate.status = "draft"
    duplicate.created_at = nil
    duplicate.updated_at = nil

    if duplicate.save
      redirect_to business_edit_social_media_post_path(duplicate)
    else
      redirect_to business_social_media_path, alert: "Unable to duplicate post."
    end
  end


  private

  def social_post_params
    params.require(:social_post).permit(
      :social_post_template_id,
      :image,
      :logo,
      content: {},
      settings: {}
    )
  end

  def default_content_for(template)
    template.fields.each_with_object({}) do |(key, field), content|
      content[key] = field["default"]
    end
  end
end
