require "rails_helper"

RSpec.describe NotificationMailer, type: :mailer do
  describe "#notify" do
    let(:user) { create(:user, email: "alice@example.com") }
    let(:notification) do
      create(:notification, user: user, title: "Hi", body: "ping", link: "/todos/1")
    end

    subject(:mail) { described_class.notify(notification) }

    it "is addressed to the user with the notification title as subject" do
      expect(mail.to).to eq([ user.email ])
      expect(mail.subject).to eq("Hi")
    end

    it "renders both html and text parts" do
      expect(mail.html_part.body.to_s).to include("ping")
      expect(mail.text_part.body.to_s).to include("ping")
    end

    it "includes the link in both parts" do
      expect(mail.html_part.body.to_s).to include("/todos/1")
      expect(mail.text_part.body.to_s).to include("/todos/1")
    end

    context "when notification has no body" do
      let(:notification) { create(:notification, user: user, title: "Quiet ping") }

      it "renders without a body paragraph" do
        expect(mail.html_part.body.to_s).not_to include("<p></p>")
      end
    end
  end
end
