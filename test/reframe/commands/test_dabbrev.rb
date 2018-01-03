require_relative "../../test_helper"

class TestDabbrev < Textbringer::TestCase
  using DabbrevExtension

  def test_dabbrev_expand
    buffer = Buffer.new_buffer("foo")
    buffer.insert(<<EOF)
font
fox
fill
foo
for
baz
bar
foo
fo
foo
fork
folk
EOF
    buffer2 = Buffer.new_buffer("bar")
    buffer2.insert(<<EOF)
follow
foil
foo

foo
fortran
EOF
    buffer2.goto_line(4)

    buffer.goto_line(9)
    pos = buffer.point
    buffer.end_of_line
    buffer.dabbrev_expand
    assert_equal("foo", buffer.substring(pos, buffer.point))
    buffer.dabbrev_expand(true)
    assert_equal("for", buffer.substring(pos, buffer.point))
    buffer.dabbrev_expand(true)
    assert_equal("fox", buffer.substring(pos, buffer.point))
    buffer.dabbrev_expand(true)
    assert_equal("font", buffer.substring(pos, buffer.point))
    buffer.dabbrev_expand(true)
    assert_equal("fork", buffer.substring(pos, buffer.point))
    buffer.dabbrev_expand(true)
    assert_equal("folk", buffer.substring(pos, buffer.point))
    buffer.dabbrev_expand(true)
    assert_equal("foil", buffer.substring(pos, buffer.point))
    buffer.dabbrev_expand(true)
    assert_equal("follow", buffer.substring(pos, buffer.point))
    buffer.dabbrev_expand(true)
    assert_equal("fortran", buffer.substring(pos, buffer.point))
    assert_raise(EditorError) do
      buffer.dabbrev_expand(true)
    end
  end

  def test_dabbrev_expand_command
    assert_raise(EditorError) do
      dabbrev_expand_command
    end

    insert(<<EOF.chop)
foo
bar
f
EOF
    dabbrev_expand_command
    assert_equal(<<EOF.chop, Buffer.current.to_s)
foo
bar
foo
EOF
  end
end
