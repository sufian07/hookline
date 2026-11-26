# Per-minute request limits. Hookline runs as one process per deployment, so an
# in-memory counter is enough; a multi-instance setup would need a shared store.
module RateLimits
  INGEST_PER_MINUTE = Integer(ENV.fetch("HOOKLINE_INGEST_PER_MINUTE", 120))
  API_PER_MINUTE = Integer(ENV.fetch("HOOKLINE_API_PER_MINUTE", 300))

  module_function

  def store
    @store ||= ActiveSupport::Cache::MemoryStore.new
  end

  # Keys are hashed so tokens never sit in memory as cache keys.
  def key_for(value)
    OpenSSL::Digest::SHA256.hexdigest(value.to_s)
  end
end
