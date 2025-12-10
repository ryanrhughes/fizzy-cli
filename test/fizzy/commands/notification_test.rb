require "test_helper"

class Fizzy::Commands::NotificationTest < Fizzy::TestCase
  def setup
    super
    @original_home = ENV["HOME"]
    @temp_dir = Dir.mktmpdir
    ENV["HOME"] = @temp_dir

    config = Fizzy::Config.new
    config.save!(token: "test_token", account: "test_account")
  end

  def teardown
    super
    ENV["HOME"] = @original_home
    FileUtils.rm_rf(@temp_dir)
  end

  def test_list_returns_notifications
    stub_request(:get, "https://app.fizzy.do/test_account/notifications")
      .to_return(
        status: 200,
        body: '[{"id": "n1", "title": "New comment", "read": false}]',
        headers: { "Content-Type" => "application/json" }
      )

    output = capture_output do
      Fizzy::Commands::Notification.new.invoke(:list, [])
    end

    result = JSON.parse(output)
    assert result["success"]
    assert_equal 1, result["data"].length
    assert_equal "New comment", result["data"][0]["title"]
  end

  def test_list_with_pagination
    stub_request(:get, "https://app.fizzy.do/test_account/notifications")
      .with(query: { "page" => "2" })
      .to_return(
        status: 200,
        body: '[{"id": "n2", "title": "Old notification"}]',
        headers: { "Content-Type" => "application/json" }
      )

    output = capture_output do
      Fizzy::Commands::Notification.new([], { page: 2 }).invoke(:list, [])
    end

    result = JSON.parse(output)
    assert result["success"]
    assert_equal "Old notification", result["data"][0]["title"]
  end

  def test_read_notification
    stub_request(:post, "https://app.fizzy.do/test_account/notifications/n1/reading")
      .to_return(
        status: 200,
        body: '{"id": "n1", "read": true}',
        headers: { "Content-Type" => "application/json" }
      )

    output = capture_output do
      Fizzy::Commands::Notification.new.invoke(:read, ["n1"])
    end

    result = JSON.parse(output)
    assert result["success"]
  end

  def test_unread_notification
    stub_request(:delete, "https://app.fizzy.do/test_account/notifications/n1/reading")
      .to_return(status: 204, body: "")

    output = capture_output do
      Fizzy::Commands::Notification.new.invoke(:unread, ["n1"])
    end

    result = JSON.parse(output)
    assert result["success"]
    assert result["data"]["unread"]
  end

  def test_read_all_notifications
    stub_request(:post, "https://app.fizzy.do/test_account/notifications/bulk_reading")
      .to_return(
        status: 200,
        body: '{"read_count": 5}',
        headers: { "Content-Type" => "application/json" }
      )

    output = capture_output do
      Fizzy::Commands::Notification.new.invoke(:read_all, [])
    end

    result = JSON.parse(output)
    assert result["success"]
  end

  private

  def capture_output
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
