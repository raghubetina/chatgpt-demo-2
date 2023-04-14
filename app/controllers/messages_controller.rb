class MessagesController < ApplicationController
  def create
    the_message = Message.new
    the_message.quiz_id = params.fetch("query_quiz_id")
    the_message.role = params.fetch("query_role")
    the_message.content = params.fetch("query_content")

    if the_message.valid?
      the_message.save

      the_quiz = Quiz.where({ :id => the_message.quiz_id }).at(0)

      client = OpenAI::Client.new(access_token: ENV.fetch("OPENAI_TOKEN"))

      api_messages_array = Array.new

      quiz_messages = Message.where({ :quiz_id => the_quiz.id }).order(:created_at)

      quiz_messages.each do |the_message|
        message_hash = { :role => the_message.role, :content => the_message.content }

        api_messages_array.push(message_hash)
      end

      response = client.chat(
        parameters: {
          model: ENV.fetch("OPENAI_MODEL"),
          messages: api_messages_array,
          temperature: 1.0,
        },
      )

      assistant_message = Message.new
      assistant_message.quiz_id = the_message.quiz_id
      assistant_message.role = "assistant"
      assistant_message.content = response.fetch("choices").at(0).fetch("message").fetch("content")
      assistant_message.save

      redirect_to("/quizzes/#{the_message.quiz_id}", { :notice => "Message created successfully." })
    else
      redirect_to("/quizzes/#{the_message.quiz_id}", { :alert => the_message.errors.full_messages.to_sentence })
    end
  end
end
