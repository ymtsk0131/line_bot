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
        post_message("<From: #{sender_name(event)}>\n#{message_text(event)}")
      end
    end

    head :ok
  end

  private

  def post_message(text)
    slack_client.chat_postMessage(channel: CHANNEL, text: text)
  end

  def sender_name(event)
    res = line_client.get_profile(event['source']['userId'])
    user_profile = JSON.parse(res.body)
    user_profile['displayName']
  end

  def message_text(event)
    case event.type
    when Line::Bot::Event::MessageType::Text
      event.message['text']      
    when Line::Bot::Event::MessageType::Image
      '写真が送信されました。'
    when Line::Bot::Event::MessageType::Video
      'ビデオが送信されました。'
    when Line::Bot::Event::MessageType::Sticker
      'スタンプが送信されました。'
    end  
  end
end