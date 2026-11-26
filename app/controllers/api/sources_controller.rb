module Api
  class SourcesController < BaseController
    def index
      render_page(Source.all) { |source| Serializers.source(source) }
    end

    def show
      render json: Serializers.source(Source.find(params[:id]))
    end

    def create
      source = Source.new(params.permit(:name, :signing_secret, :verification))
      return render_errors(source) unless source.save

      # The plaintext token exists only now; it is stored as a digest.
      render json: Serializers.source(source).merge(token: source.token, ingest_path: "/in/#{source.token}"),
             status: :created
    end
  end
end
