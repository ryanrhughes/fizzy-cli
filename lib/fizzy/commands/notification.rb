module Fizzy
  module Commands
    class Notification < Base
      desc "list", "List notifications"
      option :page, type: :numeric, desc: "Page number"
      option :all, type: :boolean, default: false, desc: "Fetch all pages"
      def list
        params = {}
        params[:page] = options[:page] if options[:page]

        result = if options[:all]
          client.get_all(client.account_path("/notifications"), params)
        else
          client.get(client.account_path("/notifications"), params)
        end
        output(result)
      rescue Fizzy::Error => e
        output_error(e)
      end

      desc "read ID", "Mark a notification as read"
      def read(id)
        result = client.post(client.account_path("/notifications/#{id}/reading"), {})
        output(result)
      rescue Fizzy::Error => e
        output_error(e)
      end

      desc "unread ID", "Mark a notification as unread"
      def unread(id)
        result = client.delete(client.account_path("/notifications/#{id}/reading"))
        output(result || Response.success(data: { unread: true }))
      rescue Fizzy::Error => e
        output_error(e)
      end

      map "read-all" => :read_all
      desc "read-all", "Mark all notifications as read"
      def read_all
        result = client.post(client.account_path("/notifications/bulk_reading"), {})
        output(result)
      rescue Fizzy::Error => e
        output_error(e)
      end
    end
  end
end
