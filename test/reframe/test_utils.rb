require_relative "../test_helper"

class TestUtils < ReFrame::TestCase
  def test_message
    message("hello world")
    assert_equal("hello world", Window.echo_area.message)

    buffer = Buffer["*Messages*"]
    buffer.read_only = false
    buffer.clear
    (1..1000).each do |i|
      buffer.insert("message#{i}\n")
    end
    buffer.read_only = true
    message("message1001")
    assert_equal("message1001", Window.echo_area.message)
    assert_equal((11..1001).map {|i| "message#{i}\n"}.join, buffer.to_s)

    message("foo", sit_for: 0.01)
    message("foo")
    message("bar", sleep_for: 0.01)
    message("bar")

    message(42)
    assert_equal("42", Window.echo_area.message)
  end

  def test_show_exception
    begin
      raise EditorError, "editor error"
    rescue => e
      show_exception(e)
      assert_equal(e.to_s, Window.echo_area.message)
    end

    begin
      exit
    rescue SystemExit => e
      assert_raise(SystemExit) do
        show_exception(e)
      end
    end
  end

  def test_read_event
    push_keys([?a, :up])
    assert_equal("a", read_event)
    assert_equal(:up, read_event)
  end

  def test_read_char
    push_keys([?a, :up])
    assert_equal("a", read_char)
    assert_raise(EditorError) do
      read_char
    end
  end

  def test_read_from_minibuffer
    push_keys("\n")
    s = read_from_minibuffer("Input: ")
    assert_equal("", s)

    push_keys("\n")
    s = read_from_minibuffer("Input: ", default: "hello")
    assert_equal("hello", s)

    push_keys("foobar\n")
    s = read_from_minibuffer("Input: ", default: "hello")
    assert_equal("foobar", s)

    Window.echo_area.active = true
    assert_raise(EditorError) do
      read_from_minibuffer("Input: ")
    end
  end

  def test_read_file_name
    push_keys("foo.rb\n")
    s = read_file_name("File name: ")
    assert_equal(File.expand_path("foo.rb"), s)

    push_keys("RE\t\n")
    s = read_file_name("File name: ")
    assert_equal(File.expand_path("README.md"), s)

    push_keys("lib\t\n")
    s = read_file_name("File name: ")
    assert_equal(File.expand_path("lib/"), s)

    push_keys("nosuchfile\t\n")
    s = read_file_name("File name: ")
    assert_equal(File.expand_path("nosuchfile"), s)
  end

  def test_read_buffer
    push_keys("foo\n")
    s = read_buffer("Buffer: ")
    assert_equal("foo", s)

    Buffer.new_buffer("foobar")
    push_keys("foo\t\n")
    s = read_buffer("Buffer: ")
    assert_equal("foobar", s)

    Buffer.new_buffer("fooquux")
    push_keys("f\tq\t\n")
    s = read_buffer("Buffer: ")
    assert_equal("fooquux", s)
  end

  def test_read_command_name
    push_keys("foo\n")
    s = read_command_name("Command: ")
    assert_equal("foo", s)

    push_keys("eval-ex\t\n")
    s = read_command_name("Command: ")
    assert_equal("eval_expression", s)
  end

  def test_yes_or_no?
    push_keys("yes\n")
    assert_equal(true, yes_or_no?("Execute?"))

    push_keys("no\n")
    assert_equal(false, yes_or_no?("Execute?"))

    push_keys("foo\nyes\n")
    assert_equal(true, yes_or_no?("Execute?"))

    push_keys("foo\nno\n")
    assert_equal(false, yes_or_no?("Execute?"))
  end

  def test_y_or_n?
    push_keys("y")
    assert_equal(true, y_or_n?("Execute?"))

    push_keys("n")
    assert_equal(false, y_or_n?("Execute?"))

    push_keys("ay")
    assert_equal(true, y_or_n?("Execute?"))

    push_keys("an")
    assert_equal(false, y_or_n?("Execute?"))
  end

  def test_read_single_char
    push_keys("c")
    assert_equal("c", read_single_char("Choose", "abcde".chars))

    push_keys("xc")
    assert_equal("c", read_single_char("Choose", "abcde".chars))
  end

  def test_read_key_sequence
    push_keys("\C-x\C-f")
    assert_equal(["\C-x", "\C-f"], read_key_sequence("Key: "))

    push_keys("\C-c\C-a")
    assert_raise(EditorError) do
      read_key_sequence("Key: ")
    end
  end

  def test_hooks
    count = 0
    hook = -> { count += 1 }
    add_hook(:test_hook, hook)
    run_hooks(:test_hook)
    assert_equal(1, count)
    run_hooks(:test_hook)
    assert_equal(2, count)
    remove_hook(:test_hook, hook)
    run_hooks(:test_hook)
    assert_equal(2, count)
    hook2 = -> { raise "hook error" }
    add_hook(:test_hook, hook2)
    assert_equal([hook2], HOOKS[:test_hook])
    run_hooks(:test_hook, remove_on_error: true)
    assert_equal([], HOOKS[:test_hook])
    add_hook(:test_hook, hook2)
    assert_equal([hook2], HOOKS[:test_hook])
    assert_raise(RuntimeError) do
      run_hooks(:test_hook)
    end
    assert_equal([hook2], HOOKS[:test_hook])
  end

  def test_set_transient_map
    map = Keymap.new
    map.define_key("a", -> {
      Buffer.current.insert("hello")
      exit_recursive_edit
    })
    push_keys("a")
    set_transient_map(map)
    recursive_edit
    assert_equal("hello", Buffer.current.to_s)
  end

  def test_gsub
    insert(<<EOF)
foo
bar
baz
EOF
    assert_equal(Buffer.current, gsub(/b(.*)/) {|s| s.capitalize})
    assert_equal(<<EOF, Buffer.current.to_s)
foo
Bar
Baz
EOF
  end
end
