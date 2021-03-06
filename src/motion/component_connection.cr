module Motion
  # :nodoc:
  class ComponentConnection
    def self.from_state(state)
      new(component: Motion.serializer.deserialize(state))
    end

    getter component : Motion::Base
    getter render_hash : UInt64?

    def initialize(@component : Motion::Base)
      timing("Connected #{@component.class}") do
        @render_hash = component.render_hash
      end
    end

    def close(&block : Motion::Base -> Nil)
      timing("Disconnected #{@component.class}") do
        block.call(component)
      end

      true
    rescue error : Exception
      handle_error(error, "disconnecting the component")

      false
    end

    def process_motion(motion : String, event : Motion::Event? = nil)
      timing("Proccessed #{motion}") do
        component.process_motion(motion, event)
      end

      true
    rescue error : Exception
      handle_error(error, "processing #{motion}")

      false
    end

    def process_model_stream(stream_topic)
      timing("Proccessed model stream #{stream_topic} for #{@component.class}") do
        component._process_model_stream
      end

      true
    rescue error : Exception
      handle_error(error, "processing model stream #{stream_topic} for #{@component.class}")

      false
    end

    def process_periodic_timer(timer : Proc(Nil), name : String)
      timing("Proccessed periodic timer #{name}") do
        # component.process_periodic_timer timer
        timer.call
      end

      true
    rescue error : Exception
      handle_error(error, "processing periodic timer #{timer}")

      false
    end

    def if_render_required(proc)
      timing("Rendered") do
        next_render_hash = component.render_hash

        next if @render_hash == next_render_hash
        # && !component.awaiting_forced_rerender?

        proc.call(component)

        @render_hash = next_render_hash
      end
    rescue error : Exception
      handle_error(error, "rendering the component")
    end

    # def broadcasts
    #   component.broadcasts
    # end

    def periodic_timers
      component.periodic_timers
    end

    private def timing(context, &block)
      logger.timing(context, &block)
    end

    private def handle_error(error, context)
      logger.error("An error occurred while #{context}. Error: #{error}")
    end

    private def logger
      Motion.logger
    end
  end
end
