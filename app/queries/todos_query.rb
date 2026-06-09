class TodosQuery
  def initialize(scope)
    @scope = scope
  end

  def call(params = {})
    result = @scope
    result = result.where(status: params[:status]) if params[:status].present?
    result.order(created_at: :desc, id: :desc)
  end
end
