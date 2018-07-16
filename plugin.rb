# name: discourse-jerome
# about: Secondary Groups
# version: 0.0.1
# authors: Test
after_initialize do
 
 
    NewPostManager.class_eval do
      def perform_create_post
        result = NewPostResult.new(:create_post)
        
        plugin_can_send_PM_J = false
        if @args[:archetype] == Archetype.private_message
           plugin_target_users_array_J =  @args[:target_usernames].split(",")
           plugin_target_users_array_J.each do |plugin_target_user_str_J|

            plugin_target_user_J = User.find_by(username: plugin_target_user_str_J)
            plugin_target_groups_J = GroupUser.select("*").where(user_id: plugin_target_user_J.id).joins(:group)
            plugin_target_groups_array_J = Array.new
            plugin_target_groups_J.each do |object|
                plugin_target_groups_array_J << object.name
             end
             
             
             
             if(self.user.custom_fields["secondary_group"].nil?)
                plugin_source_secondary_group_J =  Array.new
             else
                 plugin_source_secondary_group_J =  JSON.parse(self.user.custom_fields["secondary_group"])
             end 
             
             if(!((plugin_source_secondary_group_J & plugin_target_groups_array_J).empty? ))
                   plugin_can_send_PM_J = true
                  
              else
                 unless self.user['primary_group_id'].nil?
                      if(plugin_target_user_J['primary_group_id'] == self.user['primary_group_id'])
                          plugin_can_send_PM_J = true
                      else
                          plugin_can_send_PM_J = false
                      end
                    
                 end   
              end
              if(plugin_can_send_PM_J == false)
                break  
              end 
           end
           if plugin_can_send_PM_J
            creator = PostCreator.new(@user, @args)
            post = creator.create
            result.check_errors_from(creator)
        
            if result.success?
              result.post = post
            else
              @user.flag_linked_posts_as_spam if creator.spam?
            end  
           else
            result.errors[:base] <<'Unauthorized'
          end  

        
        else
            creator = PostCreator.new(@user, @args)
            post = creator.create
            result.check_errors_from(creator)
        
            if result.success?
              result.post = post
            else
              @user.flag_linked_posts_as_spam if creator.spam?
            end  
        end 
        
        result
      end            
    end
 
 
 
 
    UserSerializer.class_eval do
    
      def can_send_private_message_to_user
        plugin_can_send_PM_J = false
        if(scope.can_send_private_message?(object) && scope.current_user != object )
            plugin_target_groups_J = GroupUser.select("*").where(user_id: object.id).joins(:group)
            plugin_target_groups_array_J = Array.new
            plugin_target_groups_J.each do |object|
                plugin_target_groups_array_J << object.name
             end
            
            
            if(scope.current_user.custom_fields["secondary_group"].nil?)
              plugin_source_secondary_group_J =  Array.new
            else
               plugin_source_secondary_group_J =  JSON.parse(scope.current_user.custom_fields["secondary_group"])
            end              
            if(!((plugin_source_secondary_group_J & plugin_target_groups_array_J).empty? ))
                 plugin_can_send_PM_J = true
                
            else
               unless scope.current_user['primary_group_id'].nil?
                    if(object['primary_group_id'] == scope.current_user['primary_group_id'])
                        plugin_can_send_PM_J = true
                    else
                        plugin_can_send_PM_J = false
                    end
                  
                 end   
            end
              
        end
        plugin_can_send_PM_J
      end   
   end
   
   Search.class_eval do
      
     def user_search
      return if SiteSetting.hide_user_profiles_from_public && !@guardian.user
      plugin_user_J = User.find(@opts[:user_id])
      if(plugin_user_J.custom_fields["secondary_group"].nil?)
        plugin_secondary_group_J =  Array.new
      else
         plugin_secondary_group_J =  JSON.parse(plugin_user_J.custom_fields["secondary_group"])
      end
      plugin_where_query_array_J=Array.new;
      plugin_having_query_array_J = Array.new
      plugin_secondary_group_J.each do |plugin_temp_secondary_group_J|
        plugin_having_query_array_J <<  " '"+plugin_temp_secondary_group_J+"' = ANY (array_agg(groups.name)) "
      end
    
      unless plugin_user_J['primary_group_id'].nil?
         plugin_having_query_array_J << ' "users"."primary_group_id" = '+plugin_user_J['primary_group_id'].to_s
                
      end
    
      plugin_where_query_J =plugin_where_query_array_J.join("OR")
      plugin_having_query_J =plugin_having_query_array_J.join("OR")
      if(plugin_having_query_J == "")
        plugin_having_query_J = '1=2'
      end
      
      users = User.includes(:user_search_data)
        .references(:user_search_data)
        .joins(' FULL JOIN user_custom_fields ON "user_custom_fields"."user_id"="users"."id"')
        .joins(' INNER JOIN group_users ON "group_users"."user_id"="users"."id"')
        .joins(' INNER JOIN groups ON "group_users"."group_id"="groups"."id"')
        .where(active: true)
        .where(staged: false)
        .where("user_search_data.search_data @@ #{ts_query("simple")}")
        .order("CASE WHEN username_lower = '#{@original_term.downcase}' THEN 0 ELSE 1 END")
        .order("last_posted_at DESC")
        .group('"users"."id"')
        .group('"user_search_data"."user_id"')
        .having(plugin_having_query_J)
        .limit(limit)
     
      
      users.each do |user|
        @results.add(user)
      end
    end
     def posts_query(limit, opts = nil)
      opts ||= {}
        
    
      plugin_user_J = User.find(@opts[:user_id])
      if(plugin_user_J.custom_fields["secondary_group"].nil?)
        plugin_secondary_group_J =  Array.new
      else
         plugin_secondary_group_J =  JSON.parse(plugin_user_J.custom_fields["secondary_group"])
      end
      plugin_where_query_array_J=Array.new;
      plugin_secondary_group_J.each do |plugin_temp_secondary_group_J|
        plugin_where_query_array_J <<  " '"+plugin_temp_secondary_group_J+"' = ANY (array_agg(groups.name)) "
      end
      primaryGrrpId = plugin_user_J['primary_group_id']
      unless plugin_user_J['primary_group_id'].nil?
             plugin_where_query_array_J << ' "users"."primary_group_id" = '+plugin_user_J['primary_group_id'].to_s
                
      end
      plugin_where_query_J =plugin_where_query_array_J.join("OR")
      if(plugin_where_query_J == "")
        plugin_where_query_J = '1=2'
      end
      posts = Post.where(post_type: Topic.visible_post_types(@guardian.user))       
        .joins(:post_search_data, :topic)
        .joins("LEFT JOIN categories ON categories.id = topics.category_id")  
        .joins(' FULL JOIN user_custom_fields ON "user_custom_fields"."user_id"="posts"."user_id"')  
        .joins(' INNER JOIN users ON "users"."id"="posts"."user_id"') 
        .joins(' INNER JOIN group_users ON "group_users"."user_id"="users"."id"')
        .joins(' INNER JOIN groups ON "group_users"."group_id"="groups"."id"') 
        .where("topics.deleted_at" => nil)
        .where("topics.visible")
        .group('"posts"."id"')
        .group('"users"."id"')  
        .group('"topics"."id"')
         .group('"post_search_data"."post_id"')
        .having(plugin_where_query_J)   
      
                
      
      
      is_topic_search = @search_context.present? && @search_context.is_a?(Topic)

      if opts[:private_messages] || (is_topic_search && @search_context.private_message?)
        posts = posts.where("topics.archetype =  ?", Archetype.private_message)

         unless @guardian.is_admin?
           posts = posts.private_posts_for_user(@guardian.user)
         end
      else
        posts = posts.where("topics.archetype <> ?", Archetype.private_message)
      end

      if @term.present?
        if is_topic_search

          term_without_quote = @term
          if @term =~ /"(.+)"/
            term_without_quote = $1
          end

          if @term =~ /'(.+)'/
            term_without_quote = $1
          end

          posts = posts.joins('JOIN users u ON u.id = posts.user_id')
          posts = posts.where("posts.raw  || ' ' || u.username || ' ' || COALESCE(u.name, '') ilike ?", "%#{term_without_quote}%")
        else
          weights = @in_title ? 'A' : (SiteSetting.tagging_enabled ? 'ABCD' : 'ABD')
          posts = posts.where("post_search_data.search_data @@ #{ts_query(weight_filter: weights)}")
          exact_terms = @term.scan(/"([^"]+)"/).flatten
          exact_terms.each do |exact|
            posts = posts.where("posts.raw ilike ?", "%#{exact}%")
          end
        end
      end

      @filters.each do |block, match|
        if block.arity == 1
          posts = instance_exec(posts, &block) || posts
        else
          posts = instance_exec(posts, match, &block) || posts
        end
      end if @filters

      
      if @search_context.present?

        if @search_context.is_a?(User)

          if opts[:private_messages]
            posts = posts.private_posts_for_user(@search_context)
          else
            posts = posts.where("posts.user_id = #{@search_context.id}")
          end

        elsif @search_context.is_a?(Category)
          category_ids = [@search_context.id] + Category.where(parent_category_id: @search_context.id).pluck(:id)
          posts = posts.where("topics.category_id in (?)", category_ids)
        elsif @search_context.is_a?(Topic)
          posts = posts.where("topics.id = #{@search_context.id}")
            .order("posts.post_number #{@order == :latest ? "DESC" : ""}")
        end

      end

      if @order == :latest || (@term.blank? && !@order)
        if opts[:aggregate_search]
          posts = posts.order("MAX(posts.created_at) DESC")
        else
          posts = posts.reorder("posts.created_at DESC")
        end
      elsif @order == :latest_topic
        if opts[:aggregate_search]
          posts = posts.order("MAX(topics.created_at) DESC")
        else
          posts = posts.order("topics.created_at DESC")
        end
      elsif @order == :views
        if opts[:aggregate_search]
          posts = posts.order("MAX(topics.views) DESC")
        else
          posts = posts.order("topics.views DESC")
        end
      elsif @order == :likes
        if opts[:aggregate_search]
          posts = posts.order("MAX(posts.like_count) DESC")
        else
          posts = posts.order("posts.like_count DESC")
        end
      else
        data_ranking = "TS_RANK_CD(post_search_data.search_data, #{ts_query})"
        if opts[:aggregate_search]
          posts = posts.order("MAX(#{data_ranking}) DESC")
        else
          posts = posts.order("#{data_ranking} DESC")
        end
        posts = posts.order("topics.bumped_at DESC")
      end

      if secure_category_ids.present?
        posts = posts.where("(categories.id IS NULL) OR (NOT categories.read_restricted) OR (categories.id IN (?))", secure_category_ids).references(:categories)
      else
        posts = posts.where("(categories.id IS NULL) OR (NOT categories.read_restricted)").references(:categories)
      end

      posts = posts.offset(offset)
    
      posts.limit(limit)
    
    end
  end   

       
    module ::CustomSecondarGroups
        class Engine < ::Rails::Engine
            engine_name "custom_secondary_groups"
            isolate_namespace CustomSecondarGroups
        end
    end
   
   
  
   
    class CustomSecondarGroups::SecondarygroupController < ::ApplicationController
        before_action :ensure_logged_in
        def clear_secondary_group
          me = User.find_by(username: params[:username]);
          objArray = Array.new
          me.custom_fields["secondary_group"] = objArray.to_json;
          me.save;
          render :json =>me.custom_fields["secondary_group"], :status => 200
        end
        
        
        def set_secondary_group
        	 me = User.find_by(username: params[:username])
        	 secondary_group =  params[:secondary_group].split(',')
        	   
        	   
        	  
        	 objArray = Array.new
             secondary_group.each do |object|
                objArray << object
             end

        	 me = User.find_by(username: params[:username])
        	 me.custom_fields["secondary_group"] = objArray.to_json
        	 me.save
        	 render :json =>me.custom_fields["secondary_group"], :status => 200
       end
   
       def view_secondary_group
           me = User.find_by(username: params[:username])
           render :json =>me.custom_fields["secondary_group"], :status => 200
       end
   end
    CustomSecondarGroups::Engine.routes.draw do
        get '/secondary_group_api/setgroup/:username/:secondary_group' => 'secondarygroup#set_secondary_group'
        get '/secondary_group_api/viewgroup/:username/' => 'secondarygroup#view_secondary_group'
        get '/secondary_group_api/cleargroup/:username/' => 'secondarygroup#clear_secondary_group'
    end

    Discourse::Application.routes.append do
        mount ::CustomSecondarGroups::Engine, at: "/"
    end
end
