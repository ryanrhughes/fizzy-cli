module Fizzy
  module Commands
    class Step < Base
      desc "show ID", "Show a specific step (to-do item)"
      option :card, required: true, type: :string, desc: "Card number"
      def show(id)
        result = client.get(client.account_path("/cards/#{options[:card]}/steps/#{id}"))
        output(result)
      rescue Fizzy::Error => e
        output_error(e)
      end

      desc "create", "Create a new step (to-do item)"
      option :card, required: true, type: :string, desc: "Card number"
      option :content, required: true, type: :string, desc: "Step content"
      option :completed, type: :boolean, default: false, desc: "Mark as completed"
      def create
        step_params = {
          content: options[:content],
          completed: options[:completed]
        }

        result = client.post(client.account_path("/cards/#{options[:card]}/steps"), { step: step_params })
        output(result)
      rescue Fizzy::Error => e
        output_error(e)
      end

      desc "update ID", "Update a step"
      option :card, required: true, type: :string, desc: "Card number"
      option :content, type: :string, desc: "Step content"
      option :completed, type: :boolean, desc: "Mark as completed"
      option :not_completed, type: :boolean, desc: "Mark as not completed"
      def update(id)
        step_params = {}
        step_params[:content] = options[:content] if options.key?(:content)

        if options[:not_completed]
          step_params[:completed] = false
        elsif options.key?(:completed)
          step_params[:completed] = options[:completed]
        end

        result = client.put(client.account_path("/cards/#{options[:card]}/steps/#{id}"), { step: step_params })
        output(result)
      rescue Fizzy::Error => e
        output_error(e)
      end

      desc "delete ID", "Delete a step"
      option :card, required: true, type: :string, desc: "Card number"
      def delete(id)
        result = client.delete(client.account_path("/cards/#{options[:card]}/steps/#{id}"))
        output(result || Response.success(data: { deleted: true }))
      rescue Fizzy::Error => e
        output_error(e)
      end
    end
  end
end
