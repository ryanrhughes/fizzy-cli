require "test_helper"

class Fizzy::Commands::CardActionsTest < Fizzy::TestCase
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

  def test_close_card
    stub_request(:post, "https://app.fizzy.do/test_account/cards/42/closure")
      .to_return(
        status: 200,
        body: '{"id": "100", "number": 42, "status": "closed"}',
        headers: { "Content-Type" => "application/json" }
      )

    output = capture_output do
      Fizzy::Commands::Card.new.invoke(:close, ["42"])
    end

    result = JSON.parse(output)
    assert result["success"]
  end

  def test_reopen_card
    stub_request(:delete, "https://app.fizzy.do/test_account/cards/42/closure")
      .to_return(status: 204, body: "")

    output = capture_output do
      Fizzy::Commands::Card.new.invoke(:reopen, ["42"])
    end

    result = JSON.parse(output)
    assert result["success"]
    assert result["data"]["reopened"]
  end

  def test_postpone_card
    stub_request(:post, "https://app.fizzy.do/test_account/cards/42/not_now")
      .to_return(
        status: 200,
        body: '{"id": "100", "number": 42, "status": "not_now"}',
        headers: { "Content-Type" => "application/json" }
      )

    output = capture_output do
      Fizzy::Commands::Card.new.invoke(:postpone, ["42"])
    end

    result = JSON.parse(output)
    assert result["success"]
  end

  def test_move_card_to_column
    stub_request(:post, "https://app.fizzy.do/test_account/cards/42/triage")
      .with(
        body: { column_id: "col1" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      .to_return(
        status: 200,
        body: '{"id": "100", "number": 42}',
        headers: { "Content-Type" => "application/json" }
      )

    output = capture_output do
      Fizzy::Commands::Card.new([], { column: "col1" }).invoke(:column, ["42"])
    end

    result = JSON.parse(output)
    assert result["success"]
  end

  def test_untriage_card
    stub_request(:delete, "https://app.fizzy.do/test_account/cards/42/triage")
      .to_return(status: 204, body: "")

    output = capture_output do
      Fizzy::Commands::Card.new.invoke(:untriage, ["42"])
    end

    result = JSON.parse(output)
    assert result["success"]
    assert result["data"]["untriaged"]
  end

  def test_assign_user_to_card
    stub_request(:post, "https://app.fizzy.do/test_account/cards/42/assignments")
      .with(
        body: { assignee_id: "u1" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      .to_return(
        status: 200,
        body: '{"assigned": true}',
        headers: { "Content-Type" => "application/json" }
      )

    output = capture_output do
      Fizzy::Commands::Card.new([], { user: "u1" }).invoke(:assign, ["42"])
    end

    result = JSON.parse(output)
    assert result["success"]
  end

  def test_tag_card
    stub_request(:post, "https://app.fizzy.do/test_account/cards/42/taggings")
      .with(
        body: { tag_title: "urgent" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      .to_return(
        status: 200,
        body: '{"tagged": true}',
        headers: { "Content-Type" => "application/json" }
      )

    output = capture_output do
      Fizzy::Commands::Card.new([], { tag: "urgent" }).invoke(:tag, ["42"])
    end

    result = JSON.parse(output)
    assert result["success"]
  end

  def test_watch_card
    stub_request(:post, "https://app.fizzy.do/test_account/cards/42/watch")
      .to_return(
        status: 200,
        body: '{"watching": true}',
        headers: { "Content-Type" => "application/json" }
      )

    output = capture_output do
      Fizzy::Commands::Card.new.invoke(:watch, ["42"])
    end

    result = JSON.parse(output)
    assert result["success"]
  end

  def test_unwatch_card
    stub_request(:delete, "https://app.fizzy.do/test_account/cards/42/watch")
      .to_return(status: 204, body: "")

    output = capture_output do
      Fizzy::Commands::Card.new.invoke(:unwatch, ["42"])
    end

    result = JSON.parse(output)
    assert result["success"]
    assert result["data"]["unwatched"]
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
