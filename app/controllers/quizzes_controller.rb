class QuizzesController < ApplicationController
  def index
    matching_quizzes = Quiz.all

    @list_of_quizzes = matching_quizzes.order({ :created_at => :desc })

    render({ :template => "quizzes/index.html.erb" })
  end

  def show
    the_id = params.fetch("path_id")

    matching_quizzes = Quiz.where({ :id => the_id })

    @the_quiz = matching_quizzes.at(0)

    render({ :template => "quizzes/show.html.erb" })
  end

  def create
    the_quiz = Quiz.new
    the_quiz.topic = params.fetch("query_topic")

    if the_quiz.valid?
      the_quiz.save

      system_message = Message.new
      system_message.quiz_id = the_quiz.id
      system_message.role = "system"
      system_message.content = "You are a #{the_quiz.topic} tutor. Ask the user five questions to assess their #{the_quiz.topic} proficiency. Start with an easy question. After each answer, increase or decrease the difficulty of the next question based on how well the user answered.

      In the end, provide a score between 0 and 10."
      system_message.save

      user_message = Message.new
      user_message.quiz_id = the_quiz.id
      user_message.role = "user"
      user_message.content = "Can you assess my #{the_quiz.topic} proficiency?"
      user_message.save

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
        }
      )

      assistant_message = Message.new
      assistant_message.quiz_id = the_quiz.id
      assistant_message.role = "assistant"
      assistant_message.content = response.fetch("choices").at(0).fetch("message").fetch("content")
      assistant_message.save
      
      redirect_to("/quizzes/#{the_quiz.id}", { :notice => "Quiz created successfully." })
    else
      redirect_to("/quizzes", { :alert => the_quiz.errors.full_messages.to_sentence })
    end
  end
end
