class PermissionsQuery
  def initialize(scope)
    @scope = scope
  end

  def call(params = {})
    result = @scope.includes(:user_permissions)
    result = result.where("name LIKE ?", "#{sanitize_like(params[:q])}%") if params[:q].present?
    result.order(:name)
  end

  private

  def sanitize_like(value) = ActiveRecord::Base.sanitize_sql_like(value)
end
