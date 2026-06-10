class ApplicationController < ActionController::API
  include Pagy::Backend
  include ErrorHandling

  before_action :set_json_format
  before_action :authenticate_request!
  before_action :snakeize_params

  private

  def set_json_format
    request.format = :json
  end

  def authenticate_request!
    payload = Auth::JwtService.decode(bearer_token)
    raise ApplicationPolicy::Unauthorized unless payload

    @current_user = User.active.find_by(id: payload[:user_id])
    raise ApplicationPolicy::Unauthorized unless @current_user
  end

  def current_user
    @current_user
  end

  def bearer_token
    request.headers["Authorization"]&.split(" ")&.last
  end

  def authorize!(record)
    policy_class = "#{record.class.name}Policy".constantize
    policy = policy_class.new(current_user, record)
    policy.public_send("#{action_name}?")
  end

  # Recursively convert incoming param keys to snake_case so controllers
  # can always use snake_case regardless of whether the client sent camelCase.
  def snakeize_params
    request.parameters.deep_transform_keys!(&:underscore)
  end
end
