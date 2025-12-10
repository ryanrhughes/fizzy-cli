module Fizzy
  module Commands
    class Reaction < Base
      desc "list", "List reactions on a comment"
      option :card, required: true, type: :string, desc: "Card number"
      option :comment, required: true, type: :string, desc: "Comment ID"
      def list
        result = client.get(client.account_path("/cards/#{options[:card]}/comments/#{options[:comment]}/reactions"))
        output(result)
      rescue Fizzy::Error => e
        output_error(e)
      end

      desc "create", "Add a reaction to a comment"
      option :card, required: true, type: :string, desc: "Card number"
      option :comment, required: true, type: :string, desc: "Comment ID"
      option :content, required: true, type: :string, desc: "Emoji (max 16 chars)"
      def create
        result = client.post(
          client.account_path("/cards/#{options[:card]}/comments/#{options[:comment]}/reactions"),
          { reaction: { content: options[:content] } }
        )
        output(result)
      rescue Fizzy::Error => e
        output_error(e)
      end

      desc "delete ID", "Remove a reaction"
      option :card, required: true, type: :string, desc: "Card number"
      option :comment, required: true, type: :string, desc: "Comment ID"
      def delete(id)
        result = client.delete(client.account_path("/cards/#{options[:card]}/comments/#{options[:comment]}/reactions/#{id}"))
        output(result || Response.success(data: { deleted: true }))
      rescue Fizzy::Error => e
        output_error(e)
      end
    end
  end
end
