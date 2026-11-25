class IngestController < ApplicationController
  MAX_BODY_BYTES = 256.kilobytes

  # The raw body is what was signed, so parsed params are never used here.
  wrap_parameters false

  def create
    return head :content_too_large if request.content_length.to_i > MAX_BODY_BYTES

    source = Source.find_by_token(request.path_parameters[:token])
    return head :not_found unless source

    body = request.raw_post.dup.force_encoding(Encoding::UTF_8)
    return head :content_too_large if body.bytesize > MAX_BODY_BYTES
    return head :unauthorized unless authentic?(source, body)

    respond_to_result EventReceiver.new(source).call(
      event_type: request.headers["X-Hookline-Event"],
      idempotency_key: request.headers["X-Hookline-Idempotency-Key"],
      payload: body
    )
  end

  private

  def authentic?(source, body)
    WebhookSignature.valid?(
      secret: source.signing_secret,
      timestamp: request.headers["X-Hookline-Timestamp"],
      signature: request.headers["X-Hookline-Signature"],
      body:,
      now: Time.current
    )
  end

  def respond_to_result(result)
    case result.status
    when :created, :duplicate
      render json: { id: result.event.id, duplicate: result.status == :duplicate }, status: :accepted
    when :conflict
      render json: { error: "idempotency key already used with different content" }, status: :conflict
    when :invalid
      render json: { errors: result.event.errors.full_messages }, status: :unprocessable_content
    end
  end
end
