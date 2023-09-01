class GamesController < ApplicationController
  def new
    @game = Game.new
    @topics = Topic.all
    @users = User.all
  end

  def create
    @game = Game.create(game_params)
    topics_string = " "

    params[:game][:topics].each do |topic|
      unless topic == ""
        @game_topic = GameTopic.create(game_id: @game.id, topic_id: topic) unless topic == ""
        topics_string = topics_string + @game_topic.topic.name + " "
      end
    end

    GameParticipation.create(game_id: @game.id, user_id: current_user.id)
    service = OpenaiService.new(build_prompt(topics_string))
    @response = service.call
    @data = JSON.parse(@response)
    @data["questions"].each do |question|
      @question = Question.new(content:question["question"], answer: question["right_answer"])
      @question.game = @game
      @question.save
    end

    redirect_to game_path(@game)
  end

  def show
    @game = Game.find(params[:id])
    @guess = Guess.new
    @question = @game.questions.find do |q|
      q.guesses.all? { |guess| !guess.correct }
    end
  end

  def answer
    @game = Game.find(params[:id])
    # Improvement for multiuser
    @guess = Guess.last
    @question = @guess.question
    @hint = Hint.last
  end

  private

  def build_prompt(topics_string)
    "Generate a JSON with #{@game.number_of_questions}
      questions, they should not be multiple choice questions.
      The questions should include questions with both open ended answers and precise answers.
      Include a key for the 'topics' #{topics_string},
      you can also mix different topics in a single question.
      Include a key for 'difficulty',
      on a scale from 1 to 10, 1 being suited for children aged 7, 10 being suited for adult experts in the topic,
      the difficulty of the questions you generate should be #{@game.difficulty} out of 10.
      Include a key for the 'right_answer'.
      Include a key for the 'hint'."
  end

  def game_params
    params.require(:game).permit(:topics, :difficulty, :number_of_questions)
  end
end
