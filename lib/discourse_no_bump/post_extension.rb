# frozen_string_literal: true

module DiscourseNoBump
  module PostExtension
    extend ActiveSupport::Concern

    prepended { validates_with NoBumpValidator, on: :create, unless: :skip_validation }
  end
end
