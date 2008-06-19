class UserCommand < ActiveRecord::Base
  include CommandHelper
  belongs_to :user
  belongs_to :command
  has_many :queries, :dependent => :destroy
  
  acts_as_taggable
  validates_presence_of :user_id, :keyword, :name, :url
  validates_presence_of :command_id, :message=>"couldn't be created. Our support team has been notified and should contact you promptly.",
    :unless=>Proc.new {|uc| uc.errors.size > 0}
  validates_uniqueness_of :keyword, :scope => :user_id
  validates_uniqueness_of :command_id, :scope=>:user_id, :message=>'is already created for this user.'
  validates_uniqueness_of :name, :scope=>:user_id
  attr_protected :user_id
  
  has_finder :used, :conditions => ["user_commands.queries_count > 0"]
  has_finder :unused, :conditions => ["user_commands.queries_count = 0"]
  has_finder :popular, :conditions => ["user_commands.queries_count > 50"]
  has_finder :public, :conditions=>'commands.public = 1', :include=>:command
  has_finder :publicly_queriable, :conditions => {:public_queries => true}
  has_finder :quicksearches, :conditions => ["commands.kind ='parametric' AND commands.bookmarklet=0"], :include=>:command
  has_finder :bookmarklets, :conditions => ["commands.bookmarklet=1"], :include=>:command
  has_finder :shortcuts, :conditions => ["commands.kind ='shortcut' AND commands.bookmarklet=0"], :include=>:command
  has_finder :non_bootstrap, :conditions=>["commands.id NOT IN (1,2,3,4,5,6,7,8)"], :include=>:command
  has_finder :search, lambda {|v| {:conditions=>["user_commands.keyword REGEXP ? OR user_commands.url REGEXP ?", v, v]} }
  has_finder :any
  
  #fields which are passed from creating user_command to command on create + updates
  COMMAND_FIELDS = %w{url http_post url_encode public}
  #fields which are passed from creating user_command to command on create
  COMMAND_CREATE_FIELDS = %w{name description origin keyword}
  COMMAND_ONLY_FIELDS = %w{public}
  
  def validate
    if self.keyword && COMMAND_STOPWORDS.include?(self.keyword.downcase)
      errors.add_to_base "Sorry, the keyword you've chosen (#{self.keyword}) is reserved by the system. Please use something else." 
    end
  end
  
  def after_validation
    self.keyword.downcase! if self.keyword
  end
  
  def initialize(*args)
    #p args[0]
    if args[0].is_a?(Hash)
      args[0].stringify_keys! #in case it's not an insensitive hash
      command_fields = COMMAND_FIELDS + COMMAND_CREATE_FIELDS
      command_hash = args[0].slice(*command_fields)
      args[0].except!(*COMMAND_ONLY_FIELDS)
    end
    super(*args)
    # p command_hash
    # p args[0]
    if self.command_id.nil? && self.command.nil?
      create_command_from_hash(command_hash) 
    else
      self.url = self.command.url
    end
    return self
  end
    
  def create_command_from_hash(command_hash)
    if command_hash
      #if desired command is public, look for existing command
      #nil in case public not specified
      if ['1', true, nil].include?(command_hash['public']) && (existing_command = Command.find_by_url_and_public(command_hash['url'], true))
        self.command = existing_command
      else
        begin
          self.command = Command.create({:user_id=>user_id, :name=>name}.update(command_hash))
        rescue
          logger.error "Command creation failed for user_command: #{self.inspect}\n #{$!}"
        end
      end
    end
  end
  
  def update_all_attributes(hash, current_user)
    disabled_fields = get_disabled_update_fields(current_user)
    hash.except!(*disabled_fields)
    if update_attributes(hash.except(*COMMAND_ONLY_FIELDS))
      if self.command_owned_by?(current_user)
        self.command.update_attributes(hash.slice(*COMMAND_FIELDS))
      end
      return true
    else
      return false
    end
  end
  
  def get_disabled_update_fields(current_user)
    disabled_fields = [:public, :url]
    disabled_fields.delete(:url) if self.command_owned_by?(current_user)
	  disabled_fields.delete(:public) if self.command_owned_by?(current_user) && self.command_editable?
	  disabled_fields
  end
  
  def to_param; keyword; end
  
  def update_query_counts
    self.update_attribute(:queries_count, queries.count)
  end

  def public; new_record? ? true : command.public; end
  delegate :public?, :private?, :parametric?, :bookmarklet?, :to=>:command
  def public_queries?; self.public && self.public_queries; end
  
  def command_url_changed?
    self.command.url != self.url
  end
  
  def update_url
    self.update_attribute(:url, self.command.url)
  end
  
  def command_editable?; command.users.size <= 1; end
  
  def owned_by?(possible_owner); self.user == possible_owner; end
  
  def command_owned_by?(possible_owner)
    self.command.user == possible_owner
  end
  
  def update_tags(tags)
    self.tag_list = tags.split(" ").join(", ")
    self.save
  end
  
  def tag_string
    self.tag_list.join(" ")
  end
  
end