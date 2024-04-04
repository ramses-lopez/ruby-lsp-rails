# typed: true
# frozen_string_literal: true

class ApplicationController < ActionController::Base
  def create
    redirect_to(users_path)
  end
end
