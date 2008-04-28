require File.dirname(__FILE__) + '/../spec_helper'

def setup_users_controller_example_group
  controller_name :users
  integrate_views
end

describe 'user actions' do
  setup_users_controller_example_group
  
  it 'new' do
    get :new
    response.should be_success
  end
  
  it 'index'
  it 'opensearch'
end

describe 'users/show:' do
  setup_users_controller_example_group
  before(:all) { 
    @command = create_command(:kind=>'parametric')
    @command.tags << create_tag
    
    #setup @users
    @active_user = create_user
    @active_user.activate
    
    create_query(:command=>@command)
    create_query(:command=>create_command(:user=>@command.user, :kind=>'shortcut'))
    create_query(:command=>create_command(:user=>@command.user, :bookmarklet=>true))    
  }
  
  def basic_expectations
    response.should be_success
    assigns[:user].should be_an_instance_of(User)
    assigns[:tags][0].should be_an_instance_of(Tag)
    assigns[:users][0].should be_an_instance_of(User)
  end
  
  it "displays a simple user's homepage" do
    User.should_receive(:find_top_users).and_return([@active_user])
    get :show, :login=>@command.user.login
    basic_expectations
    assigns[:commands][0].should be_an_instance_of(Command)
  end
  
  it "displays advanced user's homepage to advanced user" do
    mock_user = @command.user
    mock_user.queries.should_receive(:count).and_return(101)
    login_user mock_user
    User.should_receive(:find_top_users).and_return([@active_user])
    
    get :show, :login=>@command.user.login
    basic_expectations
    assigns[:quicksearches][0].should be_an_instance_of(Command)
    assigns[:shortcuts][0].should be_an_instance_of(Command)
    assigns[:bookmarklets][0].should be_an_instance_of(Command)
  end
  
  it "displays advanced user's homepage to another user" do
    mock_user = @command.user
    mock_user.queries.should_receive(:count).and_return(101)
    User.should_receive(:find_by_login).and_return(mock_user)
    login_user
    User.should_receive(:find_top_users).and_return([@active_user])
    
    get :show, :login=>@command.user.login
    basic_expectations
    assigns[:quicksearches][0].should be_an_instance_of(Command)
    assigns[:shortcuts][0].should be_an_instance_of(Command)
    assigns[:bookmarklets][0].should be_an_instance_of(Command)
  end
  
  it 'redirects when no user specified' do
    get :show
    response.should be_redirect
    flash[:warning].should_not be_blank
  end
  
  it 'displays bad command'
  it 'displays private command'
  it 'displays illegal command'
end

describe 'users/create:' do
  setup_users_controller_example_group
  
  it 'creates a user' do
    lambda {
      lambda { post :create, :user=>random_valid_user_attributes }.should change(User, :count).by(1)
    }.should change(Command, :count).by_at_least(8)
    response.should be_redirect
    flash[:notice].should_not be_blank
  end
  
  it 'redisplays invalid submission' do
    invalid_attributes = random_valid_user_attributes
    invalid_attributes.delete(:login)
    lambda {post :create, :user=>invalid_attributes}.should_not change(User,:count)
    response.should be_success
    response.should render_template('new')
    assigns[:user].should be_an_instance_of(User)
  end
end

describe 'users/edit:' do
  setup_users_controller_example_group
  
  it 'displays page' do
    login_user
    get :edit
    response.should be_success
    assigns[:user].should be_an_instance_of(User)
  end
  
  it 'displays page when settings page is requested'
end

describe 'users/update:' do
  setup_users_controller_example_group
  
  it 'updates user including use default command boolean' do
    login_user :default_command_id=>1
    current_user.default_command_id.should_not be_nil
    put :update, :user=>{:login=>'cool'}, :use_default_command=>'no'
    response.should be_redirect
    flash[:notice].should_not be_blank
    current_user.reload
    current_user.login.should == 'cool'
    current_user.default_command_id.should be_nil
  end
  
  it 'redisplays invalid submission' do
    user = create_user
    user.stub!(:update_attributes).and_return(false)
    login_user user
    put :update, :user=>{:login=>'cool'}
    response.should be_success
    response.should render_template('edit')
    assigns[:user].should be_an_instance_of(User)
    current_user.reload.login.should_not == 'cool'
  end
end

describe 'users/activate:' do
  setup_users_controller_example_group
  
  before(:each) { @user = create_user; @user.send(:make_activation_code); @user.save}
  
  it 'activates user and redirects' do
    get :activate, :activation_code=>@user.activation_code
    response.should redirect_to(settings_path)
    flash[:notice].should_not be_blank
    @user.reload.should be_activated
  end
  
  it 'silently redirects invalid activation' do
    get :activate, :activation_code=>'XXXXXXX'
    response.should redirect_to(settings_path)
    flash[:notice].should be_blank
    @user.reload.should_not be_activated
  end
end

describe 'users/destroy:' do
  setup_users_controller_example_group
  before(:each) {@user = login_user; create_command(:user=>@user)}
  
  it 'deletes user and their commands' do
    lambda {
    lambda {
      delete :destroy
    }.should change(User, :count).by(-1)
    }.should change(Command, :count).by(-1)
    response.should be_redirect
    flash[:notice].should_not be_blank
  end
end