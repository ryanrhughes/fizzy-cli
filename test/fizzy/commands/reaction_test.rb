require "test_helper"

class Fizzy::Commands::ReactionTest < Fizzy::TestCase
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

  def test_list_returns_reactions
    stub_request(:get, "https://app.fizzy.do/test_account/cards/42/comments/c1/reactions")
      .to_return(
        status: 200,
        body: '[{"id": "r1", "content": "👍"}]',
        headers: { "Content-Type" => "application/json" }
      )

    output = capture_output do
      Fizzy::Commands::Reaction.new([], { card: "42", comment: "c1" }).invoke(:list, [])
    end

    result = JSON.parse(output)
    assert result["success"]
    assert_equal 1, result["data"].length
    assert_equal "👍", result["data"][0]["content"]
  end

  def test_create_reaction
    stub_request(:post, "https://app.fizzy.do/test_account/cards/42/comments/c1/reactions")
      .with(
        body: { reaction: { content: "🎉" } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      .to_return(
        status: 201,
        body: '{"id": "r2", "content": "🎉"}',
        headers: { "Content-Type" => "application/json" }
      )

    output = capture_output do
      Fizzy::Commands::Reaction.new([], { card: "42", comment: "c1", content: "🎉" }).invoke(:create, [])
    end

    result = JSON.parse(output)
    assert result["success"]
  end

  def test_delete_reaction
    stub_request(:delete, "https://app.fizzy.do/test_account/cards/42/comments/c1/reactions/r1")
      .to_return(status: 204, body: "")

    output = capture_output do
      Fizzy::Commands::Reaction.new([], { card: "42", comment: "c1" }).invoke(:delete, ["r1"])
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
