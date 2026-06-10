RSpec.configure do |config|
  config.add_setting :committee_options
  config.committee_options = {
    schema_path: Rails.root.join('swagger/merged/v1.yaml').to_s,
    validate_success_only: true,
    query_hash_key: 'rack.request.query_hash',
    parse_response_by_content_type: false,
    old_assert_behavior: false,
    strict_reference_validation: true
  }
end
