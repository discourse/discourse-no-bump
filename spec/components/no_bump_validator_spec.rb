# frozen_string_literal: true

require "rails_helper"

RSpec.describe DiscourseNoBump::NoBumpValidator do
  let(:bumped_at) { 1.week.ago }

  let!(:user) { Fabricate(:user) }
  let!(:topic) { Fabricate(:topic, user: user, bumped_at: bumped_at) }
  let!(:post) { Fabricate(:post, user: user, topic: topic) }

  describe "when enabled" do
    before do
      SiteSetting.no_bump_enabled = true
      SiteSetting.no_bump_trust_level = 1
    end

    describe "replying" do
      it "doesn't allow users to bump their own topics" do
        expect(post).to be_present
        reply = Fabricate.build(:post, topic: post.topic, user: user)
        expect(reply).not_to be_valid
        expect(reply.errors.first.message).to eq(
          "Please wait for other users to participate before replying",
        )
      end

      it "honors a post skips_validation flag" do
        expect(post).to be_present
        reply = Fabricate.build(:post, topic: post.topic, user: user, skip_validation: true)
        expect(reply).to be_valid
      end

      it "is disabled on personal messages" do
        pm_topic = Fabricate(:private_message_topic, user: user)
        post = Fabricate(:post, user: user, topic: pm_topic)
        expect(post).to be_present

        reply = Fabricate.build(:post, topic: pm_topic, user: user)
        expect(reply).to be_valid
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

    describe "editing" do
      it "considers changing the raw content valid" do
        post.raw = "this is different text for the body"
        expect(post).to be_valid
      end

      it "doesn't bump when revising" do
        PostRevisor.new(post).revise!(
          user,
          { raw: "this is different text for the body" },
          force_new_version: true,
        )
        topic.reload
        expect(topic.bumped_at.to_i).to eq(bumped_at.to_i)
      end

      it "will bump when staff revises" do
        PostRevisor.new(post).revise!(
          Fabricate(:admin),
          { raw: "this is different text for the body" },
          force_new_version: true,
        )
        topic.reload
        expect(topic.bumped_at.to_i).not_to eq(bumped_at.to_i)
      end
    end
  end

  describe "when disabled" do
    before { SiteSetting.no_bump_enabled = false }

    it "allows users to bump their own topics" do
      expect(post).to be_present
      reply = Fabricate.build(:post, topic: post.topic, user: user)
      expect(reply).to be_valid
    end

    it "will bump on revision" do
      PostRevisor.new(post).revise!(
        user,
        { raw: "this is different text for the body" },
        force_new_version: true,
      )
      topic.reload
      expect(topic.bumped_at.to_i).not_to eq(bumped_at.to_i)
    end
  end
end
