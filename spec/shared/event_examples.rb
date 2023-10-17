# frozen_string_literal: true

shared_examples "common copies" do |handler, name|
  describe "resource_path" do
    it "is generated correctly" do
      expect(subject.resource_path)
        .to include("/authorizations/new?handler=#{handler}")
    end
  end

  describe "resource_url" do
    it "is generated correctly" do
      expect(subject.resource_url)
        .to include("#{resource.organization.host}/authorizations/new?handler=#{handler}")
    end
  end

  describe "resource_title" do
    it "is generated correctly" do
      expect(subject.resource_title)
        .to include(name.to_s)
    end
  end
end

shared_examples "success copies" do |name|
  describe "email_intro" do
    it "is generated correctly" do
      expect(subject.email_intro)
        .to eq("You have been granted the \"#{name}\" authorization.")
    end
  end

  describe "email_outro" do
    it "is generated correctly" do
      expect(subject.email_outro)
        .to eq("You can now perform all actions that require the \"#{name}\" authorization.")
    end
  end

  describe "notification_title" do
    it "is generated correctly" do
      expect(subject.notification_title)
        .to include("Successful authorization with the \"#{name}\" method")
    end
  end
end

shared_examples "invalid copies" do |name|
  describe "email_intro" do
    it "is generated correctly" do
      expect(subject.email_intro)
        .to eq("It has not been possible to grant you the \"#{name}\" authorization.")
    end
  end

  describe "email_outro" do
    it "is generated correctly" do
      expect(subject.email_outro)
        .to eq("Please, contact the support at your platform to check what has gone wrong.")
    end
  end

  describe "notification_title" do
    it "is generated correctly" do
      expect(subject.notification_title)
        .to include("Invalid authorization with the \"#{name}\" method")
    end
  end
end
