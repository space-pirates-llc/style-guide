schema = Rails.application.config.force_ssl ? "https" : "http"
host = Rails.application.config.action_controller.default_url_options[:host]
SitemapGenerator::Sitemap.default_host = "#{schema}://#{host}"

SitemapGenerator::Sitemap.create do
  # Add routes here
end
