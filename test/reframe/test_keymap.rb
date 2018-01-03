require_relative "../test_helper"

class TestKeymap < Textbringer::TestCase
  def test_lookup
    keymap = Keymap.new
    keymap.define_key("a", :a)
    keymap.define_key("\C-f", :c_f)
    keymap.define_key("\C-x\C-s", :c_x_c_s)
    keymap.define_key(:right, :right)
    assert_raise(ArgumentError) do
      keymap.define_key([], :foo)
    end
    assert_raise(TypeError) do
      keymap.define_key({}, :foo)
    end

    assert_equal(:a, keymap.lookup([?a]))
    assert_equal(:c_f, keymap.lookup([?\C-f]))
    assert_equal(:c_x_c_s, keymap.lookup([?\C-x, ?\C-s]))
    assert_equal(:right, keymap.lookup([:right]))
    assert_equal(nil, keymap.lookup([?x]))
    assert_equal(nil, keymap.lookup([?\C-x, ?s]))
    assert_raise(ArgumentError) do
      keymap.lookup([])
    end
  end

  def test_global_map
    assert_equal(:self_insert, GLOBAL_MAP.lookup([?a]))
    assert_equal(:self_insert, GLOBAL_MAP.lookup([?あ]))
    assert_equal(nil, GLOBAL_MAP.lookup([?\C-c]))
    assert_equal(nil, GLOBAL_MAP.lookup([:foo]))
  end

  def test_s_key_name
    assert_equal("<f1>", Keymap.key_name(:f1))
    assert_equal("SPC", Keymap.key_name(" "))
    assert_equal("TAB", Keymap.key_name("\t"))
    assert_equal("RET", Keymap.key_name("\r"))
    assert_equal("ESC", Keymap.key_name("\e"))
    assert_equal("C-x", Keymap.key_name("\C-x"))
    assert_equal("C-j", Keymap.key_name("\C-j"))
    assert_equal("x", Keymap.key_name("x"))
    assert_equal("あ", Keymap.key_name("あ"))
  end
end
