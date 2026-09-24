class ProductImage < ApplicationRecord
  belongs_to :product

  has_one_attached :image

  acts_as_list scope: :product

  validate :image_attached


  private


  def image_attached
    errors.add(:image, "must be attached") unless image.attached?
  end
end