require "test_helper"

class Fizzy::Commands::StepTest < Fizzy::TestCase
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

  def test_show_returns_step
    stub_request(:get, "https://app.fizzy.do/test_account/cards/42/steps/s1")
      .to_return(
        status: 200,
        body: '{"id": "s1", "content": "Do this thing", "completed": false}',
        headers: { "Content-Type" => "application/json" }
      )

    output = capture_output do
      Fizzy::Commands::Step.new([], { card: "42" }).invoke(:show, ["s1"])
    end

    result = JSON.parse(output)
    assert result["success"]
    assert_equal "s1", result["data"]["id"]
    assert_equal "Do this thing", result["data"]["content"]
  end

  def test_create_step
    stub_request(:post, "https://app.fizzy.do/test_account/cards/42/steps")
      .with(
        body: { step: { content: "New step", completed: false } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      .to_return(
        status: 201,
        body: '{"id": "s2", "content": "New step", "completed": false}',
        headers: { "Content-Type" => "application/json" }
      )

    output = capture_output do
      Fizzy::Commands::Step.new([], { card: "42", content: "New step" }).invoke(:create, [])
    end

    result = JSON.parse(output)
    assert result["success"]
  end

  def test_create_step_completed
    stub_request(:post, "https://app.fizzy.do/test_account/cards/42/steps")
      .with(
        body: { step: { content: "Done step", completed: true } }.to_json
      )
      .to_return(
        status: 201,
        body: '{"id": "s3", "content": "Done step", "completed": true}',
        headers: { "Content-Type" => "application/json" }
      )

    output = capture_output do
      Fizzy::Commands::Step.new([], { card: "42", content: "Done step", completed: true }).invoke(:create, [])
    end

    result = JSON.parse(output)
    assert result["success"]
  end

  def test_update_step_content
    stub_request(:put, "https://app.fizzy.do/test_account/cards/42/steps/s1")
      .with(
        body: { step: { content: "Updated content" } }.to_json
      )
      .to_return(
        status: 200,
        body: '{"id": "s1", "content": "Updated content"}',
        headers: { "Content-Type" => "application/json" }
      )

    output = capture_output do
      Fizzy::Commands::Step.new([], { card: "42", content: "Updated content" }).invoke(:update, ["s1"])
    end

    result = JSON.parse(output)
    assert result["success"]
  end

  def test_update_step_mark_completed
    stub_request(:put, "https://app.fizzy.do/test_account/cards/42/steps/s1")
      .with(
        body: { step: { completed: true } }.to_json
      )
      .to_return(
        status: 200,
        body: '{"id": "s1", "completed": true}',
        headers: { "Content-Type" => "application/json" }
      )

    output = capture_output do
      Fizzy::Commands::Step.new([], { card: "42", completed: true }).invoke(:update, ["s1"])
    end

    result = JSON.parse(output)
    assert result["success"]
  end

  def test_update_step_mark_not_completed
    stub_request(:put, "https://app.fizzy.do/test_account/cards/42/steps/s1")
      .with(
        body: { step: { completed: false } }.to_json
      )
      .to_return(
        status: 200,
        body: '{"id": "s1", "completed": false}',
        headers: { "Content-Type" => "application/json" }
      )

    output = capture_output do
      Fizzy::Commands::Step.new([], { card: "42", not_completed: true }).invoke(:update, ["s1"])
    end

    result = JSON.parse(output)
    assert result["success"]
  end

  def test_delete_step
    stub_request(:delete, "https://app.fizzy.do/test_account/cards/42/steps/s1")
      .to_return(status: 204, body: "")

    output = capture_output do
      Fizzy::Commands::Step.new([], { card: "42" }).invoke(:delete, ["s1"])
    end

    result = JSON.parse(output)
    assert result["success"]
    assert result["data"]["deleted"]
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
