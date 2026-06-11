class StartEstimatedTodosJob < ApplicationJob
  queue_as :low

  def perform(today = Date.current)
    Todos::StartEstimatedService.new(today).call
  end
end
