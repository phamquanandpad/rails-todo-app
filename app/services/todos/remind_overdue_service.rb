module Todos
  class RemindOverdueService < BaseService
    BATCH_SIZE = 200

    def initialize(today = Date.current)
      @today = today
    end

    def call
      reminded = 0
      Todo.active
          .where.not(status: Todo.statuses[:completed])
          .where(estimate_end_at: ..@today)
          .includes(:user)
          .in_batches(of: BATCH_SIZE) do |batch|
        batch.each do |todo|
          Notifications::CreateService.call(
            user:  todo.user,
            title: reminder_title(todo),
            body:  reminder_body(todo),
            link:  "/todos/#{todo.id}"
          )
          reminded += 1
        end
      end
      success(data: { reminded: reminded })
    end

    private

    def reminder_title(todo)
      todo.estimate_end_at < @today ? "Todo overdue" : "Todo due today"
    end

    def reminder_body(todo)
      days = (@today - todo.estimate_end_at).to_i
      suffix = days.positive? ? "(#{days} day#{'s' if days != 1} overdue)" : "(due today)"
      %("#{todo.task}" #{suffix})
    end
  end
end
