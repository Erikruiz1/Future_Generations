class UsersController < ApplicationController

  def show
    @display_states_completed = []
    @display_states_open = []
    @correct_questions_completed = []
    @correct_questions_open = []

    @games = current_user.games
    @completed_games = @games.order(:id).select do |game|
      game.completed == true
    end
    @open_games = @games.order(:id).select do |game|
      game.completed != true
    end

    @completed_games.each do |g|
      @display_states_completed.push(progress_bar(g))
      @correct_questions_completed.push(summary(g))
    end
    @open_games.each do |g|
      @display_states_open.push(progress_bar(g))
      @correct_questions_open.push(summary(g))
    end
  end

  def summary(game)
    questions = game.questions
    correct_questions = 0
    questions.each do |question|
      question.guesses.each do |guess|
        if guess.correct == true
          correct_questions += 1
        end
      end
    end
    correct_questions
  end

  private

  def progress_bar(game)
    display_states = []
    game.questions.order(:id).each do |q|
      unless q.guesses.empty?
        q.guesses.last.correct == true ? display_states.push("correct") : display_states.push("incorrect")
      else
        display_states.push("empty")
      end
    end
    display_states
  end

end
