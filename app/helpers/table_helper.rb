module TableHelper
  
  def user_command_column_value(user_command, column)
    case column
    when :user
        user_link(user_command.user)
    when :name
      user_command_link(user_command)
    when :queries_count
      user_command.queries_count
    when :url_status
      url_status(user_command, :status_length=>25)
    when :command
      basic_command_link user_command.command
    when :keyword
      user_command.keyword
    when :command_actions
      command_actions(user_command)
    else
      ''
    end
  end
  
  def user_command_table(user_commands, options={})
    options = {:columns=>[:user, :name, :queries_count]}.merge(options)
    default_headers = {:user=>'User', :name=>'User Command', :queries_count=>'Queries'}
    options[:headers] ||= options[:columns].map {|c| default_headers[c] || c.to_s.humanize }
    active_record_table(user_commands, options)
  end
  
  def query_column_value(query, column)
    case column
    when :user
      query_user(query)
    when :query_string
      link_to_query query
    when :user_command
      user_command_link(query.user_command)
    when :created_at
	    time_ago_in_words_or_date query.created_at
	  end
  end
  
  def query_table(queries, options={})
    options.reverse_merge! :columns=>[:query_string, :created_at]
    default_headers = {:query_string=>'Query', :created_at=>'Date', :user=>'User', :user_command=>'User Command'}
    options[:headers] ||= options[:columns].map {|c| default_headers[c] || c.to_s.humanize }
    active_record_table(queries, options)
  end
  
  def active_record_table(ar_collection, options={})
    options[:table] ||= {}
    options[:headers] ||= options[:columns].map {|c| c.to_s.humanize }
    content_tag(:table, options[:table]) do
      headers = content_tag(:tr) do
        options[:headers].map {|e| content_tag(:th, *e)}.join("\n")
      end
      
      body = ar_collection.map do |uc|
        content_tag(:tr, :class=>cycle('offset', '')) do
          options[:columns].map do |c|
            content_tag(:td, send("#{ar_collection[0].class.to_s.underscore}_column_value", uc, c))
          end.join("\n")
        end
      end.join("\n")
      
      headers + "\n" + body
    end
  end
  
  def option_column_value(option, column)
    if column  == :others
      others = []
      case option.option_type
      when 'boolean'
        others << "True Value: #{h option.true_value}" unless option.true_value.blank?
      when 'enumerated'
        if option.values.blank?
          others << "No valid values"
        else
          others << truncate_with_more("Values: #{h option.values}",nil, :tag_type=>'span')
          others << truncate_with_more("Values with labels: #{h option.annotated_values}", nil,:tag_type=>'span') unless option.values_hash.blank? || option.annotated_values == option.values
        end
        others << [truncate_with_more("Note: #{h option.note}",nil,:tag_type=>'span'), {:style=>'padding-left: 20px; font-style: italic'}] unless option.note.blank?
        others << "Default: #{h option.default}" unless option.default.blank?
      else
        others << "Value: #{h option.value}" unless option.value.blank?
      end
      others << "Description: #{h option.description}" unless option.description.blank?
      content_tag(:ul, :style=>"list-style-type: disc; list-style-position: inside") do
        others.map {|e| 
          e.gsub!("\n",'') unless e.is_a?(Array) #otherwise the * will fail by dividing on '\n'
          content_tag(:li, *e)
        }
      end
    else
      option.send(column)
    end
  end
  
  def table_link_to(name, options={}, html_options={})
    html_options[:class] ||= 'faded'
    content_tag(:p, link_to(name, options, html_options))
  end
  
end