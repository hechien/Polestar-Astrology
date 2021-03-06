module Extensions
  module BsFriendlyId
    extend ActiveSupport::Concern

    module ClassMethods
      def friendly_id(column, options={})
        # alias_method :find_without_friendly_id, :find
        # alias_method :find, :find_with_friendly_id
        @column = column
        if options[:cache]
          @cache_find = true
          
          class_eval do
            def friendly_id
              slug
            end

            def self.all
              key= self.name + '/all'
              
              Rails.cache.fetch key do
                logger.info "Loading #{key}."
                super().load
              end
              # if Rails.cache.exist?(key)
              #   puts "Found #{key}."
              #   return Rails.cache.read(key)
              # else
              #   val = super().load
              #   Rails.cache.write(key, val)
              #   logger.info "Loaded All: #{key}"
              #   return val
              # end
            end
          end
        end
        
        def generate_friendly_id_for(str, id=nil)
          if id
            base_scope = where.not(id: id)
          else
            base_scope = all
          end
          
          i = nil
          if base_scope.where(slug: str.parameterize).exists?
            i = 2
            while base_scope.where(slug: "#{str} #{i}".parameterize).exists?
              i += 1
            end
          end
          str = "#{str} #{i}" unless i.nil?
          return str.parameterize
        end
        
        before_create do |model|
          model.slug = self.class.generate_friendly_id_for(model.send(column))
        end
        before_update do |model|
          model.slug = self.class.generate_friendly_id_for(model.send(column), self.id)
        end
      end
      
      def __cache_setup__(id, &block)
        if @cache_find
          key = self.name + '/' + id.to_s
          Rails.cache.fetch key do
            logger.info key
            block.call
          end

          # if Rails.cache.exist?(key)
          #   puts "No need to call Find() for #{key}"
          #   return Rails.cache.read(key)
          # else
          #   val = block.call
          #   Rails.cache.write(key, val)
          #   logger.info "Loaded and saved #{key}"
          #   return val
          # end
        else
          block.call
        end
      end
      
      def find(*args)
        id = args[0]
        __cache_setup__(id) do
          if id.kind_of?(String)
            if id.to_i > 0
              super(*args)
            else
              val = find_by(slug: args[0])
              if val
                return val
              else
                raise ActiveRecord::RecordNotFound.new("Could not find object with ID=#{args[0]}")
              end
            end
          else
            super(*args)
          end
        end  #  End cache setup block
      end
    end
  end
end

# @categories = Rails.cache.fetch("global/categories", expires_in: 10.minutes) do
#       Category.where("posts_count > 0").all
#     end