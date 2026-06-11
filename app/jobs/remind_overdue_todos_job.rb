class RemindOverdueTodosJob < ApplicationJob
  queue_as :low

  def perform(today = Date.current)
    Todos::RemindOverdueService.new(today).call
  end
end
