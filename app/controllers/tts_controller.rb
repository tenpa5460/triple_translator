# app/controllers/tts_controller.rb
class TtsController < ApplicationController
  require "net/http"
  require "uri"
  require "json"
  require "base64"

  def create
    text = params[:text].to_s
    lang = params[:lang].presence || "ja-JP"

    # 言語ごとに TTS の voice を決める
    voice =
      case lang
      when "ja-JP"
        { languageCode: "ja-JP", name: "ja-JP-Standard-A" }
      when "en-US"
        { languageCode: "en-US", name: "en-US-Standard-C" }
      when "ko-KR"
        { languageCode: "ko-KR", name: "ko-KR-Standard-C" }
      else
        { languageCode: lang, name: "" }
      end

    api_key = ENV["GOOGLE_TTS_API_KEY"] || ENV["GOOGLE_TRANSLATE_API_KEY"]
    if api_key.blank?
      render json: { error: "TTS API key not set" }, status: :internal_server_error
      return
    end

    uri = URI("https://texttospeech.googleapis.com/v1/text:synthesize?key=#{api_key}")

    request_body = {
      input:  { text: text },
      voice:  voice,
      audioConfig: { audioEncoding: "MP3" }
    }

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    req = Net::HTTP::Post.new(
      uri.request_uri,
      { "Content-Type" => "application/json" }
    )
    req.body = request_body.to_json

    res = http.request(req)

    unless res.is_a?(Net::HTTPSuccess)
      Rails.logger.error("TTS API error #{res.code}: #{res.body}")
      render json: { error: "TTS API error" }, status: :bad_gateway
      return
    end

    json = JSON.parse(res.body)
    audio_content = json["audioContent"]

    if audio_content.blank?
      Rails.logger.error("No audioContent in TTS response: #{json.inspect}")
      render json: { error: "No audioContent" }, status: :bad_gateway
      return
    end

    audio_binary = Base64.decode64(audio_content)

    # MP3 をそのまま返す
    send_data audio_binary,
              type: "audio/mpeg",
              disposition: "inline"
  end
end
