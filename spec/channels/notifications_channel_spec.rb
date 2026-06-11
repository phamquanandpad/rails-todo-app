require "rails_helper"

RSpec.describe NotificationsChannel, type: :channel do
  let(:user) { create(:user) }

  before { stub_connection current_user: user }

  it "subscribes and streams for the current user" do
    subscribe

    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_for(user)
  end

  it "transmits initial connected message with unread count" do
    create_list(:notification, 2, user: user)
    create(:notification, :read, user: user)

    subscribe

    expect(transmissions.last).to include("connected" => true, "unread" => 2)
  end
end
