Rails.application.routes.draw do
  # 最初の画面を translations#new にする
  root "translations#new"

  # リアルタイム翻訳用のAPI
  post "translation/realtime", to: "translations#realtime", as: :realtime_translation
end
