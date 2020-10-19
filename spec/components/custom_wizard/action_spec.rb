require 'rails_helper'

describe CustomWizard::Action do
  fab!(:user) { Fabricate(:user, name: "Angus", username: 'angus', email: "angus@email.com", trust_level: TrustLevel[2]) }
  fab!(:category) { Fabricate(:category, name: 'cat1', slug: 'cat-slug') }
  fab!(:group) { Fabricate(:group) }
  
  before do
    Group.refresh_automatic_group!(:trust_level_2)
    template = JSON.parse(File.open(
      "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/wizard.json"
    ).read)
    CustomWizard::Wizard.add_wizard(template)
    @wizard = CustomWizard::Wizard.create('super_mega_fun_wizard', user)
  end
  
  it 'creates a topic' do
    built_wizard = CustomWizard::Builder.new(@wizard.id, user).build
    updater = built_wizard.create_updater(built_wizard.steps[0].id,
      step_1_field_1: "Topic Title",
      step_1_field_2: "topic body"
    ).update
    updater2 = built_wizard.create_updater(built_wizard.steps[1].id, {}).update
    
    topic = Topic.where(title: "Topic Title")
    
    expect(topic.exists?).to eq(true)
    expect(Post.where(
      topic_id: topic.pluck(:id),
      raw: "topic body"
    ).exists?).to eq(true)
  end
  
  it 'sends a message' do
    User.create(username: 'angus1', email: "angus1@email.com")
    
    built_wizard = CustomWizard::Builder.new(@wizard.id, user).build
    built_wizard.create_updater(built_wizard.steps[0].id, {}).update
    built_wizard.create_updater(built_wizard.steps[1].id, {}).update
    
    topic = Topic.where(
      archetype: Archetype.private_message,
      title: "Message title"
    )
    
    post = Post.where(
      topic_id: topic.pluck(:id),
      raw: "I will interpolate some wizard fields"
    )
        
    expect(topic.exists?).to eq(true)
    expect(topic.first.topic_allowed_users.first.user.username).to eq('angus1')
    expect(post.exists?).to eq(true)
  end
  
  it 'updates a profile' do
    built_wizard = CustomWizard::Builder.new(@wizard.id, user).build
    upload = Upload.create!(
      url: '/images/image.png',
      original_filename: 'image.png',
      filesize: 100,
      user_id: -1,
    )
    steps = built_wizard.steps
    built_wizard.create_updater(steps[0].id, {}).update
    built_wizard.create_updater(steps[1].id,
      step_2_field_7: upload.as_json,
    ).update
    expect(user.profile_background_upload.id).to eq(upload.id)
  end
  
  it 'opens a composer' do
    built_wizard = CustomWizard::Builder.new(@wizard.id, user).build
    built_wizard.create_updater(built_wizard.steps[0].id, step_1_field_1: "Text input").update
    
    updater = built_wizard.create_updater(built_wizard.steps[1].id, {})
    updater.update
    
    submissions = PluginStore.get("super_mega_fun_wizard_submissions", user.id)
    category = Category.find_by(id: submissions.first['action_8'])
    
    expect(updater.result[:redirect_on_next]).to eq(
      "/new-topic?title=Title%20of%20the%20composer%20topic&body=I%20am%20interpolating%20some%20user%20fields%20Angus%20angus%20angus@email.com&category=#{category.slug}/#{category.id}&tags=tag1"
    )
  end
  
  it 'creates a category' do
    built_wizard = CustomWizard::Builder.new(@wizard.id, user).build
    built_wizard.create_updater(built_wizard.steps[0].id, step_1_field_1: "Text input").update
    built_wizard.create_updater(built_wizard.steps[1].id, {}).update
    submissions = PluginStore.get("super_mega_fun_wizard_submissions", user.id)    
    expect(Category.where(id: submissions.first['action_8']).exists?).to eq(true)
  end
  
  it 'creates a group' do
    built_wizard = CustomWizard::Builder.new(@wizard.id, user).build
    step_id = built_wizard.steps[0].id
    updater = built_wizard.create_updater(step_id, step_1_field_1: "Text input").update
    submissions = PluginStore.get("super_mega_fun_wizard_submissions", user.id)
    expect(Group.where(name: submissions.first['action_9']).exists?).to eq(true)
  end
  
  it 'adds a user to a group' do
    built_wizard = CustomWizard::Builder.new(@wizard.id, user).build
    step_id = built_wizard.steps[0].id
    updater = built_wizard.create_updater(step_id, step_1_field_1: "Text input").update
    submissions = PluginStore.get("super_mega_fun_wizard_submissions", user.id)
    group = Group.find_by(name: submissions.first['action_9'])
    expect(group.users.first.username).to eq('angus')
  end
  
  it 'watches categories' do
    built_wizard = CustomWizard::Builder.new(@wizard.id, user).build
    built_wizard.create_updater(built_wizard.steps[0].id, step_1_field_1: "Text input").update
    built_wizard.create_updater(built_wizard.steps[1].id, {}).update
    submissions = PluginStore.get("super_mega_fun_wizard_submissions", user.id)
    expect(CategoryUser.where(
      category_id: submissions.first['action_8'],
      user_id: user.id
    ).first.notification_level).to eq(2)
    expect(CategoryUser.where(
      category_id: category.id,
      user_id: user.id
    ).first.notification_level).to eq(0)
  end
  
  it 're-routes a user' do
    built_wizard = CustomWizard::Builder.new(@wizard.id, user).build
    updater = built_wizard.create_updater(built_wizard.steps.last.id, {})
    updater.update
    expect(updater.result[:redirect_on_complete]).to eq("https://google.com")
  end
end
