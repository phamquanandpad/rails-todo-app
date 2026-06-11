require "rails_helper"

RSpec.describe RemindOverdueTodosJob, type: :job do
  it "is enqueued on the low queue" do
    expect(described_class.new.queue_name).to eq("low")
  end

  it "delegates to Todos::RemindOverdueService" do
    today = Date.current
    service = instance_double(Todos::RemindOverdueService, call: nil)
    allow(Todos::RemindOverdueService).to receive(:new).with(today).and_return(service)

    described_class.perform_now(today)

    expect(service).to have_received(:call)
  end
end
