module Lolita
  module ControllerUtilities
    def self.included(base) # :nodoc:
      base.class_eval{
        include InstanceMethods
      }
    end

    # To receive real id for _object_ or url id form #MetaData get_id can be used.
    # ====Example
    #     <i># To get _object_ id</i>
    #     Metadata.find(:all) #=> [{:metaable_type=>"cms/blog", :metaable_id=>5, :url=>"about_me"}]
    #     get_id(Cms::Blog.find(5)) #=> "about_me"
    #     get_id(Cms::Blog.find(1)) #=> 1
    #     <i> # To get real _object_ id</i>
    #     params[:id] #=> "about_me"
    #     get_id #=> 5
    #     get_id(:id) #=> 5
    #     params[:blog_id] #=> "about_me"
    #     get_id(:blog_id) #=> 5
    module InstanceMethods
      # Return name based on <em>:controller</em> name.
      # ====Example
      #     params[:controller] #=> cms/blog
      #     current_session_name #=> :cms_blog
      def current_session_name
        params[:controller].gsub(/^\//,"").gsub("/","_").to_sym
      end

      # Return number that is used to identify temporary #Media files.
      # ====Example
      #     get_temp_id #=> 5436784
      def get_temp_id
        (("%10.7f" % rand).to_f*10000000).to_i
      end
      private

      def menu_actions
        []
      end

      def controller_in_parts controller=params[:controller]
        p=controller.to_s.split(/\//)
        p.shift if p[0].size<1
        p
      end
      def get_id(object=nil,controller=nil)
        object ? (object.is_a?(Symbol) ? get_url_for(object,controller) : make_url_for(object)) : get_url_for
      end

      def make_url_for(object)
        if meta_data=MetaData.find_by_object(object)
          meta_data.url
        else
          object.id
        end
      end

      def get_url_for(name=nil,controller=nil)
        name||=:id
        if params[name] && (params[name].is_a?(Integer) || (params[name].to_i.to_s.size==params[name].to_s.size))
          params[name].to_i
        else
          meta_data=MetaData.by_metaable(params[name]||params[:meta_url],controller || params[:controller])
          meta_data.metaable_id if meta_data
        end
      end
    end
  end
end