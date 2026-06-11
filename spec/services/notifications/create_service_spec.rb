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
  end
end
