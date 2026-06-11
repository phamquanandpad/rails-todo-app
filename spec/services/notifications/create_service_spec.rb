require "rails_helper"

RSpec.describe Notifications::CreateService, type: :model do
  let(:user) { create(:user) }

  describe "#call" do
    context "with valid params" do
      it "creates a notification record" do
        expect {
          Notifications::CreateService.call(user: user, title: "Hello", body: "World", link: "/todos/1")
        }.to change { user.notifications.count }.by(1)
      end

      it "returns success with the notification" do
        result = Notifications::CreateService.call(user: user, title: "Hello")

        expect(result).to be_success
        expect(result.data[:notification]).to be_a(Notification)
        expect(result.data[:notification].title).to eq("Hello")
      end

      it "broadcasts the notification over Action Cable" do
        expect(NotificationsChannel).to receive(:broadcast_to).once
        Notifications::CreateService.call(user: user, title: "Hello")
      end

      it "enqueues a NotificationMailer.notify job by default" do
        expect {
          Notifications::CreateService.call(user: user, title: "Hello")
        }.to have_enqueued_mail(NotificationMailer, :notify).on_queue("mailers")
      end

      it "skips the email when send_email: false" do
        expect {
          Notifications::CreateService.call(user: user, title: "Hello", send_email: false)
        }.not_to have_enqueued_mail(NotificationMailer, :notify)
      end
    end

    context "with invalid params" do
      it "fails when title is blank" do
        result = Notifications::CreateService.call(user: user, title: "")

        expect(result).to be_failure
        expect(result.errors).to include("Title can't be blank")
      end

      it "does not broadcast on failure" do
        expect(NotificationsChannel).not_to receive(:broadcast_to)
        Notifications::CreateService.call(user: user, title: "")
      end
    end

    context "when broadcast and mailer both raise" do
      it "still creates the notification row and returns success" do
        allow(NotificationsChannel).to receive(:broadcast_to).and_raise("boom")
        allow(NotificationMailer).to receive(:notify).and_raise("boom")

        result = Notifications::CreateService.call(user: user, title: "Hello")

        expect(result).to be_success
        expect(user.notifications.count).to eq(1)
      end
    end
  end
end
