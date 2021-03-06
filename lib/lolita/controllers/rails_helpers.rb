module Lolita
  module Controllers
    module RailsHelpers
      extend ActiveSupport::Concern
      include Lolita::Controllers::InternalHelpers
      included do
        if self.ancestors.include?(ActionController::Base)
          helpers = %w(resource resource_name use_mapping
                       resource_class lolita_mapping show_response current_form current_form=)
          hide_action *helpers

          helper_method *helpers
          prepend_before_filter :is_lolita_resource?
          prepend_around_filter :switch_locale
        end
      end

      # Return instance variable named as resource
      # For 'posts' instance variable will be @posts


      protected

      def notice(msg, options = {})
        lolita_head_msg(msg,"Lolita-Notice",options)
      end

      def alert(msg,options = {})
        lolita_head_msg(msg,"Lolita-Alert",options)
      end

      def error(msg, options = {})
        lolita_head_msg(msg,"Lolita-Error",options)
      end

      def lolita_head_msg(msg,key,options ={})
        msg = Base64.encode64(msg).gsub("\n","")
        response.headers[key] = msg
        if options[:return]
          {key => msg}
        end
      end

      def resource_attributes
        fix_attributes(params[resource_name] || {})
      end

      def resource_with_attributes(current_resource,attributes={})
        attributes||=resource_attributes
        attributes.each{|key,value|
          current_resource.send(:"#{key}=",value)
        }
        current_resource
      end

      def get_resource(id=nil)
        self.resource = resource_class.lolita.dbi.find_by_id(id || params[:id])
        raise Lolita::RecordNotFound unless self.resource
      end

      def build_resource(attributes=nil)
        self.run(:before_build_resource)
        attributes||=resource_attributes
        self.resource=resource_with_attributes(resource_class.new,attributes)
        self.run(:after_build_resource)
      end

      def nested_list?
        params[:nested] && params[:nested][:path]
      end

      def nested_resource_class conf_part
        @nested_resource_class ||= params[:nested][:parent].constantize.lolita.send(conf_part.to_sym).by_path(params[:nested][:path])
      end

      def build_response_for(conf_part,options={})
        # FIXME when asked for some resources that always create new object, there may
        # not be any args, like lolita.report on something like that
        @component_options = options
        if nested_list?
          @component_object = nested_resource_class(conf_part.to_sym)
        else
          @component_object = resource_class.lolita.send(conf_part.to_sym)
        end
        @component_builder = @component_object.build(@component_options)
      end


      private

      def fix_attributes attributes
        fix_rails_date_attributes attributes
      end

      def fix_rails_date_attributes attributes
        #{"created_at(1i)"=>"2011", "created_at(2i)"=>"4", "created_at(3i)"=>"19", "created_at(4i)"=>"16", "created_at(5i)"=>"14"}
        date_attributes = {}
        attributes.each_pair do |k,v|
          if k.to_s =~ /(.+)\((\d)i\)$/
            date_attributes[$1] = {} unless date_attributes[$1]
            date_attributes[$1][$2.to_i] = v.to_i
            attributes.delete(k)
          end
        end
        date_attributes.each_pair do |k,v|
          unless v.detect{|index,value| value == 0 && index<4}
            attributes[k] = v.size == 3 ? Date.new(v[1],v[2],v[3]) : Time.new(v[1],v[2],v[3],v[4],v[5])
          end
        end
        attributes
      end

      def switch_locale
        begin
          old_locale = ::I18n.locale
          if params[:locale]
            Lolita.locale = params[:locale].to_sym
            session[:lolita_locale] = Lolita.locale
          elsif Lolita.locales.include?(session[:lolita_locale])
            Lolita.locale = session[:lolita_locale]
          end
          ::I18n.locale = Lolita.locale
          yield
        ensure
          ::I18n.locale = old_locale
        end
      end

    end

  end
end