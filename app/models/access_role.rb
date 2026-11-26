# Maps a bearer token to a role. Tokens come from configuration; blank ones grant nothing.
module AccessRole
  module_function

  def for(token)
    return :admin if matches?(token, Rails.configuration.x.admin_token)

    :viewer if matches?(token, Rails.configuration.x.viewer_token)
  end

  def matches?(token, expected)
    expected.present? && token.present? && ActiveSupport::SecurityUtils.secure_compare(token, expected.to_s)
  end
end
