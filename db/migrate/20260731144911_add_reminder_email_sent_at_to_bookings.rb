class AddReminderEmailSentAtToBookings < ActiveRecord::Migration[8.0]
  def change
    add_column :bookings, :reminder_email_sent_at, :datetime
    add_column :bookings, :reminder_sms_sent_at, :datetime
  end
end
