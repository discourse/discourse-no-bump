# frozen_string_literal: true

# name: discourse-no-bump
# about: Prevents users from bumping topics.
# meta_topic_id: 78186
# version: 0.1
# authors: Robin Ward
# url: https://github.com/discourse/discourse-no-bump

enabled_site_setting :no_bump_enabled

after_initialize do
  class ::NoBumpValidator < ActiveModel::Validator
    def validate(record)
      return unless SiteSetting.no_bump_enabled?
      return if record.topic.private_message?
      return if record.topic.user_id != record.user_id
      return if record.user.staff? || record.user.trust_level > SiteSetting.no_bump_trust_level

      last_post_user_id =
        Post
          .with_deleted
          .where(topic_id: record.topic_id)
          .order("post_number desc")
          .limit(1)
          .pluck(:user_id)
          .first

      if last_post_user_id == record.user_id
        record.errors.add(:base, message: I18n.t("no_bump_error"))
      end
    end
  end

  add_to_class :post_revisor, :bypass_bump? do
    !@editor.staff?
  end

  class ::Post < ActiveRecord::Base
    validates_with NoBumpValidator, on: :create, unless: :skip_validation
  end
end
