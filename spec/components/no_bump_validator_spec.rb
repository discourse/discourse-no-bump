require 'rails_helper'

describe NoBumpValidator do

  let!(:user) { Fabricate(:user) }
  let!(:post) { Fabricate(:post, user: user) }

  describe "when enabled" do
    before do
      SiteSetting.no_bump_enabled = true
      SiteSetting.no_bump_trust_level = 1
    end

    it "doesn't allow users to bump their own topics" do
      expect(post).to be_present
      reply = Fabricate.build(:post, topic: post.topic, user: user)
      expect(reply).not_to be_valid
    end

    it "allows admin users to bump their own topics" do
      user.admin = true
      user.save

      expect(post).to be_present
      reply = Fabricate.build(:post, topic: post.topic, user: user)
      expect(reply).to be_valid
    end

    it "allows moderators to bump their own topics" do
      user.moderator = true
      user.save

      expect(post).to be_present
      reply = Fabricate.build(:post, topic: post.topic, user: user)
      expect(reply).to be_valid
    end

    it "allows higher trust level users to bump their own topics" do
      user.trust_level = 2
      user.save

      expect(post).to be_present
      reply = Fabricate.build(:post, topic: post.topic, user: user)
      expect(reply).to be_valid
    end

  end

  describe "when disabled" do
    before do
      SiteSetting.no_bump_enabled = false
    end

    it "allows users to bump their own topics" do
      expect(post).to be_present
      reply = Fabricate.build(:post, topic: post.topic, user: user)
      expect(reply).to be_valid
    end
  end

end
