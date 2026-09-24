class Product < ApplicationRecord

  belongs_to :business

  has_one_attached :featured_image

  has_many :product_images,
           -> { order(position: :asc) },
           dependent: :destroy

  accepts_nested_attributes_for :product_images,
                                allow_destroy: true

  has_rich_text :description
  has_rich_text :short_description


  validates :name, presence: true


  def tabs
    product_tabs.to_s.split(",").map(&:strip)
  end


  def tabs=(value)
    self.product_tabs = value.to_s.split(",").map(&:strip).reject(&:blank?).join(",")
  end

end