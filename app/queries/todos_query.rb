class TodosQuery
  def initialize(scope)
    @scope = scope
  end

  def call(params = {})
    result = @scope
    result = result.where(status: params[:status]) if params[:status].present?
    result = apply_overdue(result) if ActiveModel::Type::Boolean.new.cast(params[:overdue])
    result.order(created_at: :desc, id: :desc)
  end

  private

  def apply_overdue(scope)
    scope.where.not(status: Todo.statuses[:completed])
         .where(estimate_end_at: ..Date.current)
  end
end
