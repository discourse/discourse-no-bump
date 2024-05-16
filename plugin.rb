# frozen_string_literal: true

# name: discourse-no-bump
# about: Prevents users from bumping topics.
# meta_topic_id: 78186
# version: 0.1
# authors: Robin Ward
# url: https://github.com/discourse/discourse-no-bump

enabled_site_setting :no_bump_enabled

after_initialize do
  require_relative "lib/discourse_no_bump/no_bump_validator"
  require_relative "lib/discourse_no_bump/post_extension"

  add_to_class :post_revisor, :bypass_bump? do
    !@editor.staff?
  end

  reloadable_patch { Post.prepend(DiscourseNoBump::PostExtension) }
end
