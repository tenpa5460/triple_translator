class TranslationsController < ApplicationController
  require "net/http"
  require "uri"
  require "json"

  def new
    # 画面表示だけ
  end

  # JSから呼ばれるリアルタイム翻訳API
  def realtime
    source_text = params[:text].to_s

    if source_text.blank?
      render json: { english: "", korean: "" }
      return
    end

    english = translate_with_deepl(source_text)
    korean  = translate_with_google(source_text)

    render json: { english: english, korean: korean }
  end

  private

  def translate_with_deepl(text)
    api_key = ENV["DEEPL_API_KEY"] # ← あとで環境変数に設定
    return "" if api_key.blank?

    uri = URI("https://api-free.deepl.com/v2/translate")
    req = Net::HTTP::Post.new(uri)
    req["Authorization"] = "DeepL-Auth-Key #{api_key}"
    req.set_form_data({
      "text" => text,
      "target_lang" => "EN",
      "source_lang" => "JA"
    })

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(req)
    end

    body = JSON.parse(res.body)
    body.dig("translations", 0, "text") || ""
  rescue => e
    Rails.logger.error("[DeepL error] #{e.class}: #{e.message}")
    ""
  end

  def translate_with_google(text)
    api_key = ENV["GOOGLE_TRANSLATE_API_KEY"] # ← あとで環境変数に設定
    return "" if api_key.blank?

    uri = URI("https://translation.googleapis.com/language/translate/v2")
    uri.query = URI.encode_www_form({
      key: api_key
    })

    headers = { "Content-Type" => "application/json" }
    body = {
      q: text,
      source: "ja",
      target: "ko",
      format: "text"
    }.to_json

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.post(uri.request_uri, body, headers)
    end

    body = JSON.parse(res.body)
    body.dig("data", "translations", 0, "translatedText") || ""
  rescue => e
    Rails.logger.error("[Google error] #{e.class}: #{e.message}")
    ""
  end
end
