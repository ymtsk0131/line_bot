class WebhookController < ApplicationController
  skip_before_action :verify_authenticity_token

  CHANNEL = '#linebot'

  def callback
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless line_client.validate_signature(body, signature)
      error 400, 'Bad Request'
    end

    events = line_client.parse_events_from(body)
    events.each do |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          post_message(event.message['text'])
        when Line::Bot::Event::MessageType::Image
          post_message('写真が送信されました。')
        when Line::Bot::Event::MessageType::Video
          post_message('ビデオが送信されました。')
        when Line::Bot::Event::MessageType::Sticker
          post_message('スタンプが送信されました。')
        end
      end
    end

    head :ok
  end

  private

  def post_message(text)
    slack_client.chat_postMessage(channel: CHANNEL, text: text)
  end
end