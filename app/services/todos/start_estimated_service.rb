module Todos
  class StartEstimatedService < BaseService
    BATCH_SIZE = 200

    def initialize(today = Date.current)
      @today = today
    end

    def call
      started = 0
      Todo.active
          .pending
          .where(estimate_start_at: @today)
          .includes(:user)
          .in_batches(of: BATCH_SIZE) do |batch|
        batch.each do |todo|
          ActiveRecord::Base.transaction do
            todo.update!(status: :in_progress)
            Notifications::CreateService.call(
              user:  todo.user,
              title: "Todo started today",
              body:  %("#{todo.task}" is now in progress.),
              link:  "/todos/#{todo.id}"
            )
          end
          started += 1
        end
      end
      success(data: { started: started })
    end
  end
end
