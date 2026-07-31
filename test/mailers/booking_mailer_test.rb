require "test_helper"

class BookingMailerTest < ActionMailer::TestCase
  test "appointment_reminder" do
    mail = BookingMailer.appointment_reminder
    assert_equal "Appointment reminder", mail.subject
    assert_equal [ "to@example.org" ], mail.to
    assert_equal [ "from@example.com" ], mail.from
    assert_match "Hi", mail.body.encoded
  end
end
