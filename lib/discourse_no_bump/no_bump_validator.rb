# frozen_string_literal: true

module DiscourseNoBump
  class NoBumpValidator < ActiveModel::Validator
    # When creating a post, validates that a user cannot bump their own topic
    # unless they are staff or above a certain trust level.
    #
    # Post revisions are irrelevant, because they don't bump topics in core.
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
end
