namespace :business_websites do
  desc "Create a BusinessWebsite for each business that does not have one"

  task create_missing: :environment do
    created_count = 0
    skipped_count = 0

    Business.find_each do |business|
      if business.business_website.present?
        skipped_count += 1
        next
      end

      business.create_business_website!(
        hero: {
          title: "",
          sentence: "",
          info_boxes: [
            {
              icon: "",
              title: ""
            },
            {
              icon: "",
              title: ""
            },
            {
              icon: "",
              title: ""
            }
          ]
        },
        services: {
          title: "",
          sentence: ""
        },
        about_us: {
          title: "",
          paragraph: "",
          icon_boxes: [
            {
              title: "",
              sentence: ""
            },
            {
              title: "",
              sentence: ""
            },
            {
              title: "",
              sentence: ""
            },
            {
              title: "",
              sentence: ""
            }
          ]
        },
        visit: {
          title: "",
          sentence: ""
        }
      )

      created_count += 1
      puts "Created BusinessWebsite for #{business.business_name}"
    rescue ActiveRecord::RecordInvalid => e
      puts "Failed for business ID #{business.id}: #{e.message}"
    end

    puts
    puts "Complete"
    puts "Created: #{created_count}"
    puts "Skipped: #{skipped_count}"
  end
end